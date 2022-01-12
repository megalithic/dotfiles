SHELL := /bin/bash
.POSIX:
.PHONY: help
.DEFAULT_GOAL := install

help: ## Show this help content
	@egrep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

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
		curl -fLO https://github.com/elixir-lsp/elixir-ls/releases/latest/download/elixir-ls.zip
		unzip -o elixir-ls.zip -d $(XDG_DATA_HOME)/lsp/elixir-ls
		chmod +x $(XDG_DATA_HOME)/lsp/elixir-ls/language_server.sh
		rm elixir-ls.zip

paq: ## Install paq-nvim to $XDG_DATA_HOME/nvim/site/pack/paqs/start/paq-nvim
		git clone --depth=1 https://github.com/savq/paq-nvim.git $XDG_DATA_HOME/nvim/site/pack/paqs/start/paq-nvim
		nvim -c 'lua require("paq")(require("plugins").list):install()' +qall;

subup: ## Updates git submodules
	git submodule update --remote --merge
