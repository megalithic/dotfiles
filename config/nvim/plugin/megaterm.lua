-- @attribution: this initially was a blend of several basic and complicated term
-- plugin ideas; ultimately, I've taken many brilliant ideas from @akinsho and @kassio
-- and created my own version for my specific needs. they are the real ones here.

if not mega then return end
if not vim.g.enabled_plugin["megaterm"] then return end

local defaultCfg = {
  env = nil,
  working_directory = nil,
}
local defaultTermCfg = {
  direction = "vertical", -- terminal's direction ("horizontal"|"vertical"|"float")
  width = 96, -- terminal's width (for vertical|float)
  height = 24, -- terminal's height (for horizontal|float)
  go_back = false, -- return focus to original window after executing
  stopinsert = "auto", -- exit from insert mode (true|false|"auto")
  keep_one = true, -- keep only one terminal for testing
}

local directionsMap = {
  vertical = "vsplit",
  horizontal = "split",
}
local term = nil
local next = next

local exec = function(cmd, cfg, termCfg)
  local opts = {
    on_exit = function(termCfg) P("exiting! with custom on_exit") end,
  }
  if cfg.env and next(cfg.env) then opts.env = cfg.env end
  if cfg.working_directory and #cfg.working_directory > 0 then opts.cwd = cfg.working_directory end
  return vim.fn.termopen(cmd, opts)
end

function mega.t(cmd, cfg, termCfg)
  cfg = vim.tbl_deep_extend("force", defaultCfg, cfg or {})
  termCfg = vim.tbl_deep_extend("force", defaultTermCfg, termCfg or {})
  if termCfg.direction == "float" then
    local bufnr = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_open_win(bufnr, true, {
      row = math.ceil(vim.o.lines - termCfg.height) / 2 - 1,
      col = math.ceil(vim.o.columns - termCfg.width) / 2 - 1,
      relative = "editor",
      width = termCfg.width,
      height = termCfg.height,
      style = "minimal",
      border = "single",
    })
    return exec(cmd, cfg, termCfg)
  end

  local split = directionsMap[termCfg.direction]
  if termCfg.direction == "vertical" and termCfg.width then split = termCfg.width .. split end
  if termCfg.direction == "horizontal" and termCfg.height then split = termCfg.height .. split end

  -- Clean buffers
  if termCfg.keep_one and term then
    if vim.fn.bufexists(term) > 0 then vim.api.nvim_buf_delete(term, { force = true }) end
  end

  vim.cmd(string.format("botright %s new", split))
  exec(cmd, cfg, termCfg)
  term = vim.api.nvim_get_current_buf()
end
