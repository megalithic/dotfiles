if not mega then return end
if not vim.g.enabled_plugin["lsp"] then return end

local fn = vim.fn
local api = vim.api
local lsp = vim.lsp
local vcmd = vim.cmd
local command = mega.command
local augroup = mega.augroup
local fmt = string.format
local diagnostic = vim.diagnostic
local lspconfig = require("lspconfig")
local LSP_METHODS = vim.lsp.protocol.Methods

function mega.lsp.is_enabled_elixir_ls(ls) return vim.tbl_contains(vim.g.enabled_elixir_ls, ls) end
function mega.lsp.formatting_filter(client)
  -- dd(fmt("formatting_filter allows %s? %s", client.name, not vim.tbl_contains(vim.g.formatter_exclusions, client.name)))
  return not vim.tbl_contains(vim.g.formatter_exclusions, client.name)
end

-- Show the popup diagnostics window, but only once for the current cursor/line location
-- by checking whether the word under the cursor has changed.
local function diagnostic_popup(bufnr) vim.diagnostic.open_float(bufnr, { scope = "cursor", focus = false }) end

-- TODO: https://github.com/CKolkey/config/blob/master/nvim/lua/plugins/lsp/formatting.lua

---@param opts? table<string, any>
local function format(opts)
  opts = opts or {}
  if (#vim.lsp.get_clients({ bufnr = opts.bufnr or vim.api.nvim_get_current_buf() })) < 1 then return end

  vim.lsp.buf.format({
    bufnr = opts.bufnr,
    async = opts.async or false, -- NOTE: this is super dangerous. no sir; i don't like it.
    filter = mega.lsp.formatting_filter,
  })
end

local function get_preview_window()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(vim.api.nvim_get_current_tabpage())) do
    if vim.api.nvim_win_get_option(win, "previewwindow") then return win end
  end
  vim.cmd([[botright vnew]])
  local pwin = vim.api.nvim_get_current_win()
  local pwin_width = vim.o.columns > 210 and 90 or 70
  vim.api.nvim_win_set_option(pwin, "previewwindow", true)
  vim.api.nvim_win_set_width(pwin, pwin_width)
  vim.cmd("set filetype=preview")
  vim.cmd(fmt("let &winwidth=%d", pwin_width))
  vim.opt_local.winfixwidth = true

  return pwin
end

local function hover()
  local existing_float_win = vim.b.lsp_floating_preview
  local active_clients = vim.lsp.get_clients()

  if next(active_clients) == nil then
    vim.cmd([[execute printf('h %s', expand('<cword>'))]])
  else
    if existing_float_win and vim.api.nvim_win_is_valid(existing_float_win) then
      vim.b.lsp_floating_preview = nil
      local preview_buffer = vim.api.nvim_win_get_buf(existing_float_win)
      local pwin = get_preview_window()
      vim.api.nvim_win_set_buf(pwin, preview_buffer)
      vim.api.nvim_win_close(existing_float_win, true)
    else
      -- vim.lsp.buf.hover(nil, { focus = false, focusable = false })
      -- dd("pretty hovering")
      require("pretty_hover").hover()
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
  command(
    "LspLogDelete",
    function() vim.fn.system("rm " .. vim.lsp.get_log_path()) end,
    { desc = "Deletes the LSP log file. Useful for when it gets too big" }
  )

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
    return vim.notify(msg, L.ERROR, { title = "LSP Setup" })
  end

  local supports_highlight = (client and client.server_capabilities.documentHighlightProvider == true)
  -- local supports_inlay_hints = (client and client.server_capabilities.inlayHintProvider == true)
  -- local supports_references = (client and client.server_capabilities.referencesProvider == true)
  -- local supports_definition = (client and client.server_capabilities.definitionProvider == true)

  augroup("LspCodeLens", {
    {
      event = { "BufEnter", "CursorHold", "InsertLeave" }, -- CursorHoldI
      buffer = bufnr,
      command = function()
        if not vim.tbl_isempty(vim.lsp.codelens.get(bufnr)) then vim.lsp.codelens.refresh() end
      end,
    },
  })

  augroup("LspDocumentHighlight", {
    {
      event = { "CursorHold", "CursorHoldI" },
      buffer = bufnr,
      command = function()
        if supports_highlight and not vim.g.git_conflict_detected then vim.lsp.buf.document_highlight() end
      end,
    },
    {
      event = { "CursorMoved", "BufLeave" },
      buffer = bufnr,
      command = function()
        if not vim.g.git_conflict_detected then vim.lsp.buf.clear_references() end
      end,
    },
  })

  augroup("LspDiagnostics", {
    {
      event = { "CursorHold" },
      desc = "Show diagnostics",
      command = function(args) diagnostic_popup(args.buf) end,
    },
    -- {
    --   event = { "DiagnosticChanged" },
    --   -- buffer = bufnr,
    --   desc = "Handle diagnostics changes",
    --   command = function()
    --     vim.diagnostic.setloclist({ open = false })
    --     diagnostic_popup()
    --     if vim.tbl_isempty(vim.fn.getloclist(0)) then vim.cmd([[lclose]]) end
    --   end,
    -- },
  })

  -- augroup("LspFormat", {
  --   {
  --     event = { "BufWritePre" },
  --     command = function(args)
  --       if vim.g.disable_autoformat then return end
  --       format({ async = false, bufnr = args.buf })
  --     end,
  --   },
  -- })

  -- augroup("LspDocumentHighlight", {
  --   {
  --     event = { "InsertEnter" },
  --     buffer = bufnr,
  --     command = function()
  --       if supports_inlay_hints then vim.lsp.buf.inlay_hint(bufnr, true) end
  --     end,
  --   },
  --   {
  --     event = { "InsertLeave" },
  --     buffer = bufnr,
  --     command = function()
  --       if supports_inlay_hints then vim.lsp.buf.inlay_hint(bufnr, false) end
  --     end,
  --   },
  -- })
