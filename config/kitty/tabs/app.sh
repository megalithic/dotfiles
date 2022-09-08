#!/usr/bin/env bash

cd ~/code/outstand || return
et -c 'cd ~/code/app && ls && eval $(desk load) && dev down --remove-orphans; dev up -d && nvim -c "lua require(\"workspaces\").open(\"app\")"; exec /usr/bin/zsh' seth-dev
