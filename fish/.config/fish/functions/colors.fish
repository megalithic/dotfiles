function colors -d "Set theme (everforest)"
  # COMMAND LINE
  # default color
  set -U fish_color_normal white

  # commands like echo
  set -U fish_color_command brgreen -o

  # keywords like if - this falls back on command color if unset
  set -U fish_color_keyword purple

  # quoted text like "abc"
  set -U fish_color_quote yellow -i

  # IO redirections like >/dev/null
  set -U fish_color_redirection brgreen

  # process separators like ';' and '&'
  set -U fish_color_end purple

  # syntax errors
  set -U fish_color_error

  # ordinary command parameters
  set -U fish_color_param white

  # comments like '# important'
  set -U fish_color_comment brred

  # selected text in vi visual mode
  set -U fish_color_selection orange

  # parameter expansion operators like '*' and '~'
  set -U fish_color_operator yellow

  # character escapes like 'n' and 'x70'
  set -U fish_color_escape yellow

  # autosuggestions (the proposed rest of a command)
  set -U fish_color_autosuggestion brblack

  # the current working directory in the default prompt
  set -U fish_color_cwd

  # the username in the default prompt
  set -U fish_color_user

  # the hostname in the default prompt
  set -U fish_color_host

  # the hostname in the default prompt for remote sessions (like ssh)
  set -U fish_color_host_remote

  # the '^C' indicator on a canceled command
  set -U fish_color_cancel red

  # history search matches and selected pager items (background only)
  set -U fish_color_search_match orange

  # PAGER
  # the progress bar at the bottom left corner
  set -U fish_pager_color_progress green

  # the prefix string, i.e. the string that is to be completed
  set -U fish_pager_color_prefix

  # the completion itself, i.e. the proposed rest of the string
  set -U fish_pager_color_completion magenta

  # the completion description
  set -U fish_pager_color_description yellow

  # background of the selected completion
  set -U fish_pager_color_selected_background bryellow

  # prefix of the selected completion
  set -U fish_pager_color_selected_prefix

  # suffix of the selected completion
  set -U fish_pager_color_selected_completion

  # description of the selected completion
  set -U fish_pager_color_selected_description brblack

  set -U pure_color_mute cyan
end
