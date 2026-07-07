# Activate mise so [shell_alias] works in fish.

status is-interactive; or return
command -sq mise; or return

mise activate fish | source
