# Startup environment, in order. Sorts first in conf.d: the tool snippets after
# it return early when their tool isn't on PATH yet. Not interactive-gated:
# Rex starts commands as `fish -l -c ...` with a bare PATH.

fish_add_path -gP ~/.local/bin ~/.dotfiles/bin /opt/homebrew/bin /opt/homebrew/sbin

# mise merges ~/.config/mise/config.$MISE_ENV.toml over the global config.
set -gx MISE_ENV (hostname -s)

# Clickable stacktraces (Phoenix dev / browser devtools); Hammerspoon picks the nvim.
set -gx PLUG_EDITOR "hammerspoon://nvim-open?file=__FILE__&line=__LINE__"

command -sq mise; or return

if status is-interactive
    mise activate fish | source
else if status is-login
    # One-shot env, no prompt hooks. Not `mise activate --shims`: shims/pi
    # would shadow the ~/.local/bin/pi wrapper.
    mise env -s fish | source
end
