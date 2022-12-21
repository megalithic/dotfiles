#!/usr/bin/env bash

cd ~/code/outstand || return
et -c 'cd ~/code/atlas && ls && eval $(desk load); exec /usr/bin/zsh' seth-dev
# et -c 'cd ~/code/atlas && ls && eval $(desk load) && dev down --remove-orphans; dev up -d; exec /usr/bin/zsh' seth-dev
