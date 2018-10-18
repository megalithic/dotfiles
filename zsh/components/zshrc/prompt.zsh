#!/usr/bin/env zsh

# :: le prompte
NEWLINE=$'\n'
PROMPT_SYMBOL="❯"
PROMPT_VICMD_SYMBOL="❮"
PROMPT_BACKGROUND_SYMBOL="☉"
VCS_STAGED_SYMBOL="●"
VCS_UNSTAGED_SYMBOL="✚"

setopt prompt_subst
autoload -U colors && colors
autoload -U promptinit; promptinit
autoload -Uz vcs_info

zstyle ':vcs_info:*' enable git svn
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' check-for-staged-changes true
zstyle ':vcs_info:git*' formats "[%{$fg[magenta]%}%b%{$reset_color%}%a%m%u%c]"
zstyle ':vcs_info:*' stagedstr " %{$fg[green]%}$VCS_STAGED_SYMBOL%{$reset_color%}"
zstyle ':vcs_info:*' unstagedstr " %{$fg[red]%}$VCS_UNSTAGED_SYMBOL%{$reset_color%}"

precmd() {
  vcs_info
}

# determines which prompt symbol to use (based on vicmd conditions)
prompt_symbol() {
  echo "${${KEYMAP/vicmd/$PROMPT_VICMD_SYMBOL}/(main|viins)/$PROMPT_SYMBOL}"
}

# highlights the prompt_symbol on error..
exit_code_prompt_symbol() {
  local last_exit_code=$?
  local exit_code_prompt=''
  local symbol="$(prompt_symbol)"

  if [[ $last_exit_code -ne 0 ]]; then
    exit_code_prompt+="%{$fg[red]%}$symbol%{$reset_color%}"
  else
    exit_code_prompt+="%{$fg[green]%}$symbol%{$reset_color%}"
  fi

  echo "$exit_code_prompt"
}

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

# construct our prompt..
# NOTE: must do it here so the vicmd tings take effect; what magic?!
# NOTE part deux: you gotta keep all those zle tings together; DO NOT DELETE!
function zle-line-init zle-keymap-select {
  PROMPT='${NEWLINE}'
  PROMPT+='$(prompt_path) ${vcs_info_msg_0_} $(background_process_indicator)'
  PROMPT+='${NEWLINE}'
  PROMPT+='$(exit_code_prompt_symbol) '

  zle reset-prompt
}
zle -N zle-line-init
zle -N zle-keymap-select



