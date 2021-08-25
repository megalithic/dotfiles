#!/usr/bin/env zsh
# shellcheck shell=bash

echo "loading helpers.."

set -e

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
