#!/usr/bin/env zsh

if (command -v go &> /dev/null); then
  go get github.com/mattn/efm-langserver
fi
