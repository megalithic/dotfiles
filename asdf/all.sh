#!/bin/zsh

echo "## asdf-vm..."

git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.5.1

asdf plugin-add ruby
asdf plugin-add nodejs
# https://github.com/asdf-vm/asdf-nodejs#install
sh ~/.asdf/plugins/nodejs/bin/import-release-team-keyring

asdf install

#
# ruby-specific
sh $DOTS/asdf/ruby.sh

#
# node-specific
sh $DOTS/asdf/node.sh
