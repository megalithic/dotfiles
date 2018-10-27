#!/usr/bin/env zsh

# :: le prompte
NEWLINE=$'\n'
PROMPT_SYMBOL="❯"
PROMPT_VICMD_SYMBOL="❮"
PROMPT_BACKGROUND_SYMBOL="☉"
VCS_STAGED_SYMBOL="●"
VCS_UNSTAGED_SYMBOL="✚"

setopt prompt_subst
# autoload -U colors && colors # this is happening in colors.zsh
# autoload -U promptinit; promptinit # might not be needed?
autoload -Uz vcs_info

zstyle ':vcs_info:*' enable git svn
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' check-for-staged-changes true
zstyle ':vcs_info:*' stagedstr " %{$fg[green]%}$VCS_STAGED_SYMBOL%{$reset_color%}"
zstyle ':vcs_info:*' unstagedstr " %{$fg[red]%}$VCS_UNSTAGED_SYMBOL%{$reset_color%}"
zstyle ':vcs_info:git*' formats "[%{$fg[magenta]%}%b%{$reset_color%}%a%m%u%c]"
zstyle ':vcs_info:git' actionformats '%{%F{cyan}%}%45<…<%R%<</%{%f%}%{%F{red}%}(%a|%m)%{%f%}%{%F{cyan}%}%S%{%f%}%c%u'
zstyle ':vcs_info:git:*' patch-format '%10>…>%p%<< (%n applied)'
zstyle ':vcs_info:*+set-message:*' hooks home-path

precmd() {
  vcs_info
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
# TRAPWINCH() {
#   zle && zle -R
# }

PROMPT='${NEWLINE}$(prompt_path) ${vcs_info_msg_0_} $(background_process_indicator)${NEWLINE}${return_status} '
