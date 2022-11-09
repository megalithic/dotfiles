#!/usr/bin/env bash

[[ -f "$HOME/.config/zsh/lib/helpers.zsh" ]] && source "$HOME/.config/zsh/lib/helpers.zsh"

set -euo pipefail

[[ -v DEBUG ]] && set -x

cd ~/code/canonize/ || return
