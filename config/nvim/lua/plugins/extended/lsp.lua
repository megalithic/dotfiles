local SETTINGS = require("mega.settings")
local BORDER_STYLE = SETTINGS.border
local augroup = require("mega.autocmds").augroup
local command = vim.api.nvim_create_user_command
local U = require("mega.utils")
local fmt = string.format

local M = {}

return {
  {
    "megalithic/nvim-lspconfig",
    dependencies = {
      { "nvim-lua/lsp_extensions.nvim" },
      { "b0o/schemastore.nvim" },
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",

      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      {
        "j-hui/fidget.nvim",
        opts = {
          progress = {
            display = {
              done_icon = require("mega.settings").icons.lsp.ok,
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

      -- `neodev` configures Lua LSP for your Neovim config, runtime and plugins
      -- used for completion, annotations and signatures of Neovim apis
      { "folke/neodev.nvim", opts = {} },
    },
    config = function()
      local diagnostic_ns = vim.api.nvim_create_namespace("hldiagnosticregion")
      local diagnostic_timer
      local hl_cancel
      local hl_map = {
        [vim.diagnostic.severity.ERROR] = "DiagnosticVirtualTextError",
        [vim.diagnostic.severity.WARN] = "DiagnosticVirtualTextWarn",
        [vim.diagnostic.severity.HINT] = "DiagnosticVirtualTextHint",
        [vim.diagnostic.severity.INFO] = "DiagnosticVirtualTextInfo",
      }

      require("lspconfig.ui.windows").default_options.border = BORDER_STYLE

      local function has_existing_floats()
        local winids = vim.api.nvim_tabpage_list_wins(0)
        for _, winid in ipairs(winids) do
          if vim.api.nvim_win_get_config(winid).zindex then return true end
        end
      end

      local function diagnostic_popup(opts)
        local bufnr = opts
        if type(opts) == "table" then bufnr = opts.buf or 0 end

        local diags = vim.diagnostic.open_float(bufnr, { focus = false, scope = "cursor" })

        -- If there's no diagnostic under the cursor show diagnostics of the entire line
        if not diags then vim.diagnostic.open_float(bufnr, { focus = false, scope = "line" }) end

        -- if not vim.g.git_conflict_detected and not has_existing_floats() then
        --   -- Try to open diagnostics under the cursor
        --   local diags = vim.diagnostic.open_float(bufnr, { focus = false, scope = "cursor" })
        --
        --   -- If there's no diagnostic under the cursor show diagnostics of the entire line
        --   if not diags then vim.diagnostic.open_float(bufnr, { focus = false, scope = "line" }) end
        --
        --   return diags
        -- end
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
        vim.diagnostic["goto_" .. dir]()
      end

      --  This function gets run when an LSP attaches to a particular buffer.
      --    That is to say, every time a new file is opened that is associated with
      --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
      --    function will be executed to configure the current buffer
      function M.on_attach(client, bufnr)
        local disabled_lsp_formatting = SETTINGS.disabled_lsp_formatters
        for i = 1, #disabled_lsp_formatting do
          if disabled_lsp_formatting[i] == client.name then
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end
        end

        -- vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config) ---@diagnostic disable-line: duplicate-set-field
        --   result.diagnostics = vim.tbl_map(function(diag)
        --     if
        --       (diag.source == "biome" and diag.code == "lint/suspicious/noConsoleLog")
        --       or (diag.source == "stylelintplus" and diag.code == "declaration-no-important")
        --     then
        --       diag.severity = vim.diagnostic.severity.HINT
        --     end
        --     return diag
        --   end, result.diagnostics)
        --
        --   vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx, config)
        -- end

        local diagnostic_handler = vim.lsp.handlers["textDocument/publishDiagnostics"]
        vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
          local client_name = vim.lsp.get_client_by_id(ctx.client_id).name
          -- disables diagnostic reporting for specific clients
          if vim.tbl_contains(SETTINGS.diagnostic_exclusions, client_name) then return end

          diagnostic_handler(err, result, ctx, config)
        end

        local definition_handler = vim.lsp.handlers["textDocument/definition"]
        vim.lsp.handlers["textDocument/definition"] = function(err, result, ctx, config)
          local client_name = vim.lsp.get_client_by_id(ctx.client_id).name
          -- disables diagnostic reporting for specific clients
          if vim.tbl_contains(SETTINGS.definition_exclusions, client_name) then
            print("returning for " .. client_name)
            return
          end

          definition_handler(err, result, ctx, config)
        end

        -- if action opens up qf list, open the first item and close the list
        local function choose_list_first(items)
          print(#items)
          if #items > 1 then
            U.qf_populate(items, { title = "Definitions" })
            vim.cmd("Trouble qflist open")
          end

          -- vim.fn.setqflist({}, "r", items)
          -- vim.cmd.cfirst()
        end
        local map = function(keys, func, desc) vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "LSP: " .. desc }) end
        local icons = require("mega.settings").icons

        -- if client and client.supports_method("textDocument/inlayHint", { bufnr = bufnr }) then
        --   vim.lsp.inlay_hint.enable(bufnr, true)
        --   -- vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        -- end

        map("<leader>lic", [[<cmd>LspInfo<CR>]], "connected client info")
        map("<leader>lim", [[<cmd>Mason<CR>]], "mason info")
        map("<leader>lil", [[<cmd>LspLog<CR>]], "logs (vsplit)")

        map("[d", function() goto_diagnostic_hl("prev") end, "Go to previous [D]iagnostic message")
        map("]d", function() goto_diagnostic_hl("next") end, "Go to next [D]iagnostic message")

        map("gd", require("telescope.builtin").lsp_definitions, "[g]oto [d]efinition")
        -- map("gd", function() vim.lsp.buf.definition({ on_list = choose_list_first }) end, "[g]oto [d]efinition")
        -- map("gd", function() vim.cmd("Trouble lsp_definitions toggle focus=true") end, "[g]oto [d]efinition (trouble)")
        map("gD", function()
          vim.cmd.vsplit()
          vim.lsp.buf.definition()
          -- vim.lsp.buf.definition({ on_list = choose_list_first })
        end, "[g]oto [d]efinition (split)")
        map("gr", require("telescope.builtin").lsp_references, "[g]oto [r]eferences")
        map("gI", require("telescope.builtin").lsp_implementations, "[g]oto [i]mplementation")
        map("<leader>ltd", require("telescope.builtin").lsp_type_definitions, "[t]ype [d]efinition")
        map("<leader>lsd", require("telescope.builtin").lsp_document_symbols, "[d]ocument [s]ymbols")
        map("<leader>lsw", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[w]orkspace [s]ymbols")
        map("<leader>lca", vim.lsp.buf.code_action, "[c]ode [a]ctions")
        map("K", vim.lsp.buf.hover, "hover documentation")
        -- map("gD", vim.lsp.buf.declaration, "[g]oto [d]eclaration (e.g. to a header file in C)")
        map("<leader>rn", function()
          local params = vim.lsp.util.make_position_params()
          local current_symbol = vim.fn.expand("<cword>")
          params.old_symbol = current_symbol
          params.context = { includeDeclaration = true }
          local clients = vim.lsp.get_clients()
          client = clients[1]
          for _, possible_client in pairs(clients) do
            if possible_client.server_capabilities.renameProvider then
              client = possible_client
              break
            end
          end
          local ns = vim.api.nvim_create_namespace("LspRenamespace")

          client.request("textDocument/references", params, function(_, result)
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
                  -- print(line, start_char, end_char)
                  vim.api.nvim_buf_add_highlight(bufnr, ns, "LspReferenceWrite", line, start_char, end_char)
                end
              end
            end
            vim.cmd.redraw()
            local new_name = vim.fn.input({ prompt = fmt("%s (%d) -> ", params.old_symbol, #result) })
            vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
            if #new_name == 0 then return end
            vim.lsp.buf.rename(new_name)
          end, bufnr)
        end, "[R]e[n]ame")

        map("gn", function()
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

            local position_params = vim.lsp.util.make_position_params()
            position_params.oldName = vim.fn.expand("<cword>")
            position_params.context = { includeDeclaration = true }

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
              elseif input == position_params.oldName then
                vim.notify("input text matches current text; try again.", L.WARN, { title = "[lsp] rename" })
                return
              end

              cleanup_rename_callback()

              position_params.newName = input

              vim.lsp.buf_request(0, "textDocument/rename", position_params, function(err, result, ctx, config)
                -- result not provided, error at lsp end
                -- no changes made
                if not result or (not result.documentChanges and not result.changes) then
                  vim.notify(
                    string.format("could not perform rename: %s -> %s", position_params.oldName, position_params.newName),
                    L.ERROR,
                    { title = "[LSP] rename", timeout = 500 }
                  )

                  return
                end

                -- apply changes
                vim.lsp.handlers["textDocument/rename"](err, result, ctx, config)

                local notification, entries = {}, {}
                local num_files, num_updates = 0, 0

                -- collect changes
                if result.documentChanges then
                  for _, document in pairs(result.documentChanges) do
                    num_files = num_files + 1
                    local uri = document.textDocument.uri
                    bufnr = vim.uri_to_bufnr(uri)

                    for _, edit in ipairs(document.edits) do
                      local start_line = edit.range.start.line + 1
                      local line = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, start_line, false)[1]

                      table.insert(entries, {
                        bufnr = bufnr,
                        lnum = start_line,
                        col = edit.range.start.character + 1,
                        text = line,
                      })
                    end

                    num_updates = num_updates + vim.tbl_count(document.edits)

                    local short_uri = string.sub(vim.uri_to_fname(uri), #vim.loop.cwd() + 2)
                    table.insert(notification, string.format("\t- %d in %s", vim.tbl_count(document.edits), short_uri))
                  end
                end

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

                  notification_str = table.concat({
                    notification_str:sub(1, insert_loc - 1),
                    string.format("change%s ", (num_updates > 1 and "s") or ""),
                    notification_str:sub(insert_loc),
                  }, "")
                end

                -- vim.notify(notification_str, L.INFO, {
                --   title = string.format("[LSP] rename: %s -> %s", position_params.oldName, position_params.newName),
                --   timeout = 2500,
                -- })

                -- set qflist if more than 1 file
                if num_files > 1 then
                  U.qf_populate(entries, { title = "Applied Rename Changes" })
                  vim.cmd("Trouble qflist open")
                end
              end)
            end

            local function prepare_rename()
              current_name = vim.fn.expand("<cword>")
              rename_prompt = current_name .. default_rename_prompt
              bufnr = vim.api.nvim_create_buf(false, true)
              vim.api.nvim_buf_set_option(bufnr, "buftype", "prompt")
              vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
              vim.api.nvim_buf_set_option(bufnr, "filetype", "prompt")
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

              vim.api.nvim_win_set_option(
                winnr,
                "winhl",
                table.concat({
                  "Normal:NormalFloat",
                  "FloatBorder:FloatBorder",
                  "CursorLine:Visual",
                  "Search:None",
                }, ",")
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

        if client.name == "ElixirLS" then
          vim.keymap.set("n", "<localleader>efp", ":ElixirFromPipe<cr>", { buffer = bufnr, noremap = true, desc = "from pipe" })
          vim.keymap.set("n", "<localleader>etp", ":ElixirToPipe<cr>", { buffer = bufnr, noremap = true, desc = "to pipe (|>)" })
          vim.keymap.set("v", "<localleader>eem", ":ElixirExpandMacro<cr>", { buffer = bufnr, noremap = true, desc = "expand macro" })
        end

        command("LspCapabilities", function(ctx)
          local filter = ctx.args == "" and { bufnr = 0 } or { name = ctx.args }
          local clients = vim.lsp.get_clients(filter)
          local clientInfo = vim.tbl_map(function(c) return c.name .. "\n" .. vim.inspect(c) end, clients)
          local msg = table.concat(clientInfo, "\n\n")
          vim.notify(msg)
        end, {
          nargs = "?",
          complete = function()
            local clients = vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients())
            table.sort(clients)
            vim.fn.uniq(clients)
            return clients
          end,
        })

        augroup("LspDiagnostics", {
          {
            event = { "CursorHold" },
            desc = "Show diagnostics",
            command = diagnostic_popup,
          },
        })

        if client and client.server_capabilities.documentHighlightProvider then
          augroup("LspDocumentHighlights", {
            {
              event = { "CursorHold", "CursorHoldI" },
              buffer = bufnr,
              command = vim.lsp.buf.document_highlight,
            },
            {
              event = { "CursorMoved", "CursorMovedI" },
              buffer = bufnr,
              command = vim.lsp.buf.clear_references,
            },
          })
        end

        local max_width = math.min(math.floor(vim.o.columns * 0.7), 100)
        local max_height = math.min(math.floor(vim.o.lines * 0.3), 30)

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
        ---@return string? highlight_group
        local function diag_source_as_suffix(diag, mode)
          if not (diag.source or diag.code) then return "" end
          local source = (diag.source or ""):gsub(" ?%.$", "") -- trailing dot for lua_ls
          local rule = diag.code and ": " .. diag.code or ""

          if mode == "virtual_text" then
            return (" (%s%s)"):format(source, rule)
          elseif mode == "float" then
            return (" %s%s"):format(source, rule), "Comment"
          end
          return ""
        end

        local vim_diag = vim.diagnostic
        vim_diag.config({
          underline = true,
          signs = {
            text = {
              [vim_diag.severity.ERROR] = icons.lsp.error, -- alts: ▌
              [vim_diag.severity.WARN] = icons.lsp.warn,
              [vim_diag.severity.HINT] = icons.lsp.hint,
              [vim_diag.severity.INFO] = icons.lsp.info,
            },
            numhl = {
              [vim_diag.severity.ERROR] = "DiagnosticError",
              [vim_diag.severity.WARN] = "DiagnosticWarn",
              [vim_diag.severity.HINT] = "DiagnosticHint",
              [vim_diag.severity.INFO] = "DiagnosticInfo",
            },
            texthl = {
              [vim_diag.severity.ERROR] = "DiagnosticError",
              [vim_diag.severity.WARN] = "DiagnosticWarn",
              [vim_diag.severity.HINT] = "DiagnosticHint",
              [vim_diag.severity.INFO] = "DiagnosticInfo",
            },
            -- severity = { min = vim_diag.severity.WARN },
          },
          float = {
            show_header = true,
            source = true, -- or "always", "if_many" (for more than one source)
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
            scope = "cursor",
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
          severity_sort = true,
          virtual_text = {
            severity = { min = vim_diag.severity.ERROR },
            suffix = function(diag) return diag_source_as_suffix(diag, "virtual_text") end,
          },
          update_in_insert = false,
        })

        -- vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
        --   border = BORDER_STYLE,
        -- })
        -- vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
        --   border = BORDER_STYLE,
        -- })

        local signs = { Error = icons.lsp.error, Warn = icons.lsp.warn, Hint = icons.lsp.hint, Info = icons.lsp.info }
        for type, icon in pairs(signs) do
          local hl = "DiagnosticSign" .. type
          vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
        end

        -- Create a custom namespace. This will aggregate signs from all other
        -- namespaces and only show the one with the highest severity on a
        -- given line
        local ns = vim.api.nvim_create_namespace("mega_lsp_diagnostics")
        -- Get a reference to the original signs handler
        local orig_signs_handler = vim.diagnostic.handlers.signs
        -- Override the built-in signs handler
        local max_diagnostics = function(_, bn, _, opts)
          -- Get all diagnostics from the whole buffer rather than just the
          -- diagnostics passed to the handler
          local diagnostics = vim.diagnostic.get(bn)
          -- Find the "worst" diagnostic per line
          local max_severity_per_line = {}
          for _, d in pairs(diagnostics) do
            local m = max_severity_per_line[d.lnum]
            if not m or d.severity < m.severity then max_severity_per_line[d.lnum] = d end
          end
          -- Pass the filtered diagnostics (with our custom namespace) to
          -- the original handler
          local filtered_diagnostics = vim.tbl_values(max_severity_per_line)
          orig_signs_handler.show(ns, bn, filtered_diagnostics, opts)
        end

        if vim.tbl_contains(SETTINGS.max_diagnostic_exclusions, client.name) then
          vim.diagnostic.handlers.signs = orig_signs_handler
        else
          vim.diagnostic.handlers.signs = vim.tbl_extend("force", orig_signs_handler, {
            show = max_diagnostics,
            hide = function(_, bn) orig_signs_handler.hide(ns, bn) end,
          })
        end
        -- vim.diagnostic.handlers.signs = {
        --   show = max_diagnostics,
        --   hide = function(_, bn) orig_signs_handler.hide(ns, bn) end,
        -- }
      end

      augroup("LspAttach", {
        {
          event = { "LspAttach" },
          desc = "Attach various functionality to an LSP-connected buffer/client",
          command = function(evt)
            local client = vim.lsp.get_client_by_id(evt.data.client_id)
            if client ~= nil then M.on_attach(client, evt.buf) end
          end,
        },
      })

      local lspconfig = require("lspconfig")

      M.capabilities = vim.lsp.protocol.make_client_capabilities()
      M.capabilities.textDocument.completion.completionItem.snippetSupport = true
      if pcall(require, "cmp_nvim_lsp") then M.capabilities = require("cmp_nvim_lsp").default_capabilities(M.capabilities) end

      local servers = require("mega.servers")
      if servers == nil then return end

      function M.get_config(name)
        local config = name and servers.list[name] or {}
        if not config or config == nil then return end

        if type(config) == "function" then
          config = config()
          if not config or config == nil then return end
        end

        config.flags = { debounce_text_changes = 150 }
        config.capabilities = vim.tbl_deep_extend("force", {}, M.capabilities, config.capabilities or {})

        return config
      end

      local tools = {
        "luacheck",
        "prettier",
        "prettierd",
        "selene",
        "shellcheck",
        "shfmt",
        -- "solargraph",
        "stylua",
        "yamlfmt",
        -- "black",
        -- "buf",
        -- "cbfmt",
        -- "deno",
        -- "elm-format",
        -- "eslint_d",
        -- "fixjson",
        -- "flake8",
        -- "goimports",
        -- "isort",
      }

      require("mason").setup()
      local mr = require("mason-registry")
      for _, tool in ipairs(tools) do
        local p = mr.get_package(tool)
        if not p:is_installed() then p:install() end
      end

      -- will try and install the language servers defined in servers.lua..
      -- in addition to the others..
      local ensure_installed = {
        "black",
        "eslint_d",
        "isort",
        "prettier",
        "prettierd",
        "ruff",
        "stylua",
      }

      local servers_to_install = vim.tbl_filter(function(key)
        local s = servers.list[key]
        if type(s) == "table" then
          return not s.manual_install
        elseif type(s) == "function" then
          s = s()
          return (s and not s.manual_install)
        else
          return s
        end
      end, vim.tbl_keys(servers.list))
      vim.list_extend(ensure_installed, servers_to_install)

      require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

      -- servers.load_contrib()

      for server_name, _ in pairs(servers.list) do
        local cfg = M.get_config(server_name)

        if cfg == nil then return end

        lspconfig[server_name].setup(cfg)
      end
    end,
  },

  {
    "mhanberg/output-panel.nvim",
    keys = {
      {
        "<leader>lip",
        ":OutputPanel<CR>",
        desc = "lsp: open output panel",
      },
    },
    event = "VeryLazy",
    cmd = { "OutputPanel" },
    config = function() require("output_panel").setup() end,
  },

  {
    "elixir-tools/elixir-tools.nvim",
    cond = U.lsp.is_enabled_elixir_ls("Next LS") or U.lsp.is_enabled_elixir_ls("ElixirLS"),
    -- event = {
    --   "BufReadPre **.ex,**.exs,**.heex",
    --   "BufNewFile **.ex,**.exs,**.heex",
    -- },
    lazy = false,
    config = function()
      local elixir = require("elixir")
      local elixirls = require("elixir.elixirls")
      local nextls_cmd = function()
        local arch = {
          ["arm64"] = "arm64",
          ["aarch64"] = "arm64",
          ["amd64"] = "amd64",
          ["x86_64"] = "amd64",
        }

        local os_name = string.lower(vim.uv.os_uname().sysname)
        local current_arch = arch[string.lower(vim.uv.os_uname().machine)]
        local build_bin = fmt("next_ls_%s_%s", os_name, current_arch)

        return fmt("%s/lsp/nextls/burrito_out/%s", vim.env.XDG_DATA_HOME, build_bin)
      end

      elixir.setup({
        nextls = {
          enable = U.lsp.is_enabled_elixir_ls("Next LS"),
          autostart = true,
          cmd = nextls_cmd(),
          spitfire = true,
          init_options = {
            experimental = {
              completions = {
                enable = true, -- control if completions are enabled. defaults to false
              },
            },
          },
          on_attach = M.on_attach,
        },
        credo = {},
        elixirls = {
          enable = U.lsp.is_enabled_elixir_ls("ElixirLS"),
          cmd = fmt("%s/lsp/elixir-ls/%s", vim.env.XDG_DATA_HOME, "language_server.sh"),
          settings = elixirls.settings({
            dialyzerEnabled = true,
            enableTestLenses = true,
          }),
          on_attach = M.on_attach,
          -- on_attach = function(_client, bufnr)
          --   local map = vim.keymap.set
          --   map("n", "<localleader>efp", ":ElixirFromPipe<cr>", { buffer = bufnr, noremap = true, desc = "from pipe" })
          --   map("n", "<localleader>etp", ":ElixirToPipe<cr>", { buffer = bufnr, noremap = true, desc = "to pipe (|>)" })
          --   map("v", "<localleader>eem", ":ElixirExpandMacro<cr>", { buffer = bufnr, noremap = true, desc = "expand macro" })
          -- end,
        },
      })
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "neovim/nvim-lspconfig",
    },
  },
}