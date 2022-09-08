#!/usr/bin/env bash

cd ~/code/outstand || return
et -c 'cd ~/code/app && ls && eval $(desk load) && nvim -c "lua require(\"workspaces\").open(\"app\")"; exec /usr/bin/zsh' seth-dev
