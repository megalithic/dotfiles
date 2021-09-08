#!/usr/bin/env zsh
# shellcheck shell=bash

if [[ -f /home/linuxbrew/.linuxbrew/opt/asdf/libexec/asdf.sh ]]; then
	source /home/linuxbrew/.linuxbrew/opt/asdf/libexec/asdf.sh
else
	source "$ASDF_DIR/asdf.sh"
fi
