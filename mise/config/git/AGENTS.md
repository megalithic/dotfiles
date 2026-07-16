# Git — mise-managed configuration

Non-nix twin of `home/common/programs/git/` (the Home Manager module). Both
trees are **independent copies**: while the nix setup is still active, changes
must be mirrored manually to whichever tree you actually run.

Nothing here applies automatically. Application happens through
`mise/config/mise/global_config.toml` `[dotfiles]` table once that config is active.

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

Cutover hazard: git reads `~/.config/git/config` first, then `~/.gitconfig` —
the later file wins per key. While Home Manager still owns `~/.gitconfig`,
both exist with identical values; any new edit must land here AND be mirrored
to the nix tree, or the stale `~/.gitconfig` silently wins. Drop the HM git
module promptly after cutover (its `~/.gitconfig`/`~/.gitignore` symlinks
disappear with it).
