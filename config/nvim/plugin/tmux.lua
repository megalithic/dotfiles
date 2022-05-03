--  Intelligently navigate tmux panes and Vim splits using the same keys.
--  This also supports SSH tunnels where Vim is running on a remote host.
--
--  See https://sunaku.github.io/tmux-select-pane.html for documentation.

if vim.env.TMUX ~= nil then
  vim.cmd([[
    let progname = substitute($VIM, '.*[/\\]', '', '')
    set title titlestring=%{progname}\ %f\ #%{TmuxNavigateDirections()}

    function! TmuxNavigateDirections() abort
      let [y, x] = win_screenpos('.')
      let h = winheight('.')
      let w = winwidth('.')

      let can_go_up    = y > 2 " +1 for the tabline
      let can_go_down  = y + h < &lines - &laststatus
      let can_go_left  = x > 1
      let can_go_right = x + w < &columns

      return
            \ (can_go_up    ? 'U' : '') .
            \ (can_go_down  ? 'D' : '') .
            \ (can_go_left  ? 'L' : '') .
            \ (can_go_right ? 'R' : '')
    endfunction
  ]])
end
