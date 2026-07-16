# Zsh — mise-managed configuration

Standalone zsh config for the mise migration. There was no dedicated nix zsh
module in this repo; the Worktrunk nix module only enabled upstream zsh shell
integration. These files provide that portable layer:

- `~/.zprofile` → `mise/config/zsh/zprofile`
- `~/.zshrc` → `mise/config/zsh/zshrc`

## What lives here

- fnox-first secrets loading with opnix fallback during migration.
- `mise activate zsh` so global `[env]` and `[shell_alias]` work in zsh.
- Worktrunk upstream shell integration: `eval "$(wt config shell init zsh)"`.
- Portable hooks for fzf, direnv, starship, and zoxide.

## Keep in sync

- Cross-shell aliases live in Home Manager's mise `globalConfig` and
  `mise/config/mise/global_config.toml` `[shell_alias]`, not here.
- Fish owns a custom `wt` function; zsh uses upstream Worktrunk integration.
- Avoid nix store paths; resolve tools from PATH after `mise activate zsh`.
