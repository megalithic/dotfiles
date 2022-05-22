#!/usr/bin/env zsh
# shellcheck shell=bash

# set -euo pipefail

function detect_platform {
  if [[ -z $PLATFORM ]]; then
    platform="unknown"
    derived_platform=$(uname | tr "[:upper:]" "[:lower:]")

    if [[ $derived_platform == "darwin" ]]; then
      platform="macos"
    elif [[ $derived_platform == "linux" ]]; then
      platform="linux"
    fi

    export PLATFORM=$platform

    # if [[ "$PLATFORM" == "linux" ]]; then
    #     # If available, use LSB to identify distribution
    #     if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]; then
    #         export DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
    #         # Otherwise, use release info file
    #     else
    #         export DISTRO=$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1)
    #     fi
    # fi
    unset platform
    unset derived_platform
  fi
}
detect_platform

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

set +eu
