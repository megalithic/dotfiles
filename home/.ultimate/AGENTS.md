## Host basics

- Seth's login shell is fish. Commands he runs himself are fish syntax: `for i in (seq 6); ...; end`, `set -x VAR val`, `(cmd)` not `$(cmd)`, no `export`. Your own bash tool calls stay bash.
- macOS on both Macs (`workbookpro`, `megabookpro`). Versions differ per host and change with updates: check `sw_vers` and `fish --version` before stating one.
- Tools come from mise (`~/.dotfiles/config/mise/config.toml`); no global installs.
- Browser: Helium (`net.imput.helium`). Hammerspoon is the default URL handler and routes links to it.

## Time-sensitive handoffs

- When you hand Seth something with a deadline (an expiring approval link, a login code, a time-limited decision), also run `~/bin/notify -u critical -s ultimate -g <topic> -t <title> -m <where to find it> -o "$ULTIMATE_PUBLIC_URL/?conversation=<your conversation id>"`; it shows a critical toast that stays until dismissed, and clicking it opens your conversation in Helium. `$ULTIMATE_PUBLIC_URL` is set in your bash tool (the hub you run on, e.g. `http://127.0.0.1:4749`); your id is the `You are conversation #<id>` line in your prompt.
- Never put the link, code or secret itself in the toast, only where to find it, e.g. `-m "Approval waiting in #59372"`.
