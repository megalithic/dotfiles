#!/usr/bin/env bash

cd ~/code/outstand || return
et -c 'cd ~/code/atlas && ls && eval $(desk load) && nvim -c "lua require(\"workspaces\").open(\"atlas\")"; exec /usr/bin/zsh' seth-dev
