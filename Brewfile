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
# after a plain `brew upgrade`: run `mise run setup:rex` by hand then. setup-rex
# skips while Rex Beta (mise tool http:rex-beta) is missing, so bundle doesn't fail.
brew "tornikegomareli/tap/rexd", postinstall: "\"${DOTFILES_DIR:-$HOME/.dotfiles}/mise/scripts/setup-rex\""

# Testing:
# cask "mikker/tap/dinky"
