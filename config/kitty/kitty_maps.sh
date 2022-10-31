#!/usr/bin/env zsh

cat "$HOME"/.config/kitty/maps.conf |
/usr/bin/sed 's/^map\s*//' |
/opt/homebrew/bin/fzf --layout=reverse
