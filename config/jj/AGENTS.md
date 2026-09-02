# jj (Jujutsu) — mise-managed configuration

**Sole owner** of jj config on both hosts since the megabookpro wave-1 flip:
the Home Manager jj module is removed and `~/.jjconfig.toml` is retired
(backup at `~/.jjconfig.toml.pre-mise-bak`; solo config verified identical).

Applied through `config/mise/config.toml` `[dotfiles]` entry:
`"~/.config/jj/config.toml" = "~/.dotfiles/config/jj/config.toml"`.

## What `config.toml` merges (the nix world had THREE layers)

1. HM-rendered `~/.config/jj/config.toml` — from `default.nix` settings +
   `aliases.nix` (signing via 1Password op-ssh-sign, delta pager, colors,
   all aliases incl. the bash `util exec` workflows).
2. `~/.jjconfig.toml` — a formerly **unmanaged, hand-maintained** user config
   jj loads *before* the XDG file (XDG wins per key). Its surviving keys are
   the content of the repo's unwired `templates.nix`: `revset-aliases`
   (required by the `here`/`tug`/script aliases' `closest_bookmark()`),
   `revsets.log = "current_work"`, `template-aliases`, custom `templates.log`
   + `templates.log_node`, `ui.graph.style = "curved"`,
   `ui.should-sign-off = true`.
3. This file = (1) overlaid on (2), verified key-for-key identical to the live
   effective config, with one intended delta: `ui.pager = "delta"` (PATH via
   mise `[tools]`) instead of a nix store path.

## Conventions / notes

+ `~/.config/jj/repos/` is jj runtime state (per-repo scoped configs) — never
  managed; only `config.toml` is linked, per-file.
+ Signing needs 1Password in `/Applications` (`brew-cask:1password`) and
  `~/.ssh/allowed_signers` (absolute `/Users/seth/...` path — same username
  on both hosts; linked from `config/ssh/allowed_signers`).
+ Runtime deps: delta (`[tools]`), nvim (diff-editor `DiffEditor`), gh
  (`pr`/`push --pr` aliases), bash + rg (script aliases). `JJ_EDITOR` comes
  from the global mise config `[env]`.
+ Known quirk preserved as-is: `revset-aliases."stack(x)"` references `n`
  (copied from the live `.jjconfig.toml`; the nix `templates.nix` variant used
  `2`). Fix in both trees or not at all.
+ `~/.jjconfig.toml` is retired (wave-1 cutover); do not recreate it — a
  third config layer silently wins/loses per key and drifts.

## Applying

```sh
mise bootstrap dotfiles apply
jj config list --user | wc -l   # should match the pre-cutover count
jj log                          # custom template, curved graph, signatures
```

Cutover complete: Home Manager no longer manages `~/.config/jj/config.toml`;
mise apply is safe.
