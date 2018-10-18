#!/usr/bin/env zsh

# prompt
setopt prompt_subst
autoload -U colors && colors
autoload -U promptinit; promptinit
autoload -Uz vcs_info

zstyle ':vcs_info:*' enable git svn
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:git*' formats "[%{$fg[magenta]%}%b%{$reset_color%}%a%m%u%c]"
zstyle ':vcs_info:*' stagedstr " %{$fg[green]%}●%{$reset_color%}"
zstyle ':vcs_info:*' unstagedstr " %{$fg[red]%}✚%{$reset_color%}"
precmd() {
  vcs_info
}

# highlights the timestamp on error
function check_last_exit_code() {
  local LAST_EXIT_CODE=$?
  local EXIT_CODE_PROMPT=' '
  if [[ $LAST_EXIT_CODE -ne 0 ]]; then
    EXIT_CODE_PROMPT+="%{$fg[red]%}(%{$reset_color%}"
    EXIT_CODE_PROMPT+="%{$fg_bold[red]%}$LAST_EXIT_CODE%{$reset_color%}"
    EXIT_CODE_PROMPT+="%{$fg[red]%}) %t%{$reset_color%}"
  else
    EXIT_CODE_PROMPT+="%{$fg[green]%}%t%{$reset_color%}"
  fi

  echo "$EXIT_CODE_PROMPT"
}

_newline=$'\n'
_lineup=$'\e[1A'
_linedown=$'\e[1B'

PROMPT_SYMBOL="❯"

PROMPT='${_newline}%{$fg[blue]%}%2/%{$reset_color%} ${vcs_info_msg_0_}${_newline}${PROMPT_SYMBOL} '
# RPROMPT='%{${_lineup}%}$(check_last_exit_code)%{${_linedown}%}'
