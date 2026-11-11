# Worktrunk — mise-managed configuration

Applied through `config/mise/config.toml`:

- `[dotfiles]`: `config/worktrunk/config.toml` → `~/.config/worktrunk/config.toml`
  (per-file — `approvals.toml{,.lock}` in the same dir are mutable runtime
  state and stay unmanaged)
- `[tools]`: `worktrunk`

## Shell integration

- fish: local `wt` function in `config/fish/functions/wt.fish` + completions
  (vendored directives, implicit switch, tmux targets); upstream fish
  integration is not used.
- bash/zsh: `home/.bashrc` and `config/zsh/zshrc` run
  `eval "$(wt config shell init bash|zsh)"` after `mise activate`.
- git `wt = !wt` alias: `config/git/config`.
- Global ignores for project `.config/` dirs and `.worktrees/`:
  `config/git/ignore` + `home/.ignore`.

## Applying

```sh
mise install worktrunk
mise run update:dotfiles
wt config show   # confirm worktree-path template resolves
```
