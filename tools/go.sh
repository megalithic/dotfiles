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
  # TODO: https://golang.org/doc/go-get-install-deprecation
  # --
  # go get: installing executables with 'go get' in module mode is deprecated.
  #   Use 'go install pkg@version' instead.
  #   For more information, see https://golang.org/doc/go-get-install-deprecation
  #   or run 'go help get' or 'go help install'.

  if (has go); then
    # (! has luacheck) && luarocks install luacheck
    # -- install gopls
    GO111MODULE=on go install golang.org/x/tools/gopls@latest

    # -- install misspell
    GO111MODULE=on go install github.com/client9/misspell/cmd/misspell

    # -- install zk
    # GO111MODULE=on go get -tags "fts5 icu" -u github.com/mickael-menu/zk@HEAD

    # -- install lemonade from copy/paste over tcp
    GO111MODULE=on go install github.com/lemonade-command/lemonade@HEAD

    GO111MODULE=on go install github.com/guysherman/kittymux/go
    GO111MODULE=on CGO_ENABLED=0 go install -ldflags="-s -w" github.com/gokcehan/lf@latest

    # TODO: still need to install zk from source?
    # zk_build_path="$HOME/code/oss/zk"
    # _do_zk_install() {
    #   git clone https://github.com/mickael-menu/zk.git "$zk_build_path"
    #   cd "$HOME/code/oss/zk"
    #   chmod a+x go
    #   ./go install
    #   cd -
    # }
    # if [[ ! -d "$zk_build_path" ]]
    # then
    #   # zk folder not there, so clone it..
    #   _do_zk_install
    # else
    #   # zk folder exists so we need to rm and then clone it..
    #   rm -rf $zk_build_path
    #   _do_zk_install
    # fi
  fi
}

do_install || exit 1
# read -p "$(tput bold)$(tput setaf 5)[?] download and install golang addons (y/N)?$(tput sgr 0) " yn
# case $yn in
#   [Yy]*)
#     do_install || exit 1
#     ;;
#   [Nn]*)
#     log_warn "opted out of installing golang addons"
#     ;;
#   "")
#     log_warn "opted out of installing golang addons"
#     ;;
#   *)
#     log_warn "please answer [y]es or [n]o."
#     exec $__invocation
#     ;;
# esac
