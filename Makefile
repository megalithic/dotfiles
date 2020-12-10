BREW      := $(shell brew --version 2>/dev/null)
CLI_TOOLS := $(xcode-select --install 2>&1 | grep installed;)

default:
	make stow

stow:
	stow fish
	stow git
	stow kitty
	stow nvim
	stow tmux
	stow zsh

install:
ifndef CLI_TOOLS
else
	xcode-select --install
endif

ifndef BREW
	echo "Homebrew isn't installed... installing..."
	/usr/bin/ruby -e "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" \
else
endif

	brew bundle
	make stow

	curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	nvim +PlugInstall +qall
	mkdir -p ~/.config/nvim/backups ~/.config/nvim/swaps ~/.config/nvim/undo

ifeq ($(wildcard ~/.tmux/plugins/tpm/.),)
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
endif

ifeq ($(wildcard ~/.asdf/.),)
	git clone https://github.com/asdf-vm/asdf.git ~/.asdf
	cd ~/.asdf
	git checkout "$(git describe --abbrev=0 --tags)"
endif
