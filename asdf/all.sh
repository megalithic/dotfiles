#!/usr/bin/env zsh
# shellcheck shell=bash

log "setting up asdf for all platforms.."

# clone asdf-vm (no need for homebrew version of asdf if we're doing this)
if [[ ! -d "$HOME/.asdf" ]]; then
	log_warn "$HOME/.asdf not found; cloning it now.."
	git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf
fi

source "$HOME/.asdf/asdf.sh"

log "adding asdf plugins.."
# preferred plugins..
#  -- generic things to manage with asdf:
#     https://github.com/asdf-community/asdf-link
asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git
asdf plugin-add ruby https://github.com/asdf-vm/asdf-ruby.git
asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
asdf plugin-add elm https://github.com/asdf-community/asdf-elm.git
asdf plugin-add golang https://github.com/kennyp/asdf-golang.git
asdf plugin-add lua https://github.com/Stratus3D/asdf-lua.git
asdf plugin-add rust https://github.com/code-lever/asdf-rust.git
asdf plugin-add python https://github.com/danhper/asdf-python.git
# NOTE: using homebrew perl instead
# asdf plugin add perl https://github.com/chrolis/asdf-perl.git

# TODO: dope way of installing all the latest langs:
# https://github.com/paulfioravanti/dotfiles/blob/master/asdf/setup.sh

#
# TODO:
# add python asdf installer.. his notes about multiple python versions and reshim
# https://github.com/danhper/asdf-python
# asdf plugin-add python https://github.com/tuvistavie/asdf-python.git

log "installing asdf plugin versions.."
# must initially symlink our tool-versions file for asdf to install the right things..
export KERL_CONFIGURE_OPTIONS="--without-javac --with-ssl=$(brew --prefix openssl)"
asdf install

log "configuring ruby.."
source $DOTS/asdf/ruby.sh && log_ok "DONE configuring ruby"

log "configuring node.."
# TODO: it seems as though after installing a node vresion we have to explicitly set it with `asdf global nodejs <version>`
source "$DOTS/asdf/node.sh" && log_ok "DONE configuring node"

log "configuring lua.."
# source "$DOTS/asdf/lua.sh" && log_ok "DONE configuring lua"

log "configuring rust.."
source "$DOTS/asdf/rust.sh" && log_ok "DONE configuring rust"

log "configuring elixir.."
# NOTE: in case of `erl not found` issues: https://github.com/asdf-vm/asdf-elixir/issues/60#issuecomment-964812953
source "$DOTS/asdf/elixir.sh" && log_ok "DONE configuring elixir"

log "configuring go.."
source "$DOTS/asdf/go.sh" && log_ok "DONE configuring go"

log "configuring perl.."
# REF: https://github.com/NixOS/nixpkgs/issues/106506#issuecomment-795775642
cpan install Pod::Parser && log_ok "DONE configuring perl"

log_warn "BE SURE to read the install notes from the asdf installs above."
