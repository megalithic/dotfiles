#!/usr/bin/env zsh
# shellcheck shell=bash

if (command -v go &> /dev/null); then
  go get golang.org/x/tools/gopls@latest
  # using Brewfile -> brew "efm-langserver" instead
  # go get github.com/mattn/efm-langserver
fi
