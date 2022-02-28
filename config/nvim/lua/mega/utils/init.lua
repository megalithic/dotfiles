local vcmd, lsp, api, fn, g = vim.cmd, vim.lsp, vim.api, vim.fn, vim.g
local bmap, au = mega.bmap, mega.au
local fmt = string.format

local M = {
  lsp = {},
}
local windows = {}

function M.t(cmd_str)
  -- return api.nvim_replace_termcodes(cmd, true, true, true) -- TODO: why 3rd param false?
  return api.nvim_replace_termcodes(cmd_str, true, false, true)
end

function M.check_back_space()
  local col = fn.col(".") - 1
  return col == 0 or fn.getline("."):sub(col, col):match("%s") ~= nil
end

function M.root_has_file(name)
  local cwd = vim.loop.cwd()
  local lsputil = require("lspconfig.util")
  return lsputil.path.exists(lsputil.path.join(cwd, name)), lsputil.path.join(cwd, name)
end

-- # [ peak_definition ] ----------------------------------------------------------------
M.lsp.peek_definition = function()
  local function preview_location_callback(_, result)
    if result == nil or vim.tbl_isempty(result) then
      return nil
    end
    lsp.util.preview_location(result[1], { border = "single" })
  end

  local params = lsp.util.make_position_params()
  return lsp.buf_request(0, "textDocument/definition", params, preview_location_callback)
end

-- # [ rename ] ----------------------------------------------------------------
-- REF:
-- * https://github.com/saadparwaiz1/dotfiles/blob/macOS/nvim/plugin/lsp.lua#L29-L74
-- * https://github.com/lukas-reineke/dotfiles/blob/master/vim/lua/lsp/rename.lua (simpler impl to investigate)
-- * https://github.com/kristijanhusak/neovim-config/blob/master/nvim/lua/partials/lsp.lua#L197-L217
-- * AKINSHO: https://github.com/akinsho/dotfiles/commit/59b5011d9533de0427fc34e687c9f1a566d6020c#diff-cc18199cc4302869fa6d36870b7950eef0b03021e5e93c64e17153b234ad6800R160
local rename_prompt = ""
local default_rename_prompt = " -> "
local current_name = ""
M.lsp.rename = function()
  current_name = fn.expand("<cword>")
  rename_prompt = current_name .. default_rename_prompt
  local bufnr = api.nvim_create_buf(false, true)
  api.nvim_buf_set_option(bufnr, "buftype", "prompt")
  api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
  api.nvim_buf_set_option(bufnr, "filetype", "prompt")
  api.nvim_buf_add_highlight(bufnr, -1, "Title", 0, 0, #rename_prompt)
  fn.prompt_setprompt(bufnr, rename_prompt)
  local width = #current_name + #rename_prompt + 15
  local winnr = api.nvim_open_win(bufnr, true, {
    relative = "cursor",
    width = width,
    height = 1,
    row = -3,
    col = 1,
    style = "minimal",
    border = "single",
  })

  api.nvim_win_set_option(winnr, "winhl", "Normal:Floating")
  api.nvim_win_set_option(winnr, "relativenumber", false)
  api.nvim_win_set_option(winnr, "number", false)

  bmap("i", "<CR>", "<cmd>lua require('utils').rename_callback()<CR>")
  bmap("i", "<esc>", "<cmd>lua require('utils').cleanup_rename_callback()<cr>")
  bmap("i", "<c-c>", "<cmd>lua require('utils').cleanup_rename_callback()<cr>")

  vcmd("startinsert")
end

M.rename_callback = function()
  local new_name = vim.trim(fn.getline("."):sub(#rename_prompt, -1))

  if new_name ~= current_name then
    M.cleanup_rename_callback()
    local params = lsp.util.make_position_params()
    params.newName = new_name
    lsp.buf_request(0, "textDocument/rename", params)
  else
    mega.warn("Rename text matches; try again.")
  end
end

function M.cleanup_rename_callback()
  api.nvim_win_close(0, true)
  api.nvim_feedkeys(M.t("<Esc>"), "i", true)

  current_name = ""
  rename_prompt = default_rename_prompt
end

-- # [ preview ] ---------------------------------------------------------------
local function set_auto_close()
  au([[ CursorMoved * ++once lua require('utils').remove_wins() ]])
end

local function fit_to_node(window)
  local node = require("nvim-treesitter.ts_utils").get_node_at_cursor()
  if node:type() == "identifier" then
    node = node:parent()
  end
  local start_row, _, end_row, _ = node:range()
  local new_height = math.min(math.max(end_row - start_row + 6, 15), 30)
  api.nvim_win_set_height(window, new_height)
end

local open_preview_win = function(target, position)
  local buffer = vim.uri_to_bufnr(target)
  local win_opts = {
    relative = "cursor",
    row = 4,
    col = 4,
    width = 120,
    height = 15,
    border = g.floating_window_border,
  }

  -- Don't jump immediately, we need the windows list to contain ID before autocmd
  windows[#windows + 1] = api.nvim_open_win(buffer, false, win_opts)
  api.nvim_set_current_win(windows[#windows])
  api.nvim_buf_set_option(buffer, "bufhidden", "wipe")
  set_auto_close()
  api.nvim_win_set_cursor(windows[#windows], position)
  fit_to_node(windows[#windows])
end

function M.lsp.preview(request)
  local params = lsp.util.make_position_params()
  pcall(lsp.buf_request, 0, request, params, function(_, result)
    if not result then
      return
    end
    local data = result[1]
    local target = data.targetUri or data.uri
    local range = data.targetRange or data.range
    open_preview_win(target, { range.start.line + 1, range.start.character })
  end)
end

function M.remove_wins()
  local current = api.nvim_get_current_win()
  for i = #windows, 1, -1 do
    if current == windows[i] then
      break
    end
    pcall(api.nvim_win_close, windows[i], true)
    table.remove(windows, i)
  end
  if #windows > 0 then
    set_auto_close()
  end
end

-- # [ hover ] -----------------------------------------------------------------
function M.lsp.hover()
  if next(lsp.buf_get_clients()) == nil then
    vcmd([[execute printf('h %s', expand('<cword>'))]])
  else
    lsp.buf.hover()
  end
end

-- # [ config ] ----------------------------------------------------------------
function M.lsp.config()
  local cfg = {}
  for _, client in pairs(lsp.get_active_clients()) do
    cfg[client.name] = { root_dir = client.config.root_dir, settings = client.config.settings }
  end

  mega.log(vim.inspect(cfg))
end

-- # [ lsp_commands ] ----------------------------------------------------------------
function M.lsp.elixirls_cmd(opts)
  opts = opts or {}
  local fallback_dir = opts.fallback_dir or vim.env.XDG_DATA_HOME or "~/.local/share"

  local locations = {
    ".bin/elixir_ls.sh",
    ".elixir_ls/release/language_server.sh",
  }

  for _, location in ipairs(locations) do
    local exists, dir = M.root_has_file(location)
    if exists then
      return fn.expand(dir)
    end
  end

  return fn.expand(fmt("%s/lsp/elixir-ls/%s", fallback_dir, "language_server.sh"))
end

return M