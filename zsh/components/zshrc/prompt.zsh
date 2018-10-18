#!/usr/bin/env zsh

# pure'ish prompt

NEWLINE=$'\n'
PROMPT_SYMBOL="❯"
PROMPT_VICMD_SYMBOL="❮"
PROMPT_BACKGROUND_SYMBOL="ﱦ"

setopt prompt_subst
autoload -U colors && colors
autoload -U promptinit; promptinit
autoload -Uz vcs_info

zstyle ':vcs_info:*' enable git svn
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' check-for-staged-changes true
zstyle ':vcs_info:git*' formats "[%{$fg[magenta]%}%b%{$reset_color%}%a%m%u%c]"
zstyle ':vcs_info:*' stagedstr " %{$fg[green]%}●%{$reset_color%}"
zstyle ':vcs_info:*' unstagedstr " %{$fg[red]%}✚%{$reset_color%}"

precmd() {
  vcs_info
}

# highlights the prompt_symbol on error
exit_code_prompt_symbol() {
  local last_exit_code=$?
  local exit_code_prompt=''

  if [[ $last_exit_code -ne 0 ]]; then
    exit_code_prompt+="%{$fg_bold[red]%}$PROMPT_SYMBOL%{$reset_color%}"
  else
    exit_code_prompt+="%{$fg[green]%}$PROMPT_SYMBOL%{$reset_color%}"
  fi

  echo "$exit_code_prompt"
}

# returns a more preferred truncated path
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

# returns a fancy indicator when there are running background jobs
background_process_indicator() {
  local background_indicator=''
  [[ $(jobs -l | wc -l) -gt 0 ]] && background_indicator="$PROMPT_BACKGROUND_SYMBOL"

  echo "$background_indicator"
}

# TODO: alter the PURE_PROMPT_SYMBOL when we're in normal mode vs. insert mode
# build_prompt_symbol() {
#   # prompt_parts+=(${${KEYMAP/vicmd/${PURE_PROMPT_VICMD_SYMBOL:-❮}}/(main|viins)/${PURE_PROMPT_SYMBOL:-❯}})
#   prompt_parts+="${PROMPT_SYMBOL}"
# }

# construct our prompt
PROMPT='${NEWLINE}'
PROMPT+='$(prompt_path) ${vcs_info_msg_0_} $(background_process_indicator)'
PROMPT+='${NEWLINE}'
PROMPT+='$(exit_code_prompt_symbol) '
