local fn = vim.fn
local api = vim.api
local lsp = vim.lsp
local vcmd = vim.cmd
-- local bufmap, bmap = mega.bufmap, mega.bmap
local lspconfig = require("lspconfig")
local command = mega.command
local augroup = mega.augroup
local fmt = string.format
local diagnostic = vim.diagnostic
local U = require("mega.utils")

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
    async = opts.async, -- NOTE: this is super dangerous
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
  else
    if existing_float_win and vim.api.nvim_win_is_valid(existing_float_win) then
      vim.b.lsp_floating_preview = nil
      local preview_buffer = vim.api.nvim_win_get_buf(existing_float_win)
      local pwin = get_preview_window()
      vim.api.nvim_win_set_buf(pwin, preview_buffer)
      vim.api.nvim_win_close(existing_float_win, true)
    else
      vim.lsp.buf.hover()
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
  inoremap("<c-k>", vim.lsp.buf.signature_help, desc("lsp: signature help"))
  imap("<c-k>", vim.lsp.buf.signature_help, desc("lsp: signature help"))
  nnoremap("<leader>li", [[<cmd>LspInfo<CR>]], desc("lsp: show client info"))
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

      -- FIXME: this still throws errors in ElixirLS land:
      -- stack traceback:
      -- 	[C]: in function 'sign_place'
      -- 	/usr/local/share/nvim/runtime/lua/vim/diagnostic.lua:876: in function 'callback'
      -- 	/home/ubuntu/.dotfiles/config/nvim/plugin/lsp.lua:277: in function 'callback'
      -- 	/home/ubuntu/.dotfiles/config/nvim/plugin/lsp.lua:277: in function 'callback'
      -- 	/home/ubuntu/.dotfiles/config/nvim/plugin/lsp.lua:277: in function 'show'
      -- 	/usr/local/share/nvim/runtime/lua/vim/diagnostic.lua:1172: in function 'show'
      -- 	/usr/local/share/nvim/runtime/lua/vim/diagnostic.lua:690: in function 'set'
      -- 	/usr/local/share/nvim/runtime/lua/vim/lsp/diagnostic.lua:217: in function 'handler'
      -- 	/usr/local/share/nvim/runtime/lua/vim/lsp.lua:824: in function ''
      -- 	vim/_editor.lua: in function <vim/_editor.lua:0>
      -- and
      --
      -- Error executing lua callback: /usr/local/share/nvim/runtime/lua/vim/diagnostic.lua:1018: line value outside range
      -- stack traceback:
      -- 	[C]: in function 'nvim_buf_set_extmark'
      -- 	/usr/local/share/nvim/runtime/lua/vim/diagnostic.lua:1018: in function 'callback'
      -- 	/Users/seth/.dotfiles/config/nvim/plugin/lsp.lua:307: in function 'callback'
      -- 	/Users/seth/.dotfiles/config/nvim/plugin/lsp.lua:307: in function 'show'
      -- 	/usr/local/share/nvim/runtime/lua/vim/diagnostic.lua:1183: in function 'show'
      -- 	/usr/local/share/nvim/runtime/lua/vim/diagnostic.lua:1139: in function 'show'
      -- 	/usr/local/share/nvim/runtime/lua/vim/diagnostic.lua:1133: in function 'show'
      -- 	/usr/local/share/nvim/runtime/lua/vim/diagnostic.lua:1513: in function </usr/local/share/nvim/runtime/lua/vim/diagnostic.lua:1491>

      -- Pass the filtered diagnostics (with our custom namespace) to the original handler
      -- P(I(vim.tbl_values(max_severity_per_line)))
      callback(ns, bufnr, vim.tbl_values(max_severity_per_line), opts)
    end
  end

  local signs_handler = vim.diagnostic.handlers.signs
  vim.diagnostic.handlers.signs = {
    show = max_diagnostic(signs_handler.show),
    hide = function(_, bufnr) signs_handler.hide(ns, bufnr) end,
  }

  -- local virt_text_handler = vim.diagnostic.handlers.virtual_text
  -- vim.diagnostic.handlers.virtual_text = {
  --   show = max_diagnostic(virt_text_handler.show),
  --   hide = function(_, bufnr) virt_text_handler.hide(ns, bufnr) end,
  -- }

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
    virtual_text = { severity = { min = "ERROR", max = "ERROR" } },
    -- {
    --   spacing = 1,
    --   prefix = "",
    --   format = function(d)
    --     -- return ""
    --     local level = diagnostic.severity[d.severity]
    --     -- if level ~= "ERROR" then return "" end
    --     return fmt("%s %s", mega.icons.lsp[level:lower()], d.message)
    --     -- return fmt("%s", mega.icons.lsp[level:lower()])
    --   end,
    -- },
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
      prefix = function(diag, i, _total)
        -- local icon, highlight
        -- if diag.severity == 1 then
        --   icon = mega.icons.lsp.error
        --   highlight = "DiagnosticError"
        -- elseif diag.severity == 2 then
        --   icon = mega.icons.lsp.warn
        --   highlight = "DiagnosticWarn"
        -- elseif diag.severity == 3 then
        --   icon = mega.icons.lsp.info
        --   highlight = "DiagnosticInfo"
        -- elseif diag.severity == 4 then
        --   icon = mega.icons.lsp.hint
        --   highlight = "DiagnosticHint"
        -- end
        -- -- return i .. "/" .. total .. " " .. icon .. "  ", highlight
        -- return fmt("%s ", icon), highlight
        local level = diagnostic.severity[diag.severity]
        local prefix = fmt("%d. %s ", i, mega.icons.lsp[level:lower()])
        return prefix, "Diagnostic" .. level:gsub("^%l", string.upper)

        -- local level = diagnostic_types[diag.severity]
        -- local prefix = fmt("%d. %s ", i, level.icon)
        -- return prefix, "Diagnostic" .. level[1]
      end,
    },
  })
