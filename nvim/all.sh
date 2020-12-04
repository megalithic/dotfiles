#!/bin/zsh

echo "## NEOVIM..."

if [ ! -d "$HOME/.config" ]; then
  mkdir -p $HOME/.config
fi

ln -sfv $DOTS/nvim $HOME/.config/
ln -sfv $DOTS/nvim/vimrc $HOME/.vimrc

# vim-plug setup
# curl -fLo $DOTS/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# nvim +PlugInstall! +qall!

# packer.nvim setup
git clone https://github.com/wbthomason/packer.nvim \
    "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/pack/packer/opt/packer.nvim
    
# paq-nvim setup
git clone https://github.com/savq/paq-nvim.git \
    "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/pack/paqs/opt/paq-nvim

