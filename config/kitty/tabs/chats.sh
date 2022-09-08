#!/usr/bin/env bash

cd ~/.dotfiles || return
tmux-launch weechat "weechat"
/usr/local/bin/zsh
