# fnox: 1Password-backed secrets (non-nix twin of the opnix shell init).
# ~/.config/fnox/secrets/*.sh are rendered by `mise run setup:fnox:render` —
# one file per *_SH secret in the global fnox config. New *_SH secrets render
# and load automatically; re-run the render task when op://Crypt items change.
status is-interactive; or exit

set -l config_home "$XDG_CONFIG_HOME"
test -z "$config_home"; and set config_home "$HOME/.config"

# Load every rendered POSIX-style KEY=value secrets file as exported fish vars.
for secrets_file in "$config_home"/fnox/secrets/*.sh
    test -f "$secrets_file"; or continue
    while read -l line
        set line (string trim -- "$line")
        test -z "$line"; and continue
        string match -qr '^#' -- "$line"; and continue

        set line (string replace -r '^export[[:space:]]+' "" -- "$line")
        string match -qr '^[A-Za-z_][A-Za-z0-9_]*=' -- "$line"; or continue

        set -l parts (string split -m1 = -- "$line")
        set -gx $parts[1] $parts[2]
    end <"$secrets_file"
end

# Official shell integration: auto-load per-project fnox.toml secrets on cd.
# https://fnox.jdx.dev/guide/shell-integration.html
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
