-- Claude Code integration with multi-session support and enhanced UI
-- Adapted from @alex35mil's implementation with megalithic's dotfiles patterns

local fn = {}
local M = {}

-- Forward declarations for functions used in provider callbacks
local CCProvider

---@param bufid integer
---@return boolean
function fn.is_claude_buf(bufid)
  if not vim.api.nvim_buf_is_loaded(bufid) then return false end
  local bufname = vim.api.nvim_buf_get_name(bufid)
  return bufname:match("claude") ~= nil and vim.bo[bufid].buftype == "terminal"
end

---@return boolean
function fn.is_claude_visible() return CCProvider and CCProvider.is_active() or false end

---@return boolean
function fn.is_claude_active()
  local current_buf = vim.api.nvim_get_current_buf()
  return fn.is_claude_buf(current_buf)
end

---@return boolean
function fn.is_claude_connected()
  if not CCProvider then return false end
  local tab_id = vim.api.nvim_get_current_tabpage()
  return CCProvider.is_connected(tab_id)
end

function fn.new_line()
  vim.api.nvim_feedkeys("\\", "t", true)
  vim.defer_fn(function() vim.api.nvim_feedkeys("\r", "t", true) end, 10)
end

-- Close any diffview tabs that might interfere with diff accept/reject
function fn.ensure_diffviews_hidden()
  local ok, diffview = pcall(require, "diffview")
  if ok and diffview.close then pcall(diffview.close) end
end

function fn.accept_diff()
  if M.is_diff_active() then
    fn.ensure_diffviews_hidden()
    vim.cmd("ClaudeCodeDiffAccept")
    vim.defer_fn(function()
      if CCProvider then CCProvider.focus() end
    end, 50)
  end
end

function fn.reject_diff()
  if M.is_diff_active() then
    fn.ensure_diffviews_hidden()
    vim.cmd("ClaudeCodeDiffDeny")
    vim.defer_fn(function()
      if CCProvider then CCProvider.focus() end
    end, 50)
  end
end

-- Post content to Claude and focus the terminal
-- Handles both visible and hidden states, preserving cursor position
function fn.post_and_focus()
  local is_visible = fn.is_claude_visible()

  if is_visible then
    local mode = vim.fn.mode()

    if mode == "v" or mode == "V" then
      vim.cmd("ClaudeCodeSend")
      vim.defer_fn(function() vim.cmd("ClaudeCodeFocus") end, 10)
    else
      vim.cmd("ClaudeCodeAdd %")
      vim.cmd("ClaudeCodeFocus")
    end
  else
    -- Save state before opening Claude
    local function save_state()
      local mode = vim.fn.mode()
      local pos = vim.fn.getpos(".")
      local buf = vim.api.nvim_get_current_buf()
      local win = vim.api.nvim_get_current_win()
      local selection = nil

      if mode == "v" or mode == "V" then
        selection = {
          start_pos = vim.fn.getpos("'<"),
          end_pos = vim.fn.getpos("'>"),
          mode = mode,
        }
      end

      return {
        pos = pos,
        buf = buf,
        win = win,
        selection = selection,
        mode = mode,
      }
    end

    local function restore_state(state)
      if vim.api.nvim_buf_is_valid(state.buf) and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_set_buf(state.win, state.buf)
        vim.api.nvim_set_current_win(state.win)
        vim.fn.setpos(".", state.pos)

        if state.selection then
          vim.fn.setpos("'<", state.selection.start_pos)
          vim.fn.setpos("'>", state.selection.end_pos)
        end
      end
    end

    local was_claude_initially_connected = fn.is_claude_connected()
    local saved_state = save_state()

    -- Exit visual mode if needed
    if saved_state.selection ~= nil then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
    end

    vim.cmd("ClaudeCode")

    -- Wait for Claude connection before sending content
    local function wait_for_claude_connection(callback)
      local start_time = vim.uv.hrtime()
      local timeout_ns = 10 * 1000 * 1000 * 1000 -- 10 seconds
      local check_interval = 100 -- ms

      local function check_connection()
        local elapsed = vim.uv.hrtime() - start_time

        if fn.is_claude_connected() then
          -- Longer delay if this was a fresh connection
          local delay = was_claude_initially_connected and 100 or 500
          vim.defer_fn(callback, delay)
          return
        end

        if elapsed > timeout_ns then
          vim.notify("[ClaudeCode] Connection timeout", vim.log.levels.ERROR)
          return
        end

        vim.defer_fn(check_connection, check_interval)
      end

      check_connection()
    end

    wait_for_claude_connection(function()
      restore_state(saved_state)

      if saved_state.mode == "v" or saved_state.mode == "V" then
        vim.defer_fn(function()
          vim.cmd("ClaudeCodeSend")
          vim.defer_fn(function() vim.cmd("ClaudeCodeFocus") end, 10)
        end, 10)
      else
        vim.cmd("ClaudeCodeAdd %")
        vim.cmd("ClaudeCodeFocus")
      end
    end)
  end
