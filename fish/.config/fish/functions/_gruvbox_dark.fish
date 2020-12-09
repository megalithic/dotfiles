function _gruvbox_dark -d "Set colortheme to gruvbox dark"
  kitty @ --to unix:/tmp/kitty set-colors --reset

  set -eU termTheme

  set fish_color_normal ebdbb2
  set fish_color_command fbf1c7 bold
  set fish_color_quote 98971a
  set fish_color_end d3869b
  set fish_color_error cc241d
  set fish_color_param a89984
  set fish_color_comment 689d6a
  set fish_color_match 458588
  set fish_color_selection d79921
  set fish_color_search_match d65d0e
  set fish_color_operator b16286
  set fish_color_escape a89984
  set fish_color_cwd 789d6a
  set fish_color_autosuggestion 8ec07c
  set fish_color_user b8bb26
  set fish_color_host d6c4a1
  set fish_color_host_remote b8bb26
  set fish_color_cancel cc241d
  set fish_pager_color_background d79921
end
