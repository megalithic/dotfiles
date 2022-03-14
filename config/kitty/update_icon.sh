#!/usr/bin/env bash

set -euo pipefail

[[ -f "$HOME/.config/zsh/lib/helpers.zsh" ]] && source "$HOME/.config/zsh/lib/helpers.zsh"

if [[ $(uname) != "Darwin" ]]; then
  log_warn "this script requires MacOS (darwin); skipping."
  exit 0
fi


function __debug_info() {
  # -- set some useful vars for executable info:
  __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  __file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
  __base="$(basename "${__file}" .sh)"
  __root="$(cd "$(dirname "${__dir}")" && pwd)"
  # shellcheck disable=SC2034,SC2015
  __invocation="$(printf %q "${__file}")$( (($#)) && printf ' %q' "$@" || true)"

  printf -- "%s executation details:\n" "$__base"
  printf -- "---------------------------------------------------\n"
  printf -- "cwd:          %s\n" "$__dir"
  printf -- "filepath:     %s\n" "$__file"
  printf -- "basename:     %s\n" "$__base"
  printf -- "root:         %s\n" "$__root"
  printf -- "invocation:   %s\n" "$__invocation"
  printf -- "\n"
}
# __debug_info

# HOWTO:
# - https://www.sethvargo.com/replace-icons-osx
# - https://github.com/DinkDonk/kitty-icon#installation
cp $DOTS/config/kitty/kitty.icns /Applications/kitty.app/Contents/Resources/kitty.icns
rm /var/folders/*/*/*/com.apple.dock.iconcache
touch /Applications/kitty.app
killall Dock && killall Finder
