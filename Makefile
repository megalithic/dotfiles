BREW_BIN        		:= /usr/local/bin

XDG_CONFIG_HOME   	?= $(HOME)/.config
XDG_DATA_HOME  	 	 	?= $(HOME)/.local/share
PAQ_PATH  	 	 	 	 	?= $(XDG_DATA_HOME)/nvim/site/pack/paqs
# BREW_SCRIPTS_URL  	= https://raw.githubusercontent.com/Homebrew/install/HEAD

ASDF           	 	 	:= $(HOME)/.asdf/bin/asdf
BREW           	 	 	:= $(BREW_BIN)/brew
STOW           	 	 	:= $(BREW_BIN)/stow
NVIM           	 	 	:= $(BREW_BIN)/nvim
GIT            	 	 	:= $(BREW_BIN)/git
PAQ            	 	 	:= $(PAQ_PATH)/start/paq-nvim
TPM            	 	 	:= $(HOME)/.config/tmux/plugins/tpm
ZSH            	 	 	:= $(HOME)/.config/zsh

STOW_PKGS      	 	 	:= zsh git kitty nvim tmux misc zk weechat keyboard
BREW_PKGS      	 	 	:= $(STOW) $(NVIM) $(GIT)

.PHONY: default dots mac
.DEFAULT_GOAL := dots

dots: | $(STOW)
	$(STOW) $(STOW_PKGS)
	mkdir -p ~/.config/nvim/backups ~/.config/nvim/swaps ~/.config/nvim/undo

install: mac dots $(PAQ) $(ASDF) $(TPM)

mac:
	./macos

$(BREW):
	/usr/bin/ruby -e "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

$(BREW_PKGS):
	$(BREW) bundle

$(ASDF): | $(GIT)
	$(GIT) clone https://github.com/asdf-vm/asdf.git ~/.asdf
	cd ~/.asdf
	$(GIT) checkout "$($(GIT) describe --abbrev=0 --tags)"

$(PAQ): | $(NVIM) $(GIT)
	$(GIT) clone --depth=1 https://github.com/savq/paq-nvim.git $(PAQ)
	$(NVIM) +PaqInstall +qall

$(LSP_DIR) $(TPM_DIR):
	mkdir -p $@

$(TPM): | $(GIT)
	mkdir -p $@
	$(GIT) clone https://github.com/tmux-plugins/tpm $(HOME)/.config/tmux/plugins/tpm




# .PHONY: install brew nvim symlinks \
# 	clean clean.brew clean.nvim clean.symlinks

# install: brew nvim symlinks

# brew:
# 	curl -fsSL '$(BREW_SCRIPTS_URL)/install.sh' > install.sh
# 	/bin/bash install.sh
# 	brew bundle --file $(XDG_CONFIG_HOME)/Brewfile

# nvim:
# 	git clone https://github.com/savq/paq-nvim.git \
# 		$(PAQ_PATH)/start/paq-nvim

# symlinks:
# 	ln -s $(XDG_CONFIG_HOME)/nvim/vimrc   $(HOME)/.vimrc
# 	ln -s $(XDG_CONFIG_HOME)/zsh/.zshenv  $(HOME)/.zshenv


# clean: clean.brew clean.nvim clean.symlinks

# clean.brew:
# 	curl -fsSL '$(BREW_SCRIPTS_URL)/uninstall.sh' > uninstall.sh
# 	/bin/bash uninstall.sh

# clean.nvim:
# 	rm -rf $(PAQ_PATH)

# clean.symlinks:
# 	rm $(HOME)/.vimrc
# 	rm $(HOME)/.zshenv
