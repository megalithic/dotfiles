#!/bin/bash

# https://github.com/brookhong/Surfingkeys/blob/master/src/nvim/server/Readme.md
SCRIPT_PATH=$(dirname "$BASH_SOURCE"[0])
exec nvim --headless -c "luafile $SCRIPT_PATH/server.lua"
