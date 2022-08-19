-- NOTE:
-- This plugin is meant to work with the tmux-navigate tmux navigation plugin.
--

if not vim.env.TMUX then return end

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

  return string.format("%s%s%s%s", can_go_up, can_go_down, can_go_left, can_go_right)
end

vim.opt.titlestring =
  [[%{substitute($VIM, '.*[/\\]', '', '')} %{fnamemodify(getcwd(), ":t")} #%{v:lua.Tmux_navigate_directions()}]]
vim.opt.title = true

vim.cmd([[
" enable support for setting the window title in regular Vim under tmux
if &term =~ '^screen' && !has('nvim')
  execute "set t_ts=\e]2; t_fs=\7"
endif
]])

-- FIXME: ensure this vim.cmd is no longer needed and kill it
-- Original vimscript implementation from tmux-navigate
vim.cmd([[
"
" Intelligently navigate tmux panes and Vim splits using the same keys.
" This also supports SSH tunnels where Vim is running on a remote host.
"
" See https://sunaku.github.io/tmux-select-pane.html for documentation.
" let progname = substitute($VIM, '.*[/\\]', '', '')
" set title titlestring=%{progname}\ %f\ #%{TmuxNavigateDirections()}

function! TmuxNavigateDirections() abort
  let [y, x] = win_screenpos('.')
  let h = winheight('.')
  let w = winwidth('.')

  let can_go_up    = y > 2 " +1 for the tabline
  let can_go_down  = y + h < &lines - &laststatus
  let can_go_left  = x > 1
  let can_go_right = x + w < &columns

  return (can_go_up    ? 'U' : '') . (can_go_down  ? 'D' : '') . (can_go_left  ? 'L' : '') . (can_go_right ? 'R' : '')
endfunction

" enable support for setting the window title in regular Vim under tmux
if &term =~ '^screen' && !has('nvim')
  execute "set t_ts=\e]2; t_fs=\7"
endif
]])
