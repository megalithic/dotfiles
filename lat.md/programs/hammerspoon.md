# Hammerspoon

Hammerspoon owns macOS automation: window management, launcher panels, menubar state, and clipboard tooling. mise owns it on both hosts — brew cask app, config in `config/hammerspoon/`, fragments in `~/.local/share/hammerspoon/`.

mise installs the app through `brew-cask:hammerspoon`, and `[dotfiles]` links `~/.config/hammerspoon` to `config/hammerspoon/`.

## Ownership flip from nix

The former HM module (`nix/home/common/programs/hammerspoon/`) is removed; its launchd launcher + nix-store app copies caused duplicate instances at login.

The old setup installed `pkgs.brewCasks.hammerspoon`, generated `nix_path.lua`, and ran a launchd launcher agent that opened the Home Manager Apps copy. Duplicates happened because macOS window-resume relaunched the previous session's raw `/nix/store/...` path while the launchd agent opened the HM Apps path, and every rebuild minted a new store path that LaunchServices registered as a distinct app.

Now Hammerspoon's own `hs.autoLaunch` login item points at stable `/Applications/Hammerspoon.app`. mise owns `MJConfigFile`, and no Hammerspoon launch agent, Home Manager app copy, or nix-darwin preference remains. `config/hammerspoon/preflight.lua` sets the global `PATH` (mise shims first, then Homebrew and `~/bin` paths) and `TASK_ENV` (NOTES_HOME, XDG_*, DOTS) inline; `overrides.lua` injects both into every `hs.task`. The former `~/.local/share/hammerspoon/nix_path.lua` fragment and its `NIX_PATH`/`NIX_ENV` globals are gone.

The old nix twin `config/hammerspoon/` is retired and no longer linked anywhere; `config/hammerspoon/` is the sole source. Historical divergences that lived across the twins (kanata `daemonLabel` `dev.mise.` prefix, kanata stderr log path) are now just the mise values — the `dev.mise.` label comment in `config.lua` remains until kanata's own ownership is unified. EmmyLua's generated `annotations/timestamps.json` is repo-ignored runtime state.

The mise `up` task ends by calling `bin/hs-reload` (non-fatal if Hammerspoon is not running) so a freshly synced config is picked up safely.

## Tests

All Hammerspoon tests, mocks, and fixtures live in `config/hammerspoon/tests/`, separate from runtime modules.

Run `mise exec -- lua tests/run.lua` and `mise exec -- lua tests/pidewave.test.lua` from `config/hammerspoon/`. From the repo root, run `mise exec -- python3 -B config/hammerspoon/tests/pidewave-focus.test.py` and `mise exec -- node --test config/hammerspoon/tests/pidewave-inspect.test.mjs`. Python's `-B` keeps test runs from writing bytecode beside the production helper.

## Dock watcher

The dock watcher matches the configured TS4 USB vendor and product IDs. Connecting the dock turns Wi-Fi off; disconnecting it turns Wi-Fi on.

`config/hammerspoon/watchers/dock.lua` uses `hs.usb.watcher`. Startup inspects attached USB devices once and applies the initial state. Duplicate state events and unrelated USB devices do nothing.

The dock reads actual Wi-Fi power and interface through `hs.wifi.interfaceDetails()` and calls `hs.wifi.setPower()` only when power needs to change. Successful power changes are logged; unavailable interfaces and failed changes log and notify without background retries. There is no network watcher, Ethernet/default-route check, Wi-Fi shell task, or Wi-Fi timer. A connected dock turns Wi-Fi off even without working Ethernet; later network or manual Wi-Fi changes do not trigger dock actions.

Kanata remains driven by the Leeloo USB product ID, independently of dock state. Bluetooth keyboard polling remains removed because Leeloo Bluetooth state was unreliable. Audio selection stays with the independent audio-device watcher; the dock does not apply the legacy `docked`/`undocked` audio settings. One asynchronous Kanata task checks the current `kanata.kbd` symlink and launchd state, changes the symlink, restarts the daemon, waits, and verifies launchd without blocking Hammerspoon's event loop.

