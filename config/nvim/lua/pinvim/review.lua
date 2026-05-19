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
  repo = nil,
  files = {},
  last_message = nil,
  start_path = nil,
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

local function set_buffer_lines(bufnr, lines)
  if not valid_buf(bufnr) then return end
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false
end

local function split_lines(text)
  if not text or text == "" then return {} end
  return vim.split(text:gsub("\r\n", "\n"), "\n", { plain = true, trimempty = true })
end

local function current_start_path()
  local name = vim.api.nvim_buf_get_name(0)
  if name ~= "" then
    local stat = vim.uv.fs_stat(name)
    if stat and stat.type == "file" then return vim.fs.dirname(name) end
    if stat and stat.type == "directory" then return name end
  end
  return vim.loop.cwd()
end

local function run_command(cmd, cwd)
  if not vim.system then return { code = 127, stdout = "", stderr = "vim.system unavailable" } end
  local ok, result = pcall(function() return vim.system(cmd, { cwd = cwd, text = true }):wait() end)
  if not ok then return { code = 1, stdout = "", stderr = tostring(result) } end
  return {
    code = result.code or 0,
    stdout = result.stdout or "",
    stderr = result.stderr or "",
  }
end

local function git_root(start_path)
  if vim.fn.executable("git") ~= 1 then return nil end
  local marker = vim.fs.find(".git", { upward = true, path = start_path })[1]
  if not marker then return nil end
  local cwd = vim.fs.dirname(marker)
  local result = run_command({ "git", "rev-parse", "--show-toplevel" }, cwd)
  if result.code ~= 0 then return nil end
  local root = vim.trim(result.stdout)
  if root == "" then return nil end
  return root
end

local function jj_root(start_path)
  if vim.fn.executable("jj") ~= 1 then return nil end
  local marker = vim.fs.find(".jj", { upward = true, path = start_path })[1]
  if not marker then return nil end
  local cwd = vim.fs.dirname(marker)
  local result = run_command({ "jj", "root" }, cwd)
  if result.code ~= 0 then return nil end
  local root = vim.trim(result.stdout)
  if root == "" then return nil end
  return root
end

local function detect_repo(start_path)
  start_path = start_path or current_start_path()
  local root = jj_root(start_path)
  if root then return { type = "jj", root = root } end

  root = git_root(start_path)
  if root then return { type = "git", root = root } end

  return nil
end

local function unique_sorted(lines)
  local seen = {}
  local files = {}
  for _, line in ipairs(lines) do
    local file = vim.trim(line)
    if file ~= "" and not seen[file] then
      seen[file] = true
      table.insert(files, file)
    end
  end
  table.sort(files)
  return files
end

local function load_changed_files(repo)
  if not repo then return {}, "no supported VCS found for current root" end

  if repo.type == "jj" then
    local result = run_command({ "jj", "diff", "-r", "@", "--name-only" }, repo.root)
    if result.code ~= 0 then return {}, vim.trim(result.stderr ~= "" and result.stderr or result.stdout) end
    return unique_sorted(split_lines(result.stdout)), nil
  end

  local unstaged = run_command({ "git", "diff", "--name-only", "--no-ext-diff", "--" }, repo.root)
  local staged = run_command({ "git", "diff", "--cached", "--name-only", "--no-ext-diff", "--" }, repo.root)
  if unstaged.code ~= 0 then return {}, vim.trim(unstaged.stderr ~= "" and unstaged.stderr or unstaged.stdout) end
  if staged.code ~= 0 then return {}, vim.trim(staged.stderr ~= "" and staged.stderr or staged.stdout) end

  local lines = split_lines(unstaged.stdout)
  vim.list_extend(lines, split_lines(staged.stdout))
  return unique_sorted(lines), nil
end

local function load_file_diff(repo, file)
  if not repo then return { "pinvim review", "", "No supported VCS found for current root." } end

  if repo.type == "jj" then
    local result = run_command({ "jj", "diff", "-r", "@", "--git", "--", file }, repo.root)
    if result.code ~= 0 then
      return { "pinvim review", "", "Failed to load jj diff for " .. file .. ":", vim.trim(result.stderr) }
    end
    local lines = split_lines(result.stdout)
    if vim.tbl_isempty(lines) then return { "No diff for " .. file } end
    return lines
  end

  local sections = {}
  local staged = run_command({ "git", "diff", "--cached", "--no-ext-diff", "--", file }, repo.root)
  local unstaged = run_command({ "git", "diff", "--no-ext-diff", "--", file }, repo.root)
  if staged.code ~= 0 then
    return { "pinvim review", "", "Failed to load staged git diff for " .. file .. ":", vim.trim(staged.stderr) }
  end
  if unstaged.code ~= 0 then
    return { "pinvim review", "", "Failed to load unstaged git diff for " .. file .. ":", vim.trim(unstaged.stderr) }
  end

  local staged_lines = split_lines(staged.stdout)
  local unstaged_lines = split_lines(unstaged.stdout)
  if not vim.tbl_isempty(staged_lines) then
    vim.list_extend(sections, { "# staged changes: " .. file, "" })
    vim.list_extend(sections, staged_lines)
  end
  if not vim.tbl_isempty(staged_lines) and not vim.tbl_isempty(unstaged_lines) then
    vim.list_extend(sections, { "", "" })
  end
  if not vim.tbl_isempty(unstaged_lines) then
    vim.list_extend(sections, { "# unstaged changes: " .. file, "" })
    vim.list_extend(sections, unstaged_lines)
  end
  if vim.tbl_isempty(sections) then return { "No diff for " .. file } end
  return sections
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
    "]f next file",
    "[f previous file",
    "<CR> select file",
    "g? show buffer-local keymaps",
  }, "\n"))
