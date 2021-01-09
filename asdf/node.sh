#!/usr/bin/env zsh

if (command -v npm &> /dev/null); then
  cat $HOME/.default-npm-packages | xargs npm install -g
fi
