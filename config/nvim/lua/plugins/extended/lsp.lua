local U = require("mega.utils")
local SETTINGS = require("mega.settings")
local BORDER_STYLE = SETTINGS.border
local augroup = require("mega.autocmds").augroup
local command = vim.api.nvim_create_user_command
local methods = vim.lsp.protocol.Methods

local M = {}

return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "nvim-lua/lsp_extensions.nvim",
      "b0o/schemastore.nvim",
      "onsails/lspkind.nvim",
      "williamboman/mason.nvim",
      "youssef-lr/lsp-overloads.nvim",
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      {
        "j-hui/fidget.nvim",
        event = "LspAttach",
        cond = false,
        opts = {
          progress = {
            display = {
              done_icon = SETTINGS.icons.lsp.ok,
            },
          },
          notification = {
            view = {
              group_separator = "─────", -- digraph `hh`
            },
            window = {
              winblend = 0,
            },
          },
        },
      },
    },
    config = function()
      local lsp_ok, lspconfig = pcall(require, "lspconfig")
      if not lsp_ok then return nil end

      local diagnostic_ns = vim.api.nvim_create_namespace("hl_diagnostic_region")
      local diagnostic_timer
      local hl_cancel
      local hl_map = {
        [vim.diagnostic.severity.ERROR] = "DiagnosticVirtualTextError",
        [vim.diagnostic.severity.WARN] = "DiagnosticVirtualTextWarn",
        [vim.diagnostic.severity.HINT] = "DiagnosticVirtualTextHint",
        [vim.diagnostic.severity.INFO] = "DiagnosticVirtualTextInfo",
      }

      require("lspconfig.ui.windows").default_options.border = BORDER_STYLE

      local function show_diagnostic_popup(opts)
        local bufnr = opts
        if type(opts) == "table" then bufnr = opts.buf or 0 end
        -- Try to open diagnostics under the cursor
        local diags = vim.diagnostic.open_float(bufnr, { focus = false, scope = "cursor" })
        -- If there's no diagnostic under the cursor show diagnostics of the entire line
        if not diags then vim.diagnostic.open_float(bufnr, { focus = false, scope = "line" }) end
      end

      local function goto_diagnostic_hl(dir)
        assert(dir == "prev" or dir == "next")
        local diagnostic = vim.diagnostic["get_" .. dir]()
        if not diagnostic then return end

        if diagnostic_timer then
          diagnostic_timer:close()
          hl_cancel()
        end

        -- if end_col is 999, typically we'd get an out of range error from extmarks api
        if diagnostic.end_col ~= 999 then
          vim.api.nvim_buf_set_extmark(0, diagnostic_ns, diagnostic.lnum, diagnostic.col, {
            end_row = diagnostic.end_lnum,
            end_col = diagnostic.end_col,
            hl_group = hl_map[diagnostic.severity],
          })
        end

        hl_cancel = function()
          diagnostic_timer = nil
          hl_cancel = nil
          pcall(vim.api.nvim_buf_clear_namespace, 0, diagnostic_ns, 0, -1)
        end

        diagnostic_timer = vim.defer_fn(hl_cancel, 500)
        vim.diagnostic["goto_" .. dir]({ float = true })
      end

      local function go_to_unique_definition()
        vim.lsp.buf_request(0, "textDocument/definition", vim.lsp.util.make_position_params(), function(_, result, _, _)
          if not result or vim.tbl_isempty(result) then
            print("No definitions found")
            return
          end

          local unique_results = {}
          local seen = {}

          for _, def in ipairs(result) do
            local uri = def.uri or def.targetUri
            seen[uri] = def
          end

          for _, def in pairs(seen) do
            table.insert(unique_results, def)
          end

          if #unique_results == 1 then
            vim.lsp.util.jump_to_location(unique_results[1], "utf-8")
            mega.blink_cursorline(100, true)
          else
            local items = vim.lsp.util.locations_to_items(unique_results, "utf-8")
            vim.fn.setqflist({}, "r", { title = "LSP Definitions", items = items })
            vim.api.nvim_command("copen")
          end
        end)
      end

      local function fix_current_action()
        local params = vim.lsp.util.make_range_params() -- get params for current position
        params.context = {
          diagnostics = vim.diagnostic.get(),
          only = { "quickfix" },
        }

        local actions_per_client, err = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 900)

        if err then return end

        if actions_per_client == nil or vim.tbl_isempty(actions_per_client) or #actions_per_client == 0 then
          vim.notify("no quickfixes available")
          return
        end

        -- Collect the available actions
        local actions = {}
        for cid, resp in pairs(actions_per_client) do
          if resp.result ~= nil then
            for _, result in pairs(resp.result) do
              -- add the actions with a cid to the table
              local action = {}
              action["cid"] = cid
              for k, v in pairs(result) do
                action[k] = v
              end
              table.insert(actions, action)
            end
          end
        end

        -- Try to find a preferred action.
        local preferred_action = nil
        for _, action in ipairs(actions) do
          if action.isPreferred then
            preferred_action = action
            break
          end
        end

        -- If we failed to find a non-null-ls action, use the first one.
        local first_action = nil
        if #actions > 0 then first_action = actions[1] end

        local top_action = preferred_action or first_action

        local picked_one = false

        vim.lsp.buf.code_action({
          context = {
            only = { "quickfix" },
            diagnostics = vim.diagnostic.get(),
          },
          filter = function(action)
            if picked_one then
              return true
            elseif top_action ~= nil and action.title == top_action.title then
              picked_one = true
              return false
            else
              return true
            end
          end,
          apply = true,
        })
      end

      function M.on_attach(client, bufnr, cb)
        local filetype = vim.bo[bufnr].filetype
        local disabled_lsp_formatting = SETTINGS.disabled_lsp_formatters

        if SETTINGS.disabled_semantic_tokens[filetype] then client.server_capabilities.semanticTokensProvider = vim.NIL end

        -- if client.server_capabilities.signatureHelpProvider then require("mega.lsp_signature").setup(client) end
        if client.server_capabilities.codeLensProvider then vim.lsp.codelens.refresh({ bufnr = bufnr }) end

        for i = 1, #disabled_lsp_formatting do
          if disabled_lsp_formatting[i] == client.name then
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end
        end

        if client and client.supports_method("textDocument/inlayHint", { bufnr = bufnr }) then
          if SETTINGS.enabled_inlay_hints[filetype] then vim.lsp.inlay_hint.enable(true) end
        end

        -- EXCLUDE certain servers for diagnostics
        local diagnostic_handler = vim.lsp.handlers[methods.textDocument_publishDiagnostics]
        vim.lsp.handlers[methods.textDocument_publishDiagnostics] = function(err, result, ctx, config)
          local client_name = vim.lsp.get_client_by_id(ctx.client_id).name

          local fname = vim.api.nvim_buf_get_name(bufnr)
          local fext = fname:match("%.[^.]+$")

          -- FIXME: once "the one elixir ls to rule them all" (aka "Expert") is released, you can probably get rid of all of this non-sense i'm using to manage multiple elixir ls'
          -- this lets certain elixir language servers that i use to report diagnostics for test files (nextls doesn't, so i have to rely on elixirls or lexical to do this)
          if vim.tbl_contains(SETTINGS.diagnostic_exclusions, client_name) and fext ~= ".exs" then
            print("skipping diagnostics for " .. client_name)
            return
          else
            diagnostic_handler(err, result, ctx, config)
          end
        end

        -- EXCLUDE certain servers for definitions
        local definition_handler = vim.lsp.handlers[methods.textDocument_definition]
        vim.lsp.handlers[methods.textDocument_definition] = function(err, result, ctx, config)
          local client_name = vim.lsp.get_client_by_id(ctx.client_id).name
          if vim.tbl_contains(SETTINGS.definition_exclusions, client_name) then
            print("skipping definitions for " .. client_name)
            return
          end
          definition_handler(err, result, ctx, config)
        end

        -- EXCLUDE certain servers for references
        local references_handler = vim.lsp.handlers[methods.textDocument_references]
        vim.lsp.handlers[methods.textDocument_references] = function(err, result, ctx, config)
          local client_name = vim.lsp.get_client_by_id(ctx.client_id).name
          if vim.tbl_contains(SETTINGS.references_exclusions, client_name) then
            print("skipping references for " .. client_name)
            return
          end
          references_handler(err, result, ctx, config)
        end

        local md_namespace = vim.api.nvim_create_namespace("lsp_floats")

        --- Adds extra inline highlights to the given buffer.
        ---@param buf integer
        local function add_inline_highlights(buf)
          for l, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
            for pattern, hl_group in pairs({
              ["@%S+"] = "@parameter",
              ["^%s*(Parameters:)"] = "@text.title",
              ["^%s*(Return:)"] = "@text.title",
              ["^%s*(See also:)"] = "@text.title",
              ["{%S-}"] = "@parameter",
              ["|%S-|"] = "@text.reference",
            }) do
              local from = 1 ---@type integer?
              while from do
                local to
                from, to = line:find(pattern, from)
                if from then
                  vim.api.nvim_buf_set_extmark(buf, md_namespace, l - 1, from - 1, {
                    end_col = to,
                    hl_group = hl_group,
                  })
                end
                from = to and to + 1 or nil
              end
            end
          end
        end

        --- LSP handler that adds extra inline highlights, keymaps, and window options.
        --- Code inspired from `noice`.
        ---@param handler fun(err: any, result: any, ctx: any, config: any): integer?, integer?
        ---@param focusable boolean
        ---@return fun(err: any, result: any, ctx: any, config: any)
        local function enhanced_float_handler(handler, focusable)
          return function(err, result, ctx, config)
            local bufnr, winnr = handler(
              err,
              result,
              ctx,
              vim.tbl_deep_extend("force", config or {}, {
                border = "rounded",
                focusable = focusable,
                max_height = math.floor(vim.o.lines * 0.3),
                max_width = math.floor(vim.o.columns * 0.4),
              })
            )

            if not bufnr or not winnr then return end

            -- Conceal everything.
            vim.wo[winnr].concealcursor = "n"

            -- Extra highlights.
            add_inline_highlights(bufnr)

            -- Add keymaps for opening links.
            if focusable and not vim.b[bufnr].markdown_keys then
              vim.keymap.set("n", "K", function()
                -- Vim help links.
                local url = (vim.fn.expand("<cWORD>") --[[@as string]]):match("|(%S-)|")
                if url then return vim.cmd.help(url) end

                -- Markdown links.
                local col = vim.api.nvim_win_get_cursor(0)[2] + 1
                local from, to
                from, to, url = vim.api.nvim_get_current_line():find("%[.-%]%((%S-)%)")
                if from and col >= from and col <= to then
                  vim.system({ "xdg-open", url }, nil, function(res)
                    if res.code ~= 0 then vim.notify("Failed to open URL" .. url, vim.log.levels.ERROR) end
                  end)
                end
              end, { buffer = bufnr, silent = true })
              vim.b[bufnr].markdown_keys = true
            end
          end
        end
        -- vim.lsp.handlers[methods.textDocument_hover] = enhanced_float_handler(vim.lsp.handlers.hover, true)
        vim.lsp.handlers[methods.textDocument_signatureHelp] = enhanced_float_handler(vim.lsp.handlers.signature_help, false)

        local desc = function(d) return "[+lsp] " .. d end
        local map = vim.keymap.set
        local nmap = function(keys, func, d) map("n", keys, func, { buffer = bufnr, desc = desc(d), noremap = false }) end
        local vnmap = function(keys, func, d) map({ "v", "n" }, keys, func, { buffer = bufnr, desc = desc(d) }) end
        local icons = require("mega.settings").icons

        -- if action opens up qf list, open the first item and close the list
        local function choose_list_first(options)
          vim.fn.setqflist({}, " ", options)
          vim.cmd.cfirst()
        end

        nmap("<leader>lic", [[<cmd>LspInfo<CR>]], "connected client info")
        nmap("<leader>lim", [[<cmd>Mason<CR>]], "mason info")
        nmap("<leader>lil", [[<cmd>LspLog<CR>]], "logs (vsplit)")

        nmap("ge", show_diagnostic_popup, "[g]o to diagnostic hover")
        nmap("[d", function() goto_diagnostic_hl("prev") end, "Go to previous [D]iagnostic message")
        nmap("]d", function() goto_diagnostic_hl("next") end, "Go to next [D]iagnostic message")

        nmap("gq", function() vim.cmd("Trouble diagnostics toggle focus=true filter.buf=0") end, "[g]oto [q]uickfixlist buffer diagnostics (trouble)")
        nmap("gQ", function() vim.cmd("Trouble diagnostics toggle focus=true") end, "[g]oto [q]uickfixlist global diagnostics (trouble)")

        -- map("gd", function() require("telescope.builtin").lsp_definitions() end, "[g]oto [d]efinition")
        -- map("gd", require("telescope.builtin").lsp_definitions, "[g]oto [d]efinition")
        -- map("gd", function() vim.lsp.buf.definition({ on_list = choose_list_first }) end, "[g]oto [d]efinition")
        -- map("gd", vim.lsp.buf.definition, "[g]oto [d]efinition")
        -- nmap("gd", go_to_unique_definition, "[g]oto [d]efinition")
        nmap("gd", function()
          vim.lsp.buf.definition({ on_list = choose_list_first })
          vim.schedule(function()
            vim.cmd.norm("zz")
            mega.blink_cursorline(175)
          end)
        end, "[g]oto [d]efinition")
        nmap("gD", function()
          -- vim.schedule(function()
          --   vim.cmd("vsplit | lua vim.lsp.buf.definition()")
          --   vim.cmd("norm zz")
          -- end)

          -- vim.cmd.split({ mods = { vertical = true, split = "botright" } })
          -- vim.defer_fn(function()
          --   vim.lsp.buf.definition({ on_list = choose_list_first, reuse_win = false })
          --   -- vim.cmd.FzfLua("lsp_definitions")
          --   -- go_to_unique_definition()

          -- end, 700)

          require("fzf-lua").lsp_definitions({
            sync = true,
            jump_to_single_result = true,
            jump_to_single_result_action = require("fzf-lua.actions").file_vsplit,
          })
        end, "[g]oto [d]efinition (split)")
        -- map("gr", function() vim.cmd.Trouble("lsp_references focus=true") end, "[g]oto [r]eferences")
        -- map("gr", function() vim.cmd.FzfLua("lsp_references") end, "[g]oto [r]eferences")
        nmap("gr", function()
          if not vim.tbl_contains(SETTINGS.references_exclusions, client.name) then
            require("fzf-lua").lsp_references({
              includeDeclaration = false,
              ignore_current_line = true,
            })
          end
        end, "[g]oto [r]eferences")
        nmap("gI", require("telescope.builtin").lsp_implementations, "[g]oto [i]mplementation")
        nmap("<leader>ltd", require("telescope.builtin").lsp_type_definitions, "[t]ype [d]efinition")
        nmap("<leader>lsd", require("telescope.builtin").lsp_document_symbols, "[d]ocument [s]ymbols")
        nmap("<leader>lsw", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[w]orkspace [s]ymbols")
        vnmap("g.", function() fix_current_action() end, "[g]o run nearest/current code action")
        vnmap("<leader>la", vim.lsp.buf.code_action, "code [a]ctions")
        vnmap("<leader>lca", vim.lsp.buf.code_action, "[c]ode [a]ctions")
        nmap("ga", function() vim.cmd.FzfLua("lsp_code_actions") end, "[g]o [c]ode [a]ctions")
        -- nmap("K", vim.lsp.buf.hover, "hover documentation")

        if client.supports_method(methods.textDocument_signatureHelp) then
          if client and client.server_capabilities.signatureHelpProvider and vim.g.completer == "cmp" then
            require("lsp-overloads").setup(client, {
              -- UI options are mostly the same as those passed to vim.lsp.util.open_floating_preview
              silent = true,
              floating_window_above_cur_line = true,
              ui = {
                border = "rounded", -- The border to use for the signature popup window. Accepts same border values as |nvim_open_win()|.
                max_width = 130, -- Maximum signature popup width
                focusable = true, -- Make the popup float focusable
                focus = false, -- If focusable is also true, and this is set to true, navigating through overloads will focus into the popup window (probably not what you want)
                silent = true, -- Prevents noisy notifications (make false to help debug why signature isn't working)
                highlight = {
                  italic = true,
                  bold = true,
                  fg = "#ffffff",
                },
              },
              keymaps = {
                next_signature = "<M-j>",
                previous_signature = "<M-k>",
                next_parameter = "<M-l>",
                previous_parameter = "<M-h>",
              },
              display_automatically = true, -- Uses trigger characters to automatically display the signature overloads when typing a method signature
            })
          end
          -- -- map("i", "<C-k>", vim.lsp.buf.signature_help, { buffer = bufnr, desc = desc("signature help") })
          -- map("i", "<C-s>", function()
          --   -- Close the completion menu first (if open).
          --   local cmp = require("cmp")
          --   if cmp.visible() then cmp.close() end

          --   -- vim.lsp.buf.signature_help()

          --   vim.cmd.LspOverloadsSignature()
          -- end, { buffer = bufnr, silent = true, noremap = true, desc = desc("signature help") })
        end
        -- map("gD", vim.lsp.buf.declaration, "[g]oto [d]eclaration (e.g. to a header file in C)")
        -- rename symbol starting with empty prompt, highlight references
        nmap("<leader>rn", function()
          local bufnr = vim.api.nvim_get_current_buf()
          local params = vim.lsp.util.make_position_params()
          params.context = { includeDeclaration = true }
          local clients = vim.lsp.get_clients()
          if not clients or #clients == 0 then
            vim.print("No attached clients.")
            return
          end
          local clnt = clients[1]
          for _, possible_client in pairs(clients) do
            if possible_client.server_capabilities.renameProvider then
              clnt = possible_client
              break
            end
          end

          local ns = vim.api.nvim_create_namespace("LspRenamespace")
          clnt.request("textDocument/references", params, function(_, result)
            if not result or vim.tbl_isempty(result) then
              vim.notify("Nothing to rename.")
              return
            end

            for _, v in ipairs(result) do
              if v.range then
                local buf = vim.uri_to_bufnr(v.uri)
                local line = v.range.start.line
                local start_char = v.range.start.character
                local end_char = v.range["end"].character
                if buf == bufnr then
                  print(line, start_char, end_char)
                  vim.api.nvim_buf_add_highlight(bufnr, ns, "LspReferenceWrite", line, start_char, end_char)
                end
              end
            end
            vim.cmd.redraw()
            local new_name = vim.fn.input({ prompt = "New name: " })
            vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
            if #new_name == 0 then return end
            vim.lsp.buf.rename(new_name)
          end, bufnr)
        end, "[r]e[n]ame")

        -- map("<leader>rn", function()
        --   local params = vim.lsp.util.make_position_params()
        --   local current_symbol = vim.fn.expand("<cword>")
        --   params.old_symbol = current_symbol
        --   params.context = { includeDeclaration = true }
        --   local clients = vim.lsp.get_clients()
        --   client = clients[1]
        --   for _, possible_client in pairs(clients) do
        --     if possible_client.server_capabilities.renameProvider then
        --       client = possible_client
        --       break
        --     end
        --   end
        --   local ns = vim.api.nvim_create_namespace("LspRenamespace")
        --
        --   client.request("textDocument/references", params, function(_, result)
        --     if not result or vim.tbl_isempty(result) then
        --       vim.notify("Nothing to rename.")
        --       return
        --     end
        --
        --     for _, v in ipairs(result) do
        --       if v.range then
        --         local buf = vim.uri_to_bufnr(v.uri)
        --         local line = v.range.start.line
        --         local start_char = v.range.start.character
        --         local end_char = v.range["end"].character
        --         if buf == bufnr then
        --           -- print(line, start_char, end_char)
        --           vim.api.nvim_buf_add_highlight(bufnr, ns, "LspReferenceWrite", line, start_char, end_char)
        --         end
        --       end
        --     end
        --     vim.cmd.redraw()
        --     local new_name = vim.fn.input({ prompt = fmt("%s (%d) -> ", params.old_symbol, #result) })
        --     vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
        --     if #new_name == 0 then return end
        --     vim.lsp.buf.rename(new_name)
        --   end, bufnr)
        -- end, "[R]e[n]ame")
        --
        nmap("gn", function()
          local params = vim.lsp.util.make_position_params()
          client.request("textDocument/references", params, function(_, result)
            if not result or vim.tbl_isempty(result) then
              vim.notify("Nothing to rename.")
              return
            end
          end)

          -- populate qf list with changes (if multiple files modified)
          local function qf_rename()
            local rename_prompt = ""
            local default_rename_prompt = " -> "
            local current_name = ""

            local pos_params = vim.lsp.util.make_position_params()
            pos_params.oldName = vim.fn.expand("<cword>")
            pos_params.context = { includeDeclaration = true }

            local function cleanup_rename_callback(winnr)
              vim.api.nvim_win_close(winnr or 0, true)
              vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "i", true)

              current_name = ""
              rename_prompt = default_rename_prompt
            end

            local rename_callback = function()
              local input = vim.trim(vim.fn.getline("."):sub(#rename_prompt, -1))

              if input == nil then
                vim.notify("aborted", L.WARN, { title = "[lsp] rename" })
                return
              elseif input == pos_params.oldName then
                vim.notify("input text matches current text; try again.", L.WARN, { title = "[lsp] rename" })
                return
              end

              cleanup_rename_callback()

              pos_params.newName = input

              vim.lsp.buf_request(0, "textDocument/rename", pos_params, function(err, result, ctx, config)
                -- result not provided, error at lsp end
                -- no changes made
                if not result or not result.changes then
                  vim.notify(
                    string.format("could not perform rename: %s -> %s", pos_params.oldName, pos_params.newName),
                    L.ERROR,
                    { title = "[lsp] rename", timeout = 500 }
                  )

                  return
                end

                -- apply changes
                vim.lsp.handlers["textDocument/rename"](err, result, ctx, config)

                local notification, entries = {}, {}
                local num_files, num_updates = 0, 0

                -- collect changes
                if result.changes then
                  for uri, edits in pairs(result.changes) do
                    num_files = num_files + 1
                    bufnr = vim.uri_to_bufnr(uri)

                    for _, edit in ipairs(edits) do
                      local start_line = edit.range.start.line + 1
                      local line = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, start_line, false)[1]

                      table.insert(entries, {
                        bufnr = bufnr,
                        lnum = start_line,
                        col = edit.range.start.character + 1,
                        text = line,
                      })
                    end

                    num_updates = num_updates + vim.tbl_count(edits)

                    local short_uri = string.sub(vim.uri_to_fname(uri), #vim.loop.cwd() + 2)
                    table.insert(notification, string.format("\t- %d in %s", vim.tbl_count(edits), short_uri))
                  end
                end

                -- format notification header and content
                local notification_str = ""
                if num_files > 1 then
                  -- add header
                  table.insert(notification, 1, string.format("made %d change%s in %d files", num_updates, (num_updates > 1 and "s") or "", num_files))

                  notification_str = table.concat(notification, "\n")
                else
                  -- only 1 entry in notification table for the single file
                  notification_str = string.format("made %s", notification[1]:sub(4))

                  -- add word "change"/"changes" at this point
                  local insert_loc = notification_str:find("in")
                  if insert_loc ~= nil then
                    notification_str = table.concat({
                      notification_str:sub(1, insert_loc - 1),
                      string.format("change%s ", (num_updates > 1 and "s") or ""),
                      notification_str:sub(insert_loc),
                    }, "")

                    vim.notify(notification_str, L.INFO, {
                      title = string.format("[LSP] rename: %s -> %s", pos_params.oldName, pos_params.newName),
                      timeout = 2500,
                    })
                  end
                end

                -- set qflist if more than 1 file
                if num_files > 1 then
                  U.qflist_populate(entries, { title = "Applied Rename Changes" })
                  vim.cmd.Trouble("qflist open focus=true")
                end
              end)
            end

            local function prepare_rename()
              current_name = vim.fn.expand("<cword>")
              rename_prompt = current_name .. default_rename_prompt
              bufnr = vim.api.nvim_create_buf(false, true)
              vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = bufnr })
              vim.api.nvim_set_option_value("buftype", "prompt", { buf = bufnr })
              vim.api.nvim_set_option_value("filetype", "prompt", { buf = bufnr })
              vim.api.nvim_buf_add_highlight(bufnr, -1, "Title", 0, 0, #rename_prompt)
              vim.fn.prompt_setprompt(bufnr, rename_prompt)
              local width = #current_name + #rename_prompt + 15
              local winnr = vim.api.nvim_open_win(bufnr, true, {
                relative = "cursor",
                width = width,
                height = 1,
                row = -3,
                col = 1,
                style = "minimal",
                border = BORDER_STYLE,
              })

              vim.api.nvim_set_option_value(
                "winhl",
                table.concat({
                  "Normal:NormalFloat",
                  "FloatBorder:FloatBorder",
                  "CursorLine:Visual",
                  "Search:None",
                }, ","),
                { win = winnr }
              )

              vim.keymap.set("i", "<CR>", rename_callback, { buffer = bufnr })
              vim.keymap.set("i", "<esc>", function() cleanup_rename_callback(winnr) end, { buffer = bufnr })
              vim.keymap.set("i", "<c-c>", function() cleanup_rename_callback(winnr) end, { buffer = bufnr })

              vim.cmd.startinsert()
            end

            prepare_rename()
            -- vim.ui.input({ prompt = "rename to -> ", default = position_params.oldName }, rename_callback)
          end

          -- vim.lsp.buf.rename = qf_rename
          qf_rename()
        end, "[r]ename")

        if client.name == "elixirls" then
          vim.keymap.set("n", "<localleader>efp", ":ElixirFromPipe<cr>", { buffer = bufnr, noremap = true, desc = "from pipe" })
          vim.keymap.set("n", "<localleader>etp", ":ElixirToPipe<cr>", { buffer = bufnr, noremap = true, desc = "to pipe (|>)" })
          vim.keymap.set("v", "<localleader>eem", ":ElixirExpandMacro<cr>", { buffer = bufnr, noremap = true, desc = "expand macro" })
        end

        command(
          "LspLogDelete",
          function() vim.fn.system("rm " .. vim.lsp.get_log_path()) end,
          { desc = "Deletes the LSP log file. Useful for when it gets too big" }
        )

        command("LspCapabilities", function(ctx)
          local filter = ctx.args == "" and { bufnr = 0 } or { name = ctx.args }
          local clients = vim.lsp.get_clients(filter)
          local clientInfo = vim.tbl_map(function(c) return c.name .. "\n" .. vim.inspect(c) end, clients)
          local msg = table.concat(clientInfo, "\n\n")
          P(msg)
        end, {
          nargs = "?",
          complete = function()
            local clients = vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients())
            table.sort(clients)
            vim.fn.uniq(clients)
            return clients
          end,
        })

        local max_width = math.min(math.floor(vim.o.columns * 0.7), 100)
        local max_height = math.min(math.floor(vim.o.lines * 0.3), 30)

        -- local sev_to_icon = {}
        -- M.signs = { linehl = {}, numhl = {}, text = {} }

        -- local SIGN_TYPES = { "Error", "Warn", "Info", "Hint" }
        -- for _, type in ipairs(SIGN_TYPES) do
        --   local hl = ("DiagnosticSign%s"):format(type)
        --   local icon = icons.lsp[type:lower()]

        --   local key = type:upper()
        --   local code = vim.diagnostic.severity[key]

        --   -- for vim.notify icon
        --   sev_to_icon[code] = icon

        --   -- vim.diagnostic.config signs
        --   local sign = ("%s "):format(icon)
        --   M.signs.text[code] = sign
        --   M.signs.numhl[code] = hl
        --   vim.fn.sign_define(hl, { numhl = hl, text = sign })
        -- end

        ---@param diag vim.Diagnostic
        ---@return string
        local function diag_msg_format(diag)
          local msg = diag.message
          if diag.source == "typos" then
            msg = msg:gsub("should be", "󰁔"):gsub("`", "")
          elseif diag.source == "Lua Diagnostics." then
            msg = msg:gsub("%.$", "")
          end
          return msg
        end

        ---@param diag vim.Diagnostic
        ---@param mode "virtual_text"|"float"
        ---@return string displayedText
        ---@return string highlight
        local function diag_source_as_suffix(diag, mode)
          if not (diag.source or diag.code) then return "", "" end
          local source = (diag.source or ""):gsub(" ?%.$", "") -- trailing dot for lua_ls
          local rule = diag.code and ": " .. diag.code or ""

          if mode == "virtual_text" then
            return (" (%s%s)"):format(source, rule), "Comment"
          elseif mode == "float" then
            return (" %s%s"):format(source, rule), "Comment"
          end

          return "", ""
        end

        --       local function float_format(diagnostic)
        --         --[[ e.g.
        -- {
        --   bufnr = 1,
        --   code = "trailing-space",
        --   col = 4,
        --   end_col = 5,
        --   end_lnum = 44,
        --   lnum = 44,
        --   message = "Line with postspace.",
        --   namespace = 12,
        --   severity = 4,
        --   source = "Lua Diagnostics.",
        --   user_data = {
        --     lsp = {
        --       code = "trailing-space"
        --     }
        --   }
        -- }
        -- ]]

        --         -- diagnostic.message may be pre-parsed in lspconfig's handlers
        --         -- ["textDocument/publishDiagnostics"]
        --         -- e.g. ts_ls in dko/plugins/lsp.lua

        --         local symbol = sev_to_icon[diagnostic.severity] or "-"
        --         local source = diagnostic.source
        --         if source then
        --           if source.sub(source, -1, -1) == "." then
        --             -- strip period at end
        --             source = source:sub(1, -2)
        --           end
        --         else
        --           source = "NIL.SOURCE"
        --           vim.print(diagnostic)
        --         end
        --         local source_tag = U.smallcaps(("%s"):format(source))
        --         local code = diagnostic.code and ("[%s]"):format(diagnostic.code) or ""
        --         return ("%s %s %s\n%s"):format(symbol, source_tag, code, diagnostic.message)
        --       end

        local diag_level = vim.diagnostic.severity
        vim.diagnostic.config({
          underline = true,
          signs = {
            text = {
              [diag_level.ERROR] = icons.lsp.error, -- alts: ▌
              [diag_level.WARN] = icons.lsp.warn,
              [diag_level.HINT] = icons.lsp.hint,
              [diag_level.INFO] = icons.lsp.info,
            },
            numhl = {
              [diag_level.ERROR] = "DiagnosticError",
              [diag_level.WARN] = "DiagnosticWarn",
              [diag_level.HINT] = "DiagnosticHint",
              [diag_level.INFO] = "DiagnosticInfo",
            },
            texthl = {
              [diag_level.ERROR] = "DiagnosticError",
              [diag_level.WARN] = "DiagnosticWarn",
              [diag_level.HINT] = "DiagnosticHint",
              [diag_level.INFO] = "DiagnosticInfo",
            },
            -- severity = { min = vim_diag.severity.WARN },
          },
          float = {
            show_header = true,
            source = true,
            border = BORDER_STYLE,
            focusable = false,
            severity_sort = true,
            max_width = max_width,
            max_height = max_height,
            close_events = {
              "CursorMoved",
              "BufHidden",
              "InsertCharPre",
              "BufLeave",
              "InsertEnter",
              "FocusLost",
              "BufWritePre",
              "BufWritePost",
            },
            -- scope = "cursor",
            header = { " Diagnostics:", "DiagnosticHeader" },
            suffix = function(diag) return diag_source_as_suffix(diag, "float") end,
            prefix = function(diag, _index, total)
              if total == 1 then return "", "" end
              -- local level = diag.severity[diag.severity]
              -- local prefix = fmt("%s ", SETTINGS.icons.lsp[level:lower()])
              -- return prefix, "Diagnostic" .. level:gsub("^%l", string.upper)
              return "• ", "NonText"
            end,
            format = diag_msg_format,
          },
          -- jump = {
          --   -- Do not show floating window
          --   float = false,

          --   -- Wrap around buffer
          --   wrap = true,
          -- },
          severity_sort = true,
          virtual_text = false,
          -- virtual_text = {
          --   spacing = 2,
          --   prefix = "", -- Could be '●', '▎', 'x'
          --   only_current_line = true,
          --   highlight_whole_line = false,
          --   severity = { min = diag_level.ERROR },
          --   suffix = function(diag) return diag_source_as_suffix(diag, "virtual_text") end,
          --   format = function(diag)
          --     local source = diag.source

          --     if source then
          --       local icon = SETTINGS.icons.lsp[vim.diagnostic.severity[diag.severity]:lower()]

          --       return string.format("%s %s %s", icon, source, "[" .. (diag.code ~= nil and diag.code or diag.message) .. "]")
          --     end

          --     return string.format("%s ", diag.message)
          --   end,
          -- },
          update_in_insert = false,
        })

        local signs = { Error = icons.lsp.error, Warn = icons.lsp.warn, Hint = icons.lsp.hint, Info = icons.lsp.info }
        for type, icon in pairs(signs) do
          local hl = "DiagnosticSign" .. type
          vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
        end

        local ns = vim.api.nvim_create_namespace("mega_lsp_diagnostics")
        local orig_signs_handler = vim.diagnostic.handlers.signs
        local max_diagnostics = function(_, bn, _, opts)
          local diagnostics = vim.diagnostic.get(bn)
          local max_severity_per_line = {}
          for _, d in pairs(diagnostics) do
            local m = max_severity_per_line[d.lnum]
            if not m or d.severity < m.severity then max_severity_per_line[d.lnum] = d end
          end
          local filtered_diagnostics = vim.tbl_values(max_severity_per_line)

          if filtered_diagnostics == nil or U.tlen(filtered_diagnostics) == 0 then
            dbg(filtered_diagnostics)
            orig_signs_handler.show(ns, bn, diagnostics, opts)
          else
            orig_signs_handler.show(ns, bn, filtered_diagnostics, opts)
          end
        end

        if vim.tbl_contains(SETTINGS.max_diagnostic_exclusions, client.name) then
          vim.diagnostic.handlers.signs = orig_signs_handler
        else
          vim.diagnostic.handlers.signs = vim.tbl_extend("force", orig_signs_handler, {
            show = max_diagnostics,
            hide = function(_, bn) orig_signs_handler.hide(ns, bn) end,
          })
        end

        -- require("mega.lsp_diagnostics")

        augroup("LspProgress", {
          {
            pattern = "end",
            event = { "LspProgress" },
            desc = "Handle lsp progress message scenarios",
            command = function(evt)
              if pcall(require, "fidget") then
                local token = evt.data.params.token
                if evt.data.result and evt.data.result.token then token = evt.data.result.token end
                local client_id = evt.data.client_id
                local c = client_id and vim.lsp.get_client_by_id(client_id)
                if c and token then require("fidget").notification.remove(c.name, token) end
              end
            end,
          },
        })

        augroup("LspDiagnostics", {
          {
            event = { "CursorHold" },
            desc = "Show diagnostics",
            command = show_diagnostic_popup,
          },
        })

        -- if client and client.server_capabilities.documentHighlightProvider then
        --   augroup("LspDocumentHighlights", {
        --     {
        --       event = { "CursorHold", "CursorHoldI" },
        --       buffer = bufnr,
        --       command = vim.lsp.buf.document_highlight,
        --     },
        --     {
        --       event = { "CursorMoved", "CursorMovedI" },
        --       buffer = bufnr,
        --       command = vim.lsp.buf.clear_references,
        --     },
        --   })
        -- end

        -- invoke any additional custom on_attach things passed in
        if cb ~= nil and type(cb) == "function" then cb() end

        -- dbg({ client.name, filetype, client.server_capabilities.semanticTokensProvider })
      end

      -- TODO: fixes for nvim 10?
      -- REF: https://github.com/dkarter/dotfiles/blob/master/config/nvim/lua/plugins/mason/lsp.lua#L53
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      if pcall(require, "cmp_nvim_lsp") then capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities) end
      if pcall(require, "blink.cmp") then capabilities = require("blink.cmp").get_lsp_capabilities(capabilities) end

      capabilities.workspace = {
        didChangeWatchedFiles = {
          dynamicRegistration = false,
        },
      }
      capabilities.textDocument.foldingRange = { dynamicRegistration = false, lineFoldingOnly = true }
      capabilities.textDocument.completion = {
        dynamicRegistration = false,
        completionItem = {
          snippetSupport = true,
          documentationFormat = { "markdown", "plaintext" },
          commitCharactersSupport = true,
          deprecatedSupport = true,
          preselectSupport = true,
          tagSupport = {
            valueSet = {
              1, -- Deprecated
            },
          },
          insertReplaceSupport = true,
          resolveSupport = {
            properties = {
              "documentation",
              "detail",
              "additionalTextEdits",
              "sortText",
              "filterText",
              "insertText",
              "textEdit",
              "insertTextFormat",
              "insertTextMode",
            },
          },
          insertTextModeSupport = {
            valueSet = {
              1, -- asIs
              2, -- adjustIndentation
            },
          },
          labelDetailsSupport = true,
        },
        contextSupport = true,
        insertTextMode = 1,
        completionList = {
          itemDefaults = {
            "commitCharacters",
            "editRange",
            "insertTextFormat",
            "insertTextMode",
            "data",
          },
        },
      }

      local servers = require("mega.servers")
      if servers == nil then return end
      local server_list = servers.list(capabilities, M.on_attach)
      servers.load_unofficial()

      require("mason").setup()
      require("mason-lspconfig").setup()

      local ensure_installed = {
        "black",
        "eslint_d",
        "isort",
        "prettier",
        "prettierd",
        "ruff",
        "stylua",
        "nixpkgs-fmt",
      }

      local servers_to_install = vim.tbl_filter(function(key)
        local s = server_list[key]
        if type(s) == "table" then
          return not s.manual_install
        elseif type(s) == "function" then
          s = s()
          return (s and not s.manual_install)
        else
          return s
        end
      end, vim.tbl_keys(server_list))
      vim.list_extend(ensure_installed, servers_to_install)

      require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

      function M.get_config(name)
        local config = name and server_list[name] or {}
        if not config or config == nil then return end

        if type(config) == "function" then
          config = config()
          if not config or config == nil then return end
        end

        config.flags = { debounce_text_changes = 150 }
        config.capabilities = vim.tbl_deep_extend("force", capabilities, config.capabilities or {})
        -- config.on_init = function(client, _)
        --   client.server_capabilities.semanticTokensProvider = nil
        --   if config.on_init ~= nil and type(config.on_init) == "function" then config.on_init(client, _bufnr) end
        -- end

        return config
      end

      vim.iter(server_list):each(function(server_name, _)
        local cfg = M.get_config(server_name)
        if cfg == nil then return end
        lspconfig[server_name].setup(cfg)
      end)

      -- local ok_ex, elixir = pcall(require, "elixir")
      -- if ok_ex then
      --   local elixirls = require("elixir.elixirls")
      --   elixir.setup({
      --     credo = {
      --       on_attach = M.on_attach,
      --       enable = false,
      --     },
      --     nextls = {
      --       enable = false,
      --       version = "0.23.1",
      --       on_attach = M.on_attach,
      --       init_options = {
      --         experimental = {
      --           completions = {
      --             enable = true, -- control if completions are enabled. defaults to false
      --           },
      --         },
      --       },
      --     },

      --     -- actually lexical
      --     elixirls = {
      --       enable = true,
      --       settings = elixirls.settings({
      --         incrementalDialyzer = true,
      --         dialyzerEnabled = true,
      --         dialyzerFormat = "dialyxir_long",
      --         enableTestLenses = true,
      --         suggestSpecs = true,
      --         autoInsertRequiredAlias = true,
      --         signatureAfterComplete = true,
      --       }),
      --       cmd = vim.env.XDG_DATA_HOME .. "/lsp/lexical/_build/dev/package/lexical/bin/start_lexical.sh",
      --       on_attach = function(client, bufnr)
      --         -- NOTE: this on_attach fires before my own LspAttach autocmd handler below
      --         -- vim.keymap.set("n", "<space>pf", ":ElixirFromPipe<cr>", { buffer = true, noremap = true })
      --         -- vim.keymap.set("n", "<space>pt", ":ElixirToPipe<cr>", { buffer = true, noremap = true })
      --         -- vim.keymap.set("v", "<space>em", ":ElixirExpandMacro<cr>", { buffer = true, noremap = true })

      --         vim.api.nvim_buf_create_user_command(bufnr, "Format", function()
      --           local params = require("vim.lsp.util").make_formatting_params()
      --           client.request("textDocument/formatting", params, nil, bufnr)
      --         end, { nargs = 0 })

      --         M.on_attach(client, bufnr)
      --       end,
      --     },
      --   })
      -- end

      augroup("LspAttach", {
        {
          event = { "LspAttach" },
          desc = "Attach various functionality to an LSP-connected buffer/client",
          command = function(args)
            local client = assert(vim.lsp.get_client_by_id(args.data.client_id), "must have valid ls client")
            if client ~= nil then M.on_attach(client, args.buf) end
          end,
        },
      })
    end,
  },
  -- {
  --   "stevearc/aerial.nvim",
  --   opts = {
  --     backends = { "lsp", "treesitter" },
  --     guides = {
  --       mid_item = " ├─",
  --       last_item = " └─",
  --       nested_top = " │",
  --     },
  --     layout = {
  --       close_on_select = false,
  --       max_width = 35,
  --       min_width = 35,
  --     },
  --     show_guides = true,
  --     open_automatic = function(bufnr)
  --       local aerial = require("aerial")
  --       return vim.api.nvim_win_get_width(0) > 120
  --         and aerial.num_symbols(bufnr) > 0
  --         and not aerial.was_closed()
  --         and not vim.tbl_contains({ "markdown" }, vim.bo[bufnr].ft)
  --     end,
  --   },
  --   config = function(_, opts)
  --     require("aerial").setup(opts)

  --     vim.keymap.set("n", "<F18>", "<cmd>AerialToggle<cr>", { silent = true })

  --     vim.api.nvim_set_hl(0, "AerialLine", { link = "PmenuSel" })
  --   end,
  -- },
  -- { "elixir-tools/elixir-tools.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
  {
    -- FIXME: https://github.com/mhanberg/output-panel.nvim/issues/5
    "mhanberg/output-panel.nvim",
    lazy = false,
    keys = {
      {
        "<leader>lip",
        ":OutputPanel<CR>",
        desc = "lsp: open output panel",
      },
    },
    cmd = { "OutputPanel" },
    opts = true,
  },

  { "RaafatTurki/corn.nvim", opts = {}, enabled = false },
  {
    enabled = false,
    cond = vim.g.completer ~= "blink",
    "ray-x/lsp_signature.nvim",
    event = "BufReadPre",
    opts = {
      hint_prefix = " 󰏪 ",
      hint_scheme = "Todo", -- highlight group, alt: @variable.parameter
      floating_window = true,
      always_trigger = true,
    },
  },
}
