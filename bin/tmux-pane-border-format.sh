#!/bin/bash

# color variables
INACTIVE_BORDER_COLOR='colour237'
ACTIVE_BORDER_COLOR='colour250'
RED='#cc241d'
YELLOW='#fabd2f'
GREEN='#98971a'

# read args
for i in "$@"
do
case $i in
    --pane-current-path=*)
    PANE_CURRENT_PATH="${i#*=}"
    shift # past argument=value
    ;;
    --pane-active=*)
    PANE_ACTIVE="${i#*=}"
    shift # past argument=value
    ;;
    *) # unknown option
    ;;
esac
done

# replace full path to home directory with ~
PRETTY_PATH=$(sed "s:^$HOME:~:" <<< $PANE_CURRENT_PATH)

# calculate reset color
RESET_BORDER_COLOR=$([ $PANE_ACTIVE -eq 1 ] && echo $ACTIVE_BORDER_COLOR || echo $INACTIVE_BORDER_COLOR)

color () {
  INTENT=$1
  echo $([ $PANE_ACTIVE -eq 1 ] && echo $INTENT || echo $INACTIVE_BORDER_COLOR)
}

# git functions adapted from the bureau zsh theme
# https://github.com/robbyrussell/oh-my-zsh/blob/master/themes/bureau.zsh-theme

ZSH_THEME_GIT_PROMPT_PREFIX="["
ZSH_THEME_GIT_PROMPT_SUFFIX="] "
ZSH_THEME_GIT_PROMPT_CLEAN="#[fg=$(color $GREEN)]✓#[fg=$RESET_BORDER_COLOR]"
ZSH_THEME_GIT_PROMPT_AHEAD="↑"
ZSH_THEME_GIT_PROMPT_BEHIND="↓"
ZSH_THEME_GIT_PROMPT_STAGED="#[fg=$(color $GREEN)]●#[fg=$RESET_BORDER_COLOR]"
ZSH_THEME_GIT_PROMPT_UNSTAGED="#[fg=$(color $YELLOW)]●#[fg=$RESET_BORDER_COLOR]"
ZSH_THEME_GIT_PROMPT_UNTRACKED="#[fg=$(color $RED)]●#[fg=$RESET_BORDER_COLOR]"

git_branch () {
  ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
  ref=$(command git rev-parse --short HEAD 2> /dev/null) || return
  echo "${ref#refs/heads/}"
}

git_status () {
  _STATUS=""

  # check status of files
  _INDEX=$(command git status --porcelain 2> /dev/null)
  if [[ -n "$_INDEX" ]]; then
    if $(echo "$_INDEX" | command grep -q '^[AMRD]. '); then
      _STATUS="$_STATUS$ZSH_THEME_GIT_PROMPT_STAGED"
    fi
    if $(echo "$_INDEX" | command grep -q '^.[MTD] '); then
      _STATUS="$_STATUS$ZSH_THEME_GIT_PROMPT_UNSTAGED"
    fi
    if $(echo "$_INDEX" | command grep -q -E '^\?\? '); then
      _STATUS="$_STATUS$ZSH_THEME_GIT_PROMPT_UNTRACKED"
    fi
    if $(echo "$_INDEX" | command grep -q '^UU '); then
      _STATUS="$_STATUS$ZSH_THEME_GIT_PROMPT_UNMERGED"
    fi
  else
    _STATUS="$_STATUS$ZSH_THEME_GIT_PROMPT_CLEAN"
  fi

  # check status of local repository
  _INDEX=$(command git status --porcelain -b 2> /dev/null)
  if $(echo "$_INDEX" | command grep -q '^## .*ahead'); then
    _STATUS="$_STATUS$ZSH_THEME_GIT_PROMPT_AHEAD"
  fi
  if $(echo "$_INDEX" | command grep -q '^## .*behind'); then
    _STATUS="$_STATUS$ZSH_THEME_GIT_PROMPT_BEHIND"
  fi

  echo $_STATUS
}

git_prompt () {
  local _branch=$(git_branch)
  local _status=$(git_status)
  local _result=""
  if [[ "${_branch}x" != "x" ]]; then
    _result="$ZSH_THEME_GIT_PROMPT_PREFIX$_branch"
    if [[ "${_status}x" != "x" ]]; then
      _result="$_result $_status"
    fi
    _result="$_result$ZSH_THEME_GIT_PROMPT_SUFFIX"
  fi
  echo $_result
}

# final output
echo " $PRETTY_PATH $(cd $PANE_CURRENT_PATH && git_prompt)"
