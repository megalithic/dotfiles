#!/usr/bin/env bash

cd ~/code/outstand/mobile || return
nvim -c "lua require('workspaces').open('mobile')"

# launch expo.. figure this junk out
# ~/.dotfiles/bin/tmux-launch expo "cd ~/code/outstand/mobile; expo start"
# /usr/local/bin/zsh