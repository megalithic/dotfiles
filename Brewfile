# Packages that mise's brew backend can't handle.

tap "felixkratz/formulae", trusted: true
tap "leandrocp/lumis", trusted: true
tap "nikitabobko/tap", trusted: true
tap "tornikegomareli/tap", trusted: true

brew "felixkratz/formulae/borders", restart_service: :always
brew "nikitabobko/tap/brew-install-path"
brew "leandrocp/lumis/lumis"
brew "felixkratz/formulae/sketchybar", restart_service: :always
# Rex plugin manager. postinstall runs after bundle installs or upgrades it, not
# after a plain `brew upgrade`: run `rexd setup` by hand then. Bundle's PATH
# lacks the Homebrew bin dir, so name the binary through HOMEBREW_PREFIX.
brew "tornikegomareli/tap/rexd", postinstall: "\"$HOMEBREW_PREFIX/bin/rexd\" setup"

# Testing:
# cask "mikker/tap/dinky"