Kanata switches are serialized. If USB state changes during a switch, the newest requested profile runs next. An unchanged failed target retries once, then logs and sends a notification. If the requested profile already runs, Hammerspoon logs success and skips `launchctl kickstart`, so config reloads do not bounce Kanata. Restart diagnostics report stderr only if the stderr file changed during that attempt. Stopping the watcher terminates its active tasks and ignores stale callbacks.

## Reload safety

**Hammerspoon must only be reloaded via `bin/hs-reload`.** Unsafe CLI reload paths can crash Hammerspoon.

`bin/hs-reload` prefers `open -g hammerspoon://hs-reload`, which Hammerspoon handles inside its own process by calling the wrapped `hs.reload()` cleanup path. It does not use `hs` CLI reload or `hs` CLI menu selection, because those IPC paths can crash/kill Hammerspoon while reloading.

If the running config is too old to have the URL handler, `bin/hs-reload` falls back to a System Events menu click and fails with an Accessibility-permission error instead of trying unsafe IPC fallbacks. Hammerspoon loads no data from `~/.local/share/hammerspoon`; all configuration lives in `config/hammerspoon/`.

## Tidewave inspector handoff

`init.lua` loads `lib/interop/pidewave.lua`. Its Cmd+Shift+C event tap consumes the chord only when the focused Ghostty window identifies a connected foreground Pi.

Ineligible keys pass through; Ghostty's existing local `ignore` binding still discards this chord within Ghostty. Other applications retain their own shortcut behavior.

`lib/interop/pidewave-focus.py` verifies the title's exact tmux session/window/pane and pane-root PID, active pane/window, absence of copy mode, and a matching focused Ghostty tmux client. It requires exactly one connected bridge registration with a heartbeat younger than 45 seconds, a safe reported Tidewave endpoint, and a Unix socket owned by the manifest's live Pi PID. That PID must share the pane TTY's foreground process group and must not be stopped or a zombie. The title's pane-root PID and manifest's Pi PID are separate identities. Printable pipe-separated tmux output and shell-quoted helper arguments preserve existing parsing safeguards.

One external `gtimeout --signal=KILL 0.20` bounds the helper, including filesystem and subprocess work. Missing tools, timeouts, invalid output, stale registrations, or focus changes pass the key through. Lua checks elapsed monotonic time and rereads the focused window/title after the helper returns. Browser work runs outside the event tap; execution and the final browser handoff revalidate the captured registration rather than switching to another Pi. There is no polling cache or HTTP-probe authorization fallback.

Pi's bridge publishes `tidewaveConnected` and `tidewaveEndpoint` together from validated stock adapter status and ACP endpoint events. ACP supplies the literal URL it registered with the adapter and confirms runtime ownership through the adapter's snapshot API; bridge requires exactly one connected, enabled `tidewave` entry as well. Either event order works at startup and `/reload`, without a prompt once both inputs exist. Runtime registration can leave a warm adapter deferred until an MCP operation initializes it; the shortcut stays inactive until connected. Pi's `/pidewave` command reloads and then runs `/mcp reconnect tidewave`, making the shortcut available in one step, and reports whether Tidewave actually connected. Hammerspoon uses the exact reported scheme, host, and port, then requires the live Phoenix listener's worktree root to match Pi's git root. Missing identity fails closed; inferred ports, config mirroring, cached tools, and HTTP liveness never authorize the shortcut.

Before listing tabs, the handler requires an already-running Helium process that owns CDP port 9223. It never launches Helium, opens tabs, or navigates them. It ignores `/tidewave` routes, prefers a unique saved CDP target prefix among exact-origin app pages, otherwise accepts a sole app page, and notifies and stops for missing or ambiguous matches. Target identity survives in-tab navigation. Failed handoffs leave the existing binding, including legacy `tabUrl` or `migrationUrl`, untouched.

