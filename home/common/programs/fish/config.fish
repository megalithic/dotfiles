# devenv shell respects $SHELL — make sure it's fish
set -gx SHELL (which fish)

# enable vi mode
fish_vi_key_bindings

# clear screen + scrollback at startup (hides "Last login" after the fact)
set -g fish_greeting
printf '\33c\e[3J'

# auto-activation: load devenv env into current fish on cd (no .envrc needed)
function __devenv_auto --on-variable PWD
    if test -f "$PWD/devenv.nix"; and not set -q __DEVENV_ACTIVE
        set -gx __DEVENV_ACTIVE "$PWD"
        # devenv print-dev-env outputs bash — extract exports, convert to fish
        devenv print-dev-env --no-tui 2>/dev/null | string match -r '^export .+' | while read -l line
            # line: export VAR='value' or export VAR="value" or export VAR=value
            set -l kv (string replace 'export ' '' -- $line)
            set -l key (string replace -r '=.*' '' -- $kv)
            set -l val (string replace -r '^[^=]+=' '' -- $kv)
            # strip surrounding quotes
            set val (string trim -c "'" -- $val)
            set val (string trim -c '"' -- $val)
            if test "$key" = PATH
                # prepend devenv paths, don't replace
                set -gx PATH (string split ':' -- $val) $PATH
            else
                set -gx $key $val
            end
        end
    end
    # clear when leaving devenv dir
    if set -q __DEVENV_ACTIVE; and not string match -q "$__DEVENV_ACTIVE*" "$PWD"
        set -e __DEVENV_ACTIVE
    end
end
