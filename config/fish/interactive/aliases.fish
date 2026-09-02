status is-interactive; or return

# Cross-shell aliases live in config/mise/config.toml [shell_alias].
# Keep fish-only helpers here.
alias !! 'eval $history[1]'
alias clear 'clear && _prompt_move_to_bottom'
