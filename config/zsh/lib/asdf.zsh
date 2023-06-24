#!/usr/bin/env zsh
# shellcheck shell=bash

asdf_exec=""

if [[ -f /home/linuxbrew/.linuxbrew/opt/asdf/libexec/asdf.sh ]]; then
  asdf_exec=/home/linuxbrew/.linuxbrew/opt/asdf/libexec/asdf.sh
elif [[ -f /opt/homebrew/opt/asdf/libexec/asdf.sh ]]; then
  asdf_exec=/opt/homebrew/opt/asdf/libexec/asdf.sh
else
  asdf_exec="$HOME/.asdf/asdf.sh"
fi

source $asdf_exec
export ASDF_EXEC=$asdf_exec
