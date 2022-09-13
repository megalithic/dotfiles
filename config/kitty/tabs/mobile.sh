#!/usr/bin/env bash

cd ~/code/outstand/mobile

# sh ~/.dotfiles/bin/tmux-launch -d expo "cd ~/code/outstand/mobile; expo start"
nvim -c "lua require('workspaces').open('mobile')"
