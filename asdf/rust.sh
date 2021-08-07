#!/usr/bin/env zsh
# shellcheck shell=bash

# super verbose debugging of the running script:
# set -x

if (command -v rustup &>/dev/null); then
	rustup install stable
	rustup default stable
fi

if (command -v cargo &>/dev/null); then
	cargo install selene # https://kampfkarren.github.io/selene/selene.html
	cargo install stylua # https://github.com/johnnymorganz/stylua

	if [[ $PLATFORM == "linux" ]]; then
		cargo install git-delta
	fi
fi
