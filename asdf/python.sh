#!/bin/bash

[[ -f "$XDG_CONFIG_HOME/zsh/lib/helpers.zsh" ]] && source "$XDG_CONFIG_HOME/zsh/lib/helpers.zsh"

set -euo pipefail

# -- set some useful vars for executable info:
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename "$__file" .sh)"
__root="$(cd "$(dirname "$__dir")" && pwd)"
# shellcheck disable=SC2034,SC2015
__invocation="$(printf %q "$__file")$( (($#)) && printf ' %q' "$@" || true)"

do_install() {
  python3 -m pip install --upgrade pip
  cat "$HOME"/.default-python-packages | xargs python3 -m pip install --upgrade --user
  python3.10 -m pip install --upgrade pip
  cat "$HOME"/.default-python-packages | xargs python3.10 -m pip install --upgrade --user
  python3.11 -m pip install --upgrade pip
  cat "$HOME"/.default-python-packages | xargs python3.11 -m pip install --upgrade --user
  cat "$HOME"/.default-python-packages | xargs pip3.11 install --upgrade --user
  cat "$HOME"/.default-python-packages | xargs pip3 install --upgrade --user
  sudo cat "$HOME"/.default-python-packages | xargs /Library/Frameworks/Python.framework/Versions/3.11/bin/pip3 install --upgrade --user
}

do_install || exit 1
