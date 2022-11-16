#!/usr/bin/env bash

# REF: https://github.com/andrewferrier/dotfiles/blob/main/common/.config/nvim/skeleton/sh

[[ -f "$HOME/.config/zsh/lib/helpers.zsh" ]] && source "$HOME/.config/zsh/lib/helpers.zsh"

set -euo pipefail

[[ -v DEBUG ]] && set -x