end

-- External API functions

function M.focus()
  if CCProvider then CCProvider.focus() end
end

---@return boolean
function M.hide_active()
  if fn.is_claude_active() and CCProvider then
    CCProvider.close()
    return true
  end
  return false
end

---@param bufid integer?
---@return boolean
function M.is_diff_active(bufid)
  bufid = bufid or vim.api.nvim_get_current_buf()
  return vim.b[bufid].claudecode_diff_tab_name ~= nil
end

---@param tabid integer
---@return boolean
function M.is_diff_tab(tabid)
  local tab_wins = vim.api.nvim_tabpage_list_wins(tabid)
  for _, win in ipairs(tab_wins) do
    local bufid = vim.api.nvim_win_get_buf(win)
    if vim.b[bufid].claudecode_diff_tab_name ~= nil then return true end
  end
  return false
end

---@param path string
function M.add_file(path)
  local ok, claudecode = pcall(require, "claudecode")
  if ok and claudecode.send_at_mention then claudecode.send_at_mention(path) end
end

if not vim.g.started_by_firenvim then
  CCProvider = require("config.claudecode-provider").init({
    layout = {
      default = "side",
      side = {
        position = "right",
        width = 0.3,
      },
      float = {
        width = 0.6,
        height = 0.8,
        backdrop = false,
        border = "rounded",
      },
      common = {
        wo = {
          winbar = "",
          winhighlight = "Normal:SnacksTerminal,FloatBorder:SnacksTerminalFloatBorder,WinBar:SnacksTerminalHeader,WinBarNC:SnacksTerminalHeaderNC",
        },
        keys = {
          claude_new_line = {
            "<S-CR>",
            function() fn.new_line() end,
            mode = "t",
            desc = "New line",
          },
          claude_hide = {
            "<Esc>",
            function(self) self:hide() end,
            mode = "t",
            desc = "Hide Claude",
          },
        },
      },
    },
  })
end

return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  cond = not vim.g.started_by_firenvim,
  event = "VeryLazy",
  keys = function()
    return {
      -- Side panel toggles
      {
        "<leader>cc",
        function() CCProvider.open_on_side() end,
        mode = { "n", "i", "t", "v" },
        desc = "Toggle Claude (side)",
      },
      -- Float window toggles
      {
        "<leader>cf",
        function() CCProvider.open_float() end,
        mode = { "n", "i", "t", "v" },
        desc = "Toggle Claude (float)",
      },
      -- Continue previous session
      {
        "<leader>cC",
        function() CCProvider.open_on_side("continue") end,
        mode = { "n", "i", "t", "v" },
        desc = "Continue Claude session",
      },
      -- Resume session (pick from history)
      {
        "<leader>cr",
        function() CCProvider.open_on_side("resume") end,
        mode = { "n", "i", "t", "v" },
        desc = "Resume Claude session",
      },
      -- Post content and focus
      {
        "<leader>cp",
        fn.post_and_focus,
        mode = { "n", "i", "v" },
        desc = "Post to Claude and focus",
      },
      -- Add current buffer
      {
        "<leader>cb",
        "<cmd>ClaudeCodeAdd %<cr>",
        mode = "n",
        desc = "Add buffer to Claude",
      },
      -- Send visual selection
      {
        "<leader>cs",
        "<cmd>ClaudeCodeSend<cr>",
        mode = "v",
        desc = "Send selection to Claude",
      },
      -- Diff management
      {
        "<leader>ca",
        fn.accept_diff,
        mode = { "n", "i", "v" },
        desc = "Accept Claude diff",
      },
      {
        "<leader>cd",
        fn.reject_diff,
        mode = { "n", "i", "v" },
        desc = "Reject Claude diff",
      },
      -- Toggle layout (side <-> float)
      {
        "<leader>ct",
        CCProvider.toggle_layout,
        mode = { "n", "i", "t", "v" },
        desc = "Toggle Claude layout",
      },
      -- Focus Claude terminal
      {
        "<leader>cf",
        function() CCProvider.focus() end,
        mode = "n",
        desc = "Focus Claude",
      },
      -- Tree/Oil file addition
      {
        "<leader>cs",
        "<cmd>ClaudeCodeTreeAdd<cr>",
        desc = "Add file to Claude",
        ft = { "NvimTree", "neo-tree", "oil" },
      },
    }
  end,
  opts = {
    -- terminal = {
    --   provider = CCProvider,
    -- },
    diff_opts = {
      layout = "vertical",
      open_in_new_tab = true,
      keep_terminal_focus = false,
      hide_terminal_in_new_tab = true,
      on_new_file_reject = "close_window",
    },
  },
  config = function(_, opts)
    require("claudecode").setup(opts)

    -- Expose module functions globally for statusline/other integrations
    _G.ClaudeCode = M
  end,
}
