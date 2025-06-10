if not mega or not vim.tbl_contains(mega.enabled_plugins, "lsp") then return end

local fmt = string.format
local SETTINGS = require("mega.settings")
local BORDER_STYLE = SETTINGS.border
local methods = vim.lsp.protocol.Methods
local lsp_group = vim.api.nvim_create_augroup("lsp", { clear = true })

local function lsp_method(client, method)
  assert(client, "must have valid language server client")

  local not_supported_msg = fmt("%s not supported for %s", method, client.name)
  local method_supported = client:supports_method(method)
  if not method_supported then
    vim.notify(not_supported_msg, L.WARN)
    -- Echom(not_supported_msg, "Question")

    return function(...) return false end
  end

  return function(cb_fn)
    if method_supported and cb_fn ~= nil and type(cb_fn) == "function" then
      cb_fn()
    else
      -- vim.notify(not_supported_msg, L.WARN)
    end
  end
end

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

  local diagnostic_ns = vim.api.nvim_create_namespace("mega.hl_diagnostic_region")
  local diagnostic_timer
  local hl_cancel
  local hl_map = {
    [vim.diagnostic.severity.ERROR] = "DiagnosticVirtualTextError",
    [vim.diagnostic.severity.WARN] = "DiagnosticVirtualTextWarn",
    [vim.diagnostic.severity.HINT] = "DiagnosticVirtualTextHint",
    [vim.diagnostic.severity.INFO] = "DiagnosticVirtualTextInfo",
  }

  -- require("lspconfig.ui.windows").default_options.border = BORDER_STYLE

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
  local params = vim.lsp.util.make_range_params(0, "utf-8") -- get params for current position
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
        if from then vim.api.nvim_buf_set_extmark(buf, md_namespace, l - 1, from - 1, {
          end_col = to,
          hl_group = hl_group,
        }) end
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

-- LSP initialization callback
local function on_init(client, result)
  lsp_method(client, "textDocument/signatureHelp")(function() client.server_capabilities.signatureHelpProvider.triggerCharacters = {} end)

  -- Handle off-spec "offsetEncoding" server capability
  if result.offsetEncoding then client.offset_encoding = result.offsetEncoding end
end

local function get_capabilitites()
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

  return capabilities
end

local function make_commands(client, bufnr)
  -- Function to enable LSP
  local function enable()
    if not vim.g.lsp then vim.g.lsp = {} end
    vim.g.lsp.autostart = true
    vim.cmd("doautoall <nomodeline> FileType")
  end

  -- Function to disable LSP
  local function disable()
    if not vim.g.lsp then vim.g.lsp = {} end
    vim.g.lsp.autostart = false
    vim.lsp.stop_client(vim.lsp.get_clients())
  end

  command("LspInfo", function() vim.cmd.checkhealth("lsp") end, { desc = "View LSP info" })

  command("LspLogDelete", function() vim.fn.system("rm " .. vim.lsp.get_log_path()) end, { desc = "Deletes the LSP log file. Useful for when it gets too big" })

  command("LspRestart", function(cmd)
    local parts = vim.split(vim.trim(cmd.args), "%s+")
    if cmd.args == "" then parts = {} end

    local clients = vim.lsp.get_clients({ bufnr = bufnr })

    if #parts > 0 then clients = vim.tbl_filter(function(client) return vim.tbl_contains(parts, client.name) end, clients) end

    vim.lsp.stop_client(clients)
    vim.cmd.update()
    vim.defer_fn(vim.cmd.edit, 1000)
  end, {
    nargs = "*",
  })

  command("LspStart", enable, {})
  command("LspStop", disable, {})
end

