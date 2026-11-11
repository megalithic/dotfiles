# jj (Jujutsu) — mise-managed configuration

Global jj config for both hosts. Applied through the `config/mise/config.toml`
`[dotfiles]` table: `config/jj/config.toml` → `~/.config/jj/config.toml`.

## Conventions / notes

- `config.toml` is the only user config layer. Do not recreate
  `~/.jjconfig.toml`: jj loads it before the XDG file, so a second layer
  silently wins/loses per key and drifts.
- `~/.config/jj/repos/` is jj runtime state (per-repo scoped configs) — never
  managed; only `config.toml` is linked, per-file.
- Signing needs 1Password in `/Applications` (`brew-cask:1password`) and
  `~/.ssh/allowed_signers` (absolute `/Users/seth/...` path — same username
  on both hosts; linked from `home/.ssh/allowed_signers`).
- Runtime deps: delta (`[tools]`), nvim (diff-editor `DiffEditor`), gh
  (`pr`/`push --pr` aliases), bash + rg (script aliases). `JJ_EDITOR` comes
  from the global mise config `[env]`.
- `revset-aliases` are required by the `here`/`tug`/script aliases
  (`closest_bookmark()`).
- Known quirk preserved as-is: `revset-aliases."stack(x)"` references `n`.

## Applying

```sh
mise run update:dotfiles
jj log                          # custom template, curved graph, signatures
```
