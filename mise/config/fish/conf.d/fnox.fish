# fnox: 1Password-backed secrets (non-nix twin of the opnix shell init).
# env-vars.sh is rendered by `mise run fnox:render`; refresh it there when
# op://Crypt/env changes.
status is-interactive; or exit

set -l config_home "$XDG_CONFIG_HOME"
test -z "$config_home"; and set config_home "$HOME/.config"

# Load rendered POSIX-style KEY=value secrets as exported fish variables.
set -l secrets_file "$config_home/fnox/secrets/env-vars.sh"
if test -f "$secrets_file"
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
command -sq fnox; and fnox activate fish | source
