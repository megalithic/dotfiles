#!/usr/bin/env zsh

echo "## asdf-vm..."
echo ""

# clone asdf-vm (no need for homebrew version of asdf if we're doing this)
# if [[ ! -d "$HOME/.asdf" ]]
# then
#   echo ":: ~/.asdf not found; cloning it now.."#
#   git clone https://github.com/asdf-vm/asdf.git ~/.asdf
# fi

#
# preferred plugins..
source $HOME/.asdf/asdf.sh;

asdf plugin-add ruby https://github.com/asdf-vm/asdf-ruby.git;
asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git;
asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git;
asdf plugin-add golang https://github.com/kennyp/asdf-golang.git;
asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git;
#
# required for asdf-nodejs..
# https://github.com/asdf-vm/asdf-nodejs#install
/usr/bin/env zsh $HOME/.asdf/plugins/nodejs/bin/import-release-team-keyring;

# TODO:
# add python asdf installer.. his notes about multiple python versions and reshim
# https://github.com/danhper/asdf-python
# asdf plugin-add python https://github.com/tuvistavie/asdf-python.git

# must initially symlink our tool-versions file for asdf to install the right things..
ln -sfv $DOTS/asdf/tool-versions.symlink $HOME/.tool-versions
asdf install

#
# ruby-specific...
sh $DOTS/asdf/ruby.sh

#
# node-specific...
sh $DOTS/asdf/node.sh