The handler calls CDP `Page.bringToFront`, activates Helium, rechecks the exact app origin, and waits for a complete visible page and an enabled visible Inspect button. It clicks an inactive button once; an already-selected button waits for its panel without toggling off. Success requires both selected button and inspector panel. Only then does it save the target prefix and reported app origin in the optional [[lat.md/programs/pi-coding-agent#Session and routing extensions|Tidewave IDE Chat binding]], removing legacy route fields. CDP failures retain bounded merged stderr in notifications. Toolbar inspection does not route through `acp.ts`.

The focused-Pi and endpoint changes are not yet live-verified: no Hammerspoon reload, Pi reload, or browser activation has been performed for this rollout. Automated Lua, Python, Inspect JavaScript, ACP, bridge, and isolated adapter-contract tests pass. The manifest schema is unchanged. Coordinated live checks still require project config migration, a safe Pi reload and connected Tidewave status, Hammerspoon reload through `bin/hs-reload`, and Cmd+Shift+C against an existing matching Helium tab. See [[lat.md/programs/pi-coding-agent#Pi coding agent#Runtime settings#Tidewave endpoint publication]] for endpoint ownership and the accepted deferred-startup trade-off.

Tidewave's toolbar "Copy prompt" only writes the composed prompt to the clipboard, so after Inspect activates the handler arms a five-minute `hs.pasteboard.watcher`. Clipboard changes containing `<user_prompt>` are forwarded to the bound pane's bridge socket as `pi.control.v1` `message.send` (`mode: follow_up`, `from: tidewave`) through `lib/interop/pi.lua`'s pooled `sendPayload`, with consecutive-successful-copy suppression and a success or failure notification per copy. A failed write can be retried by copying the same prompt again. If the optional binding file cannot be written, the relay still uses the validated Pi manifest. Before `hs.socket:connect`, `pi.lua` applies `hs.http.encodeForQuery` because Hammerspoon routes Unix paths through `NSURL`; otherwise a pane suffix such as `%414` is percent-decoded and targets the wrong socket. CocoaAsyncSocket queues the first write during its asynchronous connect, and the pool checks `socket:connected()` before reusing an established connection. The watcher stops on TTL expiry, at the start of every new handshake (successful or not), on module stop, and through `init.lua`'s reload/shutdown cleanup, so reloads and failed re-handshakes cannot leave a stale binding's watcher forwarding prompts. Delivery is write-initiated: the success notification says "confirm in tmux" because bridge-level rejections surface asynchronously in logs. Non-prompt clipboard activity passes through untouched.

## Global app bindings

Global app bindings stay data-driven so app launchers, local pass-through keys, and URL-scheme actions share one configuration surface instead of per-app binding code.

`C.launchers` rows use `{ bundleID, bind, opts? }`: simple launchers omit `opts`, while `opts.passThrough`, `opts.focusOnly`, `opts.cycleWindows`, `opts.urlSchemes`, and `opts.launchCommand` handle exceptions. `opts.launchCommand` (string or argv table) replaces the LaunchServices cold start with a detaching launcher script — LaunchServices forwards no command-line flags, so launchers that need them (Helium's CDP port via `bin/helium-launch`) spawn the script through `hs.task`; focus/cycle of an already-running app never respawns. When `opts.cycleWindows = true`, hitting the app binding while that app is focused cycles visible app windows rather than browser tabs. Tuna maps `hyper+space` to its native `tuna://search` route, which toggles its panel; its own global activation shortcut remains `cmd+space`. Fantastical keeps `hyper+y` as the app toggle; `hyper+'` opens `x-fantastical3://parse?sentence=`; `hyper+shift+'` opens `x-fantastical3://parse?reminder=1&sentence=`.

## URL routing

Hammerspoon can act as the HTTP/S handler for app deep links while preserving browser auth flows.

`config/hammerspoon/watchers/url.lua` redirects Figma web URLs to `figma://...`, but paths containing `auth` such as `/app_auth` pass through to the browser.

## shade-next panel

shade-next bindings are split between generated data and handwritten lifecycle code.

mise `[dotfiles]` links `~/.config/shade-next/config.toml` from `config/shade-next/config.toml` (the former nix shade-next module is removed). `config/hammerspoon/shade_next.lua` carries the app, launch, chord, and prefill data inline (derived from `HOME`), replacing the former `~/.local/share/hammerspoon/fragments/shade-next.lua` fragment. The panel design spec lives in `~/.local/share/pi/docs/shade-next/panel-design.md`.

Key behavior: one panel-height rule across all states; block types are result cards, section lists, message rows, composer, and preview; Esc always hides the panel; route keys reserve Ctrl+n for note, Ctrl+p for Pi, Ctrl+c for calc. Compact launch geometry starts at `900×104` points and grows result panels to visible rows before clamping to the configured max height.

`hyper+return` talks directly to shade-next's control socket when the app is running. On a cold start, it invokes the mise-installed `shade-next` wrapper with the `shade-next://toggle` URL; the wrapper repairs the `~/Applications` symlink and LaunchServices registration before opening the URL. Direct URL dispatch remains only as a fallback for installs without the wrapper. The installed wrapper also makes bindings active without a local source build. When shade-next shows, it records the frontmost app before activating itself and restores it on hide without Accessibility APIs. `hyper+n` enters the route modal (`p` prefills `pi`, `n` prefills `note`). Legacy Shade keeps `hyper+return` for `shade.smartToggle()` and moves its advanced modal to `hyper+shift+n`.

The `[ui]` table in `config/shade-next/config.toml` owns panel visual defaults including `border_width`, `border_color`, and `dim_unfocused`; the panel is non-opaque so the rounded material surface shows real transparency.

## Window management

Window management uses the custom `wm.lua` grid/geometry path on `hyper+l`; native Tahoe menu tiling is optional on `hyper+w`.

`wm.lua` converts the configured `C.grid` `60×20` positions into proportional screen-local frames and applies `C.windowGap` as a pixel inset so chained movement, center sizing, split tiling, browser tab splitting, and app layout automation keep spacing across displays. WM hypemode auto-exits after 2s idle; chained keys use a 1.25s `chainExitDelay`. `hyper+l,s` moves the active Helium/Chromium tab into a right-half window via `lib.interop.browser:splitTab(false)`; `hyper+l,shift+s` moves it full-size to the next screen.

App and window watchers run layout rules on launch and window creation (not `mainWindowChanged`, which fired too often). Rule precedence is per-window: a non-empty title pattern matches first and only the first specific match places the window; a catch-all rule applies only when no specific rule matched. Manual placements bypass one later auto-layout pass through a short-lived per-window suppression entry that `placeApp` consumes.

## App watcher lifecycle

The app/context watcher stack (`watchers/app.lua`, `contexts/`, `lollygagger.lua`) is dormant. `init.lua` loads the audio, avwatchd, url, pasteboard, and dock watchers. The stack stays lifecycle-correct for re-enablement.

Per-app `hs.uielement` watchers are keyed by PID, matching `hs.uielement`'s own termination cleanup. `hs.application.watcher` terminated events arrive with a nil app name and an app object only useful for its PID, so the global callback routes them to a dedicated terminated handler: it stops and removes the per-app watcher, then runs context deactivation and lollygagger cleanup with the bundle ID cached at watch time. A relaunched app gets a fresh PID and is re-watched; the old bundleID keying blocked re-watching forever.

`contexts:preload()` is idempotent — context scripts load once per Lua state, so watcher restarts reuse existing context modals instead of minting duplicates. Context lifecycle hooks run protected: a failing hook logs instead of erroring the watcher callback (terminated events hand hooks a dead `appObj`). Stopping the app watcher exits any still-entered context modal so its hotkeys release.

The shared Hyper modal binds its physical key once across all `req("hyper", { id })` namespaces. Passthrough and app-chord bindings that wait for an app to front poll at 0.1s and give up after 10s instead of waiting forever. The quitter tracks its double-press auto-exit timer so a stale timer cannot exit a newer confirmation modal.

`config/hammerspoon/tests/run.lua` (run `lua tests/run.lua` from `config/hammerspoon/`) exercises the stack against a mock Hammerspoon runtime with a virtual clock: USB dock startup and transitions; vendor/product matching; duplicate and unrelated events; unchanged Wi-Fi power; native Wi-Fi API failures; absence of Wi-Fi tasks/timers; stale callback cleanup; independent Kanata serialization/retry/cleanup; watcher registration/termination/relaunch; context preload idempotence and frontmost gating; erroring-hook isolation; lollygagger timer cancellation; hyper bind dedupe and bounded waits; and quitter double-press timer races.

Known dormant hotspot, documented not fixed: `watchers/camera.lua` runs blocking `lsof`/`ps` in camera callbacks and needs `hs.task` conversion before re-enablement.

## Remote notifications

Telegram polling and Contacts lookups are disabled; outbound Telegram notifications remain available.

`C.notifier.telegramPollInterval = false` disables both the initial Telegram poll and its repeating timer. Outbound Telegram delivery stays enabled when credentials are available; incoming messages and button replies are not processed. The notification facade preserves `false` when passing the interval to `lib/interop/telegram.lua`.

`C.notifier.agent.phone.enabled = false` disables iMessage notification delivery, including explicit phone requests and retry escalation. The shared `sendPhone` guard returns before looking up a number, so Hammerspoon does not access the Contacts app.

## Miccheck menubar

The old `miccheck.lua` module is gone; push-to-talk/push-to-mute now lives in the standalone [[miccheck]] menubar app, and Hammerspoon only sends it mode commands.

`config/hammerspoon/lib/micctl.lua` is the one-shot socket client (`setPTTMode`, `toggleMode`) for manual/context controls such as `contexts/co.detail.mac.lua`. [[avwatchd#Consumers|Meeting enforcement]] runs through miccheckd's own persistent avwatchd subscription. Eventtap, menubar icon, hotkeys, and mute logic live in the compiled Swift app.

## Audio device watcher

`config/hammerspoon/watchers/audio.lua` selects preferred audio devices after debounced `hs.audiodevice.watcher` events.

It uses a trailing timer for `dev#` bursts, calls Hammerspoon's `hs.audiodevice` API, and logs deterministic device-change messages only when the default device actually changes. It intentionally does not shell out to `SwitchAudioSource` for status text because shell output can include terminal control sequences when Hammerspoon runs inside a console/tmux-shaped environment.

## Clipper and utilities

Hammerspoon utility helpers include `U.case`, an ordered value/predicate matcher used for small pattern-matching branches.

The pasteboard watcher inspects UTIs before reading content. Text changes reuse the watcher callback's string; image changes read one preview and one raw image representation. The clipper assigns each image a monotonic capture ID, renders one passive HUD update, and sends the raw bytes to ImageMagick over an `hs.task` stdin pipe. No image encoding, compression, or file write runs on Hammerspoon's main thread. Each save, upload, resize, OCR, and full-screen capture callback must own its task slot and match the current capture ID before it changes state.

Hyper+Shift+V enters the clipper action modal. New captures only show the passive HUD, and leaving the modal keeps that HUD visible; Esc or a panel click dismisses it. Image paste writes suppress their exact pasteboard `changeCount`, so the watcher skips the clipper's write without skipping a later external capture. The custom full-screen capture hotkey runs `screencapture` and optional ImageMagick resizing through `hs.task` before it writes PNG data to the pasteboard.

Oversized captures keep the 5MB upload gatekeeper, show a resizing warning, then ImageMagick compresses the PNG to a conservative JPEG target before replacing the upload path. The clipper calls `capper` with `{ "capper", imagePath }`; `bin/capper` owns fnox wrapping when DO Spaces variables are missing. Capper passes secrets to `s3cmd` through AWS environment variables, always uses `--config=/dev/null`, and never reads `~/.s3cfg` or puts secret values in argv. System jankyborders is not managed by nix-darwin; visible focus indication comes from tmux/Hammerspoon/Ghostty UI settings.
