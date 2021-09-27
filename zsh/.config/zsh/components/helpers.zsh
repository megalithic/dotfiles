#!/usr/bin/env zsh
# shellcheck shell=bash

set -euo pipefail

bold=$(tput bold)
underline=$(tput sgr 0 1)
reset=$(tput sgr0)

green=$(tput setaf 76)
green=$(tput setaf 2)
blue=$(tput setaf 38)
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

function log_raw {
	printf '%s%s\n%s' $(tput setaf 4) "$*" $(tput sgr 0)
}

function log {
	printf '%s%s\n%s' $(tput setaf 4) "-> $*" $(tput sgr 0)
}

function log_ok {
	printf '%s[%s] %s\n%s' $(tput setaf 2) "$(date '+%x %X')" "-> [✓] $*" $(tput sgr 0)
}

function log_warn {
	printf '%s%s[%s] %s\n%s' $(tput bold) $(tput setaf 3) "$(date '+%x %X')" "-> [!] $*" $(tput sgr 0)
}

function log_error {
	printf '%s%s[%s] %s\n%s' $(tput bold) $(tput setaf 1) "$(date '+%x %X')" "-> [x] $*" $(tput sgr 0)
}
