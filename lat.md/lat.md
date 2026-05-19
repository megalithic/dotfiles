# Dotfiles architecture

This directory documents durable design decisions for the dotfiles repo and links those decisions to source files when useful.

## Tmux layouts

Tmux layout scripts are Bash-compatible session builders discovered by `ftm` from `TMUX_LAYOUTS`.

Layout scripts use `.sh` names and `#!/usr/bin/env bash` so they can be run consistently by `bash`, independent of the user's interactive shell. When a zoxide lookup cannot resolve a session directory, layout startup falls back to `$HOME/code` rather than failing on an empty working directory.

## Neovim nightly compatibility

Neovim config tracks nightly API changes where small compatibility updates prevent startup warnings.

Autocmd callbacks should prefer current `vim.*` APIs over deprecated aliases. Yank highlighting uses `vim.hl.hl_op` instead of deprecated `vim.hl.on_yank` so startup stays clean on nightly builds.