end

-- [ MAPPINGS ] ----------------------------------------------------------------

local function setup_keymaps(client, bufnr)
  local function has(method)
    method = method:find("/") and method or "textDocument/" .. method
    -- local clients = vim.lsp.get_active_clients({ bufnr = buffer })
    -- for _, client in ipairs(clients) do
    -- if client.supports_method(method) then return true end
    -- end
    -- return false

    -- if client.supports_method(method) then dd("has " .. method) end
    return client.supports_method(method)
  end

  local desc = function(desc, expr)
    expr = expr ~= nil and expr or false
    return { desc = desc, buffer = bufnr, expr = expr }
  end

  nnoremap("[d", function() diagnostic.goto_prev({ float = true }) end, desc("lsp: prev diagnostic"))
  nnoremap("]d", function() diagnostic.goto_next({ float = true }) end, desc("lsp: next diagnostic"))

  if has("definition") then
    nnoremap("gd", function()
      -- dd(client.server_capabilities)
      if true then
        vim.cmd("Telescope lsp_definitions")
      -- vim.cmd("Trouble lsp_definitions")
      else
        vim.lsp.buf.definition()
      end
    end, desc("lsp: definition"))
  end

  nnoremap("gs", vim.lsp.buf.document_symbol, desc("lsp: document symbols"))
  nnoremap("gS", vim.lsp.buf.workspace_symbol, desc("lsp: workspace symbols"))
  nnoremap("gD", [[<cmd>vsplit | lua vim.lsp.buf.definition()<cr>]], desc("lsp: definition (vsplit)"))

  if
    not has("references")
    -- not client.server_capabilities.documentReferencesProvider and not client.server_capabilities.referencesProvider
  then
    nmap("gr", "<leader>A", desc("lsp: references"))
  else
    nmap("gr", function()
      if true then
        vim.cmd("Trouble lsp_references")
      else
        if vim.g.picker == "fzf" then
          vim.cmd("FzfLua lsp_references")
        elseif vim.g.picker == "telescope" then
          vim.cmd("Telescope lsp_references")
        else
          vim.lsp.buf.references()
        end
      end
    end, desc("lsp: references"))
  end

  nnoremap("gt", vim.lsp.buf.type_definition, desc("lsp: type definition"))
  nnoremap("gi", vim.lsp.buf.implementation, desc("lsp: implementation"))
  nnoremap("gI", vim.lsp.buf.incoming_calls, desc("lsp: incoming calls"))

  if has("codeAction") then
    nnoremap("<leader>lc", vim.lsp.buf.code_action, desc("code action"))
    xnoremap("<leader>lc", "<esc><Cmd>lua vim.lsp.buf.range_code_action()<CR>", desc("code action"))
  end

  nnoremap("gl", vim.lsp.codelens.run, desc("lsp: code lens"))

  if has("rename") then nnoremap("gn", vim.lsp.buf.rename, desc("lsp: rename")) end

  nnoremap("ger", require("mega.utils.lsp").rename_file, desc("lsp: rename file to <input>"))

  nnoremap("K", function()
    local filetype = vim.bo.filetype
    if vim.tbl_contains({ "vim", "help" }, filetype) then
      vim.cmd("h " .. vim.fn.expand("<cword>"))
    elseif vim.tbl_contains({ "man" }, filetype) then
      vim.cmd("Man " .. vim.fn.expand("<cword>"))
    elseif vim.fn.expand("%:t") == "Cargo.toml" and require("crates").popup_available() then
      require("crates").show_popup()
    else
      hover()
    end
  end, desc("lsp: hover"))

  if has("signatureHelp") then
    nnoremap("gK", vim.lsp.buf.signature_help, desc("lsp: signature help"))
    inoremap("<c-k>", vim.lsp.buf.signature_help, desc("lsp: signature help"))
    imap("<c-k>", vim.lsp.buf.signature_help, desc("lsp: signature help"))
  end

  nnoremap("<leader>lic", [[<cmd>LspInfo<CR>]], desc("connected client info"))
  nnoremap("<leader>lim", [[<cmd>Mason<CR>]], desc("mason info"))
  nnoremap(
    "<leader>lis",
    function() dd(fmt("server capabilities for %s: \r\n%s", client.name, client.server_capabilities)) end,
    desc("server capabilities")
  )
  nnoremap("<leader>lil", [[<cmd>LspLog<CR>]], desc("logs (vsplit)"))

  if has("formatting") then
    nnoremap("<leader>lft", [[<cmd>ToggleAutoFormat<cr>]], desc("toggle formatting"))
    -- nnoremap("<leader>lff", vim.lsp.buf.format, desc("format buffer"))
    nnoremap("<leader>lff", function()
      if pcall(require, "conform") then
        require("conform").format({ async = false, lsp_fallback = true })
      else
        format()
      end
    end, desc("format buffer"))
    nnoremap("=", function() vim.lsp.buf.format({ buffer = bufnr, async = true }) end, desc("lsp: format buffer"))
  end

  if has("rangeFormatting") then
    vnoremap("=", function() vim.lsp.buf.format({ buffer = bufnr, async = true }) end, desc("lsp: format buffer range"))
  end
