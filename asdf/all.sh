#!/bin/zsh

echo "## asdf-vm..."
echo ""

# clone asdf-vm (no need for homebrew version of asdf when doing this)
if [[ ! -d $HOME/.asdf ]]
then
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.5.1
fi

asdf plugin-add ruby
asdf plugin-add nodejs

# https://github.com/asdf-vm/asdf-nodejs#install
sh ~/.asdf/plugins/nodejs/bin/import-release-team-keyring

asdf install

#
# ruby-specific...
sh $DOTS/asdf/ruby.sh

#
# node-specific...
# nothing yet
