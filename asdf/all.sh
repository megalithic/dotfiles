#!/usr/bin/env zsh

log "-> installing asdf for all platforms.."

# clone asdf-vm (no need for homebrew version of asdf if we're doing this)
if [[ ! -d "$HOME/.asdf" ]]
then
  log_warn "-> $HOME/.asdf not found; cloning it now.."
  git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf
fi

source $HOME/.asdf/asdf.sh

#
# preferred plugins..
asdf plugin-add ruby https://github.com/asdf-vm/asdf-ruby.git
asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
asdf plugin-add elm https://github.com/asdf-community/asdf-elm.git
asdf plugin-add golang https://github.com/kennyp/asdf-golang.git
asdf plugin-add lua https://github.com/Stratus3D/asdf-lua.git
asdf plugin-add rust https://github.com/code-lever/asdf-rust.git
asdf plugin-add python https://github.com/danhper/asdf-python.git
asdf plugin-add nodejs
bash $HOME/.asdf/plugins/nodejs/bin/import-release-team-keyring

#
# TODO:
# add python asdf installer.. his notes about multiple python versions and reshim
# https://github.com/danhper/asdf-python
# asdf plugin-add python https://github.com/tuvistavie/asdf-python.git

#
# must initially symlink our tool-versions file for asdf to install the right things..
asdf install

#
# ruby-specific...
source $DOTS/asdf/ruby.sh

#
# node-specific...
# TODO: it seems as though after installing a node vresion we have to explicitly set it with `asdf global nodejs <version>`
source $DOTS/asdf/node.sh

#
# lua-specific...
source $DOTS/asdf/lua.sh

#
# rust-specific...
source $DOTS/asdf/rust.sh

#
# elixir-specific...
source $DOTS/asdf/elixir.sh
