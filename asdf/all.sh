#!/usr/bin/env zsh

echo ""
echo ":: setting up asdf-vm..."
echo ""

# clone asdf-vm (no need for homebrew version of asdf if we're doing this)
if [[ ! -d "$HOME/.asdf" ]]
then
  echo ""
  echo ":: ~/.asdf not found; cloning it now.."
  echo ""
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf
fi

autoload -Uz compinit && compinit
echo '. $HOME/.asdf/asdf.sh' >> ~/.zshrc
echo '. $HOME/.asdf/completions/asdf.bash' >> ~/.zshrc
source ~/.zshrc
source $HOME/.asdf/asdf.sh;

#
# preferred plugins..
#asdf plugin-add golang https://github.com/kennyp/asdf-golang.git
asdf plugin-add ruby https://github.com/asdf-vm/asdf-ruby.git
asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
asdf plugin-add elm https://github.com/vic/asdf-elm.git
asdf plugin-add lua https://github.com/Stratus3D/asdf-lua.git

#
# TODO:
# add python asdf installer.. his notes about multiple python versions and reshim
# https://github.com/danhper/asdf-python
# asdf plugin-add python https://github.com/tuvistavie/asdf-python.git

#
# must initially symlink our tool-versions file for asdf to install the right things..
source ~/.zshrc
ln -sfv $DOTS/asdf/tool-versions.symlink $HOME/.tool-versions
asdf install
source ~/.zshrc

#
# ruby-specific...
sh $DOTS/asdf/ruby.sh

#
# node-specific...
# sh $DOTS/asdf/node.sh