end

-- [ FORMATTING ] ---------------------------------------------------------------

local function setup_formatting(client, bufnr)
  -- disable formatting for the following language-servers (i.e., let null-ls takeover):

  -- REF: disable formatting for specific clients via format's filtering table
  -- https://github.com/mhanberg/.dotfiles/commit/3d606966b04dbf33aa125d3f8a03cabf7f8a6712#diff-406a4eb2a988e31ffbf893c2e01684e43e72f4595eef92845fbb3f60e9156563R29-R35
  local disabled_lsp_formatting = { "tailwindcss", "html", "tsserver", "ls_emmet", "zk", "sumneko_lua" }
  for i = 1, #disabled_lsp_formatting do
    if disabled_lsp_formatting[i] == client.name then
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end
  end

  if vim.g.formatter == "null-ls" then
    local function has_formatter(ft)
      local sources = require("null-ls.sources")
      local available = sources.get_available(ft, "NULL_LS_FORMATTING")
      return #available > 0
    end

    if client.name == "null-ls" then
      if has_formatter(api.nvim_buf_get_option(bufnr, "filetype")) then
        client.server_capabilities.documentFormattingProvider = true
      else
        client.server_capabilities.documentFormattingProvider = false
      end
    end
  elseif vim.g.formatter == "conform" then
    -- local function has_formatter(ft)
    --   local sources = require("conform").list_formatters(bufnr)
    --   local available = sources.get_available(ft, "NULL_LS_FORMATTING")
    --   return #available > 0
    -- end
    -- -- Disable autoformat on certain filetypes
    -- local ignore_filetypes = { "sql", "java" }
    -- if vim.tbl_contains(ignore_filetypes, vim.bo[args.buf].filetype) then return end
    -- -- Disable with a global or buffer-local variable
    -- if vim.g.disable_autoformat or vim.b[args.buf].disable_autoformat then return end
  end
