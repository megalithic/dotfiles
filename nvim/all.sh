#!/bin/zsh

echo "## NEOVIM..."

if [ ! -d "$HOME/.config" ]; then
  mkdir -p $HOME/.config
fi

ln -sfv $DOTS/nvim $HOME/.config/nvim
ln -sfv $DOTS/nvim/init.vim $HOME/.vimrc

curl -fLo $DOTS/nvim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

nvim +PlugInstall! +qall!

pip3 install -U --upgrade neovim
