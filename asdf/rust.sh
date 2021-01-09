#!/usr/bin/env zsh

# super verbose debugging of the running script:
# set -x

if (command -v rustup &> /dev/null); then
  rustup install stable
  rustup default stable
fi
