-- lua/lsp/progress.lua
-- LSP progress indicator in bottom-right floating window

local M = {}

local ns = vim.api.nvim_create_namespace("mega.lsp.progress")
local timer = nil  -- Created lazily
local buf = -1
local win = -1

-- Clamp value between min and max
local function clamp(val, min, max)
  return math.floor(math.max(min, math.min(val, max)))
end

-- Truncate text with ellipsis if too long
local function truncate(text, max_width)
  if #text <= max_width then return text end
  local ellipsis = "..."
  local cut = max_width - #ellipsis
  if cut <= 0 then return ellipsis end
  return text:sub(1, cut) .. ellipsis
end

-- Get or create timer (lazy initialization)
local function get_timer()
  if not timer then
    timer = vim.uv.new_timer()
  end
  return timer
end

-- Show progress notification
local function show(lines, hl, keep_ms)
  hl = hl or "Comment"
  keep_ms = keep_ms or 1500

  if vim.tbl_isempty(lines) then return end

  -- Dimensions
  local min_width, min_height = 1, 1
  local max_width = math.floor(vim.o.columns / 3)
  local max_height = vim.o.lines - 5

  local text_width = vim.iter(lines):fold(1, function(max, val)
    return math.max(max, #val)
  end)

  local width = clamp(text_width, min_width, max_width)
  local height = clamp(#lines, min_height, max_height)

  local win_config = {
    relative = "editor",
    anchor = "SE",
    row = vim.o.lines - 2,
    col = vim.o.columns,
    width = width,
    height = height,
    zindex = 100,
    style = "minimal",
    border = "rounded",
    focusable = false,
    noautocmd = true,
  }

  -- Create or reuse buffer
  if not vim.api.nvim_buf_is_valid(buf) then
    buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].filetype = "lsp_progress"
  end

  -- Create or update window
  if not vim.api.nvim_win_is_valid(win) then
    win = vim.api.nvim_open_win(buf, false, win_config)
    vim.wo[win].winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder"
  else
    vim.api.nvim_win_set_config(win, win_config)
  end

  -- Truncate lines to fit window
  local win_width = vim.api.nvim_win_get_width(win)
  local buf_lines = {}
  for _, line in ipairs(lines) do
    table.insert(buf_lines, truncate(line, win_width))
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, buf_lines)
  vim.hl.range(buf, ns, hl, { 0, 0 }, { #buf_lines, -1 })

  -- Auto-close after delay
  local t = get_timer()
  if t and keep_ms > 0 then
    t:stop()
    t:start(keep_ms, 0, function()
      t:stop()
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
      end)
    end)
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("mega.lsp.progress", { clear = true })

  vim.api.nvim_create_autocmd("LspProgress", {
    group = group,
    desc = "Show LSP progress in floating window",
    callback = function()
      -- Get status message, strip leading percentage
      local msg = vim.lsp.status() or ""
      msg = msg:gsub("^%s*%d+%%:%s*", "")

      if msg == "" then return end

      -- Split multiple progress items
      local lines = vim.split(msg, ", ")
      show(lines, "Comment", 1500)
    end,
  })

  -- Clean up timer on VimLeave
  vim.api.nvim_create_autocmd("VimLeave", {
    group = group,
    callback = function()
      if timer then
        timer:stop()
        timer:close()
        timer = nil
      end
    end,
  })
end

return M
