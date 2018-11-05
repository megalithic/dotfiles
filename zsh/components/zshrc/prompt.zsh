#!/usr/bin/env zsh

# :: le prompte
NEWLINE=$'\n'
PROMPT_SYMBOL="❯"
PROMPT_VICMD_SYMBOL="❮"
PROMPT_BACKGROUND_SYMBOL="☉"
VCS_STAGED_SYMBOL="✱"
VCS_UNSTAGED_SYMBOL="✚"
VCS_UNTRACKED_SYMBOL="…"
VCS_AHEAD_SYMBOL="↑" # ⇡↑
VCS_BEHIND_SYMBOL="↓" # ⇡↓

setopt prompt_subst
autoload -Uz vcs_info

zstyle ':vcs_info:*' enable git hg
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' check-for-staged-changes true
zstyle ':vcs_info:*' stagedstr "%{$fg[green]%}$VCS_STAGED_SYMBOL%{$reset_color%}"
zstyle ':vcs_info:*' unstagedstr "%{$fg[red]%}$VCS_UNSTAGED_SYMBOL%{$reset_color%}"
zstyle ':vcs_info:git*' formats "%F{245}[%F{130}%b%{$reset_color%}%a%m%u%c%F{245}]%{$reset_color%}"
zstyle ':vcs_info:git' actionformats '%{%F{cyan}%}%45<…<%R%<</%{%f%}%{%F{red}%}(%a|%m)%{%f%}%{%F{cyan}%}%S%{%f%}%c%u'
zstyle ':vcs_info:git:*' patch-format '%10>…>%p%<< (%n applied)'
zstyle ':vcs_info:git+post-backend:*' hooks git-post-backend-updown
zstyle ':vcs_info:git*+set-message:*' hooks git-untracked

# NOTE: suggested by osse on #zsh@freenode (presently not working though):
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

# TODO: need to figure out how to execute this every (n) seconds
fetch_upstream() {
  command git -c gc.auto=0 fetch 2>/dev/null &
	wait $! || return $fail_code
}

ASYNC_PROC=0
ASYNC_DATA="${TMPPREFIX}-prompt_megalithic"
precmd() {
  function async() {
    fetch_upstream
    vcs_info
    # save to temp file
    printf "%s" "${vcs_info_msg_0_}" > $ASYNC_DATA
    # signal parent
    kill -s USR1 $$
  }

  # do not clear PROMPT, let it persist
  # kill child if necessary
  if [[ "${ASYNC_PROC}" != 0 ]]; then
    kill -s HUP $ASYNC_PROC >/dev/null 2>&1 || :
  fi
  # start background computation
  async &!
  ASYNC_PROC=$!
}

TRAPUSR1() {
  # read from temp file
  PROMPT='${NEWLINE}$(prompt_path) $(cat $ASYNC_DATA) $(background_process_indicator)${NEWLINE}${return_status} '
  # reset proc number
  ASYNC_PROC=0
  # redisplay
  zle && zle reset-prompt
}

# ASYNC_PROC=0
# precmd() {
#   # TODO: need to figure out how to execute this every (n) seconds
#   async() {
#     # save to temp file
#     printf "%s" "$(fetch_upstream)" > "${HOME}/.zsh_tmp_prompt"

#     # signal parent
#     kill -s USR1 $$
#   }

#   # do not clear RPROMPT, let it persist

#   # kill child if necessary
#   if [[ "${ASYNC_PROC}" != 0 ]]; then
#     kill -s HUP $ASYNC_PROC >/dev/null 2>&1 || :
#   fi

#   # start background computation
#   async &!
#   ASYNC_PROC=$!

#   # vcs_info
#   # zle && zle .reset-prompt
# }

# TRAPUSR1() {
#   vcs_info
#   # read from temp file
#   # RPROMPT="$(cat ${HOME}/.zsh_tmp_prompt)"

#   # reset proc number
#   ASYNC_PROC=0

#   # redisplay
#   zle && zle reset-prompt
#   # zle && zle .reset-prompt
# }

# returns a more preferred truncated path..
prompt_path() {
  local prompt_path=''
  local pwd="${PWD/#$HOME/~}"
  if [[ "$pwd" == (#m)[/~] ]]; then
    prompt_path="~"
  else
    prompt_path="%{$fg[blue]%}${${${(@j:/:M)${(@s:/:)pwd}##.#?}:h}%/}/${pwd:t}%{$reset_color%}"
  fi

  echo "$prompt_path"
}

# returns a fancy indicator when there are running background jobs..
background_process_indicator() {
  local background_indicator=''
  [[ $(jobs -l | wc -l) -gt 0 ]] && background_indicator="%{$fg[green]%}$PROMPT_BACKGROUND_SYMBOL%{$reset_color%}"

  echo "$background_indicator"
}

# handle vi-mode / prompt_symbol / return code switching..
function zle-line-init zle-keymap-select {
  # We keep the prompt as a single var, so that reset-prompt redraws the whole thing
  local prompt_char="${${KEYMAP/vicmd/$PROMPT_VICMD_SYMBOL}/(main|viins)/$PROMPT_SYMBOL}"

  # Make prompt_char red if the last executed command failed. This needs to be
  # here because outside the function body, precedence breaks it.
  return_status="%(?:%{$fg[green]%}$prompt_char:%{$fg[red]%}$prompt_char)"
  zle && zle .reset-prompt
}
zle -N zle-line-init
zle -N zle-keymap-select

# Redraw prompt when terminal size changes
TRAPWINCH() {
  zle && zle -R
}

# source "$DOTS/zsh/components/zshrc/async-git-prompt.plugin.zsh"

# PROMPT='${NEWLINE}$(prompt_path) ${vcs_info_msg_0_} $(background_process_indicator)${NEWLINE}${return_status} '
PROMPT=''
