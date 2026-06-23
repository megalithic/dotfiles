# Managed by mise bootstrap. Keep local-only shell code in conf.d/local.fish.

set -gx DOTS "$HOME/.dotfiles"
set -gx CODE "$HOME/code"
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx XDG_DATA_HOME "$HOME/.local/share"
set -gx XDG_STATE_HOME "$HOME/.local/state"
set -gx XDG_CACHE_HOME "$HOME/.cache"
set -gx PI_STATE_DIR "$XDG_STATE_HOME/pi"
set -gx PLUG_EDITOR "hammerspoon://nvim-open?file=__FILE__&line=__LINE__"

fish_add_path --prepend \
  "$HOME/.local/bin" \
  "$HOME/bin" \
  "$DOTS/bin" \
  "$HOME/.cargo/bin" \
  /opt/homebrew/bin \
  /opt/homebrew/sbin

set -g fish_prompt_pwd_dir_length 20

if set -q TMUX
  set -gx TMUX_SESSION (tmux display-message -p '#S' 2>/dev/null)
end

for file in $XDG_CONFIG_HOME/fish/conf.d/*.fish
  source $file
end
