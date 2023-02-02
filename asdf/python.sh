#!/bin/zsh
# shellcheck shell=bash

[[ -f "$HOME/.dotfiles/config/zsh/lib/helpers.zsh" ]] && source "$HOME/.dotfiles/config/zsh/lib/helpers.zsh"

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
  python3 -m pip install --upgrade --user -r "$HOME/.default-python-packages"
  # cat "$HOME/.default-python-packages" | xargs python3 -m pip install --upgrade --user
  python3.10 -m pip install --upgrade pip
  python3.10 -m pip install --upgrade --user -r "$HOME/.default-python-packages"
  # cat "$HOME/.default-python-packages" | xargs python3.10 -m pip install --upgrade --user
  python3.11 -m pip install --upgrade pip
  python3.11 -m pip install --upgrade --user -r "$HOME/.default-python-packages"
  # cat "$HOME/.default-python-packages" | xargs python3.11 -m pip install --upgrade --user
  pip3.11 -m pip install --upgrade --user -r "$HOME/.default-python-packages"
  # cat "$HOME/.default-python-packages" | xargs pip3.11 install --upgrade --user
  pip3 -m pip install --upgrade --user -r "$HOME/.default-python-packages"
  # cat "$HOME/.default-python-packages" | xargs pip3 install --upgrade --user
  sudo /Library/Frameworks/Python.framework/Versions/3.11/bin/pip3 -m pip install --upgrade --user -r "$HOME/.default-python-packages"
  # sudo cat "$HOME/.default-python-packages" | xargs /Library/Frameworks/Python.framework/Versions/3.11/bin/pip3 install --upgrade --user

  asdf reshim python
}

do_install || exit 1
