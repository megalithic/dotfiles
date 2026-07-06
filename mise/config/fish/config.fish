# Standalone fish config — non-nix port of home/common/programs/fish.
# No external plugins; everything lives in this directory.
# Nix-only setup still loads from ~/.local/share/fish/nix.fish when present (see conf.d/env.fish).

if status is-interactive
    set -g fish_greeting

    set -l fish_bin (command -s fish)
    test -n "$fish_bin"; and set -gx SHELL "$fish_bin"

    fish_vi_key_bindings

    # Clear screen + scrollback at startup (hides "Last login" after the fact).
    printf '\33c\e[3J'

    set -l fish_config_dir (dirname (status --current-filename))

    for file in \
        "$fish_config_dir/functions/_prompt_move_to_bottom.fish" \
        "$fish_config_dir/functions/_prompt_reset_mouse.fish" \
        "$fish_config_dir/functions/_fzf_tab.fish" \
        "$fish_config_dir/interactive/aliases.fish" \
        "$fish_config_dir/interactive/abbreviations.fish" \
        "$fish_config_dir/interactive/completions.fish" \
        "$fish_config_dir/interactive/keybindings.fish" \
        "$fish_config_dir/interactive/theme.fish"

        test -f "$file"; and source "$file"
    end

    _prompt_move_to_bottom
end
