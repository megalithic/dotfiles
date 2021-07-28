#!/usr/bin/env zsh
# shellcheck shell=bash

## -- setup elixir_ls
ls_build_path="$XDG_CONFIG_HOME/lsp/elixir_ls"
function _do_clone {
  # clone project
  git clone https://github.com/elixir-lsp/elixir-ls "$ls_build_path"
  cd "$ls_build_path"
}

function _mix {
  # fetch dependencies and compile
  mix deps.get && mix compile && \
    # install executable
    mix elixir_ls.release -o release && \
    cd -
}

if [[ ! -d "$ls_build_path" ]]
then
  # elixir_ls not there, so clone it..
  _do_clone && _mix
else
  # elixir_ls exists so we need to rm and then clone it..
  rm -rf $ls_build_path
  _do_clone && _mix
fi


## -- setup tree-sitter-elixir
ts_build_path="$XDG_CONFIG_HOME/treesitter/tree-sitter-elixir"
if [[ ! -d "$ts_build_path" ]]
then
  # tree-sitter-elixir not there, so clone it..
  git clone https://github.com/Tuxified/tree-sitter-elixir.git "$ts_build_path"
else
  # tree-sitter-elixir exists so we need to rm and then clone it..
  rm -rf $ts_build_path
  git clone https://github.com/Tuxified/tree-sitter-elixir.git "$ts_build_path"
fi
