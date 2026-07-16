# Bash / POSIX profile — mise-managed configuration

Non-nix twin of `home/common/programs/bash/default.nix` plus the portable shell
hooks that Home Manager used to inject from program modules. These files are
linked by `mise/config/mise/global_config.toml`:

- `~/.profile` → `mise/config/bash/profile`
- `~/.bashrc` → `mise/config/bash/bashrc`
- `~/.bash_profile` → `mise/config/bash/bash_profile`

## What moved here

- Git worktree helper functions and completions from the nix bash module.
- `mise activate bash` so global `[env]` and `[shell_alias]` work in bash.
- Worktrunk upstream shell integration: `eval "$(wt config shell init bash)"`.
- Portable hooks for fzf, direnv, starship, zoxide, Ghostty shell integration,
  and the yazi `yy` cwd helper.
- fnox-first secrets loading with opnix fallback during migration.

## Keep in sync

- Cross-shell aliases live in Home Manager's mise `globalConfig` and
  `mise/config/mise/global_config.toml` `[shell_alias]`, not here.
- Fish owns a custom `wt` function; bash uses upstream Worktrunk integration.
- Avoid nix store paths; resolve tools from PATH after `mise activate bash`.
