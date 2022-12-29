local fn = vim.fn
local api = vim.api
local lsp = vim.lsp
local vcmd = vim.cmd
local command = mega.command
local augroup = mega.augroup
local fmt = string.format
local diagnostic = vim.diagnostic

local M = {
  "neovim/nvim-lspconfig",
  event = "BufReadPre",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    -- { "folke/neoconf.nvim", cmd = "Neoconf", config = true },
    -- {
    --   "folke/neodev.nvim",
    --   config = {
    --     debug = true,
    --     experimental = {
    --       pathStrict = true,
    --     },
    --     -- library = {
    --     --   runtime = "~/projects/neovim/runtime/",
    --     -- },
    --   },
    -- },
  },
  -- pin = true,
}

-- [ HELPERS ] -----------------------------------------------------------------

-- Show the popup diagnostics window, but only once for the current cursor/line location
-- by checking whether the word under the cursor has changed.
local function diagnostic_popup(bufnr)
  -- local cword = vim.fn.expand("<cword>")
  -- if cword ~= vim.w.lsp_diagnostics_cword then
  --   vim.w.lsp_diagnostics_cword = cword
  --   if vim.b.lsp_hover_win and api.nvim_win_is_valid(vim.b.lsp_hover_win) then return end
  --   vim.diagnostic.open_float(args.buf, { scope = "line", focus = false })
  -- end
  vim.diagnostic.open_float(bufnr, { scope = "line", focus = false })
end

local format_exclusions = {}
local function formatting_filter(client) return not vim.tbl_contains(format_exclusions, client.name) end

---@param opts table<string, any>
local function format(opts)
  opts = opts or {}
  if (#vim.lsp.get_active_clients({ bufnr = opts.bufnr or vim.api.nvim_get_current_buf() })) < 1 then return end

  vim.lsp.buf.format({
    bufnr = opts.bufnr,
    async = opts.async, -- NOTE: this is super dangerous. no sir; i don't like it.
    filter = formatting_filter,
  })
end

local function get_preview_window()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(vim.api.nvim_get_current_tabpage())) do
    if vim.api.nvim_win_get_option(win, "previewwindow") then return win end
  end
  vim.cmd([[new]])
  local pwin = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_option(pwin, "previewwindow", true)
  vim.api.nvim_win_set_height(pwin, vim.api.nvim_get_option("previewheight"))
  return pwin
end

local function hover()
  local existing_float_win = vim.b.lsp_floating_preview
  if next(vim.lsp.get_active_clients()) == nil then
    vim.cmd([[execute printf('h %s', expand('<cword>'))]])
    -- require("hover").hover_select()
  else
    if existing_float_win and vim.api.nvim_win_is_valid(existing_float_win) then
      vim.b.lsp_floating_preview = nil
      local preview_buffer = vim.api.nvim_win_get_buf(existing_float_win)
      local pwin = get_preview_window()
      vim.api.nvim_win_set_buf(pwin, preview_buffer)
      vim.api.nvim_win_close(existing_float_win, true)
    else
      vim.lsp.buf.hover()
      -- require("hover").hover()
    end
  end
end

-- [ COMMANDS ] ----------------------------------------------------------------

