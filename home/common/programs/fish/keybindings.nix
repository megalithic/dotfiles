# Fish shell keybindings (loaded in interactiveShellInit)
''
  # Keep prompt at bottom of terminal
  _prompt_move_to_bottom

  # Use ntfy for fish-done plugin notifications
  set -g __done_notification_command 'ntfy send -t "$title" -m "$message" &'

  # Cursor styles
  set fish_cursor_default     block      blink
  set fish_cursor_insert      line       blink
  set fish_cursor_replace_one underscore blink
  set fish_cursor_visual      underscore blink

  # Line navigation
  bind -M insert ctrl-a beginning-of-line
  bind -M normal ctrl-a beginning-of-line
  bind -M default ctrl-a beginning-of-line

  bind -M insert ctrl-e end-of-line
  bind -M normal ctrl-e end-of-line
  bind -M default ctrl-e end-of-line

  # Accept autosuggestion
  bind -M insert ctrl-y accept-autosuggestion
  bind -M normal ctrl-y accept-autosuggestion
  bind -M default ctrl-y accept-autosuggestion

  # Edit command in $EDITOR
  bind -M insert ctrl-v edit_command_buffer
  bind ctrl-v edit_command_buffer

  # Rerun previous command
  bind -M insert ctrl-s 'commandline $history[1]' 'commandline -f execute'

  # Restore old ctrl+c behavior (don't clear line)
  # https://github.com/fish-shell/fish-shell/issues/11327
  bind -M insert -m insert ctrl-c cancel-commandline

  # FZF widgets
  bind -M insert ctrl-d fzf-dir-widget
  bind -M normal ctrl-d fzf-dir-widget
  bind -M default ctrl-d fzf-dir-widget

  bind -M insert ctrl-b fzf-jj-bookmarks
  bind -M normal ctrl-b fzf-jj-bookmarks
  bind -M default ctrl-b fzf-jj-bookmarks

  bind -M insert ctrl-o fzf-vim-widget
  bind -M normal ctrl-o fzf-vim-widget
  bind -M default ctrl-o fzf-vim-widget

  # Bang shortcuts for `!!` and `!$`
  bind ! bind_bang
  bind '$' bind_dollar
''
