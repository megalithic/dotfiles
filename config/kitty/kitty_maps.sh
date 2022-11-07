#!/usr/bin/env bash

PATH="$PATH:/usr/local/bin:/usr/bin"

cat "$HOME"/.config/kitty/maps.conf |
egrep "^map" |
sort |
column -t -s'#' |
fzf --layout=reverse
