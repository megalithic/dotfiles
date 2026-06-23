# Fish shell configuration — managed by mise bootstrap.
# Ported from Home Manager-generated config (home/common/programs/fish/).
# Keep local-only additions in conf.d/local.fish (git-ignored).

# -- shell init (from completions.nix + shellInit) --

# PATH: Brew and user binaries first, system paths follow
fish_add_path --prepend \
  "$HOME/.local/bin" \
  "$HOME/bin" \
  "$DOTS/bin" \
  "$HOME/.cargo/bin" \
  /opt/homebrew/bin \
  /opt/homebrew/sbin

set -g fish_prompt_pwd_dir_length 20

# jj bookmark completion helper
function __fish_jj_bookmarks
  jj bookmark list --template 'if(!remote, name ++ "\n")' 2>/dev/null
end

# jj bookmark completions
complete -c jj -n "__fish_seen_subcommand_from push" -s b -l bookmark -xa "(__fish_jj_bookmarks)" -d "Bookmark"
complete -c jj -n "__fish_seen_subcommand_from git; and __fish_seen_subcommand_from push" -s b -l bookmark -xa "(__fish_jj_bookmarks)" -d "Bookmark"
complete -c jj -n "__fish_seen_subcommand_from bookmark; and __fish_seen_subcommand_from delete d forget f set s move m rename r" -xa "(__fish_jj_bookmarks)" -d "Bookmark name"

# mix task completion helper (project-aware)
function __fish_mix_tasks
  mix help 2>/dev/null | string match -r '^mix \S+' | string replace 'mix ' ""
end

# mix task completions
complete -c mix -xa "(__fish_mix_tasks)"

# Git worktree completions
function __fish_git_pr_branches
  gh pr list --state open --json number,title,author,createdAt,headRefName --limit 50 2>/dev/null | jq -r '.[] | "\(.headRefName)"'
end

complete -c git-worktree-cd -f -a '(__git_worktree_names)' -d 'Worktree'
complete -c git-worktree-new -f -a '(__git_worktree_names)' -d 'Worktree'
complete -c git-worktree-prune -f -a '(__git_worktree_names)' -d 'Worktree'
complete -c git-worktree-pr -f -a '(__fish_git_pr_branches)' -d 'PR branch'

# -- environment (from shellInit) --

set -gx DOTS "$HOME/.dotfiles"
set -gx CODE "$HOME/code"
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx XDG_DATA_HOME "$HOME/.local/share"
set -gx XDG_STATE_HOME "$HOME/.local/state"
set -gx XDG_CACHE_HOME "$HOME/.cache"
set -gx PI_STATE_DIR "$XDG_STATE_HOME/pi"

# PLUG_EDITOR for clickable stacktraces (Phoenix dev / browser devtools).
# Always set — Hammerspoon resolves target nvim instance dynamically at
# click time (file-already-open > active tmux client > most-recent socket).
set -gx PLUG_EDITOR "hammerspoon://nvim-open?file=__FILE__&line=__LINE__"

# Capture tmux session name (consumed by other tools)
if set -q TMUX
  set -gx TMUX_SESSION (tmux display-message -p '#S')
end

# -- interactive shell (from keybindings.nix + theme.nix + plugins) --

