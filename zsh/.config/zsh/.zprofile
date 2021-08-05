#!/usr/bin/env zsh
# shellcheck shell=bash

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

source "$ZDOTDIR/components/env.zsh"

#ft=zsh:foldenable:foldmethod=marker:ft=zsh;ts=2;sts=2;sw=2
#
