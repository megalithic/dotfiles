#!/bin/zsh
# shellcheck shell=bash

[[ -f "$HOME/.dotfiles/config/zsh/lib/helpers.zsh" ]] && source "$HOME/.dotfiles/config/zsh/lib/helpers.zsh"

case $(uname) in
  Darwin)
    # -- intel mac:
    [ -f "/usr/local/bin/brew" ] && eval "$(/usr/local/bin/brew shellenv)"
    # -- M1 mac:
    [ -f "/opt/homebrew/bin/brew" ] && eval "$(/opt/homebrew/bin/brew shellenv)"
    ;;
  Linux)
    [ -d "/home/linuxbrew/.linuxbrew" ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    ;;
esac

set -euo pipefail

do_install() {
  # python3.12 -m pip install --upgrade --user pip
  # python3.12 -m pip install --upgrade --user -r "$HOME/.default-python-packages"
  # pip3.12 -m pip install --upgrade --user -r "$HOME/.default-python-packages"
  # pip3 -m pip install --upgrade --user -r "$HOME/.default-python-packages"
  # pip -m pip install --upgrade --user -r "$HOME/.default-python-packages"

  [[ -f "/usr/local/bin/brew" ]] && /usr/local/opt/python@3.12/bin/python3.12 -m pip install --upgrade --user --break-system-packages -r "$HOME/.default-python-packages"
  [[ -f "/opt/homebrew/bin/brew" ]] && /opt/homebrew/opt/python@3.12/bin/python3.12 -m pip install --upgrade --user --break-system-packages -r "$HOME/.default-python-packages"

  if (command -v rtx &>/dev/null); then
    rtx reshim python
  elif (command -v mise &>/dev/null); then
    mise reshim python
  elif (command -v asdf &>/dev/null); then
    asdf reshim python
  fi
}

do_install || exit 1
