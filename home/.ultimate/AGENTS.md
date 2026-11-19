## Host basics

- Seth's login shell is fish. Commands he runs himself are fish syntax: `for i in (seq 6); ...; end`, `set -x VAR val`, `(cmd)` not `$(cmd)`, no `export`. Your own bash tool calls stay bash.
- macOS on both Macs (`workbookpro`, `megabookpro`). Versions differ per host and change with updates: check `sw_vers` and `fish --version` before stating one.
- Tools come from mise (`~/.dotfiles/config/mise/config.toml`); no global installs.
- Browser: Helium (`net.imput.helium`). Hammerspoon is the default URL handler and routes links to it.
