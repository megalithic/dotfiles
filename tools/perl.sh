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
  #export PERL_MM_USE_DEFAULT=1;
  PERL_MM_USE_DEFAULT=1 cpan install Pod::Parser && log_ok "DONE configuring perl"

  if (command -v rtx &>/dev/null); then
    rtx reshim perl
  elif (command -v asdf &>/dev/null); then
    asdf reshim perl
  fi
}

do_install || exit 1