local function setup_commands(bufnr)
  FormatRange = function()
    local start_pos = api.nvim_buf_get_mark(0, "<")
    local end_pos = api.nvim_buf_get_mark(0, ">")
    lsp.buf.range_formatting({}, start_pos, end_pos)
  end
  vcmd([[ command! -range LspFormatRange execute 'lua FormatRange()' ]])

  command("LspLog", function() vim.cmd("vnew " .. vim.lsp.get_log_path()) end)

  command("LspFormat", function() format({ bufnr = bufnr, async = false }) end)

  -- A helper function to auto-update the quickfix list when new diagnostics come
  -- in and close it once everything is resolved. This functionality only runs while
  -- the list is open.
  -- REF:
  -- * https://github.com/akinsho/dotfiles/blob/main/.config/nvim/plugin/lsp.lua#L28-L58
  -- * https://github.com/onsails/diaglist.nvim
  local function make_diagnostic_qf_updater()
    local cmd_id = nil
    return function()
      if not api.nvim_buf_is_valid(0) then return end
      pcall(vim.diagnostic.setqflist, { open = false })
      mega.toggle_list("quickfix")
      if not mega.is_vim_list_open() and cmd_id then
        api.nvim_del_autocmd(cmd_id)
        cmd_id = nil
      end
      if cmd_id then return end
      cmd_id = api.nvim_create_autocmd("DiagnosticChanged", {
        callback = function()
          if mega.is_vim_list_open() then
            pcall(vim.diagnostic.setqflist, { open = false })
            if #fn.getqflist() == 0 then mega.toggle_list("quickfix") end
          end
        end,
      })
    end
  end
  command("LspDiagnostics", make_diagnostic_qf_updater())
  nnoremap("<leader>ll", "<Cmd>LspDiagnostics<CR>", "lsp: toggle quickfix diagnostics")
end

-- [ AUTOCMDS ] ----------------------------------------------------------------
---@param client table<string, any>
---@param bufnr number
local function setup_autocommands(client, bufnr)
  if not client then
    local msg = fmt("Unable to setup LSP autocommands, client for %d is missing", bufnr)
    return vim.notify(msg, "error", { title = "LSP Setup" })
  end

  local supports_highlight = (client and client.server_capabilities.documentHighlightProvider == true)

  augroup("LspCodeLens", {
    {
      event = { "BufEnter", "CursorHold", "InsertLeave" }, -- CursorHoldI
      buffer = bufnr,
      command = function()
        if not vim.tbl_isempty(vim.lsp.codelens.get(bufnr)) then vim.lsp.codelens.refresh() end
      end,
    },
  })

  -- augroup("LspDocumentHighlight", {
  --   {
  --     event = { "CursorHold", "CursorHoldI" },
  --     buffer = bufnr,
  --     command = function()
  --       if supports_highlight then vim.lsp.buf.document_highlight() end
  --     end,
  --   },
  --   {
  --     event = { "CursorMoved", "BufLeave" },
  --     buffer = bufnr,
  --     command = function() vim.lsp.buf.clear_references() end,
  --   },
  -- })

  augroup("LspDiagnostics", {
    {
      event = { "CursorHold" },
      buffer = bufnr,
      desc = "Show diagnostics",
      command = function(args) diagnostic_popup(args.buf) end,
    },
    -- {
    --   event = { "DiagnosticChanged" },
    --   buffer = bufnr,
    --   desc = "Handle diagnostics changes",
    --   command = function()
    --     vim.diagnostic.setloclist({ open = false })
    --     diagnostic_popup()
    --     -- if vim.tbl_isempty(vim.fn.getloclist(0)) then vim.cmd([[lclose]]) end
    --   end,
    -- },
  })
  if client.server_capabilities.signatureHelpProvider then
    augroup("LspFormat", {
      event = { "CursorHoldI" },
      buffer = bufnr,
      callback = function()
        vim.defer_fn(function()
          local line = vim.api.nvim_get_current_line()
          line = vim.trim(line:sub(1, vim.api.nvim_win_get_cursor(0)[2] + 1))
          local len = line:len()
          local char_post = line:sub(len, len)
          local char_pre = line:sub(len - 1, len - 1)
          local show_signature = char_pre == "(" or char_pre == "," or char_post == ")"
          if show_signature then vim.lsp.buf.signature_help() end
        end, 500)
      end,
    })
  end
  augroup("LspFormat", {
    {
      event = { "BufWritePre" },
      -- buffer = bufnr,
      command = function(args)
        format({ async = false, bufnr = args.buf }) -- prefer `false` here
      end,
    },
  })
