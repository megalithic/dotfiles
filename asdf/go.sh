#!/usr/bin/env zsh
# shellcheck shell=bash

if (command -v go &> /dev/null); then
  # -- install gopls
  GO111MODULE=on go get golang.org/x/tools/gopls@latest

  # -- install efm-langserver
  # using Brewfile -> brew "efm-langserver" instead
  # GO111MODULE=on go get github.com/mattn/efm-langserver@latest

  # -- install zk
  GO111MODULE=on go get -tags "fts5 icu" -u github.com/mickael-menu/zk@HEAD

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
