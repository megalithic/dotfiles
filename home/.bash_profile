# Login bash entrypoint for mise-managed dotfiles.
[ -f "$HOME/.profile" ] && . "$HOME/.profile"
[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
