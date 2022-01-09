SHELL := /bin/bash
.POSIX:
.PHONY: help
# .PHONY: default dots mac linux help
.DEFAULT_GOAL := install

help: ## Show this help content
	@egrep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: dot ## Runs the default dotbot install script (same as `dot`)

dot: ## Runs the default dotbot install script
	./install

macos: ## Runs the macos-specific dotbot install script
	./macos
	# ./install -vv -c install-mac.conf.yaml

linux: ## Runs the linux-specific dotbot install script
	./linux
	# ./install -vv -c install-linux.conf.yaml

platforms: ## Runs all platform-specific dotbot install scripts
	macos linux

subup: ## Updates git submodules
	git submodule update --remote --merge
