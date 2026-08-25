# fnox: 1Password-backed secrets (non-nix twin of the opnix shell init).
# Secrets are individual op:// field references in
# ~/.config/fnox/config.toml; `fnox activate fish` exports them (daemon-cached)
# and auto-loads per-project fnox.toml secrets on cd.
# https://fnox.jdx.dev/guide/shell-integration.html
status is-interactive; or exit

# `fnox activate` bakes the resolved versioned mise install path into its hook
# functions; `mise up` deletes that path on upgrade, breaking prompt hooks in
# long-running shells. Swap it for the stable shim path, which survives upgrades.
if command -sq fnox
    set -l fnox_shim $HOME/.local/share/mise/shims/fnox
    if test -x $fnox_shim
        fnox activate fish | string replace -ra '[^\s()]*/mise/installs/fnox/[^\s()/]+/fnox' $fnox_shim | source
    else
        fnox activate fish | source
    end
end
