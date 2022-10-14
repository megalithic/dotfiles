#!/usr/bin/env bash

cd ~/code/outstand || return
et -c 'cd ~/code/app && ls && eval $(desk load); dev up -d; exec /usr/bin/zsh' seth-dev