end

-- [ MAPPINGS ] ----------------------------------------------------------------

local function setup_keymaps(client, bufnr)
  local desc = function(desc) return { desc = desc, buffer = bufnr } end

  nnoremap("[d", function() diagnostic.goto_prev({ float = true }) end, desc("lsp: prev diagnostic"))
  nnoremap("]d", function() diagnostic.goto_next({ float = true }) end, desc("lsp: next diagnostic"))
  nnoremap("gd", vim.lsp.buf.definition, desc("lsp: definition"))
  nnoremap("gr", vim.lsp.buf.references, desc("lsp: references"))
  nnoremap("gt", vim.lsp.buf.type_definition, desc("lsp: type definition"))
  nnoremap("gi", vim.lsp.buf.implementation, desc("lsp: implementation"))
  nnoremap("gI", vim.lsp.buf.incoming_calls, desc("lsp: incoming calls"))
  nnoremap("<leader>lc", vim.lsp.buf.code_action, desc("code action"))
  xnoremap("<leader>lc", "<esc><Cmd>lua vim.lsp.buf.range_code_action()<CR>", desc("code action"))
  nnoremap("gl", vim.lsp.codelens.run, desc("lsp: code lens"))
  nnoremap("gn", require("mega.plugins.lsp.rename").rename, desc("lsp: rename"))
  nnoremap("K", hover, desc("lsp: hover"))
  -- nnoremap("gK", require("hover").hover_select, desc("lsp: hover (select)"))
  -- inoremap("<C-k>", vim.lsp.buf.signature_help, desc("lsp: signature help"))
  -- imap("<C-k>", vim.lsp.buf.signature_help, desc("lsp: signature help"))
  imap("<C-k>", function()
    vim.lsp.buf.signature_help()
    return ""
  end, { expr = true })
  nnoremap("<leader>lic", [[<cmd>LspInfo<CR>]], desc("connected client info"))
  nnoremap("<leader>lim", [[<cmd>Mason<CR>]], desc("mason info"))
  nnoremap(
    "<leader>lis",
    [[<cmd>lua =vim.lsp.get_active_clients()[1].server_capabilities<CR>]],
    desc("server capabilities")
  )
  nnoremap("<leader>lil", [[<cmd>LspLog<CR>]], desc("logs (vsplit)"))
  nnoremap("<leader>lf", vim.lsp.buf.format, desc("format buffer"))
  nnoremap("<leader>lft", [[<cmd>ToggleNullFormatters<cr>]], desc("toggle formatting"))
  nnoremap("=", function() vim.lsp.buf.format({ buffer = bufnr, async = true }) end, desc("lsp: format buffer"))
  vnoremap("=", function() vim.lsp.buf.format({ buffer = bufnr, async = true }) end, desc("lsp: format buffer range"))
end

-- [ FORMATTING ] ---------------------------------------------------------------

-- FIXME: deal with formatting exclusions for null to format vs. the in-built formatting for a client
local function setup_formatting(client, bufnr)
  -- disable formatting for the following language-servers (i.e., let null-ls takeover):
  local disabled_lsp_formatting = { "tailwindcss", "html", "tsserver", "ls_emmet", "zk", "sumneko_lua" }
  for i = 1, #disabled_lsp_formatting do
    if disabled_lsp_formatting[i] == client.name then
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end
  end

  local function has_nls_formatter(ft)
    local sources = require("null-ls.sources")
    local available = sources.get_available(ft, "NULL_LS_FORMATTING")
    return #available > 0
  end

  if client.name == "null-ls" then
    if has_nls_formatter(api.nvim_buf_get_option(bufnr, "filetype")) then
      client.server_capabilities.documentFormattingProvider = true
    else
      client.server_capabilities.documentFormattingProvider = false
    end
  end
end

-- [ DIAGNOSTICS ] -------------------------------------------------------------

