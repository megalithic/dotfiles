# https://sw.kovidgoyal.net/kitty/shell-integration/?highlight=tmux#manual-shell-integration

if [[ -n $KITTY_INSTALLATION_DIR ]]; then
  export KITTY_SHELL_INTEGRATION="enabled"
  autoload -Uz -- "$KITTY_INSTALLATION_DIR/shell-integration/zsh/kitty-integration"
  kitty-integration
  unfunction kitty-integration
fi

# if [[ ! -z "${KITTY_WINDOW_ID}" ]]; then
#   kitty + complete setup zsh | source /dev/stdin
# fi

# export KITTY_LISTEN_ON="tcp:localhost:45876"
export KITTY_LISTEN_ON="unix:/tmp/mykitty"

