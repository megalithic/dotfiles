local fn = vim.fn
local api = vim.api
local lsp = vim.lsp
local vcmd = vim.cmd
local command = mega.command
local augroup = mega.augroup
local fmt = string.format
local diagnostic = vim.diagnostic

local max_width = math.min(math.floor(vim.o.columns * 0.7), 100)
local max_height = math.min(math.floor(vim.o.lines * 0.3), 30)

vim.opt.completeopt = { "menu", "menuone", "noselect", "noinsert" }
vim.opt.shortmess:append("c") -- Don't pass messages to |ins-completion-menu|

vim.lsp.set_log_level("ERROR")
require("vim.lsp.log").set_format_func(vim.inspect)

-- NOTE:
-- To learn what capabilities are available you can run the following command in
-- a buffer with a started [LSP](https://neovim.io/doc/user/lsp.html#LSP) client:
-- :lua =vim.lsp.get_active_clients()[1].server_capabilities

-- [ HELPERS ] -----------------------------------------------------------------

-- Show the popup diagnostics window, but only once for the current cursor location
-- by checking whether the word under the cursor has changed.
local function diagnostic_popup()
  local cword = vim.fn.expand("<cword>")
  if cword ~= vim.w.lsp_diagnostics_cword then
    vim.w.lsp_diagnostics_cword = cword
    vim.diagnostic.open_float(0, { scope = "line", focus = false }) -- alts: "cursor", "line"
  end
end

local format_exclusions = {}
local function formatting_filter(client) return not vim.tbl_contains(format_exclusions, client.name) end

---@param opts table<string, any>
local function format(opts)
  opts = opts or {}
  -- if vim.fn.bufloaded(bufnr) then
  vim.lsp.buf.format({
    bufnr = opts.bufnr,
    async = opts.async, -- NOTE: this is super dangerous. no sir; i don't like it.
    filter = formatting_filter,
  })
  -- end
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

local function setup_commands()
  FormatRange = function()
    local start_pos = api.nvim_buf_get_mark(0, "<")
    local end_pos = api.nvim_buf_get_mark(0, ">")
    lsp.buf.range_formatting({}, start_pos, end_pos)
  end
  vcmd([[ command! -range LspFormatRange execute 'lua FormatRange()' ]])

  command("LspLog", function() vim.cmd("vnew " .. vim.lsp.get_log_path()) end)

  command("LspFormat", function() format({ bufnr = 0, async = false }) end)

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
  augroup("LspCodeLens", {
    {
      event = { "BufEnter", "CursorHold", "InsertLeave" }, -- CursorHoldI
      buffer = 0,
      command = function()
        if not vim.tbl_isempty(vim.lsp.codelens.get(bufnr)) then vim.lsp.codelens.refresh() end
      end,
    },
  })

  -- augroup("LspSignatureHelp", {
  --   {
  --     event = { "CursorHoldI" },
  --     buffer = 0,
  --     command = function() vim.lsp.buf.signature_help() end,
  --   },
  -- })

  -- augroup("LspDocumentHighlight", {
  --   {
  --     event = { "CursorHold", "CursorHoldI" },
  --     buffer = bufnr,
  --     command = function()
  --       vim.lsp.buf.document_highlight()
  --     end,
  --   },
  --   {
  --     event = { "CursorMoved", "BufLeave" },
  --     buffer = bufnr,
  --     command = function()
  --       vim.lsp.buf.clear_references()
  --     end,
  --   },
  -- })
  --
  augroup("LspDiagnostics", {
    {
      event = { "CursorHold" },
      desc = "Show diagnostics",
      command = function() diagnostic_popup() end,
    },
  })

  -- format on save
  augroup("LspFormat", {
    {
      event = { "BufWritePre" },
      command = function()
        format({ async = false, bufnr = 0 }) -- prefer `false` here
      end,
    },
  })
end

-- [ MAPPINGS ] ----------------------------------------------------------------

local function setup_mappings(client, bufnr)
  local desc = function(desc) return { desc = desc, buffer = bufnr } end

  nnoremap("[d", function() diagnostic.goto_prev({ float = false }) end, desc("lsp: prev diagnostic"))
  nnoremap("]d", function() diagnostic.goto_next({ float = false }) end, desc("lsp: next diagnostic"))
  nnoremap("gd", vim.lsp.buf.definition, desc("lsp: definition"))
  nnoremap("gr", vim.lsp.buf.references, desc("lsp: references"))
  nnoremap("gt", vim.lsp.buf.type_definition, desc("lsp: type definition"))
  nnoremap("gi", vim.lsp.buf.implementation, desc("lsp: implementation"))
  nnoremap("gI", vim.lsp.buf.incoming_calls, desc("lsp: incoming calls"))
  nnoremap("<leader>lc", vim.lsp.buf.code_action, desc("lsp: code action"))
  xnoremap("<leader>lc", "<esc><Cmd>lua vim.lsp.buf.range_code_action()<CR>", desc("lsp: code action"))
  nnoremap("gl", vim.lsp.codelens.run, desc("lsp: code lens"))
  nnoremap("gn", require("mega.lsp.rename").rename, desc("lsp: rename"))
  nnoremap("K", hover, desc("lsp: hover"))
  nnoremap("gK", require("hover").hover_select, desc("lsp: hover (select)"))
  inoremap("<c-k>", vim.lsp.buf.signature_help, desc("lsp: signature help"))
  imap("<c-k>", vim.lsp.buf.signature_help, desc("lsp: signature help"))
  nnoremap("<leader>li", [[<cmd>LspInfo<CR>]], desc("lsp: show client info"))
  nnoremap("<leader>lm", [[<cmd>Mason<CR>]], desc("lsp: show mason info"))
  nnoremap(
    "<leader>lic",
    [[<cmd>lua =vim.lsp.get_active_clients()[1].server_capabilities<CR>]],
    desc("lsp: show server capabilities")
  )
  -- nnoremap("<leader>ll", [[<cmd>LspLog<CR>]], desc("lsp: show log"))
  nnoremap("<leader>rf", vim.lsp.buf.format, desc("lsp: format buffer"))
end

-- [ FORMATTING ] ---------------------------------------------------------------

local function setup_formatting(client, bufnr)
  -- disable formatting for the following language-servers (let null-ls takeover):
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

  local virt_text_handler = diagnostic.handlers.virtual_text
  diagnostic.handlers.virtual_text = vim.tbl_extend("force", virt_text_handler, {
    show = max_diagnostic(virt_text_handler.show),
    hide = function(_, bufnr) virt_text_handler.hide(ns, bufnr) end,
  })

  diagnostic.config({
    signs = {
      -- With highest priority
      priority = 9999,
      -- Only for warnings and errors
      severity = { min = "HINT", max = "ERROR" },
    },
    underline = true,
    -- TODO: https://github.com/akinsho/dotfiles/commit/dd1518bb8d60f9ae13686b85d8ea40762893c3c9
    severity_sort = true,
    -- Show virtual text only for errors
    virtual_text = { spacing = 1, prefix = "", severity = { min = "ERROR", max = "ERROR" } },
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

-- [ ON_ATTACH ] ---------------------------------------------------------------

---Add buffer local mappings, autocommands, tagfunc, etc for attaching servers
---@param client table lsp client
---@param bufnr number
local function on_attach(client, bufnr)
  if not client then
    vim.notify("No LSP client found; aborting on_attach.")
    return
  end

  if client.config.flags then client.config.flags.allow_incremental_sync = true end

  -- Live color highlighting; handy for tailwindcss
  -- HT: kabouzeid
  if client.server_capabilities.colorProvider then
    -- require("mega.lsp.document_colors").buf_attach(bufnr, { single_column = true, col_count = 2 })
    require("document-color").buf_attach(bufnr, { mode = "background" })
    require("colorizer").detach_from_buffer()
  end

  if client.server_capabilities.definitionProvider then vim.bo[bufnr].tagfunc = "v:lua.vim.lsp.tagfunc" end

  if client.server_capabilities.documentFormattingProvider then
    vim.bo[bufnr].formatexpr = "v:lua.vim.lsp.formatexpr()"
  end

  --- Guard against servers without the signatureHelper capability
  if client.server_capabilities.signatureHelpProvider then
    require("lsp-overloads").setup(client, {
      ui = {
        -- The border to use for the signature popup window. Accepts same border values as |nvim_open_win()|.
        border = mega.get_border(),
      },
      keymaps = {
        next_signature = "<C-j>",
        previous_signature = "<C-k>",
        next_parameter = "<C-l>",
        previous_parameter = "<C-h>",
      },
    })
  end

  require("mega.lsp.handlers")
  setup_formatting(client, bufnr)
  setup_commands()
  setup_autocommands(client, bufnr)
  setup_diagnostics()
  setup_mappings(client, bufnr)
  setup_highlights(client, bufnr)

  api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
end

require("mega.lsp.null_ls")(on_attach)
-- require("mega.lsp.servers")(on_attach)
require("mega.lsp.mason")(on_attach)
