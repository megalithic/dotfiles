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

local max_width = math.min(math.floor(vim.o.columns * 0.7), 100)
local max_height = math.min(math.floor(vim.o.lines * 0.3), 30)

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

  -- local ok, _ = pcall(require, "colorizer")
  -- if ok then
  --   require("colorizer").highlight_buffer(
  --     bufnr,
  --     nil,
  --     vim.list_slice(lines, 2, #lines),
  --     0,
  --     require("colorizer").get_buffer_options(0)
  --   )
  -- end

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



-- do
--   local nnotify_ok, nnotify = pcall(require, "notify")

--   if nnotify_ok and nnotify then
--     local client_notifs = {}

--     local function get_notif_data(client_id, token)
--       if not client_notifs[client_id] then client_notifs[client_id] = {} end

--       if not client_notifs[client_id][token] then client_notifs[client_id][token] = {} end

--       return client_notifs[client_id][token]
--     end

--     local spinner_frames = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" }

--     local function update_spinner(client_id, token)
--       local notif_data = get_notif_data(client_id, token)

--       if notif_data.spinner then
--         local new_spinner = (notif_data.spinner + 1) % #spinner_frames
--         notif_data.spinner = new_spinner
--         notif_data.notification = nnotify(nil, nil, {
--           hide_from_history = true,
--           icon = spinner_frames[new_spinner],
--           replace = notif_data.notification,
--         })

--         vim.defer_fn(function() update_spinner(client_id, token) end, 100)
--       end
--     end

--     local function format_title(title, client_name) return client_name .. (#title > 0 and ": " .. title or "") end

--     local function format_message(message, percentage)
--       return (percentage and percentage .. "%\t" or "") .. (message or "")
--     end

--     vim.lsp.handlers["$/progress"] = function(_, result, ctx)
--       local client_id = ctx.client_id
--       local client = vim.lsp.get_client_by_id(client_id)
--       if
--         client
--         and (
--           client.name == "elixirls"
--           or client.name == "sumneko_lua"
--           or client.name == "rust_analyzer"
--           or client.name == "clangd"
--           or client.name == "shellcheck"
--           or client.name == "bashls"
--         )
--       then
--         return
--       end
--       local val = result.value

--       if not val.kind then return end

--       local notif_data = get_notif_data(client_id, result.token)

--       if val.kind == "begin" then
--         local message = format_message(val.message, val.percentage)

--         notif_data.notification = nnotify(message, "info", {
--           title = format_title(val.title, vim.lsp.get_client_by_id(client_id).name),
--           icon = spinner_frames[1],
--           timeout = false,
--           hide_from_history = false,
--         })

--         notif_data.spinner = 1
--         update_spinner(client_id, result.token)
--       elseif val.kind == "report" and notif_data then
--         notif_data.notification = nnotify(format_message(val.message, val.percentage), "info", {
--           replace = notif_data.notification,
--           hide_from_history = false,
--         })
--       elseif val.kind == "end" and notif_data then
--         notif_data.notification = nnotify(val.message and format_message(val.message) or "Complete", "info", {
--           icon = "",
--           replace = notif_data.notification,
--           timeout = 3000,
--         })

--         notif_data.spinner = nil
--       end
--     end
--   end
-- end

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
