#!/usr/bin/env zsh
# shellcheck shell=bash

#set -euo pipefail

bold=$(tput bold)
underline=$(tput sgr 0 1)
reset=$(tput sgr 0)

# green=$(tput setaf 76)
green=$(tput setaf 2)
purple=$(tput setaf 5)
yellow=$(tput setaf 3)
grey=$(tput setaf 247)
white=$(tput setaf 253)
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

function log_info {
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

dotsay() {
  local result=$(_colorized $@)
  echo "$result"
}

indent() {
  sed 's/^/    /'
}

function checkyes() {
  result=1
  tput setaf 6
  if [[ x$(basename $SHELL) = x'bash' ]]; then
    read -p "$@ [y/N]: " yn; case "$yn" in [yY]*) result=0;; *) result=1;; esac
  elif [[ x$(basename $SHELL) = x'zsh' ]]; then
    printf "$@ [y/N]: "; if read -q; then result=0; else result=1; fi; echo
  fi
  tput sgr0
  return $result
}

_colorized() {
  echo "$@" | sed -E \
    -e 's/((@(red|green|yellow|blue|magenta|cyan|white|reset|b|u))+)[[]{2}(.*)[]]{2}/\1\4@reset/g' \
    -e "s/@red/$(tput setaf 1)/g" \
    -e "s/@green/$(tput setaf 2)/g" \
    -e "s/@yellow/$(tput setaf 3)/g" \
    -e "s/@blue/$(tput setaf 4)/g" \
    -e "s/@magenta/$(tput setaf 5)/g" \
    -e "s/@cyan/$(tput setaf 6)/g" \
    -e "s/@white/$(tput setaf 7)/g" \
    -e "s/@reset/$(tput sgr0)/g" \
    -e "s/@b/$(tput bold)/g" \
    -e "s/@u/$(tput sgr 0 1)/g"
}

set +eu
