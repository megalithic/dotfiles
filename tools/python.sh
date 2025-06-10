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
  LATEST_PYTHON="3.13"
  LATEST_PYTHON_INSTALLED="${LATEST_PYTHON}.4"

  # python3.12 -m pip install --upgrade --user pip
  # python3.12 -m pip install --upgrade --user -r "$HOME/.default-python-packages"
  # pip3.12 -m pip install --upgrade --user -r "$HOME/.default-python-packages"
  # pip3 -m pip install --upgrade --user -r "$HOME/.default-python-packages"
  # pip -m pip install --upgrade --user -r "$HOME/.default-python-packages"

  [[ -f "/opt/homebrew/bin/brew" ]] && /opt/homebrew/opt/python@${LATEST_PYTHON}/bin/python${LATEST_PYTHON} -m pip install --upgrade --user --break-system-packages -r "$HOME/.default-python-packages"

  # [[ -f "/usr/local/bin/brew" ]] && /usr/local/opt/python@${LATEST_PYTHON}/bin/python${LATEST_PYTHON} -m pip install --upgrade --user --break-system-packages -r "$HOME/.default-python-packages"

  # NOTE:
  #
  # For weechat it likely uses this dylib for whatever the latest brew install of python is: /opt/homebrew/Cellar/python@3.13/3.13.3/Frameworks/Python.framework/Versions/3.13/lib/libpython3.13.dylib
  # We need to point it to mise's version: $XDG_DATA_HOME/mise/installs/python/3.13/lib/libpython3.13.dylib
  #
  # Generic fixes provided by brave ai (not for python specifically):
  # export DYLD_LIBRARY_PATH=/path/to/specific/libcurl:$DYLD_LIBRARY_PATH/path/to/weechat-binary
  # install_name_tool -change /usr/local/lib/libcurl.dylib /path/to/specific/libcurl.dylib /path/to/weechat-binary
  # chrpath -r /path/to/specific/libcurl.dylib $(which weechat)

  if (command -v mise &> /dev/null); then
    $XDG_DATA_HOME/mise/installs/python/${LATEST_PYTHON}/bin/python${LATEST_PYTHON} -m pip install --upgrade --user --break-system-packages -r "$HOME/.default-python-packages"
    [[ -f "/opt/homebrew/bin/brew" ]] &&
      install_name_tool -change \
        /opt/homebrew/Cellar/python@${LATEST_PYTHON}/${LATEST_PYTHON}/Frameworks/Python.framework/Versions/${LATEST_PYTHON}/lib/libpython${LATEST_PYTHON}.dylib \
        $XDG_DATA_HOME/mise/installs/python/${LATEST_PYTHON}/lib/libpython${LATEST_PYTHON}.dylib \
        $(which weechat)

    # chrpath -r $XDG_DATA_HOME/mise/installs/python/${LATEST_PYTHON}/lib/libpython${LATEST_PYTHON}.dylib $(which weechat)

    mise reshim python
  elif (command -v rtx &> /dev/null); then
    rtx reshim python
  elif (command -v asdf &> /dev/null); then
    asdf reshim python
  fi
}

do_install && log_ok "finished installing python/pip packages" || exit 1
