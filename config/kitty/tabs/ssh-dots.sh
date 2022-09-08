#!/usr/bin/env bash

cd ~/.dotfiles || return
et -c 'cd ~/.dotfiles && ls; exec /usr/bin/zsh' seth-dev
