#!/bin/bash

[[ -f "$XDG_CONFIG_HOME/zsh/lib/helpers.zsh" ]] && source "$XDG_CONFIG_HOME/zsh/lib/helpers.zsh"

set -euo pipefail

do_install() {
  # -- handling the install of rust with asdf
  # - or -
  # -- handle with direct install via rustup
  # if (has rustup); then
  #   log "installing rustup"
  # 	rustup install stable
  # 	rustup default stable
  # fi

  if (has cargo); then
    # (! has luacheck) && luarocks install luacheck
    cargo install selene  # https://kampfkarren.github.io/selene/selene.html
    cargo install stylua  # https://github.com/johnnymorganz/stylua
    cargo install distant # https://github.com/chipsenkbeil/distant

    if [[ $PLATFORM == "linux" ]]; then
      cargo install git-delta
    fi
  fi
}

read -p "$(tput bold)$(tput setaf 5)[?] download and install rust addons (y/N)?$(tput sgr 0) " yn
case $yn in
  [Yy]*)
    do_install || exit 1
    ;;
  [Nn]*)
    log_warn "opted out of installing rust addons"
    ;;
  "")
    log_warn "opted out of installing rust addons"
    ;;
  *)
    log_warn "please answer [y]es or [n]o."
    exec $__invocation
    ;;
esac
