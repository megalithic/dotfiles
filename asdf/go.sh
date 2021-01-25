#!/usr/bin/env zsh
# shellcheck shell=bash

if (command -v go &> /dev/null); then
  go get github.com/mattn/efm-langserver
fi
