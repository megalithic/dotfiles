# Zsh — mise-managed configuration

Portable zsh config. Fish is the login shell; zsh is a secondary shell.

- `home/.zshenv` → `~/.zshenv` (sets `ZDOTDIR=~/.config/zsh`)
- `config/zsh/zshrc` → `~/.config/zsh/zshrc`

## What lives here

- Fnox shell activation for 1Password-backed secrets.
- `mise activate zsh` so global `[env]` and `[shell_alias]` work in zsh.
- Worktrunk upstream shell integration: `eval "$(wt config shell init zsh)"`.
- Portable hooks for fzf, direnv, starship, and zoxide.

## Keep in sync

- Cross-shell aliases live in `config/mise/config.toml` `[shell_alias]`, not here.
- Fish owns a custom `wt` function; zsh uses upstream Worktrunk integration.
- Resolve tools from PATH after `mise activate zsh`; don't hardcode install paths.
