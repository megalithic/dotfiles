-- presently using plugin/lsp/* instead
if true then return {} end

local U = require("mega.utils")
local SETTINGS = require("mega.settings")
local BORDER_STYLE = SETTINGS.border
local augroup = require("mega.autocmds").augroup
local command = vim.api.nvim_create_user_command
local methods = vim.lsp.protocol.Methods
-- local snacks = require("snacks").picker

local M = {}

return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason-org/mason.nvim",
      { "mason-org/mason-lspconfig.nvim", version = "*" },
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      "nvim-lua/lsp_extensions.nvim",
      "b0o/schemastore.nvim",
      "onsails/lspkind.nvim",
      "youssef-lr/lsp-overloads.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      local lsp_ok, lspconfig = pcall(require, "lspconfig")
      if not lsp_ok then return nil end

      local diagnostic_ns = vim.api.nvim_create_namespace("mega.hl_diagnostic_region")
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

        -- if SETTINGS.disabled_semantic_tokens[filetype] then client.server_capabilities.semanticTokensProvider = vim.NIL end

        -- if client.server_capabilities.signatureHelpProvider then require("mega.lsp_signature").setup(client) end
        if client.server_capabilities.codeLensProvider then vim.lsp.codelens.refresh({ bufnr = bufnr }) end

        for i = 1, #disabled_lsp_formatting do
          if disabled_lsp_formatting[i] == client.name then
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end
        end

        if client and client:supports_method("textDocument/inlayHint", { bufnr = bufnr }) then
          if SETTINGS.enabled_inlay_hints[filetype] then vim.lsp.inlay_hint.enable(true) end
        end

        -- EXCLUDE certain servers for diagnostics
        local diagnostic_handler = vim.lsp.handlers[methods.textDocument_publishDiagnostics]
        vim.lsp.handlers[methods.textDocument_publishDiagnostics] = function(err, result, ctx, config)
          local client_name = vim.lsp.get_client_by_id(ctx.client_id).name

          if bufnr == nil or not vim.api.nvim_buf_is_valid(bufnr) then return end

          local fname = vim.api.nvim_buf_get_name(bufnr)
          local fext = fname:match("%.[^.]+$")

          -- FIXME: once "the one elixir ls to rule them all" (aka "Expert") is released, you can probably get rid of all of this non-sense i'm using to manage multiple elixir ls'
          -- this lets certain elixir language servers that i use to report diagnostics for test files (nextls doesn't, so i have to rely on elixirls or lexical to do this)
          if SETTINGS.diagnostic_exclusions and vim.tbl_contains(SETTINGS.diagnostic_exclusions, client_name) then
            if client.name == "elixirls" and fext ~= ".exs" then
              diagnostic_handler(err, result, ctx, config)
            else
              print("skipping diagnostics for " .. client_name)
              return
            end
          else
            diagnostic_handler(err, result, ctx, config)
          end
        end

        -- EXCLUDE certain servers for definitions
        local definition_handler = vim.lsp.handlers[methods.textDocument_definition]
        vim.lsp.handlers[methods.textDocument_definition] = function(err, result, ctx, config)
          local client_name = vim.lsp.get_client_by_id(ctx.client_id).name
          if SETTINGS.definition_exclusions and vim.tbl_contains(SETTINGS.definition_exclusions, client_name) then
            print("skipping definitions for " .. client_name)
            return
          end
          definition_handler(err, result, ctx, config)
        end

        -- EXCLUDE certain servers for references
        local references_handler = vim.lsp.handlers[methods.textDocument_references]
        vim.lsp.handlers[methods.textDocument_references] = function(err, result, ctx, config)
          local client_name = vim.lsp.get_client_by_id(ctx.client_id).name
          if SETTINGS.references_exclusions and vim.tbl_contains(SETTINGS.references_exclusions, client_name) then
            print("skipping references for " .. client_name)
            return
          end
          references_handler(err, result, ctx, config)
        end

        local md_namespace = vim.api.nvim_create_namespace("mega.lsp_floats")

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
        local map = function(modes, keys, func, d, opts)
          opts = vim.tbl_deep_extend("keep", { buffer = bufnr, desc = desc(d) }, opts or {})
          vim.keymap.set(modes, keys, func, opts)
        end
        local nmap = function(keys, func, d) map("n", keys, func, d, { noremap = false }) end
        local imap = function(keys, func, d) map("i", keys, func, d, { noremap = false }) end
        local vnmap = function(keys, func, d, opts) map({ "v", "n" }, keys, func, d, opts) end
        local icons = require("mega.settings").icons

        local max_width = math.min(math.floor(vim.o.columns * 0.7), 100)
        local max_height = math.min(math.floor(vim.o.lines * 0.3), 30)

        nmap("<leader>lic", [[<cmd>LspInfo<CR>]], "connected client info")
        nmap("<leader>lim", [[<cmd>Mason<CR>]], "mason info")
        nmap("<leader>lil", [[<cmd>LspLog<CR>]], "logs (vsplit)")

        nmap("ge", show_diagnostic_popup, "[g]o to diagnostic hover")
        nmap("gl", show_diagnostic_popup, "[g]o to diagnostic hover")
        nmap("[d", function() goto_diagnostic_hl("prev") end, "Go to previous [D]iagnostic message")
        nmap("]d", function() goto_diagnostic_hl("next") end, "Go to next [D]iagnostic message")

        nmap("gq", function() vim.cmd("Trouble diagnostics toggle focus=true filter.buf=0") end, "[g]oto [q]uickfixlist buffer diagnostics (trouble)")
        nmap("gQ", function() vim.cmd("Trouble diagnostics toggle focus=true") end, "[g]oto [q]uickfixlist global diagnostics (trouble)")

        if client:supports_method(methods.textDocument_references) then
          map(
            "n",
            "gr",
            function()
              Snacks.picker.lsp_references({
                include_declaration = false,
                include_current = false,
              })
            end,
            "[g]oto [r]eferences",
            { nowait = true }
          )
          -- { "gr", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References" },
        end

        -- nmap("gr", function()
        --   if not SETTINGS.references_exclusions or not vim.tbl_contains(SETTINGS.references_exclusions, client.name) then
        --     -- require("telescope.builtin").lsp_references()
        --     require("fzf-lua").lsp_references({
        --       include_declaration = false,
        --       ignore_current_line = true,
        --     })
        --   end
        -- end, "[g]oto [r]eferences")

        if client:supports_method(methods.textDocument_definition) then
          -- nmap("gd", "<cmd>vsplit<cr><cmd>lua require('snacks').picker.lsp_definitions()<cr>", "goto definition (vsplit)")
          nmap("gd", "<cmd>lua require('snacks').picker.lsp_definitions()<cr>", "[g]oto [d]efinition")
          -- nmap("gd", function() require("fzf-lua").lsp_definitions({ jump1 = true }) end, "Go to definition")
          -- nmap("gD", function() require("fzf-lua").lsp_definitions({ jump1 = false }) end, "Peek definition")
          -- nmap("gd", "<cmd>vsplit | lua vim.lsp.buf.definition()<cr>", "Goto Definition in Vertical Split")
        end

        if client:supports_method(methods.textDocument_signatureHelp) then
          nmap("gk", function()
            local ok_blink, blink = pcall(require, "blink.cmp")
            if ok_blink then
              local blink_window = require("blink.cmp.completion.windows.menu")
              if blink_window.win:is_open() then blink.hide() end
            end
            --

            vim.lsp.buf.signature_help()
          end, "Signature help")

          imap("<C-k>", function()
            local ok_blink, blink = pcall(require, "blink.cmp")
            if ok_blink then
              local blink_window = require("blink.cmp.completion.windows.menu")
              if blink_window.win:is_open() then blink.hide() end
            end
            --

            vim.lsp.buf.signature_help()
          end, "Signature help")
        end

        nmap("gI", require("telescope.builtin").lsp_implementations, "[g]oto [i]mplementation")
        nmap("<leader>ltd", require("telescope.builtin").lsp_type_definitions, "[t]ype [d]efinition")
        nmap("\\dS", require("telescope.builtin").lsp_document_symbols, "[d]ocument [s]ymbols")
        nmap("<leader>lsd", require("telescope.builtin").lsp_document_symbols, "[d]ocument [s]ymbols")
        nmap("<leader>lsw", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[w]orkspace [s]ymbols")
        vnmap("g.", function() fix_current_action() end, "[g]o run nearest/current code action")
        vnmap("<leader>la", vim.lsp.buf.code_action, "code [a]ctions")
        vnmap("<leader>lca", vim.lsp.buf.code_action, "[c]ode [a]ctions")
        nmap("ga", function() vim.cmd.FzfLua("lsp_code_actions") end, "[g]o [c]ode [a]ctions")
        -- nmap("K", vim.lsp.buf.hover, "hover documentation")

        -- if client:supports_method(methods.textDocument_signatureHelp) then
        --   if client and client.server_capabilities.signatureHelpProvider and vim.g.completer == "cmp" then
        --     require("lsp-overloads").setup(client, {
        --       -- UI options are mostly the same as those passed to vim.lsp.util.open_floating_preview
        --       silent = true,
        --       floating_window_above_cur_line = true,
        --       ui = {
        --         border = "rounded", -- The border to use for the signature popup window. Accepts same border values as |nvim_open_win()|.
        --         max_width = 130, -- Maximum signature popup width
        --         focusable = true, -- Make the popup float focusable
        --         focus = false, -- If focusable is also true, and this is set to true, navigating through overloads will focus into the popup window (probably not what you want)
        --         silent = true, -- Prevents noisy notifications (make false to help debug why signature isn't working)
        --         highlight = {
        --           italic = true,
        --           bold = true,
        --           fg = "#ffffff",
        --         },
        --       },
        --       keymaps = {
        --         next_signature = "<M-j>",
        --         previous_signature = "<M-k>",
        --         next_parameter = "<M-l>",
        --         previous_parameter = "<M-h>",
        --       },
        --       display_automatically = true, -- Uses trigger characters to automatically display the signature overloads when typing a method signature
        --     })
        --   end
        --   -- -- map("i", "<C-k>", vim.lsp.buf.signature_help, { buffer = bufnr, desc = desc("signature help") })
        --   -- map("i", "<C-s>", function()
        --   --   -- Close the completion menu first (if open).
        --   --   local cmp = require("cmp")
        --   --   if cmp.visible() then cmp.close() end

        --   --   -- vim.lsp.buf.signature_help()

        --   --   vim.cmd.LspOverloadsSignature()
        --   -- end, { buffer = bufnr, silent = true, noremap = true, desc = desc("signature help") })
        -- end
        -- map("gD", vim.lsp.buf.declaration, "[g]oto [d]eclaration (e.g. to a header file in C)")
        -- rename symbol starting with empty prompt, highlight references

        vnmap("gn", function()
          local ok_rename, rename = pcall(dofile, vim.fn.stdpath("config") .. "/plugin/lsp/rename.lua")

          if ok_rename then
            rename(client)
          else
            -- when rename opens the prompt, this autocommand will trigger
            -- it will "press" CTRL-F to enter the command-line window `:h cmdwin`
            -- in this window I can use normal mode keybindings
            local cmdId
            cmdId = vim.api.nvim_create_autocmd({ "CmdlineEnter" }, {
              callback = function()
                local key = vim.api.nvim_replace_termcodes("<C-f>", true, false, true)
                vim.api.nvim_feedkeys(key, "c", false)
                vim.api.nvim_feedkeys("0", "n", false)
                -- autocmd was triggered and so we can remove the ID and return true to delete the autocmd
                cmdId = nil
                return true
              end,
            })
            vim.lsp.buf.rename()
            -- if LPS couldn't trigger rename on the symbol, clear the autocmd
            vim.defer_fn(function()
              -- the cmdId is not nil only if the LSP failed to rename
              if cmdId then vim.api.nvim_del_autocmd(cmdId) end
            end, 500)
          end
        end, "[g]oto re[n]ame symbol/references")

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
          -- virtual_lines = {
          --   current_line = true,
          -- },
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

        local ns = vim.api.nvim_create_namespace("mega.lsp_max_severity_diagnostics")
        local orig_signs_handler = vim.diagnostic.handlers.signs
        local max_diagnostics = function(_ns, bn, _diagnostics, opts)
          local diagnostics = vim.diagnostic.get(bn)
          local max_severity_per_line = {}
          for _, d in pairs(diagnostics) do
            local m = max_severity_per_line[d.lnum]
            if not m or d.severity < m.severity then max_severity_per_line[d.lnum] = d end
          end
          local filtered_diagnostics = vim.tbl_values(max_severity_per_line)

          -- dbg(filtered_diagnostics)

          if filtered_diagnostics == nil or U.tlen(filtered_diagnostics) == 0 then
            orig_signs_handler.show(ns, bn, diagnostics, opts)
          else
            orig_signs_handler.show(ns, bn, filtered_diagnostics, opts)
          end
        end

        local fname = vim.api.nvim_buf_get_name(bufnr)
        local fext = fname:match("%.[^.]+$")

        if
          SETTINGS.max_diagnostic_exclusions and vim.tbl_contains(SETTINGS.max_diagnostic_exclusions, client.name)
          or (client.name == "elixirls" and fext ~= ".exs")
        then
          vim.diagnostic.handlers.signs = orig_signs_handler
        else
          vim.diagnostic.handlers.signs = vim.tbl_extend("force", orig_signs_handler, {
            show = max_diagnostics,
            hide = function(_, bn) orig_signs_handler.hide(ns, bn) end,
          })
        end

        -- vim.lsp.handlers["window/showMessage"] = function(_, result)
        --   -- if require("vim.lsp.log").should_log(convert_lsp_log_level_to_neovim_log_level(result.type)) then
        --   vim.print(result.message)
        --   local levels = {
        --     "ERROR",
        --     "WARN",
        --     "INFO",
        --     "DEBUG",
        --     [0] = "TRACE",
        --   }
        --   vim.notify(result.message, vim.log.levels[levels[result.type]])
        --   -- end
        -- end

        augroup("LspProgress", {
          {
            pattern = "end",
            event = { "LspProgress" },
            desc = "Handle lsp progress message scenarios",
            command = function(evt)
              if pcall(require, "fidget") and package.loaded("fidget.nvim") then
                local token = evt.data.params.token
                if evt.data.result and evt.data.result.token then token = evt.data.result.token end
                local client_id = evt.data.client_id
                local c = client_id and vim.lsp.get_client_by_id(client_id)
                if c and token then require("fidget").notification.remove(c.name, token) end
              end
            end,
          },
        })

        -- augroup("LspDiagnostics", {
        --   {
        --     event = { "CursorHold" },
        --     desc = "Show diagnostics",
        --     command = show_diagnostic_popup,
        --   },
        -- })

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
      if pcall(require, "cmp_nvim_lsp") and vim.g.completer == "cmp" then capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities) end
      if pcall(require, "blink.cmp") and vim.g.completer == "blink" then capabilities = require("blink.cmp").get_lsp_capabilities(capabilities) end

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

      require("mason").setup({
        install_root_dir = vim.fs.joinpath(vim.env.XDG_DATA_HOME, "lsp/mason"),
      })

      local ensure_servers_installed = {
        -- "postgres_lsp",
        -- "tailwindcss@0.12.18",
        -- "lua_ls",
        -- "tailwindcss-language-server@0.0.27",
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
      vim.list_extend(ensure_servers_installed, servers_to_install)

      require("mason-lspconfig").setup({
        ensure_installed = ensure_servers_installed,
        automatic_enable = false, --ensure_servers_installed,
        automatic_installation = true,
      })

      local ensure_tools_installed = {
        "black",
        "eslint_d",
        "isort",
        "prettier",
        "prettierd",
        "ruff",
        "stylua",
        "nixpkgs-fmt",
        -- "tailwindcss-language-server@0.12.18",
        -- "tailwindcss-language-server@0.0.27",
      }

      require("mason-tool-installer").setup({ ensure_installed = ensure_tools_installed })

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
        -- vim.lsp.config(server_name, cfg)
      end)

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
}
