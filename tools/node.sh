#!/usr/bin/env zsh
# shellcheck shell=bash

if (command -v rtx &>/dev/null); then
  rtx reshim nodejs
elif (command -v asdf &>/dev/null); then
  asdf reshim nodejs
fi

if (command -v npm &>/dev/null); then
  cat $HOME/.default-npm-packages | xargs npm install -g
fi

if (command -v yarn &>/dev/null); then
  cat $HOME/.default-npm-packages | xargs yarn global add
fi
