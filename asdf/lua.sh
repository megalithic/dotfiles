#!/bin/bash

[[ -f "$XDG_CONFIG_HOME/zsh/lib/helpers.zsh" ]] && source "$XDG_CONFIG_HOME/zsh/lib/helpers.zsh"

set -euo pipefail

do_install() {
  if (has luarocks); then
    (! has luacheck) && luarocks install luacheck
    (! has lcf) && luarocks install lcf
    # (! has lua-lsp) && luarocks install --server=https://luarocks.org/dev lua-lsp
    (! has lua-format) && luarocks install --server=https://luarocks.org/dev luaformatter
    (! has lua-nuspell) && luarocks install lua-nuspell
  fi
}

read -p "$(tput bold)$(tput setaf 5)[?] download and install lua addons (y/N)?$(tput sgr 0) " yn
case $yn in
  [Yy]*)
    do_install || exit 1
    ;;
  [Nn]*)
    log_warn "opted out of installing lua addons"
    ;;
  "")
    log_warn "opted out of installing lua addons"
    ;;
  *)
    log_warn "please answer [y]es or [n]o."
    exec $__invocation
    ;;
esac
