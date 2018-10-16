#!/bin/zsh

echo "## asdf-vm..."
echo ""

# clone asdf-vm (no need for homebrew version of asdf when doing this)
# if [[ ! -d $HOME/.asdf ]]
# then
#   echo ":: ~/.asdf not found; cloning it now.."#
#   git clone https://github.com/asdf-vm/asdf.git ~/.asdf
# fi

#
# preferred plugins..
asdf plugin-add ruby
asdf plugin-add nodejs
asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
asdf plugin-add elm https://github.com/vic/asdf-elm.git
asdf plugin-add lua https://github.com/Stratus3D/asdf-lua.git

#
# required for asdf-nodejs..
# https://github.com/asdf-vm/asdf-nodejs#install
sh ~/.asdf/plugins/nodejs/bin/import-release-team-keyring

asdf install

#
# ruby-specific...
sh $DOTS/asdf/ruby.sh

#
# node-specific...
sh $DOTS/asdf/node.sh
yarn global add neovim # neovim gets angry when trying to use asdf's shim of neovim-node-host
