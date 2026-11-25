## Host basics

- Seth's login shell is fish. Commands he runs himself are fish syntax: `for i in (seq 6); ...; end`, `set -x VAR val`, `(cmd)` not `$(cmd)`, no `export`. Your own bash tool calls stay bash.
- macOS on both Macs (`workbookpro`, `megabookpro`). Versions differ per host and change with updates: check `sw_vers` and `fish --version` before stating one.
- Tools come from mise (`~/.dotfiles/config/mise/config.toml`); no global installs.
- Browser: Helium (`net.imput.helium`). Hammerspoon is the default URL handler and routes links to it.
- GNU sed comes first on PATH via mise (`config/mise/config.toml` `_.path`), so BSD `sed -i ''` fails. Change files with your edit tools; in scripts, use GNU sed syntax.
- `rg` reads `~/.config/ripgrep/rc` (`RIPGREP_CONFIG_PATH`), which adds line:col prefixes, `--hidden` and `--follow`. Use `rg --no-config` when a script or pipeline parses its output.

## Changing ~/.dotfiles

- Every agent, including other projects' @ultimates, changes `~/.dotfiles` and anything linked from it only through a branch of the `.dotfiles` hub, or by asking the hub's @ultimate to start one.
- Never edit the main checkout (`~/.dotfiles`) or a deployed link target (`~/.config/…`, `~/.ultimate/…`, `~/.pi/…`, `~/bin`) in place. The exception: settings files Seth's own apps write through their links.

## Certainty

- Before naming a cause, check the user's own config and history (key mappings, captures, recent changes) and the logs, and reproduce it. Until then, call the cause unverified.
- Every completion says who acts next and on which machine: "Seth, on workbookpro: approve card 12", never just "waits on @ultimate".

## Time-sensitive handoffs

- When you hand Seth something with a deadline (an expiring approval link, a login code, a time-limited decision), also run `~/bin/notify -u critical -s ultimate -g <topic> -t <title> -m <where to find it>`; it shows a critical toast that stays until dismissed.
- In Ultimate, add `-o "$ULTIMATE_PUBLIC_URL/?conversation=<your conversation id>"` so clicking the toast opens your conversation in Helium. `$ULTIMATE_PUBLIC_URL` is set in your bash tool (the hub you run on, e.g. `http://127.0.0.1:4749`); your id is the `You are conversation #<id>` line in your prompt. Pi has no conversation URL: leave `-o` out there.
- Never put the link, code or secret itself in the toast, only where to find it, e.g. `-m "Approval waiting in #59372"`.
- Give the prerequisites (account, workspace, admin approval, which machine) before you hand over anything time-limited, so it is not spent before Seth can use it.