end

-- [ HANDLERS ] ----------------------------------------------------------------
local function setup_handlers()
  local opts = {
    border = mega.get_border(),
    max_width = max_width,
    max_height = max_height,
    focusable = false,
    focus = false,
    silent = true,
    severity_sort = true,
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
  }

  -- NOTE: the hover handler returns the bufnr,winnr so can be used for mappings
  -- WIP: colorize color things in a hover buffer with nvim-colorizer?
  local function hover_handler(_, result, ctx, config)
    config = config or {}
    config.focus_id = ctx.method
    if not (result and result.contents) then
      vim.notify("No information available")
      return
    end

    local util = require("vim.lsp.util")

    local lines = util.convert_input_to_markdown_lines(result.contents)
    lines = util.trim_empty_lines(lines)
    if vim.tbl_isempty(lines) then
      vim.notify("No information available")
      return
    end

    local bufnr = util.open_floating_preview(lines, "markdown", config)
    -- local lines = vim.split(result.contents.value, "\n")

    local ok, mod = pcall(require, "colorizer")
    if ok then
      require("colorizer").highlight_buffer(
        bufnr,
        nil,
        vim.list_slice(lines, 2, #lines),
        0,
        require("colorizer").get_buffer_options(0)
      )
    end

    return bufnr
  end

  lsp.handlers["textDocument/hover"] = lsp.with(hover_handler, opts)
  -- lsp.handlers["textDocument/hover"] = lsp.with(lsp.handlers.hover, opts)
  local signature_help_opts = mega.table_merge(opts, {
    -- anchor = "SW",
    -- relative = "cursor",
    -- row = -1,
    border = mega.get_border(),
    max_width = max_width,
    max_height = max_height,
  })
  lsp.handlers["textDocument/signatureHelp"] = lsp.with(lsp.handlers.signature_help, signature_help_opts)

  lsp.handlers["window/showMessage"] = function(_, result, ctx)
    local client = lsp.get_client_by_id(ctx.client_id)
    local lvl = ({ "ERROR", "WARN", "INFO", "DEBUG" })[result.type]
    vim.notify(result.message, lvl, {
      title = "LSP | " .. client.name,
      timeout = 8000,
      keep = function() return lvl == "ERROR" or lvl == "WARN" end,
    })
  end

  do
    local rename_handler = lsp.handlers["textDocument/rename"]
    local function parse_edits(entries, bufnr, text_edits)
      for _, edit in ipairs(text_edits) do
        local start_line = edit.range.start.line + 1
        local line = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, start_line, false)[1]

        table.insert(entries, {
          bufnr = bufnr,
          lnum = start_line,
          col = edit.range.start.character + 1,
          text = line,
        })
      end
    end

    -- Populates the quickfix list with all rename locations.
    lsp.handlers["textDocument/rename"] = function(err, result, ...)
      rename_handler(err, result, ...)
      if err then return end

      local entries = {}
      if result.changes then
        for uri, edits in pairs(result.changes) do
          local bufnr = vim.uri_to_bufnr(uri)
          parse_edits(entries, bufnr, edits)
        end
      elseif result.documentChanges then
        for _, doc_change in ipairs(result.documentChanges) do
          if doc_change.textDocument then
            local bufnr = vim.uri_to_bufnr(doc_change.textDocument.uri)
            parse_edits(entries, bufnr, doc_change.edits)
          else
            vim.notify(("Failed to parse TextDocumentEdit of kind: %s"):format(doc_change.kind or "N/A"))
          end
        end
      end

      vim.fn.setqflist(entries)
    end
  end

  do
    local nnotify_ok, nnotify = pcall(require, "notify")

    if nnotify_ok and nnotify then
      local client_notifs = {}

      local function get_notif_data(client_id, token)
        if not client_notifs[client_id] then client_notifs[client_id] = {} end

        if not client_notifs[client_id][token] then client_notifs[client_id][token] = {} end

        return client_notifs[client_id][token]
      end

      local spinner_frames = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" }

      local function update_spinner(client_id, token)
        local notif_data = get_notif_data(client_id, token)

        if notif_data.spinner then
          local new_spinner = (notif_data.spinner + 1) % #spinner_frames
          notif_data.spinner = new_spinner
          notif_data.notification = nnotify(nil, nil, {
            hide_from_history = true,
            icon = spinner_frames[new_spinner],
            replace = notif_data.notification,
          })

          vim.defer_fn(function() update_spinner(client_id, token) end, 100)
        end
      end

      local function format_title(title, client_name) return client_name .. (#title > 0 and ": " .. title or "") end

      local function format_message(message, percentage)
        return (percentage and percentage .. "%\t" or "") .. (message or "")
      end

      vim.lsp.handlers["$/progress"] = function(_, result, ctx)
        local client_id = ctx.client_id
        local client = vim.lsp.get_client_by_id(client_id)
        if
          client.name == "elixirls"
          or client.name == "sumneko_lua"
          or client.name == "rust_analyzer"
          or client.name == "clangd"
          or client.name == "shellcheck"
        then
          return
        end
        local val = result.value

        if not val.kind then return end

        local notif_data = get_notif_data(client_id, result.token)

        if val.kind == "begin" then
          local message = format_message(val.message, val.percentage)

          notif_data.notification = nnotify(message, "info", {
            title = format_title(val.title, vim.lsp.get_client_by_id(client_id).name),
            icon = spinner_frames[1],
            timeout = false,
            hide_from_history = false,
          })

          notif_data.spinner = 1
          update_spinner(client_id, result.token)
        elseif val.kind == "report" and notif_data then
          notif_data.notification = nnotify(format_message(val.message, val.percentage), "info", {
            replace = notif_data.notification,
            hide_from_history = false,
          })
        elseif val.kind == "end" and notif_data then
          notif_data.notification = nnotify(val.message and format_message(val.message) or "Complete", "info", {
            icon = "",
            replace = notif_data.notification,
            timeout = 3000,
          })

          notif_data.spinner = nil
        end
      end
    end
  end

  -- lsp.handlers["textDocument/definition"] = function(_, result)
  --   if result == nil or vim.tbl_isempty(result) then
  --     print("Definition not found")
  --     return nil
  --   end
  --   local function jumpto(loc)
  --     local split_cmd = vim.uri_from_bufnr(0) == loc.targetUri and "edit" or "vnew"
  --     vim.cmd(split_cmd)
  --     lsp.util.jump_to_location(loc)
  --   end
  --   if vim.tbl_islist(result) then
  --     jumpto(result[1])

  --     if #result > 1 then
  --       fn.setqflist(lsp.util.locations_to_items(result))
  --       api.nvim_command("copen")
  --       api.nvim_command("wincmd p")
  --     end
  --   else
  --     jumpto(result)
  --   end
  -- end
end

-- [ HANDLERS ] ----------------------------------------------------------------
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

---Add buffer local mappings, autocommands, tagfunc etc for attaching servers
---@param client table lsp client
---@param bufnr number
function mega.lsp.on_attach(client, bufnr)
  if not client then
    vim.notify("No LSP client found; aborting on_attach.")
    return
  end

  -- P(client.server_capabilities)

  if client.config.flags then client.config.flags.allow_incremental_sync = true end

  -- Live color highlighting; handy for tailwindcss
  -- HT: kabouzeid
  if client.server_capabilities.colorProvider then
    require("mega.lsp.document_colors").buf_attach(bufnr, { single_column = true, col_count = 2 })
  end

  if client.server_capabilities.definitionProvider then vim.bo[bufnr].tagfunc = "v:lua.vim.lsp.tagfunc" end

  if client.server_capabilities.documentFormattingProvider then
    vim.bo[bufnr].formatexpr = "v:lua.vim.lsp.formatexpr()"
  end

  setup_formatting(client, bufnr)
  setup_commands()
  setup_autocommands(client, bufnr)
  setup_diagnostics()
  setup_handlers()
  setup_mappings(client, bufnr)
  setup_highlights(client, bufnr)

  api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
end

-- [ SERVERS ] -----------------------------------------------------------------

local function lsp_setup(server_name, opts)
  logger.debug("Adding", server_name, "to lspconfig")
  lspconfig[server_name].setup(opts)
end

local function build_command(server_name, path, args)
  args = args or {}

  local exists, dir = U.workspace_has_file(path)
  logger.debug("workspace_has_file", exists, dir)
  if exists then
    dir = vim.fn.expand(dir)
    logger.fmt_debug("%s: %s %s", server_name, dir, args)
    return vim.list_extend({ dir }, args)
  else
    return nil
  end
end

local function lsp_cmd_override(server_name, opts, cmd_path, args)
  args = args or {}

  local cmd = build_command(server_name, cmd_path, args)
  if cmd ~= nil then opts.cmd = cmd end

  opts.on_new_config = function(new_config, _)
    local new_cmd = build_command(server_name, cmd_path, args)
    if new_cmd ~= nil then new_config.cmd = new_cmd end
  end
end

local function root_pattern(...)
  local patterns = vim.tbl_flatten({ ... })

  return function(startpath)
    for _, pattern in ipairs(patterns) do
      return lspconfig.util.search_ancestors(startpath, function(path)
        if lspconfig.util.path.exists(fn.glob(lspconfig.util.path.join(path, pattern))) then return path end
      end)
    end
  end
end

mega.lsp.servers = {
  bashls = true,
  dockerls = function()
    return {
      single_file_support = true,
      settings = {
        docker = {
          languageserver = {
            formatter = {
              ignoreMultilineInstructions = true,
            },
          },
        },
      },
    }
  end,
  elmls = true,
  clangd = true,
  rust_analyzer = true,
  vimls = true,
  zk = true,
  pyright = function()
    return {
      single_file_support = false,
      settings = {
        python = {
          analysis = {
            autoSearchPaths = true,
            diagnosticMode = "workspace",
            useLibraryCodeForTypes = true,
          },
        },
      },
    }
  end,
  jsonls = function()
    return {
      commands = {
        Format = {
          function() lsp.buf.range_formatting({}, { 0, 0 }, { fn.line("$"), 0 }) end,
        },
      },
      init_options = { provideFormatter = false },
      single_file_support = true,
      settings = {
        json = {
          format = { enable = false },
          schemas = require("schemastore").json.schemas(),
        },
      },
    }
  end,
  yamlls = function()
    return {
      settings = {
        yaml = {
          format = { enable = true },
          validate = true,
          hover = true,
          completion = true,
          schemas = require("schemastore").json.schemas(),
          customTags = {
            "!reference sequence", -- necessary for gitlab-ci.yaml files
          },
        },
      },
    }
  end,

  -- @see https://gist.github.com/folke/fe5d28423ea5380929c3f7ce674c41d8
  -- NOTE: we return a function here so that the lua dev dependency is not
  -- required until the setup function is called.
  sumneko_lua = function()
    local path = vim.split(package.path, ";")
    table.insert(path, "lua/?.lua")
    table.insert(path, "lua/?/init.lua")

    local plugins = ("%s/site/pack/paq"):format(fn.stdpath("data"))
    local emmy = ("%s/start/emmylua-nvim"):format(plugins)
    local plenary = ("%s/start/plenary.nvim"):format(plugins)
    -- local paq = ('%s/opt/paq-nvim'):format(plugins)

    return {
      handlers = {
        -- Don't open quickfix list in case of multiple definitions. At the
        -- moment, this conflicts the `a = function()` code style because
        -- sumneko_lua treats both `a` and `function()` to be definitions of `a`.
        ["textDocument/definition"] = function(_, result, ctx, _)
          -- Adapted from source:
          -- https://github.com/neovim/neovim/blob/master/runtime/lua/vim/lsp/handlers.lua#L341-L366
          if result == nil or vim.tbl_isempty(result) then return nil end
          local client = vim.lsp.get_client_by_id(ctx.client_id)

          local res = vim.tbl_islist(result) and result[1] or result
          vim.lsp.util.jump_to_location(res, client.offset_encoding)
        end,
      },
      settings = {
        Lua = {
          runtime = {
            path = path,
            version = "LuaJIT",
          },
          format = { enable = false },
          diagnostics = {
            globals = {
              "vim",
              "Color",
              "c",
              "Group",
              "g",
              "s",
              "describe",
              "it",
              "before_each",
              "after_each",
              "hs",
              "spoon",
              "config",
              "watchers",
              "mega",
              "map",
              "nmap",
              "vmap",
              "xmap",
              "smap",
              "omap",
              "imap",
              "lmap",
              "cmap",
              "tmap",
              "noremap",
              "nnoremap",
              "vnoremap",
              "xnoremap",
              "snoremap",
              "onoremap",
              "inoremap",
              "lnoremap",
              "cnoremap",
              "tnoremap",
            },
          },
          completion = { keywordSnippet = "Replace", callSnippet = "Replace" },
          workspace = {
            -- Don't analyze code from submodules
            ignoreSubmodules = true,
            library = { vim.fn.expand("$VIMRUNTIME/lua"), emmy, plenary },
            checkThirdParty = false,
          },
          telemetry = {
            enable = false,
          },
        },
      },
    }
  end,

  tailwindcss = function()
    return {
      cmd = { "tailwindcss-language-server", "--stdio" },
      init_options = {
        userLanguages = {
          elixir = "phoenix-heex",
          eruby = "erb",
          heex = "phoenix-heex",
        },
      },
      handlers = {
        ["tailwindcss/getConfiguration"] = function(_, _, params, _, bufnr, _)
          vim.lsp.buf_notify(bufnr, "tailwindcss/getConfigurationResponse", { _id = params._id })
        end,
      },
      settings = {
        includeLanguages = {
          typescript = "javascript",
          typescriptreact = "javascript",
          ["html-eex"] = "html",
          ["phoenix-heex"] = "html",
          heex = "html",
          eelixir = "html",
          elm = "html",
          erb = "html",
        },
        tailwindCSS = {
          lint = {
            cssConflict = "warning",
            invalidApply = "error",
            invalidConfigPath = "error",
            invalidScreen = "error",
            invalidTailwindDirective = "error",
            invalidVariant = "error",
            recommendedVariantOrder = "warning",
          },
          experimental = {
            classRegex = {
              [[class= "([^"]*)]],
              [[class: "([^"]*)]],
              "~H\"\"\".*class=\"([^\"]*)\".*\"\"\"",
            },
          },
          validate = true,
        },
      },
      filetypes = {
        "css",
        "scss",
        "sass",
        "html",
        "heex",
        "elixir",
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
      },
      root_dir = root_pattern(
        "./assets/tailwind.config.js",
        "tailwind.config.js",
        "tailwind.config.ts",
        "postcss.config.js",
        "postcss.config.ts",
        "package.json",
        "node_modules",
        ".git"
      ),
    }
  end,
  elixirls = function()
    return {
      cmd = { require("mega.utils").lsp.elixirls_cmd() },
      settings = {
        elixirLS = {
          fetchDeps = false,
          dialyzerEnabled = true,
          dialyzerFormat = "dialyxir_short",
          enableTestLenses = false,
          suggestSpecs = true,
        },
      },
      filetypes = { "elixir", "eelixir", "heex" },
      root_dir = root_pattern("mix.exs", ".git") or vim.loop.os_homedir(),
    }
  end,
  solargraph = function()
    return {
      cmd = { "solargraph", "stdio" },
      filetypes = { "ruby" },
      settings = {
        solargraph = {
          diagnostics = true,
          useBundler = true,
        },
      },
    }
  end,
  cssls = function()
    return {
      -- REF: https://github.com/microsoft/vscode/issues/103163
      --      - custom css linting rules and custom data
      cmd = { "vscode-css-language-server", "--stdio" },
      filetypes = { "css", "scss" },
      settings = {
        css = {
          lint = {
            unknownProperties = "ignore",
            unknownAtRules = "ignore",
          },
        },
        scss = {
          lint = {
            idSelector = "warning",
            zeroUnits = "warning",
            duplicateProperties = "warning",
          },
          completion = {
            completePropertyWithSemicolon = true,
            triggerPropertyValueCompletion = true,
          },
        },
      },
    }
  end,
  html = function()
    return {

      cmd = { "vscode-html-language-server", "--stdio" },
      filetypes = { "html", "javascriptreact", "typescriptreact", "eelixir", "html.heex", "heex" },
      init_options = {
        configurationSection = { "html", "css", "javascript", "eelixir", "heex", "html.heex" },
        embeddedLanguages = {
          css = true,
          javascript = true,
          elixir = true,
          heex = true,
        },
      },
    }
  end,
  tsserver = function()
    local function do_organize_imports()
      local params = {
        command = "_typescript.organizeImports",
        arguments = { api.nvim_buf_get_name(0) },
        title = "",
      }
      lsp.buf.execute_command(params)
    end
    return {
      filetypes = {
        "javascript",
        "javascriptreact",
        "javascript.jsx",
        "typescript",
        "typescriptreact",
        "typescript.tsx",
      },
      commands = {
        OrganizeImports = {
          do_organize_imports,
          description = "Organize Imports",
        },
      },
    }
  end,
}