local function setup_diagnostics()
  -- ( signs ) --
  local function sign(opts)
    fn.sign_define(opts.hl, {
      text = opts.icon,
      texthl = opts.hl,
      culhl = opts.hl .. "Line",
      --     numhl = fmt("%sNumLine", hl),
      --     linehl = fmt("%sLine", hl),
    })
  end

  sign({ hl = "DiagnosticSignError", icon = mega.icons.lsp.error })
  sign({ hl = "DiagnosticSignWarn", icon = mega.icons.lsp.warn })
  sign({ hl = "DiagnosticSignInfo", icon = mega.icons.lsp.info })
  sign({ hl = "DiagnosticSignHint", icon = mega.icons.lsp.hint })

  --- Restricts nvim's diagnostic signs to only the single most severe one per line
  --- @see `:help vim.diagnostic`
  -- TODO: https://github.com/kristijanhusak/neovim-config/blob/master/nvim/lua/partials/lsp.lua#L152-L159
  local ns = api.nvim_create_namespace("severe-diagnostics")
  local function max_diagnostic(callback)
    return function(_, bufnr, _, opts)
      -- Get all diagnostics from the whole buffer rather than just the
      -- diagnostics passed to the handler
      local diagnostics = vim.diagnostic.get(bufnr)
      -- Find the "worst" diagnostic per line
      local max_severity_per_line = {}
      for _, d in pairs(diagnostics) do
        local m = max_severity_per_line[d.lnum]
        if not m or d.severity < m.severity then max_severity_per_line[d.lnum] = d end
      end
      callback(ns, bufnr, vim.tbl_values(max_severity_per_line), opts)
    end
  end

  local signs_handler = diagnostic.handlers.signs
  diagnostic.handlers.signs = vim.tbl_extend("force", signs_handler, {
    show = max_diagnostic(signs_handler.show),
    hide = function(_, bufnr) signs_handler.hide(ns, bufnr) end,
  })

  -- local virt_text_handler = diagnostic.handlers.virtual_text
  -- diagnostic.handlers.virtual_text = vim.tbl_extend("force", virt_text_handler, {
  --   show = max_diagnostic(virt_text_handler.show),
  --   hide = function(_, bufnr) virt_text_handler.hide(ns, bufnr) end,
  -- })

  -- FIXME:
  -- require("mega.lsp.virtual_text")

  diagnostic.config({
    signs = {
      priority = 9999,
      severity = { min = diagnostic.severity.HINT },
    },
    underline = { severity = { min = diagnostic.severity.HINT } },
    severity_sort = true,
    virtual_text = {
      spacing = 1,
      prefix = "",
      source = "if_many", -- or "always", "if_many" (for more than one source)
      severity = { min = diagnostic.severity.ERROR },
      format = function(d)
        local lvl = diagnostic.severity[d.severity]
        local icon = mega.icons.lsp[lvl:lower()]
        return fmt("%s %s", icon, d.message)
      end,
    },
    update_in_insert = false,
    float = {
      show_header = true,
      source = "always", -- or "always", "if_many" (for more than one source)
      border = mega.get_border(),
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
      header = { "Diagnostics:", "DiagnosticHeader" },
      ---@diagnostic disable-next-line: unused-local
      prefix = function(diag, i, total)
        local level = diagnostic.severity[diag.severity]
        local prefix = fmt("%d. %s ", i, mega.icons.lsp[level:lower()])
        return prefix, "Diagnostic" .. level:gsub("^%l", string.upper)
      end,
    },
  })
end

-- [ HIGHLIGHTS ] --------------------------------------------------------------
local function setup_highlights(client, bufnr)
  -- :h lsp-events
  -- autocmd User LspProgressUpdate redrawstatus
  -- autocmd User LspRequest redrawstatus
  if client then
    mega.augroup(fmt("LspHighlights%s", client.name), {
      event = { "ColorScheme" },
      pattern = bufnr,
      command = function()
        if client.name == "tailwindcss" then
          P(fmt("current client connected is %s; ready for highlights.", client.name))
        end
      end,
    })
  end
