# Atuin — mise-managed shell history

Atuin is a shell history replacement/search layer. It does **not** replace
zoxide: zoxide jumps to directories (`z foo`), while Atuin searches commands
(`Ctrl-R`) with cwd/host/session/exit-code metadata.

Applied through `mise/config/mise/global_config.toml`:

- `[tools]`: `atuin = "latest"`
- `[dotfiles]`: `~/.config/atuin/config.toml` → `mise/config/atuin/config.toml`
- Shell hooks:
  - bash: `mise/config/bash/bashrc`
  - zsh: `mise/config/zsh/zshrc`
  - fish: `mise/config/fish/conf.d/atuin.fish`

## Policy

- Local-first: `auto_sync = false` until `atuin register` / `atuin login` is
  done intentionally. Flip `auto_sync = true` only after auth/encryption key is
  set up.
- `Ctrl-R` is managed by Atuin. Up-arrow stays native shell history via
  `atuin init --disable-up-arrow` so normal prompt behavior is preserved.
- AI keybinding is disabled (`--disable-ai`).
- Keep filters conservative: built-in `secrets_filter = true` plus explicit
  token/password/secret filters and secret-directory cwd filters.

## Useful commands

```sh
atuin import auto     # one-time import existing shell histories
atuin search          # interactive search
atuin stats           # command stats
atuin register        # optional hosted sync account
atuin login           # optional sync on another machine
atuin sync            # manual sync after login
```
