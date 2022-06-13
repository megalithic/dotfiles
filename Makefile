SHELL := /bin/bash
.POSIX:
.PHONY: help dots up install subup xcode macos linux
.DEFAULT_GOAL := up

help: ## Show this help content
	@echo "Usage: make [command]"
	@echo "Make utility to help with my ~/.dotfiles management."
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo

dots: xcode install

up:
	$(HOME)/.dotfiles/bin/dotup

install: ## Runs the default dotbot install script
	./install

xcode: ## Install Xcode + CLI tools
	$(HOME)/.dotfiles/bin/xcode-install -f

macos: ## (WIP) Runs the macos-specific dotbot install script
	./macos
	# ./install -vv -c install-mac.conf.yaml

linux: ## (WIP) Runs the linux-specific dotbot install script
	./linux
	# ./install -vv -c install-linux.conf.yaml

all: ## (WIP) Runs all platform-specific dotbot install scripts
	macos linux

subup: ## Updates git submodules
	git submodule update --remote --merge
