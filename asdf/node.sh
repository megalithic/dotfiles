#!/usr/bin/env zsh
# shellcheck shell=bash

asdf reshim nodejs
if (command -v npm &>/dev/null); then
	cat $HOME/.default-npm-packages | xargs npm install -g
fi

if (command -v yarn &>/dev/null); then
  cat $HOME/.default-npm-packages | xargs yarn global add
fi