end

function M.config()
  local max_width = math.min(math.floor(vim.o.columns * 0.7), 100)
  local max_height = math.min(math.floor(vim.o.lines * 0.3), 30)

  vim.opt.completeopt = { "menu", "menuone", "noselect", "noinsert" }
  vim.opt.shortmess:append("c") -- Don't pass messages to |ins-completion-menu|

  require("mason")
  -- require("mega.plugins.lsp.diagnostics").setup()

  -- This function allows reading a per project "settings.json" file in the `.vim` directory of the project.
  ---@param client table<string, any>
  ---@return boolean
  local function on_init(client)
    local settings = client.workspace_folders[1].name .. "/.vim/settings.json"

    if fn.filereadable(settings) == 0 then return true end
    local ok, json = pcall(fn.readfile, settings)
    if not ok then return true end

    local overrides = vim.json.decode(table.concat(json, "\n"))

    for name, config in pairs(overrides) do
      if name == client.name then
        client.config = vim.tbl_deep_extend("force", client.config, config)
        client.notify("workspace/didChangeConfiguration")

        vim.schedule(function()
          local path = fn.fnamemodify(settings, ":~:.")
          local msg = fmt("loaded local settings for %s from %s", client.name, path)
          vim.notify_once(msg, vim.log.levels.INFO, { title = "LSP Settings" })
        end)
      end
    end
    return true
  end

  local client_overrides = {
    elixirls = function(client, bufnr)
      local manipulate_pipes = function(direction, client)
        local row, col = mega.get_cursor_position()

        client.request_sync("workspace/executeCommand", {
          command = "manipulatePipes:serverid",
          arguments = { direction, "file://" .. vim.api.nvim_buf_get_name(0), row, col },
        }, nil, 0)
      end

      local function from_pipe(c)
        return function() manipulate_pipes("fromPipe", c) end
      end

      local function to_pipe(c)
        return function() manipulate_pipes("toPipe", c) end
      end

      local function restart(c)
        return function()
          c.request_sync("workspace/executeCommand", {
            command = "restart:serverid",
            arguments = {},
          }, nil, 0)

          vim.cmd([[w | edit]])
        end
      end

      local function expand_macro(c)
        return function()
          local params = vim.lsp.util.make_given_range_params()

          local text = vim.api.nvim_buf_get_text(
            0,
            params.range.start.line,
            params.range.start.character,
            params.range["end"].line,
            params.range["end"].character,
            {}
          )

          local resp = c.request_sync("workspace/executeCommand", {
            command = "expandMacro:serverid",
            arguments = { params.textDocument.uri, vim.fn.join(text, "\n"), params.range.start.line },
          }, nil, 0)

          local content = {}
          if resp["result"] then
            for k, v in pairs(resp.result) do
              vim.list_extend(content, { "# " .. k, "" })
              vim.list_extend(content, vim.split(v, "\n"))
            end
          else
            table.insert(content, "Error")
          end

          vim.schedule(
            function() vim.lsp.util.open_floating_preview(vim.lsp.util.trim_empty_lines(content), "elixir", {}) end
          )
        end
      end

      local add_user_cmd = vim.api.nvim_buf_create_user_command
      add_user_cmd(bufnr, "ElixirFromPipe", from_pipe(client), {})
      add_user_cmd(bufnr, "ElixirToPipe", to_pipe(client), {})
      add_user_cmd(bufnr, "ElixirRestart", restart(client), {})
      add_user_cmd(bufnr, "ElixirExpandMacro", expand_macro(client), { range = true })
    end,
  }

  ---Add buffer local mappings, autocommands, tagfunc, etc for attaching servers
  ---@param client table lsp client
  ---@param bufnr number
  local function on_attach(client, bufnr)
    if not client then
      vim.notify("No LSP client found; aborting on_attach.")
      return
    end

    local caps = client.server_capabilities

    if client.config.flags then client.config.flags.allow_incremental_sync = true end

    -- Live color highlighting; handy for tailwindcss
    -- HT: kabouzeid
    if type(caps.provider) == "boolean" and caps.colorProvider then
      if client.name == "tailwindcss" then
        -- require("mega.lsp.document_colors").buf_attach(bufnr, { single_column = true, col_count = 2 })
        require("document-color").buf_attach(bufnr, { mode = "single" })
        do
          local ok, colorizer = pcall(require, "colorizer")
          if ok and colorizer then colorizer.detach_from_buffer() end
        end
      end
    end

    -- if caps.documentSymbolProvider then
    --   local ok, navic = mega.require("nvim-navic")
    --   if ok and navic then navic.attach(client, bufnr) end
    -- end

    if caps.definitionProvider then vim.bo[bufnr].tagfunc = "v:lua.vim.lsp.tagfunc" end

    if caps.documentFormattingProvider then vim.bo[bufnr].formatexpr = "v:lua.vim.lsp.formatexpr()" end

    require("mega.plugins.lsp.handlers").setup()
    if caps.signatureHelpProvider then require("mega.plugins.lsp.signature").setup(client) end
    setup_formatting(client, bufnr)
    setup_commands(bufnr)
    setup_autocommands(client, bufnr)
    setup_diagnostics()
    setup_keymaps(client, bufnr)
    setup_highlights(client, bufnr)

    vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

    if client_overrides[client.name] then client_overrides[client.name](client, bufnr) end
  end

  local servers = require("mega.plugins.lsp.servers").setup()

  -- all the server capabilities we could want
  local function get_server_capabilities()
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities.offsetEncoding = { "utf-16" }
    capabilities.textDocument.codeLens = { dynamicRegistration = false }
    -- TODO: what is dynamicRegistration doing here? should I not always set to true?
    capabilities.textDocument.colorProvider = { dynamicRegistration = false }
    capabilities.textDocument.completion.completionItem.documentationFormat = { "markdown" }
    capabilities.textDocument.foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true,
    }
    capabilities.textDocument.codeAction = {
      dynamicRegistration = false,
      codeActionLiteralSupport = {
        codeActionKind = {
          valueSet = {
            "",
            "quickfix",
            "refactor",
            "refactor.extract",
            "refactor.inline",
            "refactor.rewrite",
            "source",
            "source.organizeImports",
          },
        },
      },
    }

    local nvim_lsp_ok, cmp_nvim_lsp = mega.require("cmp_nvim_lsp")
    if nvim_lsp_ok then capabilities = cmp_nvim_lsp.default_capabilities(capabilities) end

    -- local nvim_tokens_ok, nvim_semantic_tokens = mega.require("nvim-semantic-tokens")
    -- if nvim_tokens_ok then capabilities = nvim_semantic_tokens.update_capabilities(capabilities) end

    return capabilities
  end

  ---Get the configuration for a specific language server
  ---@type lspconfig.options
  ---@param name string
  ---@return table<string, any>?
  local function get_config(name)
    local config = servers[name]
    if not config then return end
    local t = type(config)
    if t == "boolean" then config = {} end
    if t == "function" then config = config() end

    config.on_init = on_init
    config.flags = { debounce_text_changes = 150 }
    config.capabilities = get_server_capabilities()
    config.on_attach = on_attach

    return config
  end

  for server, _ in pairs(servers) do
    -- opts = vim.tbl_deep_extend("force", {}, options, opts or {})
    local opts = get_config(server)

    if server == "tsserver" then
      require("typescript").setup({ server = opts })
    else
      require("lspconfig")[server].setup(opts)
    end
  end

  require("mega.plugins.null-ls").setup({ on_attach = on_attach })
end

return M
