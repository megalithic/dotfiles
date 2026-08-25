# Atuin shell history search. Ctrl-R only; keep native up-arrow behavior.

status is-interactive; or return
command -sq atuin; or return

atuin init fish --disable-up-arrow --disable-ai | source