end

function M.select_file()
  local node = state.tree and state.tree:get_node() or nil
  if not (node and node.path) then
    notify("no file selected", vim.log.levels.WARN)
    return false
  end

  set_buffer_lines(state.diff_buf, load_file_diff(state.repo, node.path))
  if valid_win(state.diff_win) then
    vim.wo[state.diff_win].wrap = false
    vim.api.nvim_win_set_cursor(state.diff_win, { 1, 0 })
  end
  notify("loaded " .. node.path)
  return true
end

function M.next_file()
  if valid_win(state.tree_win) then vim.api.nvim_set_current_win(state.tree_win) end
  vim.cmd("normal! j")
  return M.select_file()
end

function M.previous_file()
  if valid_win(state.tree_win) then vim.api.nvim_set_current_win(state.tree_win) end
  vim.cmd("normal! k")
  return M.select_file()
end

local function set_review_maps(bufnr, tree_buffer)
  local map_opts = function(desc) return { buffer = bufnr, silent = true, nowait = true, desc = desc } end

  vim.keymap.set("n", "q", M.close, map_opts("pinvim review close"))
  vim.keymap.set("n", "R", M.refresh, map_opts("pinvim review refresh"))
  vim.keymap.set("n", "g?", show_buffer_maps, map_opts("pinvim review buffer keymaps"))

  if tree_buffer then
    vim.keymap.set("n", "]f", M.next_file, map_opts("pinvim review next file"))
    vim.keymap.set("n", "[f", M.previous_file, map_opts("pinvim review previous file"))
    vim.keymap.set("n", "<CR>", M.select_file, map_opts("pinvim review select file"))
  end
end

local function diff_placeholder_lines()
  if state.last_message then return {
    "pinvim review",
    "",
    state.last_message,
  } end

  return {
    "pinvim review",
    "",
    "Select changed file from tree to view diff.",
    "",
    "Maps:",
    "  q     close review",
    "  R     refresh review",
    "  ]f    next file",
    "  [f    previous file",
    "  <CR>  select file",
    "  g?    show buffer-local keymaps",
  }
end

local function render_diff_placeholder() set_buffer_lines(state.diff_buf, diff_placeholder_lines()) end

local function render_tree()
  if not valid_buf(state.tree_buf) then return end

  local ok, NuiTree = pcall(require, "nui.tree")
  if not ok then
    set_buffer_lines(state.tree_buf, {
      "pinvim review files",
      "",
      "nui.nvim unavailable; cannot render tree",
    })
    return
  end

  state.repo = detect_repo(state.start_path)
  state.files, state.last_message = load_changed_files(state.repo)

  local children = {}
  if state.last_message then
    table.insert(children, NuiTree.Node({ id = "message", text = state.last_message, path = nil }))
  elseif vim.tbl_isempty(state.files) then
    table.insert(children, NuiTree.Node({ id = "empty", text = "no changed files", path = nil }))
    state.last_message = "No changed files."
  else
    for _, file in ipairs(state.files) do
      table.insert(children, NuiTree.Node({ id = file, text = file, path = file }))
    end
  end

  local label = "changed files"
  if state.repo then label = label .. " (" .. state.repo.type .. ": " .. state.repo.root .. ")" end
  local root = NuiTree.Node({ id = "root", text = label }, children)
  root:expand()

  state.tree = NuiTree({
    bufnr = state.tree_buf,
    nodes = { root },
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
    "repo: " .. (state.repo and (state.repo.type .. " " .. state.repo.root) or "(none)"),
  }
  notify(table.concat(lines, "\n"))
  return vim.deepcopy(state)
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
  state.start_path = current_start_path()
  vim.o.winwidth = 1

  vim.cmd("tabnew")
  state.tab = vim.api.nvim_get_current_tabpage()
  state.diff_win = vim.api.nvim_get_current_win()
  state.diff_buf = vim.api.nvim_get_current_buf()
  configure_review_buffer(state.diff_buf, "pinvim-review://diff", "diff")
  set_review_maps(state.diff_buf, false)
  render_diff_placeholder()

  vim.cmd("topleft vertical new")
  state.tree_win = vim.api.nvim_get_current_win()
  state.tree_buf = vim.api.nvim_get_current_buf()
  configure_review_buffer(state.tree_buf, "pinvim-review://files", "pinvimreview")
  set_review_maps(state.tree_buf, true)
  render_tree()
  render_diff_placeholder()

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
  state.repo = nil
  state.files = {}
  state.last_message = nil
  state.start_path = nil

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
