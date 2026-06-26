# Portable environment setup. Nix-specific PATH setup is generated at ~/.local/share/fish/nix.fish.

set -l data_home "$XDG_DATA_HOME"
test -z "$data_home"; and set data_home "$HOME/.local/share"

set -l nix_fish "$data_home/fish/nix.fish"
test -f "$nix_fish"; and source "$nix_fish"

set -g fish_prompt_pwd_dir_length 20

# PLUG_EDITOR for clickable stacktraces (Phoenix dev / browser devtools).
# Hammerspoon resolves target nvim instance dynamically at click time.
set -gx PLUG_EDITOR "hammerspoon://nvim-open?file=__FILE__&line=__LINE__"

# Capture tmux session name for tools that need the current session context.
if set -q TMUX; and command -sq tmux
    set -gx TMUX_SESSION (tmux display-message -p '#S')
end
