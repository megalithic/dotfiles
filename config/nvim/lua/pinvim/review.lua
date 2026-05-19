-- lua/pinvim/review.lua
-- Review-mode UI for pinvim. Keep transport in lua/pinvim.lua.

local M = {}

local state = {
  active = false,
  tab = nil,
  previous_tab = nil,
  previous_win = nil,
  previous_winwidth = nil,
  tree_win = nil,
  tree_buf = nil,
  diff_win = nil,
  diff_buf = nil,
  tree = nil,
}

local function valid_buf(bufnr) return bufnr and vim.api.nvim_buf_is_valid(bufnr) end
local function valid_win(winid) return winid and vim.api.nvim_win_is_valid(winid) end
local function valid_tab(tabpage) return tabpage and vim.api.nvim_tabpage_is_valid(tabpage) end

local function notify(message, level) vim.notify("pinvim review: " .. message, level or vim.log.levels.INFO) end

local function review_width()
  local columns = vim.o.columns > 0 and vim.o.columns or 120
  return math.max(1, math.floor(columns * 0.2))
end

local function configure_review_buffer(bufnr, name, filetype)
  vim.api.nvim_buf_set_name(bufnr, name)
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].buflisted = false
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = filetype
end

local function show_buffer_maps()
  local ok, whichkey = pcall(require, "which-key")
  if ok and whichkey then
    whichkey.show({ global = false })
    return
  end

  notify(table.concat({
    "buffer maps",
    "q close review",
    "R refresh review",
    "<CR> select file placeholder",
    "g? show buffer-local keymaps",
  }, "\n"))
end

local function set_review_maps(bufnr)
  local map_opts = function(desc) return { buffer = bufnr, silent = true, nowait = true, desc = desc } end

  vim.keymap.set("n", "q", M.close, map_opts("pinvim review close"))
  vim.keymap.set("n", "R", M.refresh, map_opts("pinvim review refresh"))
  vim.keymap.set("n", "<CR>", M.select_file, map_opts("pinvim review select file"))
  vim.keymap.set("n", "g?", show_buffer_maps, map_opts("pinvim review buffer keymaps"))
end

local function diff_placeholder_lines()
  return {
    "pinvim review",
    "",
    "Diff viewer placeholder.",
    "jj/git diff loading lands in next plan step.",
    "",
    "Maps:",
    "  q     close review",
    "  R     refresh review",
    "  g?    show buffer-local keymaps",
  }
end

local function render_diff_placeholder()
  if not valid_buf(state.diff_buf) then return end
  vim.bo[state.diff_buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.diff_buf, 0, -1, false, diff_placeholder_lines())
  vim.bo[state.diff_buf].modifiable = false
end

local function render_tree()
  if not valid_buf(state.tree_buf) then return end

  local ok, NuiTree = pcall(require, "nui.tree")
  if not ok then
    vim.bo[state.tree_buf].modifiable = true
    vim.api.nvim_buf_set_lines(state.tree_buf, 0, -1, false, {
      "pinvim review files",
      "",
      "nui.nvim unavailable; cannot render tree",
    })
    vim.bo[state.tree_buf].modifiable = false
    return
  end

  local nodes = {
    NuiTree.Node({ id = "root", text = "changed files" }, {
      NuiTree.Node({ id = "placeholder", text = "diff source pending", path = nil }),
    }),
  }

  state.tree = NuiTree({
    bufnr = state.tree_buf,
    nodes = nodes,
    get_node_id = function(node) return node.id or node.text end,
    prepare_node = function(node)
      if node.id == "root" then return "▾ " .. node.text end
      return "  • " .. node.text
    end,
  })
  state.tree:render()
end

function M.is_active() return state.active and valid_tab(state.tab) end

