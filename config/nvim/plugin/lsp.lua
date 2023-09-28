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
local servers = require("mega.servers")

function mega.lsp.has_method(client, method)
  method = method:find("/") and method or "textDocument/" .. method

  -- if client.supports_method(method) then dd(client.name .. " has " .. method) end

  return client.supports_method(method)
end
function mega.lsp.is_enabled_elixir_ls(ls) return vim.tbl_contains(vim.g.enabled_elixir_ls, ls) end
function mega.lsp.formatting_filter(client)
  -- dd(fmt("formatting_filter allows %s? %s", client.name, not vim.tbl_contains(vim.g.formatter_exclusions, client.name)))
  return not vim.tbl_contains(vim.g.formatter_exclusions, client.name)
end

-- Show the popup diagnostics window, but only once for the current cursor/line location
-- by checking whether the word under the cursor has changed.
local function diagnostic_popup(bufnr)
  if not vim.g.git_conflict_detected then vim.diagnostic.open_float(bufnr, { scope = "cursor", focus = false }) end
end

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

local function hover()
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

      nnoremap("q", function()
        vim.api.nvim_win_close(0, true)
        vim.cmd("wincmd p")
      end, { buffer = preview_buffer })
    else
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
      event = { "CursorHold" },
      buffer = bufnr,
      command = function()
        if mega.lsp.has_method(client, "documentHighlight") and not vim.g.git_conflict_detected then
          vim.lsp.buf.document_highlight()
        end
      end,
    },
    {
      event = { "CursorMoved", "BufLeave", "WinLeave" },
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

local function cancelable(method)
  return function()
    local params = vim.lsp.util.make_position_params()
    local bufnr = vim.api.nvim_get_current_buf()
    local cursor = vim.api.nvim_win_get_cursor(0)
    vim.lsp.buf_request(0, method, params, function(...)
      local new_cursor = vim.api.nvim_win_get_cursor(0)
      if vim.api.nvim_get_current_buf() == bufnr and vim.deep_equal(cursor, new_cursor) then
        vim.lsp.handlers[method](...)
      end
    end)
  end
end

local function setup_keymaps(client, bufnr)
  local function desc(description, expr)
    expr = expr ~= nil and expr or false
    return { desc = description, buffer = bufnr, expr = expr }
  end

  local function safemap(method, mode, key, rhs, description)
    if mega.lsp.has_method(client, method) then
      vim.keymap.set(mode, key, rhs, { buffer = bufnr, desc = description })
    end
  end

  nnoremap("<leader>lic", [[<cmd>LspInfo<CR>]], desc("connected client info"))
  nnoremap("<leader>lim", [[<cmd>Mason<CR>]], desc("mason info"))
  nnoremap(
    "<leader>lis",
    function() dd(fmt("server capabilities for %s: \r\n%s", client.name, client.server_capabilities)) end,
    desc("server capabilities")
  )
  nnoremap("<leader>lil", [[<cmd>LspLog<CR>]], desc("logs (vsplit)"))

  nnoremap("[d", function() diagnostic.goto_prev({ float = true }) end, desc("lsp: prev diagnostic"))
  nnoremap("]d", function() diagnostic.goto_next({ float = true }) end, desc("lsp: next diagnostic"))

  safemap("definition", "n", "gd", function()
    vim.lsp.buf.definition()
    -- if vim.g.picker == "fzf" then
    --   vim.cmd("FzfLua lsp_definitions")
    -- elseif vim.g.picker == "telescope" then
    --   vim.cmd("Telescope lsp_definitions")
    -- else
    --   vim.lsp.buf.definition()
    -- end
  end, "lsp: definition")
  safemap("definition", "n", "gD", [[<cmd>vsplit | lua vim.lsp.buf.definition()<cr>]], "lsp: definition (vsplit)")
  nnoremap("gs", vim.lsp.buf.document_symbol, desc("lsp: document symbols"))
  nnoremap("gS", vim.lsp.buf.workspace_symbol, desc("lsp: workspace symbols"))

  safemap("references", "n", "gr", function()
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
  end, "lsp: references")
  if client.name == "lexical" then safemap("references", "n", "gr", "<leader>A", "lsp: references") end
  safemap("typeDefinition", "n", "gt", vim.lsp.buf.type_definition, "lsp: type definition")
  safemap("implementation", "n", "gi", vim.lsp.buf.implementation, "lsp: implementation")
  nnoremap("gI", vim.lsp.buf.incoming_calls, desc("lsp: incoming calls"))
  safemap("codeAction", "n", "<leader>lc", vim.lsp.buf.code_action, "code action")
  safemap("codeAction", "x", "<leader>lc", "<esc><Cmd>lua vim.lsp.buf.range_code_action()<CR>", "code action")
  nnoremap("gl", vim.lsp.codelens.run, desc("lsp: code lens"))
  safemap("rename", "n", "gn", vim.lsp.buf.rename, "lsp: rename")
  nnoremap("ger", require("mega.utils.lsp").rename_file, desc("lsp: rename file to <input>"))
  nnoremap("gen", require("mega.utils.lsp").rename_file, desc("lsp: rename file to <input>"))
  safemap("hover", "n", "K", function()
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
  safemap("signatureHelp", "n", "gK", vim.lsp.buf.signature_help, "lsp: signature help")
  safemap("signatureHelp", "i", "<c-k>", vim.lsp.buf.signature_help, "lsp: signature help")
  safemap("formatting", "n", "<leader>lft", [[<cmd>ToggleAutoFormat<cr>]], "toggle formatting")
  safemap("formatting", "n", "<leader>lff", function()
    if pcall(require, "conform") then
      require("conform").format({ async = false, lsp_fallback = true })
    else
      format()
    end
  end, "format buffer")
  safemap(
    "formatting",
    "n",
    "=",
    function() vim.lsp.buf.format({ buffer = bufnr, async = true }) end,
    "lsp: format buffer"
  )
  safemap(
    "formattingRange",
    "v",
    "=",
    function() vim.lsp.buf.format({ buffer = bufnr, async = true }) end,
    "lsp: format buffer range"
  )
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

  -- This section overrides the default diagnostic handlers for signs and virtual text so that only
  -- the most severe diagnostic is shown per line

  --- The custom namespace is so that ALL diagnostics across all namespaces can be aggregated
  --- including diagnostics from plugins
  local ns = api.nvim_create_namespace("severe-diagnostics")

  --- Restricts nvim's diagnostic signs to only the single most severe one per line
  --- see `:help vim.diagnostic`
  ---@param callback fun(namespace: integer, bufnr: integer, diagnostics: table, opts: table)
  ---@return fun(namespace: integer, bufnr: integer, diagnostics: table, opts: table)
  local function max_diagnostic(callback)
    return function(_, bufnr, diagnostics, opts)
      local max_severity_per_line = vim.iter(diagnostics):fold({}, function(diag_map, d)
        local m = diag_map[d.lnum]
        if not m or d.severity < m.severity then diag_map[d.lnum] = d end
        return diag_map
      end)
      callback(ns, bufnr, vim.tbl_values(max_severity_per_line), opts)
    end
  end

  local signs_handler = diagnostic.handlers.signs
  diagnostic.handlers.signs = vim.tbl_extend("force", signs_handler, {
    show = max_diagnostic(signs_handler.show),
    hide = function(_, bufnr) signs_handler.hide(ns, bufnr) end,
  })

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
--
-- ---@alias ClientOverrides {on_attach: fun(client: lsp.Client, bufnr: number), semantic_tokens: fun(bufnr: number, client: lsp.Client, token: table)}
-- local client_overrides = {
--   lexical = {
--     on_attach = function(client, bufnr)
--       dd(I(mega.lsp.has_method(client, "references")))
--       if
--         not mega.lsp.has_method(client, "references")
--         -- and not client.server_capabilities.documentReferencesProvider
--         -- and not client.server_capabilities.referencesProvider
--       then
--         nmap("gr", "<leader>A", { desc = "lsp: references", buffer = bufnr })
--       end
--     end,
--   },
-- }

---@param client lsp.Client
---@param bufnr number
local function setup_semantic_tokens(client, bufnr)
  -- fully disable semantic tokens highlighting
  client.server_capabilities.semanticTokensProvider = nil

  -- local overrides = client_overrides[client.name]
  -- if not overrides or not overrides.semantic_tokens then return end
  --
  -- mega.augroup(fmt("LspSemanticTokens%s", client.name), {
  --   event = "LspTokenUpdate",
  --   buffer = bufnr,
  --   desc = fmt("Configure the semantic tokens for the %s", client.name),
  --   command = function(args) overrides.semantic_tokens(args.buf, client, args.data.token) end,
  -- })
end

---Add buffer local mappings, autocommands, tagfunc, etc for attaching servers
---@param client table lsp client
---@param bufnr number
local function on_attach(client, bufnr)
  if not client or not bufnr then
    vim.notify("No LSP client found; aborting on_attach.")
    return
  end

  if client.config.flags then client.config.flags.allow_incremental_sync = true end

  -- Live color highlighting; handy for tailwindcss
  -- HT: kabouzeid
  if mega.lsp.has_method(client, "color") then
    if client.name == "tailwindcss" then
      require("document-color").buf_attach(bufnr, { mode = "single" })
      do
        local ok, colorizer = pcall(require, "colorizer")
        if ok and colorizer then colorizer.detach_from_buffer() end
      end
    end
  end

  -- Disable completion for certain clients (using this mostly for the multiple elixir clients i'm using at the moment):
  --
  -- if mega.lsp.has_method(client, "completion") then
  --   if vim.tbl_contains({ "lexical" }, client.name) then
  --     dd(fmt("disabling completionProvider for %s", client.name))
  --     caps.completionProvider = nil
  --   end
  -- end

  --   if mega.lsp.has_method(client, "documentSymbol") then
  --   local ok, navic = mega.require("nvim-navic")
  --   if ok and navic then navic.attach(client, bufnr) end
  -- end

  if mega.lsp.has_method(client, "definition") then vim.bo[bufnr].tagfunc = "v:lua.vim.lsp.tagfunc" end
  if mega.lsp.has_method(client, "formatting") then vim.bo[bufnr].formatexpr = "v:lua.vim.lsp.formatexpr()" end

  require("mega.utils.lsp").setup_rename(client, bufnr)

  setup_formatting(client, bufnr)
  setup_commands(bufnr)
  setup_autocommands(client, bufnr)
  setup_diagnostics(client, bufnr)
  setup_keymaps(client, bufnr)
  setup_highlights(client, bufnr)
  setup_semantic_tokens(client, bufnr)

  if mega.lsp.has_method(client, "completion") then
    client.server_capabilities.completionProvider.triggerCharacters = { ".", ":" }
  end

  vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
  -- if client_overrides[client.name] then client_overrides[client.name](client, bufnr) end
end

-- all the server capabilities we could want
local function get_server_capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities.offsetEncoding = { "utf-16" }
  capabilities.textDocument.codeLens = { dynamicRegistration = false }
  -- TODO: what is dynamicRegistration doing here? should I not always set to true?
  capabilities.textDocument.colorProvider = { dynamicRegistration = false }
  capabilities.textDocument.completion.completionItem.documentationFormat = { "markdown" }
  capabilities.textDocument.completion.completionItem.snippetSupport = true
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

local function get_config(name)
  local config = name and servers.list[name] or {}
  if not config or config == nil then return end

  if type(config) == "function" then
    config = config()
    if not config or config == nil then return end
  end

  config.on_init = on_init
  config.flags = { debounce_text_changes = 150 }
  config.capabilities = get_server_capabilities()
  config.on_attach = on_attach

  return config
end

servers.load_unofficial()
for server, _ in pairs(servers.list) do
  local cfg = get_config(server)

  if cfg ~= nil then lspconfig[server].setup(cfg) end
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
