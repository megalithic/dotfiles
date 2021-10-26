#!/bin/zsh

echo "## NEOVIM..."

log "symlinking vimrc to $HOME"
ln -sfv $HOME/.config/nvim/.vimrc $HOME/.vimrc && log_ok "done symlinking vimrc" || {
	echo 'symlinking failed'
	exit 1
}

# vim-plug setup
# curl -fLo $DOTS/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# nvim +PlugInstall! +qall!

# # packer.nvim setup
# git clone https://github.com/wbthomason/packer.nvim \
#     "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/pack/packer/opt/packer.nvim
#
# # paq-nvim setup
# git clone https://github.com/savq/paq-nvim.git \
#     "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/pack/paqs/opt/paq-nvim
