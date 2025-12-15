#!/usr/bin/env zsh
# shellcheck shell=bash

export MISE_SHELL=zsh

mise() {
  local command
  command="${1:-}"
  if [ "$#" = 0 ]; then
    command /opt/homebrew/bin/mise
    return
  fi
  shift

  case "$command" in
    deactivate|shell)
      eval "$(/opt/homebrew/bin/mise "$command" "$@")"
      ;;
    *)
      command /opt/homebrew/bin/mise "$command" "$@"
      ;;
  esac
}

_mise_hook() {
  if [[ ! -n $IN_NIX_SHELL ]]; then
    trap -- '' SIGINT;
    eval "$("/opt/homebrew/bin/mise" hook-env -s zsh)";
    trap - SIGINT;
  fi
}

typeset -ag precmd_functions;
if [[ -z "${precmd_functions[(r)_mise_hook]+1}" ]]; then
  precmd_functions=( _mise_hook ${precmd_functions[@]} )
 # [[ ! -n $IN_NIX_SHELL ]] && precmd_functions=( _mise_hook ${precmd_functions[@]} )
fi

typeset -ag chpwd_functions;
if [[ -z "${chpwd_functions[(r)_mise_hook]+1}" ]]; then
  chpwd_functions=( _mise_hook ${chpwd_functions[@]} )
 # [[ ! -n $IN_NIX_SHELL ]] && chpwd_functions=( _mise_hook ${chpwd_functions[@]} )
fi
