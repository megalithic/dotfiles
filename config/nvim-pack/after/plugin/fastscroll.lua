-- after/plugin/fastscroll.lua
-- Reduce rendering overhead during rapid j/k scrolling
--
-- Problem: holding j/k with fast key repeat triggers expensive redraws.
--   - relativenumber: recalculates ALL line numbers every cursor move
--   - snacks.words: LSP reference highlighting on CursorMoved
--   - noice.nvim: UI redraws for cmdline/messages
--   - cursorline: full-line highlight redraw (but needed to track cursor!)
--
-- Solution: disable expensive things during scroll, re-enable after 150ms idle.
-- Keep cursorline ON so the cursor is never "lost".
--
-- Ref: https://github.com/neovim/neovim/issues/14154
--      https://eduncan911.com/software/fix-slow-scrolling-in-vim-and-neovim.html

if not Plugin_enabled() then return end

local timer = vim.uv.new_timer()
local scrolling = false
local saved = {}

local DEBOUNCE_MS = 150

local function enter_fast_scroll()
  if scrolling then return end
  scrolling = true

  -- Flag for other plugins (set first so they can check it)
  vim.g._fast_scrolling = true

  -- Disable relativenumber (forces all line number recalc per move)
  saved.relativenumber = vim.wo.relativenumber
  vim.wo.relativenumber = false

  -- Disable snacks.words (LSP reference highlight on CursorMoved)
  saved.snacks_words = vim.g.snacks_words
  vim.g.snacks_words = false

  -- Disable noice (expensive redraws during scroll)
  local noice_ok, noice = pcall(require, "noice")
  if noice_ok then
    saved.noice = true
    noice.disable()
  end
end

local function exit_fast_scroll()
  if not scrolling then return end
  scrolling = false

  vim.g._fast_scrolling = false

  if saved.relativenumber ~= nil then vim.wo.relativenumber = saved.relativenumber end
  if saved.snacks_words ~= nil then vim.g.snacks_words = saved.snacks_words end

  -- Re-enable noice
  if saved.noice then
    local noice_ok, noice = pcall(require, "noice")
    if noice_ok then noice.enable() end
  end

  saved = {}
end

-- Pre-create the scheduled callback (avoid creating new function on every keypress)
local scheduled_exit = vim.schedule_wrap(exit_fast_scroll)

local function on_scroll_key()
  enter_fast_scroll()
  timer:stop()
  timer:start(DEBOUNCE_MS, 0, scheduled_exit)
end

-- Hook j/k and scroll keys
-- for _, key in ipairs({ "j", "k", "<C-d>", "<C-u>", "<C-f>", "<C-b>" }) do
--   vim.keymap.set("n", key, function()
--     on_scroll_key()
--     return key
--   end, { expr = true, silent = true })
-- end

-- Clean up on window change
-- vim.api.nvim_create_autocmd("WinLeave", {
--   group = vim.api.nvim_create_augroup("mega.fastscroll", { clear = true }),
--   callback = function()
--     if scrolling then
--       timer:stop()
--       exit_fast_scroll()
--     end
--   end,
-- })
