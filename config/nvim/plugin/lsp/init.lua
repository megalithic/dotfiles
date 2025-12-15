if not Plugin_enabled("lsp") then return end

local M = {}

local fmt = string.format
local methods = vim.lsp.protocol.Methods
local lsp_group = vim.api.nvim_create_augroup("mega_mvim.lsp", { clear = true })
local diagnostics_mod
local preview_opts = {
  border = "rounded",
  focusable = false,
  silent = true,
}

local function lsp_method(client, method)
  assert(client, "must have valid language server client")

  local not_supported_msg = fmt("%s not supported for %s", method, client.name)
  local method_supported = client:supports_method(method)
  if not method_supported then
    -- vim.notify(not_supported_msg, L.WARN)
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

local function fix_current_action()
  local params = vim.lsp.util.make_range_params(0, "utf-16") -- get params for current position
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

---If the LSP response includes any `node_modules`, then try to remove them and
---see if there are any options left. We probably want to navigate to the code
---in OUR codebase, not inside `node_modules`.
---
---This can happen if a type is used to explicitly type a variable:
---```ts
---const MyComponent: React.FC<Props> = () => <div />
---````
---
---Running "Go to definition" on `MyComponent` would give the `React.FC`
---definition in `node_modules/react` as the first result, but we don't want
---that.
---@param results lsp.LocationLink[]
---@return lsp.LocationLink[]
local function filter_out_libraries_from_lsp_items(results)
  local without_node_modules = vim.tbl_filter(
    function(item) return item.targetUri and not string.match(item.targetUri, "node_modules") end,
    results
  )

  if #without_node_modules > 0 then return without_node_modules end

  return results
end

---@param results lsp.LocationLink[]
---@return lsp.LocationLink[]
local function filter_out_same_location_from_lsp_items(results)
  return vim.tbl_filter(function(item)
    local from = item.originSelectionRange
    local to = item.targetSelectionRange

    return not (
      from
      and from.start.character == to.start.character
      and from.start.line == to.start.line
      and from["end"].character == to["end"].character
      and from["end"].line == to["end"].line
    )
  end, results)
end

---This function is mostly copied from Telescope, I only added the
---`node_modules` filtering.
local function list_or_jump(action, title, opts)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local make_entry = require("telescope.make_entry")

  opts = opts or {}

  local params = vim.lsp.util.make_position_params(0, "utf-16")
  vim.lsp.buf_request(0, action, params, function(err, result, ctx)
    if err then
      vim.api.nvim_err_writeln("Error when executing " .. action .. " : " .. err.message)
      return
    end
    local flattened_results = {}
    if result then
      -- textDocument/definition can return Location or Location[]
      if not vim.islist(result) then flattened_results = { result } end

      vim.list_extend(flattened_results, result)
    end

    -- This is the only added step to the Telescope function
    flattened_results = filter_out_same_location_from_lsp_items(filter_out_libraries_from_lsp_items(flattened_results))

    local offset_encoding = vim.lsp.get_client_by_id(ctx.client_id).offset_encoding

    if #flattened_results == 0 then
      return
    elseif #flattened_results == 1 and opts.jump_type ~= "never" then
      local uri = params.textDocument.uri
      if uri ~= flattened_results[1].uri and uri ~= flattened_results[1].targetUri then
        if opts.jump_type == "tab" then
          vim.cmd.tabedit()
        elseif opts.jump_type == "split" then
          vim.cmd.new()
        elseif opts.jump_type == "vsplit" then
          vim.cmd.vnew()
        elseif opts.jump_type == "tab drop" then
          local file_uri = flattened_results[1].uri
          if file_uri == nil then file_uri = flattened_results[1].targetUri end
          local file_path = vim.uri_to_fname(file_uri)
          vim.cmd("tab drop " .. file_path)
        end
      end

      vim.lsp.util.show_document(flattened_results[1], offset_encoding, { focus = true, reuse_win = opts.reuse_win })
    else
      local locations = vim.lsp.util.locations_to_items(flattened_results, offset_encoding)
      pickers
        .new(opts, {
          prompt_title = title,
          finder = finders.new_table({
            results = locations,
            entry_maker = opts.entry_maker or make_entry.gen_from_quickfix(opts),
          }),
          previewer = conf.qflist_previewer(opts),
          sorter = conf.generic_sorter(opts),
          push_cursor_on_edit = true,
          push_tagstack_on_edit = true,
        })
        :find()
    end
  end)
end

local function definitions(opts) return list_or_jump("textDocument/definition", "LSP Definitions", opts) end

-- local hover_handler = vim.lsp.buf.hover
-- local signature_handler = vim.lsp.buf.signature_help
-- ---@diagnostic disable-next-line: duplicate-set-field
-- vim.lsp.buf.hover = function() return enhanced_float_handler(hover_handler, true) end
-- ---@diagnostic disable-next-line: duplicate-set-field
-- vim.lsp.buf.signature_help = function() return enhanced_float_handler(signature_handler, true) end

-- vim.lsp.handlers[methods.textDocument_hover] = enhanced_float_handler(hover_handler, true)
-- vim.lsp.handlers[methods.textDocument_signatureHelp] = enhanced_float_handler(signature_handler, false)
-- vim.lsp.handlers[methods.textDocument_hover] = enhanced_float_handler(vim.lsp.handlers.hover, true)
-- vim.lsp.handlers[methods.textDocument_signatureHelp] = enhanced_float_handler(vim.lsp.handlers.signature_help, false)

-- LSP initialization callback
local function on_init(client, result)
  lsp_method(client, "textDocument/signatureHelp")(
    function() client.server_capabilities.signatureHelpProvider.triggerCharacters = {} end
  )

  -- Handle off-spec "offsetEncoding" server capability
  if result.offsetEncoding then client.offset_encoding = result.offsetEncoding end
end

function M.capabilitites()
  local capabilities = vim.lsp.protocol.make_client_capabilities()

  if pcall(require, "cmp_nvim_lsp") and vim.g.completer == "cmp" then
    capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
  end
  if pcall(require, "blink.cmp") and vim.g.completer == "blink" then
    capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)
  end

  return vim.tbl_deep_extend("force", capabilities, {
    workspace = {
      -- PERF: didChangeWatchedFiles is too slow.
      -- FIXME: Remove this when https://github.com/neovim/neovim/issues/23291#issuecomment-1686709265 is fixed.
      didChangeWatchedFiles = {
        dynamicRegistration = false,
      },
    },
    foldingRange = { dynamicRegistration = false, lineFoldingOnly = true },
    textDocument = {
      completion = {
        dynamicRegistration = false,
        completionItem = {
          snippetSupport = true,
          commitCharactersSupport = true,
          deprecatedSupport = true,
          preselectSupport = true,
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
          labelDetailsSupport = true,
        },
        contextSupport = true,
        completionList = {
          itemDefaults = {
            "commitCharacters",
            "editRange",
            "insertTextFormat",
            "insertTextMode",
            "data",
          },
        },
      },
    },
  })
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

  Command("LspInfo", function() vim.cmd.checkhealth("lsp") end, { desc = "View LSP info" })
  Command(
    "LspLog",
    function() vim.cmd.tabnew(vim.lsp.log.get_filename()) end,
    { desc = "Opens LSP log file in new tab." }
  )
  Command(
    "LspLogDelete",
    function() vim.fn.system("rm " .. vim.lsp.get_log_path()) end,
    { desc = "Deletes the LSP log file. Useful for when it gets too big" }
  )

  Command("LspRestart", function(cmd)
    local parts = vim.split(vim.trim(cmd.args), "%s+")
    if cmd.args == "" then parts = {} end

    local clients = vim.lsp.get_clients({ bufnr = bufnr })

    if #parts > 0 then
      clients = vim.tbl_filter(function(client) return vim.tbl_contains(parts, client.name) end, clients)
    end

    vim.lsp.stop_client(clients)
    vim.cmd.update()
    vim.defer_fn(vim.cmd.edit, 1000)
  end, {
    nargs = "*",
  })

  Command("LspStart", enable, {})
  Command("LspStop", disable, {})
end

local function make_keymaps(client, bufnr)
  -- local ok_snacks = pcall(require, "snacks")

  local desc = function(str)
    if str == nil then return "" end
    return "[+lsp] " .. str
  end

  local map = function(modes, keys, func, d, opts)
    opts = vim.tbl_deep_extend("keep", { buffer = bufnr, desc = desc(d) }, opts or {})
    vim.keymap.set(modes, keys, func, opts)
  end
  local nmap = function(keys, func, d) map("n", keys, func, d, { noremap = false }) end
  local imap = function(keys, func, d) map("i", keys, func, d, { noremap = false }) end
  local vnmap = function(keys, func, d, opts) map({ "v", "n" }, keys, func, d, opts) end

  nmap("<leader>lic", [[<cmd>LspInfo<CR>]], "connected client info")
  nmap("<leader>lim", [[<cmd>Mason<CR>]], "mason info")
  nmap("<leader>lil", [[<cmd>LspLog<CR>]], "logs (vsplit)")

  nmap("gl", diagnostics_mod.show_diagnostic_popup, "[g]o to diagnostic hover")
  nmap("K", function()
    vim.diagnostic.hide(nil, bufnr)
    vim.lsp.buf.hover({ border = "rounded" })
  end, "hover docs")
  -- nmap("gD", vim.lsp.buf.declaration, "[g]oto [d]eclaration")
  vnmap("ga", vim.lsp.buf.code_action, "run code actions")
  vnmap("gl", vim.lsp.codelens.run, "run code lens")
  vnmap("g==", function() fix_current_action() end, "[g]o run nearest/current code action")

  nmap(
    "[e",
    function() diagnostics_mod.goto_diagnostic_hl("prev", { severity = L.ERROR }) end,
    "Go to previous [e]rror diagnostic message"
  )
  nmap(
    "]e",
    function() diagnostics_mod.goto_diagnostic_hl("next", { severity = L.ERROR }) end,
    "Go to next [e]rror diagnostic message"
  )

  nmap("[d", function() diagnostics_mod.goto_diagnostic_hl("prev") end, "[g]oto previous [d]iagnostic message")
  nmap("]d", function() diagnostics_mod.goto_diagnostic_hl("next") end, "[g]oto next [d]iagnostic message")

  nmap(
    "gq",
    function() vim.cmd("Trouble diagnostics toggle focus=true filter.buf=0") end,
    "[g]oto [q]uickfixlist buffer diagnostics (trouble)"
  )
  nmap(
    "gQ",
    function() vim.cmd("Trouble diagnostics toggle focus=true") end,
    "[g]oto [q]uickfixlist global diagnostics (trouble)"
  )

  -- "<leader>ss", function() Snacks.picker.lsp_symbols() end, desc = "LSP Symbols" },
  --    { "<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols" },

  -- vnmap("grn", function()
  --   -- local bufnr = vim.api.nvim_get_current_buf()
  --   local params = vim.lsp.util.make_position_params(0, "utf-16")
  --   params.context = { includeDeclaration = true }
  --   local clients = vim.lsp.get_clients()
  --   if not clients or #clients == 0 then
  --     vim.print("No attached clients.")
  --     return
  --   end
  --   local client = clients[1]
  --   for _, possible_client in pairs(clients) do
  --     if possible_client.server_capabilities.renameProvider then
  --       client = possible_client
  --       break
  --     end
  --   end
  --   local ns = vim.api.nvim_create_namespace("LspRenamespace")

  --   client:request("textDocument/references", params, function(_, result)
  --     if result and not vim.tbl_isempty(result) then
  --       for _, v in ipairs(result) do
  --         if v.range then
  --           local buf = vim.uri_to_bufnr(v.uri)
  --           local line = v.range.start.line
  --           local start_char = v.range.start.character
  --           local end_char = v.range["end"].character
  --           if buf == bufnr then vim.hl.range(bufnr, ns, "LspReferenceWrite", line, start_char, end_char) end
  --         end
  --       end
  --       vim.cmd.redraw()
  --     end

  --     local new_name = vim.fn.input({ prompt = "New name: " })
  --     vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  --     if #new_name == 0 then return end
  --     vim.lsp.buf.rename(new_name)
  --   end, bufnr)
  -- end, "rename symbol/references")

  vnmap("gn", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local old_name = vim.fn.expand("<cword>")
    local params = vim.lsp.util.make_position_params(nil, "utf-16")
    params.context = { includeDeclaration = true }
    local clients = vim.lsp.get_clients()
    if not clients or #clients == 0 then
      vim.print("No attached clients.")
      return
    end

    client = clients[1]
    local is_valid_client = false
    for _, possible_client in pairs(clients) do
      if possible_client.server_capabilities.renameProvider then
        is_valid_client = true
        client = possible_client
        break
      end
    end

    local ns = vim.api.nvim_create_namespace("LspRenamespace")

    client:request("textDocument/references", params, function(_, result)
      if result and not vim.tbl_isempty(result) then
        for _, v in ipairs(result) do
          if v.range then
            local buf = vim.uri_to_bufnr(v.uri)
            local start_line = v.range.start.line
            local start_char = v.range.start.character
            local end_line = v.range["end"].line
            local end_char = v.range["end"].character
            if buf == bufnr then
              vim.hl.range(bufnr, ns, "LspReferenceWrite", { start_line, start_char }, { end_line, end_char })
            end
          end
        end
        vim.cmd.redraw()
      end

      -- input(old_name):mount()

      local new_name = vim.fn.input({ prompt = "New name: " })
      vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
      if #new_name == 0 then return end
      if is_valid_client then
        vim.lsp.buf.rename(new_name)
      else
        require("grug-far").open({
          prefills = { search = old_name, replacement = new_name, paths = vim.fn.expand("%") },
        })
      end
    end, bufnr)
  end)

  vnmap("<leader>ln", function()
    -- if lsp_method(client, "textDocument/rename") then return require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } }) end
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
    -- map("n", "gr", function()
    --   vim.cmd.Pick('lsp scope="references"')
    --   -- require("fzf-lua").lsp_references({
    --   --   include_declaration = false,
    --   --   ignore_current_line = true,
    --   -- })
    --   -- Snacks.picker.lsp_references({
    --   --   include_declaration = false,
    --   --   include_current = false,
    --   -- })
    -- end, "[g]oto [r]eferences", { nowait = true })

    -- map("n", "gR", function()
    --   Snacks.picker.lsp_references({
    --     include_declaration = false,
    --     include_current = false,
    --     auto_confirm = true,
    --     jump = { tagstack = true, reuse_win = true },
    --   })
    -- end, "[g]oto [r]eferences", { nowait = true })
  end)

  lsp_method(client, "textDocument/definition")(function()
    -- nmap("gd", function()
    --   -- require("telescope").lsp_definitions({ jump1 = true })
    --
    --   vim.cmd.Pick('lsp scope="definitions"')
    --   -- MiniPick.registry.LspPicker("definition", true)
    -- end, "[g]oto [d]efinition")
    nmap(
      "gd",
      function()
        Snacks.picker.lsp_definitions({
          include_declaration = false,
          include_current = false,
          auto_confirm = true,
          jump = { tagstack = true, reuse_win = true },
        })
      end,
      "[g]oto [d]efinition"
    )
    -- nmap("gD", function() require("fzf-lua").lsp_definitions({ jump1 = false }) end, "Peek definition")
    -- nmap("gD", "<CMD>Glance definitions<CR>", "[g]lance [d]efinition")
    nmap("gD", "<cmd>vsplit | lua vim.lsp.buf.definition()<cr>", "Goto Definition in Vertical Split")
    nmap("<C-]>", definitions, "goto definition")
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

---@param args vim.api.keyset.create_autocmd.callback_args
function M.on_detach(args)
  local client = vim.lsp.get_client_by_id(args.data.client_id)
  if not client or not client.attached_buffers then return end
  for buf_id in pairs(client.attached_buffers) do
    if buf_id ~= args.buf then return end
  end
  client:stop()
end

function M.on_attach(client, bufnr, _client_id)
  client.flags.allow_incremental_sync = true

  vim.b[bufnr].lsp = client.name
  local filetype = vim.bo[bufnr].filetype
  local disabled_lsp_formatting = vim.g.disabled_lsp_formatters

  -- load diagnostics config
  local ok_diagnostics, setup_diagnostics = pcall(dofile, vim.fn.stdpath("config") .. "/plugin/lsp/diagnostics.lua")
  if ok_diagnostics then diagnostics_mod = setup_diagnostics(client, bufnr) end

  make_commands(client, bufnr)
  make_keymaps(client, bufnr)

  lsp_method(client, methods.textDocument_formatting)(function()
    -- Disable formatting for certain language servers
    for i = 1, #disabled_lsp_formatting do
      if disabled_lsp_formatting[i] == client.name then
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
      end
    end

    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "*",
      callback = function(args)
        require("conform").format({
          bufnr = args.buf,
          async = true,
          lsp_format = "fallback",
          timeout_ms = 5000,
          filter = function(client, exclusions)
            local client_name = type(client) == "table" and client.name or client
            exclusions = exclusions or disabled_lsp_formatting

            return not exclusions or not vim.tbl_contains(exclusions, client_name)
          end,
        })
      end,
    })

    -- Auto-formatting on save
    -- if not lsp_method(client, methods.textDocument_willSaveWaitUntil) then
    -- vim.api.nvim_create_autocmd("BufWritePre", {
    --   group = lsp_group,
    --   buffer = bufnr,
    --   callback = function()
    --     local autoformat =
    --       vim.F.if_nil(client.settings and client.settings.autoformat, vim.b.lsp and vim.b.lsp.autoformat, vim.g.lsp and vim.g.lsp.autoformat, false)
    --     if autoformat then vim.lsp.buf.format({ bufnr = bufnr, id = client_id or client.id }) end
    --   end,
    -- })
    -- end
  end)

  lsp_method(client, methods.textDocument_semanticTokens_full)(function()
    if vim.g.disabled_semantic_tokens[filetype] then client.server_capabilities.semanticTokensProvider = vim.NIL end
  end)

  lsp_method(client, methods.textDocument_inlayHint)(function()
    if vim.g.enabled_inlay_hints[filetype] then vim.lsp.inlay_hint.enable(true) end
  end)

  lsp_method(client, methods.textDocument_documentSymbol)(function()
    if pcall(require, "nvim-navic") then require("nvim-navic").attach(client, bufnr) end
  end)

  -- Document highlighting
  lsp_method(client, methods.textDocument_documentHighlight)(function()
    Augroup(lsp_group, {
      {
        event = { "CursorHold", "InsertLeave" },
        -- buffer = bufnr,
        command = function() vim.lsp.buf.document_highlight() end,
      },
      {
        event = { "CursorMoved", "InsertEnter" },
        -- buffer = bufnr,
        command = function() vim.lsp.buf.clear_references() end,
      },
    })
  end)

  -- -- Code lens
  -- lsp_method(client, methods.textDocument_codeLens)(function()
  --   Augroup(lsp_group, {
  --     {
  --       event = { "LspProgress" },
  --       pattern = "end",
  --       command = function(args)
  --         if args.buf == bufnr then
  --           vim.lsp.codelens.refresh({ bufnr = args.buf })
  --         end
  --       end,
  --     },
  --     {
  --       event = { "BufEnter", "TextChanged", "InsertLeave" },
  --       buffer = bufnr,
  --       command = function(args)
  --         vim.lsp.codelens.refresh({ bufnr = args.buf })
  --       end,
  --     },
  --   })
  --
  --   vim.lsp.codelens.refresh({ bufnr = bufnr })
  -- end)

  lsp_method(client, methods.textDocument_signatureHelp)(function()
    Augroup(lsp_group, {
      {
        event = { "CursorHoldI" },
        buffer = bufnr,
        command = function(args)
          local node = vim.treesitter.get_node()
          if node and (node:type() == "arguments" or (node:parent() and node:parent():type() == "arguments")) then
            vim.defer_fn(function() vim.lsp.buf.signature_help(preview_opts) end, 500)
          end
        end,
      },
    })
  end)

  -- Folding
  -- vim.opt.foldmethod = "expr"
  -- if lsp_method(client, methods.textDocument_foldingRange) and vim.lsp.foldexpr then
  --   vim.opt.foldexpr = "v:lua.vim.lsp.foldexpr()"
  --   vim.opt.foldtext = "v:lua.vim.lsp.foldtext()"
  -- elseif vim.treesitter.foldexpr then
  --   vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
  --   vim.opt.foldtext = ""
  -- else
  --   vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
  --   vim.opt.foldtext = ""
  -- end
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
        -- assert(client_config.on_attach, "must have an on_attach function for language server client")

        if client_config.on_attach and type(client_config.on_attach == "function") then
          client_config.on_attach(client, bufnr)
        else
          vim.notify(string.format("No on_attach found for %s", client.name), L.WARN)
        end
      end
    end,
  },
  {
    event = { "LspDetach" },
    command = function(args)
      M.on_detach(args)

      vim.schedule(function()
        local buf = args.buf
        if vim.api.nvim_buf_is_valid(buf) then
          vim.b[buf].lsp = nil
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds({ group = lsp_group, buffer = buf })
        end
      end)
    end,
  },
  {
    event = { "LspProgress" },
    pattern = "*",
    command = function(args)
      local buf = args.buf
      local client_id = args.data.client_id
      local value = args.data.params.value

      if value.kind == "begin" then
        io.stdout:write("\027]9;4;1;0\027\\")
      elseif value.kind == "end" then
        io.stdout:write("\027]9;4;0;0\027\\")
      elseif value.kind == "report" then
        if value.percentage and value.percentage >= 0 and value.percentage <= 100 then
          io.stdout:write(string.format("\027]9;4;1;%d\027\\", value.percentage))
        end
      end
    end,
  },
})

-- Configure LSP for all servers
vim.lsp.config("*", {
  on_init = on_init,
  workspace_required = true,
  capabilities = M.capabilitites(),
})

local ok_servers, servers = pcall(dofile, vim.fn.stdpath("config") .. "/plugin/lsp/servers.lua")
if not ok_servers then
  Echom(string.format("Unable to load language server list: \r\n%s", servers), "Error")
  return
end

local enabled_servers = {}
-- local lsp_cmds = require("lsp_cmds")

vim.iter(servers):each(function(name, config)
  if type(config) == "function" then config = config() end
  if type(config) == "boolean" then config = {} end

  if config ~= nil and config and (config.enabled == nil or config.enabled == true) then
    table.insert(enabled_servers, name)

    if config["on_attach"] ~= nil and type(config["on_attach"]) == "function" then
      Echom(fmt("%s has a custom on_attach fn", name), "Question")

      config.on_attach = function(client, bufnr, client_id)
        -- make sure we call our default/main on_attach here:
        M.on_attach(client, bufnr, client_id)

        -- additional on_attach handlers?
        config["on_attach"](client, bufnr, client_id)
      end
    else
      config["on_attach"] = M.on_attach
    end

    -- if lsp_cmds[name] then
    --   vim.inspect(lsp_cmds[name])
    --   config.cmd = lsp_cmds[name]
    -- end

    vim.lsp.config[name] = config
    vim.lsp.enable(name, true)
  end
end)

Load_macros(M, "on_attach")

return M