local function make_keymaps(client, bufnr)
  local snacks = require("snacks").picker

  local desc = function(str) return "[+lsp] " .. str end

  local map = function(modes, keys, func, d, opts)
    opts = vim.tbl_deep_extend("keep", { buffer = bufnr, desc = desc(d) }, opts or {})
    vim.keymap.set(modes, keys, func, opts)
  end
  local nmap = function(keys, func, d) map("n", keys, func, d, { noremap = false }) end
  local imap = function(keys, func, d) map("i", keys, func, d, { noremap = false }) end
  local vnmap = function(keys, func, d, opts) map({ "v", "n" }, keys, func, d, opts) end

  nmap("gl", show_diagnostic_popup, "[g]o to diagnostic hover")
  nmap("K", vim.lsp.buf.hover, "hover docs")
  nmap("gD", vim.lsp.buf.declaration, "goto declaration")
  vnmap("ga", vim.lsp.buf.code_action, "code actions")
  vnmap("g.", function() fix_current_action() end, "[g]o run nearest/current code action")

  nmap("[d", function() goto_diagnostic_hl("prev") end, "Go to previous [D]iagnostic message")
  nmap("]d", function() goto_diagnostic_hl("next") end, "Go to next [D]iagnostic message")

  nmap("gq", function() vim.cmd("Trouble diagnostics toggle focus=true filter.buf=0") end, "[g]oto [q]uickfixlist buffer diagnostics (trouble)")
  nmap("gQ", function() vim.cmd("Trouble diagnostics toggle focus=true") end, "[g]oto [q]uickfixlist global diagnostics (trouble)")

  -- "<leader>ss", function() Snacks.picker.lsp_symbols() end, desc = "LSP Symbols" },
  --    { "<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols" },

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
  end, "rename symbol/references")

  lsp_method(client, "textDocument/references")(function()
    map(
      "n",
      "gr",
      function()
        snacks.lsp_references({
          include_declaration = false,
          include_current = false,
        })
      end,
      "[g]oto [r]eferences",
      { nowait = true }
    )
    -- { "gr", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References" },
  end)

  lsp_method(client, "textDocument/definition")(function()
    nmap("gd", "<cmd>vsplit<cr><cmd>lua require('snacks').picker.lsp_definitions()<cr>", "goto definition (vsplit)")
    -- nmap("gd", function() require("fzf-lua").lsp_definitions({ jump1 = true }) end, "Go to definition")
    -- nmap("gD", function() require("fzf-lua").lsp_definitions({ jump1 = false }) end, "Peek definition")
    -- nmap("gd", "<cmd>vsplit | lua vim.lsp.buf.definition()<cr>", "Goto Definition in Vertical Split")
  end)

  lsp_method(client, methods.textDocument_signatureHelp)(function()
    local function signature_help()
      local ok_blink, blink = pcall(require, "blink.cmp")
      if ok_blink then
        local blink_window = require("blink.cmp.completion.windows.menu")
        if blink_window.win:is_open() then blink.hide() end
      end

      vim.lsp.buf.signature_help()
    end

    nmap("gk", signature_help, "Signature help")
    imap("<C-k>", signature_help, "signature help")
  end)

  nmap("<leader>lf", vim.lsp.buf.format, "format")
  nmap("<leader>lii", "<cmd>LspInfo<cr>", "server info")
  nmap("<leader>lRi", "<cmd>LspRestart<cr>", "restart server(s)")

  -- Inlay hints
  lsp_method(client, "textDocument/inlayHint")(function()
    vim.keymap.set("n", "yoh", function()
      local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
      vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
    end, { buffer = bufnr, desc = "Toggle inlay hints" })
  end)
end

local function on_attach(client, bufnr, client_id)
  vim.b[bufnr].lsp = client.name

  make_commands(client, bufnr)
  make_keymaps(client, bufnr)

  -- Document highlighting
  lsp_method(client, "textDocument/documentHighlight")(function()
    Augroup(lsp_group, {
      {

        event = { "CursorHold", "InsertLeave" },
        buffer = bufnr,
        command = function() vim.lsp.buf.document_highlight() end,
      },

      {

        event = { "CursorMoved", "InsertEnter" },
        buffer = bufnr,
        command = function() vim.lsp.buf.clear_references() end,
      },
    })
  end)

  -- Code lens
  lsp_method(client, "textDocument/codeLens")(function()
    vim.api.nvim_create_autocmd("LspProgress", {
      group = lsp_group,
      pattern = "end",
      callback = function(progress_args)
        if progress_args.buf == bufnr then vim.lsp.codelens.refresh({ bufnr = bufnr }) end
      end,
    })
    vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "InsertLeave" }, {
      group = lsp_group,
      buffer = bufnr,
      callback = function() vim.lsp.codelens.refresh({ bufnr = bufnr }) end,
    })

    vim.lsp.codelens.refresh({ bufnr = bufnr })
  end)

  -- Folding
  lsp_method(client, "textDocument/foldingRange")(function()
    -- vim.wo[0][0].foldmethod = "expr"
    -- vim.wo[0][0].foldexpr = "v:lua.vim.lsp.foldexpr()"

    -- foldcolumn = "1",
    -- foldlevel = 99,
    -- vim.opt.foldlevelstart = 99
    -- foldmethod = "indent",
    -- foldtext = "v:lua.vim.treesitter.foldtext()",
  end)

  -- Auto-formatting on save
  -- if not lsp_method(client, "textDocument/willSaveWaitUntil") and lsp_method(client, "textDocument/formatting") then
  --   vim.api.nvim_create_autocmd("BufWritePre", {
  --     group = lsp_group,
  --     buffer = bufnr,
  --     callback = function()
  --       local autoformat =
  --         vim.F.if_nil(client.settings and client.settings.autoformat, vim.b.lsp and vim.b.lsp.autoformat, vim.g.lsp and vim.g.lsp.autoformat, false)
  --       if autoformat then vim.lsp.buf.format({ bufnr = bufnr, id = client_id or client.id }) end
  --     end,
  --   })
  -- end

  lsp_method(client, "textDocument/completion")(function()
    if client.name == "lua-language-server" then client.server_capabilities.completionProvider.triggerCharacters = { ".", ":" } end
    vim.lsp.completion.enable(true, client_id or client.id, bufnr, { autotrigger = true })
  end)

  lsp_method(client, "textDocument/documentColor")(function() vim.lsp.document_color.enable(true, bufnr, { style = "virtual" }) end)

  -- load diagnostics config
  local ok_diagnostics, diagnostics = pcall(dofile, vim.fn.stdpath("config") .. "/plugin/lsp/diagnostics.lua")
  if ok_diagnostics then diagnostics(client, bufnr) end
