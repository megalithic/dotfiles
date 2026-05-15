---
name: web-browser
description: "Interact with web pages using Chrome DevTools Protocol. Launches a managed browser instance (Helium / Brave Nightly / Chrome) with an isolated profile and exposes nav, eval, screenshot, pick, and emulation helpers. Run scripts/start.js first."
---

# Web Browser Skill

Minimal CDP-based browser automation. Scripts live in `scripts/` and run via
`node`. The skill manages its own browser instance with an **isolated profile
cache** — it never attaches to your live browser profile.

> Adapted from [mitsuhiko/agent-stuff](https://github.com/mitsuhiko/agent-stuff/tree/main/skills/web-browser) with Helium + Brave Nightly support.

## Start the browser

```bash
./scripts/start.js                  # Fresh isolated profile (default)
./scripts/start.js --profile        # Copy WEB_BROWSER_PROFILE into cache
./scripts/start.js --reset-profile  # Clear cached profile before launch
```

Launches the browser with remote debugging on `:9222`.

### Profile cache layout

```
~/.cache/agent-web/browser/
  fresh-profile/    # default (--no flag)
  profile-copy/     # --profile mode
  state.json        # pid, port, mode, binary
```

### Browser binary resolution

Default preference order (first match wins):

1. `$WEB_BROWSER_PATH` (if set + exists)
2. `/Applications/Helium.app/Contents/MacOS/Helium`
3. `/Applications/Brave Browser Nightly.app/Contents/MacOS/Brave Browser Nightly`
4. `/Applications/Brave Browser.app/Contents/MacOS/Brave Browser`
5. Google Chrome / Chromium / Chrome Canary

### Profile source resolution (`--profile` mode)

1. `$WEB_BROWSER_PROFILE` (if set + exists)
2. `~/Library/Application Support/BraveSoftware/Brave-Browser-Nightly`
3. `~/Library/Application Support/BraveSoftware/Brave-Browser`
4. `~/Library/Application Support/Google/Chrome`

### Env vars

| Var                   | Default (nix)                                                                  | Purpose                            |
|-----------------------|--------------------------------------------------------------------------------|------------------------------------|
| `WEB_BROWSER_PATH`    | `/Applications/Helium.app/Contents/MacOS/Helium`                               | Browser binary                     |
| `WEB_BROWSER_PROFILE` | `~/Library/Application Support/BraveSoftware/Brave-Browser-Nightly`            | Source profile for `--profile`     |
| `BROWSER_DEBUG_HOST`  | `localhost`                                                                    | CDP host                           |
| `BROWSER_DEBUG_PORT`  | `9222`                                                                         | CDP port                           |
| `DEBUG`               | unset                                                                          | Set to `1` for verbose stderr      |

`WEB_BROWSER_PATH` + `WEB_BROWSER_PROFILE` are set via `home.sessionVariables`
in `home/common/programs/pi-coding-agent/default.nix`. Override per-shell by
exporting before invoking the scripts.

## Navigate

```bash
./scripts/nav.js https://example.com         # current tab
./scripts/nav.js https://example.com --new   # new tab
```

## Evaluate JavaScript

```bash
./scripts/eval.js 'document.title'
./scripts/eval.js 'document.querySelectorAll("a").length'
```

Runs in async context. Prefer single quotes to avoid shell escaping.

## Screenshot

```bash
./scripts/screenshot.js                       # viewport
./scripts/screenshot.js --full-page           # full document
./scripts/screenshot.js --device iphone-14    # one-off mobile emulation
./scripts/screenshot.js --device pixel-7 --full-page
```

Writes to a temp file and prints the path.

## Device emulation (persistent)

```bash
./scripts/emulate.js --list             # show available presets
./scripts/emulate.js iphone-14          # apply preset
./scripts/emulate.js pixel-7 --landscape
./scripts/emulate.js --reset            # clear
```

Sets an **active** emulation preference. `nav.js`, `eval.js`, `pick.js`,
`dismiss-cookies.js`, and `screenshot.js` automatically reapply it.

## Pick elements

```bash
./scripts/pick.js "Click the submit button"
```

Interactive picker. Click to select, Cmd/Ctrl+Click for multi-select, Enter to
finish.

## Dismiss cookie dialogs

```bash
./scripts/dismiss-cookies.js          # accept
./scripts/dismiss-cookies.js --reject # reject where possible
```

Common chain:

```bash
./scripts/nav.js https://example.com && ./scripts/dismiss-cookies.js
```

## Logs (console + errors + network)

`start.js` automatically spawns `watch.js` which writes JSONL to:

```
~/.cache/agent-web/logs/YYYY-MM-DD/<targetId>.jsonl
```

Tail:

```bash
./scripts/logs-tail.js            # dump current log + exit
./scripts/logs-tail.js --follow   # keep following
```

Summarize network responses:

```bash
./scripts/net-summary.js
```

## Quick mobile debug flow

```bash
./scripts/start.js
./scripts/nav.js https://example.com
./scripts/emulate.js iphone-14
./scripts/nav.js https://example.com       # reload with mobile UA
./scripts/dismiss-cookies.js
./scripts/screenshot.js --full-page
```

## Runtime dependencies

Scripts require the `ws` npm module (declared in `scripts/package.json`).
The skill directory is **read-only** in nix-store; node_modules wiring is
handled by the surrounding nix build (see ticket dot-ol82 / 3.7). If you
hit `Cannot find package 'ws'`, the npm install step has not yet been
wired — install manually:

```bash
cd ~/.pi/agent/skills/web-browser/scripts  # read-only — copy out first
# or use a writable mirror
```

## Migration notes (vs old agent-browser CLI)

The previous version of this skill required `browser connect 9222` against a
user-launched browser. The new version **owns** the browser lifecycle and uses
an isolated profile — your daily browser stays untouched. No `connect` step.
