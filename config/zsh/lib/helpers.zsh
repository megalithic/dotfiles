#!/usr/bin/env zsh
# shellcheck shell=bash

# set -euo pipefail

bold=$(tput bold)
underline=$(tput sgr 0 1)
reset=$(tput sgr 0)

# green=$(tput setaf 76)
green=$(tput setaf 2)
purple=$(tput setaf 5)
# blue=$(tput setaf 38)
blue=$(tput setaf 4)
cyan=$(tput setaf 6)
tan=$(tput setaf 3)
red=$(tput setaf 1)

function e_arrow() {
  printf "➜ $1\n"
}

function e_success() {
  printf "${green}✔ %s${reset}\n" "$@"
}

function e_warning() {
  printf "${tan}➜ %s${reset}\n" "$@"
}

function e_error() {
  printf "${red}✖ %s${reset}\n" "$@"
}

function e_bold() {
  printf "${bold}%s${reset}\n" "$@"
}

function e_note() {
  printf "${underline}${bold}${blue}NOTE:${reset}  ${blue}%s${reset}\n" "$@"
}

# REF: https://gist.github.com/junegunn/f4fca918e937e6bf5bad#gistcomment-3484821
function valid() {
  local cmd="${@:-}"
  $cmd >&/dev/null

  # REF: https://access.redhat.com/solutions/196563
  if [[ $? -eq 128 ]]; then
    return
  fi
}

# ZSH only and most performant way to check existence of an executable
# https://www.topbug.net/blog/2016/10/11/speed-test-check-the-existence-of-a-command-in-bash-and-zsh/
exists() { (($+commands[$1])); }

function has() {
  type "$1" &>/dev/null
}

function log_raw {
  printf '%s%s\n%s' $(tput setaf 4) "$*" $(tput sgr 0)
}

# function log {
# 	printf '%s%s\n%s' $(tput setaf 4) "➜ $*" $(tput sgr 0)
# }

function log {
  printf '%s[%s] %s\n%s' $(tput setaf 4) "$(date '+%x %X')" "➜ $*" $(tput sgr 0)
}

function log_ok {
  printf '%s[%s] %s\n%s' $(tput setaf 2) "$(date '+%x %X')" "➜ [✓] $*" $(tput sgr 0)
}

function log_warn {
  printf '%s%s[%s] %s\n%s' $(tput bold) $(tput setaf 3) "$(date '+%x %X')" "➜ [!] $*" $(tput sgr 0)
}

function log_error {
  printf '%s%s[%s] %s\n%s' $(tput bold) $(tput setaf 1) "$(date '+%x %X')" "➜ [x] $*" $(tput sgr 0)
}

function clean_exit {
    set +x
    if [[ "$1" != "0" ]]; then
        log_error "Fatal error code \"${1}\" occurred on line \"${2}\""
    fi
}

set +eu
