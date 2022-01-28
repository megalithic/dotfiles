#!/bin/bash

[[ -f "$XDG_CONFIG_HOME/zsh/lib/helpers.zsh" ]] && source "$XDG_CONFIG_HOME/zsh/lib/helpers.zsh"

set -euo pipefail

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
    GO111MODULE=on go get golang.org/x/tools/gopls@latest

    # -- install misspell
    GO111MODULE=on go get -u github.com/client9/misspell/cmd/misspell

    # -- install zk
    GO111MODULE=on go get -tags "fts5 icu" -u github.com/mickael-menu/zk@HEAD

    # -- install lemonade from copy/paste over tcp
    GO111MODULE=on go get -u github.com/lemonade-command/lemonade@HEAD

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

read -p "$(tput bold)$(tput setaf 5)[?] download and install golang addons (y/N)?$(tput sgr 0) " yn
case $yn in
  [Yy]*)
    do_install || exit 1
    ;;
  [Nn]*)
    log_warn "opted out of installing golang addons"
    ;;
  "")
    log_warn "opted out of installing golang addons"
    ;;
  *)
    log_warn "please answer [y]es or [n]o."
    exec $__invocation
    ;;
esac
