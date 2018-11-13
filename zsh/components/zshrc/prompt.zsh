#!/usr/bin/env zsh

# :: le prompte
NEWLINE=$'\n'
PROMPT_SYMBOL="❯"
PROMPT_VICMD_SYMBOL="%F{244}❮%{$reset_color%}"
PROMPT_BACKGROUND_SYMBOL="❯" # 
VCS_STAGED_SYMBOL="✱"
VCS_UNSTAGED_SYMBOL="✚"
VCS_UNTRACKED_SYMBOL="?" # …
VCS_AHEAD_SYMBOL="↑"
VCS_BEHIND_SYMBOL="↓"

# :: settings for softmoth/zsh-vim-mode
unset MODE_CURSOR_DEFAULT
TMUX_PASSTHROUGH=1
MODE_CURSOR_VICMD="#E6EEF3 block"
MODE_CURSOR_VIINS="#A8CE93 blinking bar"
MODE_CURSOR_SEARCH="#D18EC2 steady underline"

setopt prompt_subst
autoload -Uz vcs_info

zstyle ':vcs_info:*' enable git hg
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' check-for-staged-changes true
zstyle ':vcs_info:*' stagedstr "%{$fg[green]%}$VCS_STAGED_SYMBOL%{$reset_color%}"
zstyle ':vcs_info:*' unstagedstr "%{$fg[red]%}$VCS_UNSTAGED_SYMBOL%{$reset_color%}"
zstyle ':vcs_info:git*' formats "%F{245}[%F{130}%b%{$reset_color%}%F{245}] %a%m%u%c%{$reset_color%}"
zstyle ':vcs_info:git' actionformats '%{%F{cyan}%}%45<…<%R%<</%{%f%}%{%F{red}%}(%a|%m)%{%f%}%{%F{cyan}%}%S%{%f%}%c%u'
zstyle ':vcs_info:git:*' patch-format '%10>…>%p%<< (%n applied)'
zstyle ':vcs_info:git+post-backend:*' hooks git-post-backend-updown
zstyle ':vcs_info:git*+set-message:*' hooks git-untracked

# NOTE: suggested by osse on irc.freenode.net#zsh (presently not working though):
# zstyle ':vcs_info:git*+set-message:*' hooks git-conditionally-add-space-to-branch
# +vi-git-conditionally-add-space-to-branch() { 
#   hook_com[branch]+="${hook_com[branch]:+}"
# }

+vi-git-post-backend-updown() {
  git rev-parse @{upstream} >/dev/null 2>&1 || return

  local -a x; x=( $(git rev-list --left-right --count HEAD...@{upstream} ) )
  hook_com[branch]+="%f" # end coloring
  (( x[2] )) && hook_com[branch]+=" $VCS_BEHIND_SYMBOL$x[2]"
  (( x[1] )) && hook_com[branch]+=" $VCS_AHEAD_SYMBOL$x[1]"
  return 0
}

+vi-git-untracked() {
  if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]] && \
     git status --porcelain | grep -m 1 '^??' &>/dev/null
  then
    hook_com[misc]="$VCS_UNTRACKED_SYMBOL"
  fi
}

precmd() {
  vcs_info
  zle && { zle -R; zle reset-prompt }
}

# returns a more preferred truncated path..
prompt_path() {
  local prompt_path=''
  local pwd="${PWD/#$HOME/~}"
  if [[ "$pwd" == (#m)[~] ]]; then # also, if you want both `/` and `~`, then [/~]
    prompt_path="~"
  else
    prompt_path="%{$fg[blue]%}${${${(@j:/:M)${(@s:/:)pwd}##.#?}:h}%/}/${pwd:t}%{$reset_color%}"
  fi

  echo "$prompt_path"
}

# returns a fancy indicator when there are running background jobs..
background_process_indicator() {
  local background_indicator=''
  [[ $(jobs -l | wc -l) -gt 0 ]] && background_indicator="%F{183}$PROMPT_BACKGROUND_SYMBOL%{$reset_color%}"

  echo "$background_indicator"
}

# # handle vi-mode / prompt_symbol / return code switching..
function zle-line-init zle-keymap-select {
  # We keep the prompt as a single var, so that reset-prompt redraws the whole thing
  local prompt_char="${${KEYMAP/vicmd/$PROMPT_VICMD_SYMBOL}/(main|viins)/$PROMPT_SYMBOL}"

  # Make prompt_char red if the last executed command failed. This needs to be
  # here because outside the function body, precedence breaks it.
  return_status_prompt="%(?:%{$fg[green]%}$prompt_char:%{$fg[red]%}$prompt_char)"
  zle && { zle -R; zle reset-prompt }
}
zle -N zle-line-init
zle -N zle-keymap-select

# redraw prompt when terminal size changes
TRAPWINCH() {
  zle && { zle -R; zle reset-prompt }
}

# prompt with red when things go wrong, otherwise, normal color when things are good
prompt_status_symbol() {
  echo "%(?:%{$fg[green]%}$PROMPT_SYMBOL:%{$fg[red]%}$PROMPT_SYMBOL)"
}

# render dat prompt
# PROMPT='${NEWLINE}$(prompt_path) ${vcs_info_msg_0_}${NEWLINE}$(background_process_indicator)$(prompt_status_symbol) '
PROMPT='${NEWLINE}$(prompt_path) ${vcs_info_msg_0_}${NEWLINE}$(background_process_indicator)${return_status_prompt} '
