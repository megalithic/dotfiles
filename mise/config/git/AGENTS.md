# Git — mise-managed configuration

**Sole owner** of global git config on both hosts since the megabookpro
wave-1 flip (the Home Manager git module is removed; no mirroring needed).
Applied through the `mise/config/mise/global_config.toml` `[dotfiles]` table.

## Layout — XDG-native (deliberately different from the nix tree)

The HM module split git config across `~/.config/git/config` (generated
signing block + include) and `~/.gitconfig` (main config) — a Home Manager
artifact, since `programs.git` only writes the XDG path. This tree collapses
that into a single XDG-native layout; **no `~/.gitconfig` or `~/.gitignore`
exist in the mise world**.

```
git/
├── config        # → ~/.config/git/config — single merged global config:
│                 #   signing (1Password op-ssh-sign, ssh key, gpgSign) folded
│                 #   into the former ~/.gitconfig content; no core.excludesfile
│                 #   (XDG ignore is git's built-in default); includes an
│                 #   untracked `config.local` for machine-local overrides
├── ignore        # → ~/.config/git/ignore — global excludes (former
│                 #   ~/.gitignore content + adopted local additions)
├── tool-ignore   # → ~/.ignore — rg/fd global ignore (not read by git)
└── disabled/     # parked files, unwired in nix too (kept for parity):
    ├── gitconfig_macos   # osxkeychain/gh credential helpers, commit template
    ├── gitconfig_linux   # linuxbrew gh credential helper
    └── gitmessage        # conventional-commit template (needs commit.template)
```

## Conventions

- Machine-local/untracked settings go in `~/.config/git/config.local` (already
  included from `config`); never edit the symlinked files in place.
- Signing needs 1Password installed in `/Applications` (op-ssh-sign lives in
  the app bundle; `brew-cask:1password` in `[bootstrap.packages]`) and
  `~/.ssh/allowed_signers` for verification (`git log --show-signature`;
  linked from `mise/config/ssh/allowed_signers`). The agent's key selection
  comes from `~/.config/1Password/ssh/agent.toml`
  (`mise/config/1password/agent.toml`).
- Runtime deps referenced by `config`: delta (pager), git-lfs (filter), nvim
  (editor + codediff diff/merge tool), fzf (`cof` alias), worktrunk (`wt`
  alias), brew git contrib (`jump` alias). All but worktrunk are in
  `mise/config/mise/global_config.toml` (`[tools]` / `[bootstrap.packages]`).

## Applying

```sh
mise bootstrap dotfiles apply   # links config, ignore, tool-ignore
git config --list --show-origin # verify origins point at ~/.config/git/config
```

Cutover complete (wave 1): the HM git module and its `~/.gitconfig` /
`~/.gitignore` symlinks are gone; `~/.config/git/config` is the only global
config git reads. If a stray `~/.gitconfig` ever reappears, it wins per key —
delete it.
