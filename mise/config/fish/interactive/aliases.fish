status is-interactive; or return

# Cross-shell aliases live in mise/config/mise/global_config.toml [shell_alias].
# Keep fish-only helpers here.
alias !! 'eval $history[1]'
alias clear 'clear && _prompt_move_to_bottom'