end

-- [ DIAGNOSTICS ] -------------------------------------------------------------

-- FIXME:
-- Error executing vim.schedule lua callback: Vim:E474: Invalid argument
-- stack traceback:
-- 	[C]: in function 'sign_place'
-- 	/usr/local/share/nvim/runtime/lua/vim/diagnostic.lua:908: in function 'callback'
-- 	/Users/seth/.dotfiles/config/nvim/plugin/lsp.lua:358: in function 'callback'
-- 	/Users/seth/.dotfiles/config/nvim/plugin/lsp.lua:358: in function 'callback'
-- 	/Users/seth/.dotfiles/config/nvim/plugin/lsp.lua:358: in function 'callback'
-- 	/Users/seth/.dotfiles/config/nvim/plugin/lsp.lua:358: in function 'callback'
-- 	/Users/seth/.dotfiles/config/nvim/plugin/lsp.lua:358: in function 'callback'
-- 	/Users/seth/.dotfiles/config/nvim/plugin/lsp.lua:358: in function 'callback'
-- 	/Users/seth/.dotfiles/config/nvim/plugin/lsp.lua:358: in function 'callback'
-- 	/Users/seth/.dotfiles/config/nvim/plugin/lsp.lua:358: in function 'callback'
-- 	/Users/seth/.dotfiles/config/nvim/plugin/lsp.lua:358: in function 'show'
-- 	/usr/local/share/nvim/runtime/lua/vim/diagnostic.lua:1233: in function 'show'
-- 	/usr/local/share/nvim/runtime/lua/vim/diagnostic.lua:706: in function 'set'
-- 	/usr/local/share/nvim/runtime/lua/vim/lsp/diagnostic.lua:236: in function 'handler'
-- 	/usr/local/share/nvim/runtime/lua/vim/lsp.lua:1164: in function ''
-- 	vim/_editor.lua: in function <vim/_editor.lua:0>
local function setup_diagnostics(client, _bufnr)
  local function sign(opts)
    fn.sign_define(opts.hl, {
      text = opts.icon,
      texthl = opts.hl,
      culhl = opts.hl .. "Line",
      numhl = opts.hl .. "Line",
      -- linehl = opts.hl .. "Line",
    })
  end
  sign({ hl = "DiagnosticSignError", icon = mega.icons.lsp.error })
  sign({ hl = "DiagnosticSignWarn", icon = mega.icons.lsp.warn })
  sign({ hl = "DiagnosticSignInfo", icon = mega.icons.lsp.info })
  sign({ hl = "DiagnosticSignHint", icon = mega.icons.lsp.hint })

  --- Restricts nvim's diagnostic signs to only the single most severe one per line
  -- REF: `:help vim.diagnostic`
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
      local new_diags = vim.tbl_values(max_severity_per_line)
      callback(ns, bufnr, new_diags, opts)
    end
  end

  --   local signs_handler = diagnostic.handlers.signs
  --   diagnostic.handlers.signs = vim.tbl_extend("force", signs_handler, {
  --     show = max_diagnostic(signs_handler.show),
  --     hide = function(_, bufnr) signs_handler.hide(ns, bufnr) end,
  --   })

  local virt_text_handler = diagnostic.handlers.virtual_text
  diagnostic.handlers.virtual_text = vim.tbl_extend("force", virt_text_handler, {
    show = max_diagnostic(virt_text_handler.show),
    hide = function(_, bufnr) virt_text_handler.hide(ns, bufnr) end,
  })

  local max_width = math.min(math.floor(vim.o.columns * 0.7), 100)
  local max_height = math.min(math.floor(vim.o.lines * 0.3), 30)
  mega.lsp.diagnostic_config = {
    signs = {
      priority = 9999,
      severity = { min = diagnostic.severity.HINT },
    },
    underline = { severity = { min = diagnostic.severity.HINT } },
    severity_sort = true,
    virtual_text = {
      prefix = function(d)
        local level = diagnostic.severity[d.severity]
        return mega.icons.lsp[level:lower()]
      end,
      source = "always", -- or "always", "if_many" (for more than one source)
      severity = { min = diagnostic.severity.ERROR },
      format = function(d)
        -- dd(fmt("virtual_text_format: %s", I(d)))
        return d.message
        -- local lvl = diagnostic.severity[d.severity]
        -- local icon = mega.icons.lsp[lvl:lower()]
        -- return fmt("%s %s", icon, d.message)
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
      scope = "cursor",
      header = { " Diagnostics:", "DiagnosticHeader" },
      prefix = function(diag, i, _total)
        local level = diagnostic.severity[diag.severity]
        local prefix = fmt("%d. ", i)
        -- local prefix = fmt("%d. %s ", i, mega.icons.lsp[level:lower()])
        return prefix, "Diagnostic" .. level:gsub("^%l", string.upper)
      end,
    },
  }
  diagnostic.config(mega.lsp.diagnostic_config)

  local diagnostic_handler = lsp.handlers[LSP_METHODS.textDocument_publishDiagnostics]
  lsp.handlers[LSP_METHODS.textDocument_publishDiagnostics] = function(err, result, ctx, config)
    local client_name = vim.lsp.get_client_by_id(ctx.client_id).name

    if vim.tbl_contains(vim.g.diagnostic_exclusions, client_name) then return end
    -- dd(fmt("diagnostic client: %s", client_name))

    -- result.diagnostics = vim.tbl_map(show_related_locations, result.diagnostics)
    diagnostic_handler(err, result, ctx, config)
  end
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

