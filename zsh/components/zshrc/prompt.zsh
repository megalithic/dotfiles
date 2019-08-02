#!/usr/bin/env zsh

# :: le prompt symbols n such
NEWLINE=$'\n'
PROMPT_SYMBOL="❯"
PROMPT_VICMD_SYMBOL="%F{244}❮%{$reset_color%}"
PROMPT_BACKGROUND_SYMBOL="❯"
VCS_STAGED_SYMBOL=$'\uf067'
VCS_UNSTAGED_SYMBOL=$'\ufbc2'
VCS_UNTRACKED_SYMBOL="?" # …
VCS_STASHES_SYMBOL=$'\uf530'
VCS_AHEAD_SYMBOL="↑"
VCS_BEHIND_SYMBOL="↓"

# :: load gitstatus
# DERIVED FROM: https://github.com/romkatv/gitstatus/blob/master/gitstatus.prompt.zsh
# Sets GITSTATUS_PROMPT to reflect the state of the current git repository (empty if not
# in a git repository).
source "$DOTS/zsh/components/zshrc/gitstatus/gitstatus.plugin.zsh"
function gitstatus_prompt_update() {
  emulate -L zsh
  typeset -g GITSTATUS_PROMPT=""

  # Call gitstatus_query synchronously. Note that gitstatus_query can also be called
  # asynchronously; see documentation in gitstatus.plugin.zsh.
  gitstatus_query MY                  || return 1  # error
  [[ $VCS_STATUS_RESULT == ok-sync ]] || return 0  # not a git repo

  local     reset='%f'       # no foreground
  local     clean='%F{243}'  # gray foreground
  local untracked='%F{252}'  # white foreground
  local  modified='%F{130}'  # brown foreground

  local p
  if (( VCS_STATUS_HAS_STAGED || VCS_STATUS_HAS_UNSTAGED )); then
    p+=$modified
  elif (( VCS_STATUS_HAS_UNTRACKED )); then
    p+=$untracked
  else
    p+=$clean
  fi
  p+="${clean}[${p}${${VCS_STATUS_LOCAL_BRANCH:-@${VCS_STATUS_COMMIT}}//\%/%%}${clean}] "            # escape %

  [[ -n $VCS_STATUS_TAG               ]] && p+="#${VCS_STATUS_TAG//\%/%%}"  # escape %
  [[ $VCS_STATUS_HAS_STAGED      == 1 ]] && p+="${modified}$VCS_STAGED_SYMBOL"
  [[ $VCS_STATUS_HAS_UNSTAGED    == 1 ]] && p+="${modified}$VCS_UNSTAGED_SYMBOL"
  [[ $VCS_STATUS_HAS_UNTRACKED   == 1 ]] && p+="${untracked}$VCS_UNTRACKED_SYMBOL"
  [[ $VCS_STATUS_COMMITS_AHEAD  -gt 0 ]] && p+="${clean} $VCS_AHEAD_SYMBOL${VCS_STATUS_COMMITS_AHEAD}"
  [[ $VCS_STATUS_COMMITS_BEHIND -gt 0 ]] && p+="${clean} $VCS_BEHIND_SYMBOL${VCS_STATUS_COMMITS_BEHIND}"
  [[ $VCS_STATUS_STASHES        -gt 0 ]] && p+="${clean} $VCS_STASHES_SYMBOL${VCS_STATUS_STASHES}"

  GITSTATUS_PROMPT="${reset}${p}${reset}"
}

# Start gitstatusd instance with name "MY". The same name is passed to
# gitstatus_query in gitstatus_prompt_update.
gitstatus_stop MY && gitstatus_start MY

# On every prompt, fetch git status and set GITSTATUS_PROMPT.
autoload -Uz add-zsh-hook
add-zsh-hook precmd gitstatus_prompt_update

# Enable/disable the correct prompt expansions.
setopt nopromptbang prompt{percent,subst}

precmd() {
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
PROMPT='${NEWLINE}$(prompt_path) $GITSTATUS_PROMPT${NEWLINE}$(background_process_indicator)${return_status_prompt} '
