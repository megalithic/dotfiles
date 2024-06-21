#!/bin/bash

source "${HOME}/.dotfiles/config/zsh/lib/helpers.zsh"

set -euo pipefail

# -- set some useful vars for executable info:
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename "$__file" .sh)"
__root="$(cd "$(dirname "$__dir")" && pwd)"
# shellcheck disable=SC2034,SC2015
__invocation="$(printf %q "$__file")$( (($#)) && printf ' %q' "$@" || true)"

do_install() {
  if (has luarocks); then
    (! has luacheck) && luarocks install luacheck
    (! has lcf) && luarocks install lcf
    # (! has lua-lsp) && luarocks install --server=https://luarocks.org/dev lua-lsp
    (! has lua-format) && luarocks install --server=https://luarocks.org/dev luaformatter
    (! has lua-nuspell) && luarocks install lua-nuspell
    (! has penlight) && luarocks install penlight

    # NOTE: these ought to install to ~/.luarocks
    # luarocks install --lua-version 5.4 fsm 1.1.0-1
    # luarocks install --lua-version 5.4 lustache 1.3.1-0
    # luarocks install --lua-version 5.4 middleclass 4.1.1-0
    luarocks install fsm 1.1.0-1
    luarocks install lustache 1.3.1-0
    luarocks install middleclass 4.1.1-0
  fi
}

do_install || exit 1
# read -p "$(tput bold)$(tput setaf 5)[?] download and install lua addons (y/N)?$(tput sgr 0) " yn
# case $yn in
#   [Yy]*)
#     do_install || exit 1
#     ;;
#   [Nn])
#     log_warn "opted out of installing lua addons"
#     ;;
#   "")
#     log_warn "opted out of installing lua addons"
#     ;;
#   *)
#     log_warn "please answer [y]es or [n]o."
#     exec $__invocation
#     ;;
# esac
