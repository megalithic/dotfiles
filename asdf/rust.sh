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
  # -- handling the install of rust with asdf
  # - or -
  # -- handle with direct install via rustup
  # if (has rustup); then
  #   log "installing rustup"
  # 	rustup install stable
  # 	rustup default stable
  # fi

  # NOTE: you might have to run `rustup update stable` from time to time!
  # - e.g. remember that issue with edition2021 and updating stylua?
  # - REF: https://stackoverflow.com/questions/69848319/unable-to-specify-edition2021-in-order-to-use-unstable-packages-in-rust

  if (has cargo); then
    # (! has luacheck) && luarocks install luacheck
    cargo install selene    # https://kampfkarren.github.io/selene/selene.html
    cargo install stylua    # https://github.com/johnnymorganz/stylua
    cargo install distant   # https://github.com/chipsenkbeil/distant
    cargo install taplo-lsp # https://taplo.tamasfe.dev/lsp/
    cargo install cbfmt
    cargo install shellharden
    cargo install --git https://github.com/solidiquis/erdtree
  fi
}

do_install || exit 1
# read -p "$(tput bold)$(tput setaf 5)[?] download and install rust addons (Y/n)?$(tput sgr 0) " yn
# case $yn in
#   [Yy]*)
#     do_install || exit 1
#     ;;
#   [Nn])
#     log_warn "opted out of installing rust addons"
#     ;;
#   "")
#     log_warn "opted out of installing rust addons"
#     ;;
#   *)
#     log_warn "please answer [y]es or [n]o."
#     exec $__invocation
#     ;;
# esac
