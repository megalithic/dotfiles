#!/usr/bin/env zsh

elixir_ls_path="$XDG_CONFIG_HOME/elixir_ls"

function _do_clone {
  # clone project
  git clone https://github.com/elixir-lsp/elixir-ls "$elixir_ls_path"
  cd "$elixir_ls_path"
}

function _mix {
  # fetch dependencies and compile
  mix deps.get && mix compile

  # install executable
  mix elixir_ls.release -o release

  cd -
}

if [[ ! -d "$elixir_ls_path" ]]
then
  # elixir_ls not there, so clone it..
  _do_clone && _mix
else
  # elixir_ls exists so we need to rm and then clone it..
  rm -rf $elixir_ls_path
  _do_clone && _mix
fi