end

-- Create autogroup for LSP events
Augroup(lsp_group, {
  {
    event = { "LspAttach" },
    command = function(args)
      local bufnr = args.buf

      local client = assert(vim.lsp.get_client_by_id(args.data.client_id), "must have valid language server client")
      if client == nil then return end

      local client_config = vim.lsp.config[client.name]
      if client_config ~= nil then
        assert(client_config.on_attach, "must have an on_attach function for language server client")
        client_config.on_attach(client, bufnr)
      end
    end,
  },
  {
    event = { "LspDetach" },
    command = function(args)
      local buf = args.buf
      vim.b[buf].lsp = nil
      vim.lsp.buf.clear_references()
      vim.api.nvim_clear_autocmds({ group = lsp_group, buffer = buf })
    end,
  },
  {
    event = { "LspProgress" },
    pattern = "*",
    command = function(args) vim.cmd.redrawstatus() end,
  },
})

-- Configure LSP for all servers
vim.lsp.config("*", {
  on_init = on_init,
  workspace_required = true,
  capabilities = get_capabilitites(),
})

local ok_servers, servers = pcall(dofile, vim.fn.stdpath("config") .. "/plugin/lsp/servers.lua")
if not ok_servers then
  Echom("Unable to load language server list", "Error")
  return
end

local enabled_servers = {}

vim.iter(servers):each(function(name, config)
  if type(config) == "function" then config = config() end

  if config ~= nil and config then
    table.insert(enabled_servers, name)

    if config.on_attach ~= nil and type(config.on_attach) == "function" then
      Echom(fmt("%s has a custom on_attach fn", name), "Question")

      config.on_attach = function(client, bufnr, client_id)
        -- make sure we call our default/main on_attach here:
        on_attach(client, bufnr, client_id)

        -- additional on_attach handlers?
        config.on_attach(client, bufnr, client_id)
      end
    else
      config.on_attach = on_attach
    end

    vim.lsp.config[name] = config
    vim.lsp.enable(name, true)
  end
end)
