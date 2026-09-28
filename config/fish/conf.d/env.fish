# Portable environment setup.

set -g fish_prompt_pwd_dir_length 20

# Host-specific mise config: mise merges ~/.config/mise/config.$MISE_ENV.toml
# on top of the global config. Must be set before conf.d/mise.fish activates
# (conf.d loads alphabetically: env.fish < mise.fish).
set -gx MISE_ENV (hostname -s)

# PLUG_EDITOR for clickable stacktraces (Phoenix dev / browser devtools).
# Hammerspoon resolves target nvim instance dynamically at click time.
set -gx PLUG_EDITOR "hammerspoon://nvim-open?file=__FILE__&line=__LINE__"

# Capture tmux session name for tools that need the current session context.
if set -q TMUX; and command -sq tmux
    set -gx TMUX_SESSION (tmux display-message -p '#S')
end
