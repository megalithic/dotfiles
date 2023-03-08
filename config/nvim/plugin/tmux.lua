-- NOTE:
-- This plugin is meant to work with the tmux-navigate tmux navigation plugin.
-- REF: maybe try: https://github.com/numToStr/Navigator.nvim
--

if not mega then return end
if not vim.env.TMUX then return end
if not vim.g.enabled_plugin["tmux"] then return end

function Tmux_navigate_directions()
  local pos = vim.api.nvim_win_get_position(0)
  local row = pos[1]
  local col = pos[2]

  local h = vim.api.nvim_win_get_height(0)
  local w = vim.api.nvim_win_get_width(0)

  local can_go_up = (row > 2) and "U" or "" -- +1 if we use the tabline/winbar
  local can_go_down = ((row + h) < (vim.o.lines - vim.o.laststatus)) and "D" or ""
  local can_go_left = (col > 1) and "L" or ""
  local can_go_right = ((col + w) < vim.o.columns) and "R" or ""

  local directions = string.format("%s%s%s%s", can_go_up, can_go_down, can_go_left, can_go_right)
  -- P(directions)
  return directions
end

vim.opt.titlestring =
  [[%{substitute($VIM, '.*[/\\]', '', '')} %{fnamemodify(getcwd(), ":t")} #%{v:lua.Tmux_navigate_directions()}]]

vim.cmd([[
" enable support for setting the window title in regular Vim under tmux
if &term =~ '^screen' && !has('nvim')
  execute "set t_ts=\e]2; t_fs=\7"
endif
]])

-- P(vim.opt.titlestring:get())
