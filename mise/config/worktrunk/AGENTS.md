# Worktrunk — mise-managed configuration

Non-nix twin of `home/common/programs/worktrunk/` (the Home Manager module).
Both trees are **independent copies**: while the nix setup is still active,
changes must be mirrored manually to whichever tree you actually run.

Applied through `mise/config/mise/global_config.toml`:

- `[dotfiles]`: `"~/.config/worktrunk/config.toml" = "~/.dotfiles/mise/config/worktrunk/config.toml"`
  (per-file — `approvals.toml{,.lock}` in the same dir are mutable runtime
  state and stay unmanaged)
- `[tools]`: `worktrunk = "latest"` (registry backends:
  `aqua:max-sixty/worktrunk`, `cargo:worktrunk`) — replaces `pkgs.worktrunk`

## What the nix module provided, and where it lives in the mise world

| Nix piece | mise home |
| --- | --- |
| `pkgs.worktrunk` binary | `[tools]` `worktrunk` |
| `xdg.configFile worktrunk/config.toml` (worktree-path template) | this dir's `config.toml` |
| `enableFishIntegration = false` + local `wt` fish function (vendored directives, implicit switch, tmux targets) | already migrated: `mise/config/fish/functions/wt.fish` + completions |
| `enableBashIntegration/ZshIntegration` (`eval "$(wt config shell init bash|zsh)"` in rc files) | migrated: `mise/config/bash/bashrc` and `mise/config/zsh/zshrc` run the upstream init after `mise activate` |
| gitconfig `wt = !wt` alias | already migrated: `mise/config/git/config` |
| global ignore project `.config/` dirs, `.worktrees/` (via tool-ignore) | already migrated: `mise/config/git/ignore` + `tool-ignore` |

## Applying

```sh
mise install worktrunk
mise bootstrap dotfiles apply
wt config show   # confirm worktree-path template resolves
```

Do not apply while Home Manager still owns `~/.config/worktrunk/config.toml`.
