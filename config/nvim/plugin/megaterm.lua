-- @attribution: this initially was a blend of several basic and complicated term
-- plugin ideas; ultimately, I've taken many brilliant ideas from @akinsho and @kassio
-- and created my own version for my specific needs. they are the real ones here.

if not mega then return end
if not vim.g.enabled_plugin["megaterm"] then return end

local directionsMap = {
  vertical = "vsplit",
  horizontal = "split",
}
local term = nil
local next = next

local exec = function(cmd, cfg, termCfg)
  local opts = {
    on_exit = callbacks.bind_on_exit(termCfg),
  }
  if cfg.env and next(cfg.env) then opts.env = cfg.env end
  if cfg.working_directory and #cfg.working_directory > 0 then opts.cwd = cfg.working_directory end
  return vim.fn.termopen(cmd, opts)
end

return function(cmd, cfg, termCfg)
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
