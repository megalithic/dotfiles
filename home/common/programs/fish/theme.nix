# Fish shell theme - Everforest
''
  # Everforest color palette
  set -l foreground d3c6aa
  set -l selection 2d4f67
  set -l comment 859289
  set -l red e67e80
  set -l orange ff9e64
  set -l yellow dbbc7f
  set -l green a7c080
  set -l purple d699b6
  set -l cyan 7fbbb3
  set -l pink d699b6

  # Syntax Highlighting Colors
  set -g fish_color_normal $foreground
  set -g fish_color_command $cyan
  set -g fish_color_keyword $pink
  set -g fish_color_quote $yellow
  set -g fish_color_redirection $foreground
  set -g fish_color_end $orange
  set -g fish_color_error $red
  set -g fish_color_param $purple
  set -g fish_color_comment $comment
  set -g fish_color_selection --background=$selection
  set -g fish_color_search_match --background=$selection
  set -g fish_color_operator $green
  set -g fish_color_escape $pink
  set -g fish_color_autosuggestion $comment

  # Completion Pager Colors
  set -g fish_pager_color_progress $comment
  set -g fish_pager_color_prefix $cyan
  set -g fish_pager_color_completion $foreground
  set -g fish_pager_color_description $comment

  # Darker background settings
  set -g fish_color_host_remote d699b6
  set -g fish_color_host 7fbbb3
  set -g fish_color_cancel e67e80
  set -g fish_pager_color_prefix 7fbbb3
  set -g fish_pager_color_completion d3c6aa
  set -g fish_pager_color_description 6c7b77
  set -g fish_pager_color_progress 7fbbb3

  # Prompt colors
  set -g fish_color_cwd_root e67e80
  set -g fish_color_user 7fbbb3
''