vim.opt.shortmess:append("c") -- Don't pass messages to |ins-completion-menu|

-- Setup neovim lua configuration
-- require("neodev").setup()
require("mason")

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

local client_overrides = {}

---@param client lsp.Client
---@param bufnr number
local function setup_semantic_tokens(client, bufnr)
  local overrides = client_overrides[client.name]
  if not overrides or not overrides.semantic_tokens then return end

  mega.augroup(fmt("LspSemanticTokens%s", client.name), {
    event = "LspTokenUpdate",
    buffer = bufnr,
    desc = fmt("Configure the semantic tokens for the %s", client.name),
    command = function(args) overrides.semantic_tokens(args.buf, client, args.data.token) end,
  })
end

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
      require("document-color").buf_attach(bufnr, { mode = "single" })
      do
        local ok, colorizer = pcall(require, "colorizer")
        if ok and colorizer then colorizer.detach_from_buffer() end
      end
    end
  end

  -- Disable completion for certain clients (using this mostly for the multiple elixir clients i'm using at the moment):
  -- if type(caps.provider) == "boolean" and caps.completionProvider then
  --   if vim.tbl_contains({ "lexical" }, client.name) then
  --     dd(fmt("disabling completionProvider for %s", client.name))
  --     caps.completionProvider = nil
  --   end
  -- end

  -- if caps.documentSymbolProvider then
  --   local ok, navic = mega.require("nvim-navic")
  --   if ok and navic then navic.attach(client, bufnr) end
  -- end

  -- if client.supports_method("textDocument/signatureHelp") then
  --   require("lsp_signature").on_attach({
  --     -- -- hint_inline = function()
  --     -- --   return true
  --     -- -- end,
  --     -- handler_opts = { border = mega.get_border() },
  --     -- hint_prefix = "",
  --     -- hint_enable = false,
  --     -- fixpos = true,
  --     -- padding = " ",
  --     debug = false, -- set to true to enable debug logging
  --     log_path = vim.fs.joinpath(vim.fn.stdpath("cache"), "lsp_signature.log"), -- log dir when debug is on
  --     -- default is  ~/.cache/nvim/lsp_signature.log
  --     verbose = false, -- show debug line number
  --
  --     bind = true, -- This is mandatory, otherwise border config won't get registered.
  --     -- If you want to hook lspsaga or other signature handler, pls set to false
  --     doc_lines = 10, -- will show two lines of comment/doc(if there are more than two lines in doc, will be truncated);
  --     -- set to 0 if you DO NOT want any API comments be shown
  --     -- This setting only take effect in insert mode, it does not affect signature help in normal
  --     -- mode, 10 by default
  --
  --     max_height = 12, -- max height of signature floating_window
  --     max_width = 80, -- max_width of signature floating_window
  --     noice = false, -- set to true if you using noice to render markdown
  --     wrap = true, -- allow doc/signature text wrap inside floating_window, useful if your lsp return doc/sig is too long
  --
  --     floating_window = true, -- show hint in a floating window, set to false for virtual text only mode
  --
  --     floating_window_above_cur_line = true, -- try to place the floating above the current line when possible Note:
  --     -- will set to true when fully tested, set to false will use whichever side has more space
  --     -- this setting will be helpful if you do not want the PUM and floating win overlap
  --
  --     floating_window_off_x = 0, -- adjust float windows x position.
  --     -- can be either a number or function
  --     floating_window_off_y = 0, -- adjust float windows y position. e.g -2 move window up 2 lines; 2 move down 2 lines
  --     -- can be either number or function, see examples
  --
  --     close_timeout = 4000, -- close floating window after ms when laster parameter is entered
  --     fix_pos = false, -- set to true, the floating window will not auto-close until finish all parameters
  --     hint_prefix = "",
  --     hint_enable = false,
  --     -- hint_enable = true, -- virtual hint enable
  --     -- hint_prefix = "➜ ", -- Panda for parameter, NOTE: for the terminal not support emoji, might crash
  --     -- hint_scheme = "String",
  --     hi_parameter = "LspSignatureActiveParameter", -- how your parameter will be highlight
  --     handler_opts = {
  --       border = mega.get_border(),
  --     },
  --
  --     always_trigger = false, -- sometime show signature on new line or in middle of parameter can be confusing, set it to false for #58
  --
  --     auto_close_after = nil, -- autoclose signature float win after x sec, disabled if nil.
  --     extra_trigger_chars = {}, -- Array of extra characters that will trigger signature completion, e.g., {"(", ","}
  --     zindex = 200, -- by default it will be on top of all floating windows, set to <= 50 send it to bottom
  --
  --     padding = "", -- character to pad on left and right of signature can be ' ', or '|'  etc
  --
  --     -- transparency = 10, -- disabled by default, allow floating win transparent value 1~100
  --     shadow_blend = 36, -- if you using shadow as border use this set the opacity
  --     shadow_guibg = mega.colors.bg_dark.hex, -- if you using shadow as border use this set the color e.g. 'Green' or '#121315'
  --     timer_interval = 200, -- default timer check interval set to lower value if you want to reduce latency
  --     toggle_key = nil, -- toggle signature on and off in insert mode,  e.g. toggle_key = '<M-x>'
  --
  --     select_signature_key = nil, -- cycle to next signature, e.g. '<M-n>' function overloading
  --     move_cursor_key = nil, -- imap, use nvim_set_current_win to move cursor between current win and floating
  --   }, bufnr)
  -- end

  if caps.definitionProvider then vim.bo[bufnr].tagfunc = "v:lua.vim.lsp.tagfunc" end

  if caps.documentFormattingProvider then vim.bo[bufnr].formatexpr = "v:lua.vim.lsp.formatexpr()" end

  require("mega.utils.lsp").setup_rename(client, bufnr)

  setup_formatting(client, bufnr)
  setup_commands(bufnr)
  setup_autocommands(client, bufnr)
  setup_diagnostics(client, bufnr)
  setup_keymaps(client, bufnr)
  setup_highlights(client, bufnr)
  setup_semantic_tokens(client, bufnr)

  -- fully disable semantic tokens highlighting
  client.server_capabilities.semanticTokensProvider = nil
  if client.server_capabilities.completionProvider ~= nil then
    client.server_capabilities.completionProvider.triggerCharacters = { ".", ":" }
  end

  vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

  if client_overrides[client.name] then client_overrides[client.name](client, bufnr) end
end

local servers = require("mega.servers")

-- all the server capabilities we could want
local function get_server_capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities.offsetEncoding = { "utf-16" }
  capabilities.textDocument.codeLens = { dynamicRegistration = false }
  -- TODO: what is dynamicRegistration doing here? should I not always set to true?
  capabilities.textDocument.colorProvider = { dynamicRegistration = false }
  capabilities.textDocument.completion.completionItem.documentationFormat = { "markdown" }
  -- textDocument = { foldingRange = { dynamicRegistration = false, lineFoldingOnly = true } },

  -- FIX: https://github.com/neovim/neovim/issues/23291
  -- NOTE: this might break nextls/elixirls:
  -- capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false

  -- disable semantic token highlighting
  -- capabilities.textDocument.semanticTokensProvider = false
  capabilities.textDocument.foldingRange = {
    dynamicRegistration = false,
    lineFoldingOnly = true,
  }
  -- capabilities.textDocument.codeAction = {
  --   dynamicRegistration = false,
  --   codeActionLiteralSupport = {
  --     codeActionKind = {
  --       valueSet = {
  --         "",
  --         "quickfix",
  --         "refactor",
  --         "refactor.extract",
  --         "refactor.inline",
  --         "refactor.rewrite",
  --         "source",
  --         "source.organizeImports",
  --       },
  --     },
  --   },
  -- }

  local nvim_lsp_ok, cmp_nvim_lsp = mega.wrap_err(require, "cmp_nvim_lsp")
  if nvim_lsp_ok then capabilities = cmp_nvim_lsp.default_capabilities(capabilities) end

  return capabilities
end

---Get the configuration for a specific language server
---@type lspconfig.options
---@param name string
---@return table<string, any>?
local function get_config(name)
  local config = name and servers.list[name] or {}
  local t = type(config)
  if t == "function" then config = config() end
  if t == "function" and config == false then config = nil end

  if not config then return end
  -- if config == false or config == nil then return end

  config.on_init = on_init
  config.flags = { debounce_text_changes = 150 }
  config.capabilities = get_server_capabilities()
  config.on_attach = on_attach

  return config
end

for server, _ in pairs(servers.list) do
  servers.load_unofficial()
  local opts = get_config(server)

  if opts ~= nil then
    if server == "tsserver" then
      -- require("typescript-tools").setup({
      --   capabilities = get_server_capabilities(),
      --   on_attach = on_attach,
      --   settings = {
      --     separate_diagnostic_server = true,
      --     publish_diagnostic_on = "insert_leave",
      --     tsserver_plugins = { "typescript-styled-plugin" },
      --   },
      -- })
      -- require("typescript").setup({ server = opts })
      lspconfig[server].setup(opts)
    else
      lspconfig[server].setup(opts)
    end
  end
end

-- REF:
-- https://github.com/neovim/neovim/issues/23291#issuecomment-1687088266
do -- fswatch
  local FSWATCH_EVENTS = {
    Created = 1,
    Updated = 2,
    Removed = 3,
    -- Renamed
    OwnerModified = 2,
    AttributeModified = 2,
    MovedFrom = 1,
    MovedTo = 3,
    -- IsFile
    IsDir = false,
    IsSymLink = false,
    PlatformSpecific = false,
    -- Link
    -- Overflow
  }

  --- @param data string
  --- @param opts table
  --- @param callback fun(path: string, event: integer)
  local function fswatch_output_handler(data, opts, callback)
    local d = vim.split(data, "%s+")
    local cpath = d[1]

    for i = 2, #d do
      if FSWATCH_EVENTS[d[i]] == false then return end
    end

    if opts.include_pattern and opts.include_pattern:match(cpath) == nil then return end

    if opts.exclude_pattern and opts.exclude_pattern:match(cpath) ~= nil then return end

    for i = 2, #d do
      local e = FSWATCH_EVENTS[d[i]]
      if e then callback(cpath, e) end
    end
  end

  local function fswatch(path, opts, callback)
    local obj = vim.system({
      "fswatch",
      "--recursive",
      "--event-flags",
      "--exclude",
      "/.git/",
      path,
    }, {
      stdout = function(err, data)
        if err then error(err) end

        if not data then return end

        for line in vim.gsplit(data, "\n", { plain = true, trimempty = true }) do
          fswatch_output_handler(line, opts, callback)
        end
      end,
    })

    return function() obj:kill(2) end
  end

  if vim.fn.executable("fswatch") == 1 then require("vim.lsp._watchfiles")._watchfunc = fswatch end
end