function M.status()
  local status = M.is_active() and "active" or "inactive"
  local lines = {
    "pinvim review status",
    "state: " .. status,
    "tab: " .. (valid_tab(state.tab) and tostring(state.tab) or "(none)"),
    "tree buffer: " .. (valid_buf(state.tree_buf) and tostring(state.tree_buf) or "(none)"),
    "diff buffer: " .. (valid_buf(state.diff_buf) and tostring(state.diff_buf) or "(none)"),
  }
  notify(table.concat(lines, "\n"))
  return vim.deepcopy(state)
end

function M.select_file()
  local node = state.tree and state.tree:get_node() or nil
  if node and node.path then
    notify("selected " .. node.path)
  else
    notify("diff source pending; no file selected", vim.log.levels.WARN)
  end
end

function M.refresh()
  if not M.is_active() then
    notify("not active", vim.log.levels.WARN)
    return false
  end

  render_tree()
  render_diff_placeholder()
  notify("refreshed")
  return true
end

function M.open()
  if M.is_active() then
    if valid_tab(state.tab) then vim.api.nvim_set_current_tabpage(state.tab) end
    return true
  end

  state.previous_tab = vim.api.nvim_get_current_tabpage()
  state.previous_win = vim.api.nvim_get_current_win()
  state.previous_winwidth = vim.o.winwidth
  vim.o.winwidth = 1

  vim.cmd("tabnew")
  state.tab = vim.api.nvim_get_current_tabpage()
  state.diff_win = vim.api.nvim_get_current_win()
  state.diff_buf = vim.api.nvim_get_current_buf()
  configure_review_buffer(state.diff_buf, "pinvim-review://diff", "diff")
  set_review_maps(state.diff_buf)
  render_diff_placeholder()

  vim.cmd("topleft vertical new")
  state.tree_win = vim.api.nvim_get_current_win()
  state.tree_buf = vim.api.nvim_get_current_buf()
  configure_review_buffer(state.tree_buf, "pinvim-review://files", "pinvimreview")
  set_review_maps(state.tree_buf)
  render_tree()

  if valid_win(state.diff_win) then vim.api.nvim_set_current_win(state.diff_win) end
  vim.api.nvim_win_set_width(state.tree_win, review_width())
  vim.wo[state.diff_win].wrap = false
  if valid_win(state.tree_win) then vim.api.nvim_set_current_win(state.tree_win) end

  state.active = true
  notify("opened")
  return true
end

function M.close()
  if not M.is_active() then
    state.active = false
    notify("not active", vim.log.levels.WARN)
    return false
  end

  local previous_tab = state.previous_tab
  local previous_win = state.previous_win
  local review_tab = state.tab

  if valid_tab(review_tab) then
    vim.api.nvim_set_current_tabpage(review_tab)
    if #vim.api.nvim_list_tabpages() > 1 then
      vim.cmd("tabclose")
    else
      for _, winid in ipairs({ state.tree_win, state.diff_win }) do
        if valid_win(winid) then pcall(vim.api.nvim_win_close, winid, true) end
      end
    end
  end

  if state.previous_winwidth then vim.o.winwidth = state.previous_winwidth end

  state.active = false
  state.tab = nil
  state.tree_win = nil
  state.tree_buf = nil
  state.diff_win = nil
  state.diff_buf = nil
  state.tree = nil

  if valid_tab(previous_tab) then vim.api.nvim_set_current_tabpage(previous_tab) end
  if valid_win(previous_win) then vim.api.nvim_set_current_win(previous_win) end

  notify("closed")
  return true
end

function M.toggle()
  if M.is_active() then return M.close() end
  return M.open()
end

function M.setup(_api, _config)
  vim.api.nvim_create_user_command("PiReview", M.open, { desc = "Open pinvim review mode" })
  vim.api.nvim_create_user_command("PiReviewClose", M.close, { desc = "Close pinvim review mode" })
  vim.api.nvim_create_user_command("PiReviewStatus", M.status, { desc = "Show pinvim review status" })

  vim.keymap.set("n", "gds", M.toggle, { silent = true, desc = "pinvim review toggle" })

  return M
end

return M