status is-interactive; and begin

  # --- abbreviations ---
  abbr --add -- !! 'eval \$history[1]'
  abbr --add -- j just
  abbr --add -- ju just
  abbr --add -- ms 'm s'
  abbr --add -- next 'NVIM_APPNAME=next nvim -O'
  abbr --add -- nvim 'nvim -O'
  abbr --add -- pp 'p --profile'
  abbr --add -- vim 'nvim -O'
  abbr --add -- z zoxide

  # --- aliases ---
  alias !! 'eval \$history[1]'
  alias ,q exit
  alias :Q exit
  alias :e nvim
  alias :q exit
  alias cat bat
  alias clear 'clear && _prompt_move_to_bottom'
  alias copy pbcopy
  alias eza 'eza --icons always --color always --git -lah --group-directories-first --color-scale'
  alias l 'eza --all --long --color=always --color-scale=all --group-directories-first --sort=type --hyperlink --icons=always --octal-permissions'
  alias la 'eza -lahF --group-directories-first --color=always --icons=always --hyperlink'
  alias ll 'eza -lahF --group-directories-first --color=always --icons=always --hyperlink'
  alias lla 'eza -la'
  alias ls 'eza --all --group-directories-first --color=always --hyperlink'
  alias lt 'eza --tree'
  alias mega 'ftm mega'
  alias paste pbpaste
  alias pathi 'echo "$PATH" | tr ":" "\n"'
  alias pic 'pi -c'
  alias pinspect 'echo "$PATH" | tr ":" "\n"'
  alias pir 'pi -r'
  alias pis pinvim
  alias pisock pinvim
  alias q exit
  alias rm 'trash -v'
  alias tree 'eza --tree --color=always'
  alias vimdiff 'nvim -d'

  # --- fzf shell integration (from Brew/Aqua fzf) ---
  fzf --fish | source

  # --- keep prompt at bottom ---
  _prompt_move_to_bottom

  # --- fish-done notifications via ntfy ---
  set -g __done_notification_command 'ntfy send -t "$title" -m "$message" &'

  # --- cursor styles ---
  set fish_cursor_default block blink
  set fish_cursor_insert line blink
  set fish_cursor_replace_one underscore blink
  set fish_cursor_visual underscore blink

  # --- line navigation keybindings ---
  bind -M insert ctrl-a beginning-of-line
  bind -M normal ctrl-a beginning-of-line
  bind -M default ctrl-a beginning-of-line

  bind -M insert ctrl-e end-of-line
  bind -M normal ctrl-e end-of-line
  bind -M default ctrl-e end-of-line

  # accept autosuggestion
  bind -M insert ctrl-y accept-autosuggestion
  bind -M normal ctrl-y accept-autosuggestion
  bind -M default ctrl-y accept-autosuggestion

  # edit command in $EDITOR
  bind -M insert ctrl-v edit_command_buffer
  bind ctrl-v edit_command_buffer

  # rerun previous command
  bind -M insert ctrl-s 'commandline $history[1]' 'commandline -f execute'

  # restore old ctrl+c behavior
  bind -M insert -m insert ctrl-c cancel-commandline

  # --- fzf widgets ---
  bind -M insert ctrl-d fzf-dir-widget
  bind -M normal ctrl-d fzf-dir-widget
  bind -M default ctrl-d fzf-dir-widget

  bind -M insert ctrl-b fzf-jj-bookmarks
  bind -M normal ctrl-b fzf-jj-bookmarks
  bind -M default ctrl-b fzf-jj-bookmarks

  bind -M insert ctrl-o fzf-vim-widget
  bind -M normal ctrl-o fzf-vim-widget
  bind -M default ctrl-o fzf-vim-widget

  # bang shortcuts
  bind ! bind_bang
  bind '$' bind_dollar

  # --- Everforest theme ---
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

  set -g fish_pager_color_progress $comment
  set -g fish_pager_color_prefix $cyan
  set -g fish_pager_color_completion $foreground
  set -g fish_pager_color_description $comment

  set -g fish_color_host_remote d699b6
  set -g fish_color_host 7fbbb3
  set -g fish_color_cancel e67e80
  set -g fish_pager_color_prefix 7fbbb3
  set -g fish_pager_color_completion d3c6aa
  set -g fish_pager_color_description 6c7b77
  set -g fish_pager_color_progress 7fbbb3

  set -g fish_color_cwd_root e67e80
  set -g fish_color_user 7fbbb3

  # --- shell integrations ---

  # Ghostty shell integration (Brew cask path as fallback)
  if set -q GHOSTTY_RESOURCES_DIR
    set -l ghostty_fish_integration "$GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish"
    if test -f "$ghostty_fish_integration"
      source "$ghostty_fish_integration"
    else if test -f "/Applications/Ghostty.app/Contents/Resources/ghostty/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish"
      source "/Applications/Ghostty.app/Contents/Resources/ghostty/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish"
    end
  end

  # worktrunk shell init
  if command -v wt >/dev/null 2>&1
    wt config shell init fish | source
  end

  # zoxide init
  zoxide init fish | source

  # starship prompt
  if test "$TERM" != dumb
    starship init fish | source
  end

  # mise activate
  mise activate fish | source

  # direnv hook
  if not functions -q __direnv_export_eval
    direnv hook fish | source
  end

  # -- fnox secret loading (replaces OpNix) --
  # Sourced from conf.d/fnox.fish

  # -- source conf.d files --
  for file in $XDG_CONFIG_HOME/fish/conf.d/*.fish
    source $file
  end

end