require("mega.lsp.null_ls")(mega.lsp.on_attach)

function mega.lsp.get_server_config(server)
  local function server_capabilities()
    local nvim_lsp_ok, cmp_nvim_lsp = mega.require("cmp_nvim_lsp")

    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities.offsetEncoding = { "utf-16" }
    capabilities.textDocument.codeLens = { dynamicRegistration = false }
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

    if nvim_lsp_ok then capabilities = cmp_nvim_lsp.update_capabilities(capabilities) end

    return capabilities
  end

  local conf = mega.lsp.servers[server]
  local conf_type = type(conf)
  local config = conf_type == "table" and conf or conf_type == "function" and conf() or {}

  config.flags = { debounce_text_changes = 200 }
  config.capabilities = server_capabilities()
  config.on_attach = mega.lsp.on_attach

  -- TODO: json loaded lsp config; also @akinsho is a beast.
  -- https://github.com/akinsho/dotfiles/commit/c087fd471f0d80b8bf41502799aeb612222333ff
  -- config.on_init = mega.lsp.on_init

  return config
end

-- Load lspconfig servers with their configs
for server, _ in pairs(mega.lsp.servers) do
  if server == nil or lspconfig[server] == nil then
    vim.notify("unable to setup ls for " .. server)
    return
  end

  local config = mega.lsp.get_server_config(server)
  lspconfig[server].setup(config)
end
