#!/bin/zsh
# shellcheck shell=bash

[[ -f "$HOME/.dotfiles/config/zsh/lib/helpers.zsh" ]] && source "$HOME/.dotfiles/config/zsh/lib/helpers.zsh"

case `uname` in
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
  python -m pip install --upgrade pip
  python -m pip install --upgrade -r "$HOME/.default-python-packages"

  python3 -m pip install --upgrade pip
  python3 -m pip install --upgrade -r "$HOME/.default-python-packages"
  # cat "$HOME/.default-python-packages" | xargs python3 -m pip install --upgrade
  python3.10 -m pip install --upgrade pip
  python3.10 -m pip install --upgrade -r "$HOME/.default-python-packages"
  # cat "$HOME/.default-python-packages" | xargs python3.10 -m pip install --upgrade
  python3.11 -m pip install --upgrade pip
  python3.11 -m pip install --upgrade -r "$HOME/.default-python-packages"
  # cat "$HOME/.default-python-packages" | xargs python3.11 -m pip install --upgrade
  pip3.11 -m pip install --upgrade  -r "$HOME/.default-python-packages"
  # cat "$HOME/.default-python-packages" | xargs pip3.11 install --upgrade
  pip3 -m pip install --upgrade  -r "$HOME/.default-python-packages"
  # cat "$HOME/.default-python-packages" | xargs pip3 install --upgrade
  # sudo /Library/Frameworks/Python.framework/Versions/3.11/bin/pip3 -m pip install --upgrade  -r "$HOME/.default-python-packages"
  [[ -f "/usr/local/bin/brew" ]] && /usr/local/opt/python@3.11/bin/python3.11 -m pip install --upgrade  -r "$HOME/.default-python-packages"
  [[ -f "/opt/homebrew/bin/brew" ]] && /opt/homebrew/opt/python@3.11/bin/python3.11 -m pip install --upgrade  -r "$HOME/.default-python-packages"
  # sudo cat "$HOME/.default-python-packages" | xargs /Library/Frameworks/Python.framework/Versions/3.11/bin/pip3 install --upgrade

  asdf reshim python
}

do_install || exit 1
