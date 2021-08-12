#!/usr/bin/env zsh
# shellcheck shell=bash

# super verbose debugging of the running script:
# set -x

# -- handling the install of rust with asdf
# - or - 
# -- handle with direct install via rustup
# if (command -v rustup &>/dev/null); then
#   log "installing rustup"
# 	rustup install stable
# 	rustup default stable
# fi

if (command -v cargo &>/dev/null); then

  # if [[ ! -d $HOME/.cargo ]]; then
  #   mkdir -p $HOME/.cargo
  # fi

  log "installing cargo crates"
	cargo install selene # https://kampfkarren.github.io/selene/selene.html
	cargo install stylua # https://github.com/johnnymorganz/stylua

	if [[ $PLATFORM == "linux" ]]; then
		cargo install git-delta
	fi
fi
