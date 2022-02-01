SHELL := /bin/bash
.POSIX:
.PHONY: help install macos linux all elixirls paq subup nvim
.DEFAULT_GOAL := install

help: ## Show this help content
	@echo "Usage: make [command]"
	@echo "Make utility to help with my ~/.dotfiles management."
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo

install: ## Runs the default dotbot install script
	./install

macos: ## Runs the macos-specific dotbot install script
	./macos
	# ./install -vv -c install-mac.conf.yaml

linux: ## Runs the linux-specific dotbot install script
	./linux
	# ./install -vv -c install-linux.conf.yaml

all: ## Runs all platform-specific dotbot install scripts
	macos linux

elixirls: ## Install elixir-ls binary to $XDG_DATA_HOME/lsp/elixir-ls
	$(HOME)/.dotfiles/bin/elixirls-install

elixirls-master: ## Install elixir-ls from source to $XDG_DATA_HOME/lsp/elixir-ls
	$(HOME)/.dotfiles/bin/elixirls-install master

paq: ## Install paq-nvim to $XDG_DATA_HOME/nvim/site/pack/paqs/start/paq-nvim
	$(HOME)/.dotfiles/bin/paq-install

nvim: ## Update and build neovim from source
	$(HOME)/.dotfiles/bin/nvim-install

subup: ## Updates git submodules
	git submodule update --remote --merge
