#!/usr/bin/env zsh

# https://github.com/junegunn/fzf/wiki/Color-schemes#color-configuration
# interactive color picker for fzf themes: https://minsw.github.io/fzf-color-picker/
#
# REF:
# https://github.com/junegunn/fzf/wiki/Configuring-shell-key-bindings
# https://gist.github.com/junegunn/8b572b8d4b5eddd8b85e5f4d40f17236
# https://sourcegraph.com/github.com/junegunn/fzf/-/blob/ADVANCED.md#--height
# https://pragmaticpineapple.com/four-useful-fzf-tricks-for-your-terminal/#4-preview-files-before-selecting-them

# TODO:
# https://www.reddit.com/r/vim/comments/10mh48r/fuzzy_search/
# perf gains to be had here: https://github.com/ranelpadon/configs/blob/master/zshrc/rg_fzf_bat.sh

export FZF_TMUX_HEIGHT='22%'
export FZF_DEFAULT_OPTS="
--inline-info
--select-1
--ansi
--highlight-line
--info=inline-right
--no-border
--reverse
--extended
--bind=ctrl-j:ignore,ctrl-k:ignore
--bind=ctrl-j:down,ctrl-k:up
--bind=ctrl-b:preview-up,ctrl-f:preview-down
--bind=ctrl-u:abort
--bind=esc:abort
--bind=ctrl-c:abort
--bind=?:toggle-preview
--cycle
--preview-window=right:60%
--preview='preview {}'
--margin=0,0
--padding=0,0
--prompt=' '
--pointer=' '
--marker='󰛄 '
--scrollbar='▓'
"
# --tiebreak=index

# alts: 󰛄
# --bind=ctrl-f:page-down,ctrl-b:page-up
# --bind=ctrl-u:preview-up,ctrl-d:preview-down
# --preview='bat --color=always --style=header,grid --line-range :300 {}'
# --no-multi
# --reverse
# --height=22%

_fzf_megaforest() {
  local color00='#323d43'
  local color01='#3c474d'
  local color02='#465258'
  local color03='#505a60'
  local color04='#d8caac'
  local color05='#d5c4a1'
  local color06='#ebdbb2'
  local color07='#fbf1c7'
  local color08='#fb4934'
  local color09='#fe8019'
  local color0A='#fabd2f'
  local color0B='#b8bb26'
  local color0C='#8ec07c'
  local color0D='#83a598'
  local color0E='#d3869b'
  local color0F='#d65d0e'

  # --color=bg+:$color01,spinner:$color0C,hl:$color0A,gutter:$color01
  export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS
--color=bg+:$color01,spinner:$color0C,hl:$color0A,gutter:$color01
--color=fg:$color04,header:$color0D,info:$color0A,pointer:$color0C
--color=marker:$color0E,fg+:$color06,prompt:$color0A,hl+:$color0F
"
}
# ,label:6,query:7,separator:-1

# set -U FZF_DEFAULT_OPTS "--reverse --no-info --prompt=' ' --pointer='' --marker=' ' --ansi --color gutter:-1,bg+:-1,header:4,separator:0,info:0,label:4,border:4,prompt:7,pointer:5,query:7,prompt:7"
# CTRL-/ to toggle small preview window to see the full command
# CTRL-Y to copy the command into clipboard using pbcopy
export FZF_CTRL_R_OPTS="
--header=\"command history [$(tput setaf 255)ctrl-y$(tput sgr 0): $(tput setaf 245)copy to clipboard$(tput sgr 0)]\"
--preview 'echo {}' --preview-window up:3
--bind '?:toggle-preview'
--bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
--color header:italic"
# export FZF_TMUX_OPTS="$FZF_DEFAULT_OPTS" #"-p --no-info --ansi --color gutter:-1,bg+:-1,header:4,separator:0,info:0,label:4,border:4,prompt:7,pointer:5,query:7,prompt:7"

# open fzf in a tmux popup
# export FZF_TMUX_OPTS='-p 45%,50%'

_fzf_megaforest

# FZF_FIND_CMD=find
# if command -v bfs > /dev/null ; then
#   FZF_FIND_CMD=bfs
# fi
#
# FZFCMD="command $FZF_FIND_CMD -L . \
# -name .git -prune -o \
# -name node_modules -prune -o \
# -type d -print -o \
# -type f -print -o \
# -type l -print 2>/dev/null \
# | sed 1d | cut -b3-" 2>/dev/null

if has fd; then
  # LIST_DIR_CONTENTS='ls --almost-all --group-directories-first --color=always {}'
  # LIST_FILE_CONTENTS='head -n128 {}'
  # export FZF_ALT_C_OPTS="--preview '$LIST_DIR_CONTENTS'"
  # export FZF_CTRL_T_OPTS="--preview 'if [[ -f {} ]]; then $LIST_FILE_CONTENTS; elif [[ -d {} ]]; then $LIST_DIR_CONTENTS; fi'"

  # export FZF_DEFAULT_COMMAND='fd --type f --follow --hidden --color=always --ignore-file \"$XDG_CONFIG_HOME/fd/ignore\"'
  export FZF_DEFAULT_COMMAND="fd --type f --follow --hidden --color=always --no-ignore-vcs"
  # export FZF_CTRL_T_OPTS="--with-nth"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND" # | sed 's/^[ \t]*//'"

  export FZF_ALT_C_OPTS="--preview 'exa -T {}' --height=60%"
  # export FZF_ALT_C_COMMAND="fd -t d -d 1"
  # export FZF_ALT_C_COMMAND="fd -I -t d -d 1 --follow --hidden --color=always --no-ignore-vcs --exclude 'Library'"
  # export FZF_ALT_C_COMMAND="fd -I -t d --max-depth 5 --follow --hidden --color=always --no-ignore-vcs --exclude 'Library' | proximity-sort ."
  export FZF_ALT_C_COMMAND="fd --type d --follow --hidden --color=always --no-ignore-vcs --exclude 'Library'"
fi

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
  git) git --help -a | grep -E '^\s+' | awk '{print $1}' | fzf "$@" ;;
  cd) fzf --preview 'tree -C {} | head -200' "$@" ;;
  *) fzf "$@" ;;
  esac
}

# custom-fzf-preview() {
#   choice=$(
#     rg --files --hidden | fzf --cycle --preview="preview --ueberzugpp {}"
#     preview --cleanup
#   )
#   if [ -n "$choice" ]; then
#     printf "\n%s" "$choice"
#     zle accept-line
#   fi
# }
#
# zle -N custom-fzf-preview
#
# bindkey '^!' custom-fzf-preview
