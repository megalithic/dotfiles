#!/usr/bin/env zsh

log "-> setting up asdf for all platforms.."

# clone asdf-vm (no need for homebrew version of asdf if we're doing this)
if [[ ! -d "$HOME/.asdf" ]]
then
  log_warn "-> $HOME/.asdf not found; cloning it now.."
  git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf
fi

source $HOME/.asdf/asdf.sh

log "-> adding asdf plugins.."
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

log "-> installing asdf plugin versions.."
# must initially symlink our tool-versions file for asdf to install the right things..
asdf install

#
log "-> configuring ruby-specific.."
source $DOTS/asdf/ruby.sh && log_ok "-> DONE configuring ruby"

#
log "-> configuring node-specific.."
# TODO: it seems as though after installing a node vresion we have to explicitly set it with `asdf global nodejs <version>`
source $DOTS/asdf/node.sh && log_ok "-> DONE configuring node"

#
log "-> configuring lua-specific.."
source $DOTS/asdf/lua.sh && log_ok "-> DONE configuring lua"

#
log "-> configuring rust-specific.."
source $DOTS/asdf/rust.sh && log_ok "-> DONE configuring rust"

#
log "-> configuring elixir-specific.."
source $DOTS/asdf/elixir.sh && log_ok "-> DONE configuring elixir"
