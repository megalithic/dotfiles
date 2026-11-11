# Git — mise-managed configuration

Global git config for both hosts, applied through the `config/mise/config.toml`
`[dotfiles]` table. Layout is XDG-native: there is no `~/.gitconfig` or
`~/.gitignore`.

```
git/
├── config        # → ~/.config/git/config — single global config: signing
│                 #   (1Password op-ssh-sign, ssh key, gpgSign); no
│                 #   core.excludesfile (XDG ignore is git's built-in default);
│                 #   includes an untracked `config.local` for machine-local
│                 #   overrides
├── ignore        # → ~/.config/git/ignore — global excludes
└── disabled/     # parked files, not deployed:
    ├── gitconfig_macos   # osxkeychain/gh credential helpers, commit template
    ├── gitconfig_linux   # linuxbrew gh credential helper
    └── gitmessage        # conventional-commit template (needs commit.template)
```

## Conventions

- Machine-local/untracked settings go in `~/.config/git/config.local` (already
  included from `config`); never edit the symlinked files in place.
- A stray `~/.gitconfig` wins per key over `~/.config/git/config`; delete it.
- Signing needs 1Password installed in `/Applications` (op-ssh-sign lives in
  the app bundle; `brew-cask:1password` in `[bootstrap.packages]`) and
  `~/.ssh/allowed_signers` for verification (`git log --show-signature`;
  linked from `home/.ssh/allowed_signers`). The agent's key selection
  comes from `~/.config/1Password/ssh/agent.toml`
  (`config/1Password/ssh/agent.toml`).
- Runtime deps referenced by `config`: delta (pager), git-lfs (filter), nvim
  (editor + codediff diff/merge tool), fzf (`cof` alias), worktrunk (`wt`
  alias), brew git contrib (`jump` alias). All are in
  `config/mise/config.toml` (`[tools]` / `[bootstrap.packages]`).

## Applying

```sh
mise run update:dotfiles        # links config, ignore (rg/fd ignore: home/.ignore)
git config --list --show-origin # verify origins point at ~/.config/git/config
```
