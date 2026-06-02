#!/usr/bin/env bash
# shellcheck shell=bash

source "$HOME/.dotfiles/bin/helpers"

log_info "Installing 'Symbols Only' nerd fonts to ~/Library/Fonts.."

wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/NerdFontsSymbolsOnly/SymbolsNerdFont-Regular.ttf &&
  mv SymbolsNerdFont-Regular.ttf ~/Library/Fonts
wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/NerdFontsSymbolsOnly/SymbolsNerdFontMono-Regular.ttf &&
  mv SymbolsNerdFontMono-Regular.ttf ~/Library/Fonts

log_ok "Installed 'Symbols Only' nerd fonts to ~/Library/Fonts"
