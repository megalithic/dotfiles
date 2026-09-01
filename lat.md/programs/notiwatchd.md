# notiwatchd

`mise/config/notiwatchd/notiwatchd.swift` is a single-file Swift daemon watching Notification Center deliveries via the usernoted SQLite store: matches JSON rules, records to its own DB, broadcasts NDJSON on a Unix socket, routes to sinks.

Sinks are `bin/ntfy`, arbitrary exec commands, and webhooks.

## Why the usernoted DB, not accessibility

The AX route broke on Tahoe and there is no public API for other apps' notifications; the usernoted SQLite store is the only reliable source and works on Tahoe 26.6.2 (verified live).

The old Hammerspoon AX watcher (`watchers/notification.lua`, Sequoia-era) broke because Tahoe renders banners with system SwiftUI and stacked notifications expose no recognized AX subrole. Every delivered notification lands as a row in `~/Library/Group Containers/group.com.apple.usernoted/db2/db` (`record` table, binary-plist `data` blob with `req.titl`/`req.subt`/`req.body`). Rows persist until dismissed/withdrawn (~1 week retention), so watching inserts catches even fast-withdrawn notifications (e.g. Slack read elsewhere).

## Architecture

A readonly watcher over the usernoted DB with a persisted high-water mark, kqueue + fallback-poll triggering, its own SQLite store, an NDJSON broadcast socket, and a hot-reloaded JSON config.

- Source: readonly SQLite connection to the usernoted DB. High-water mark on `rec_id` (persisted in own store's `state` table; re-anchors if the source DB resets). First run anchors at current max, no backlog spam.
- Trigger: kqueue `DispatchSource` file watchers on `db` and `db-wal` (write/extend/delete/rename, re-arms on delete/rename), debounced 200ms, plus a fallback poll (`poll_fallback_seconds`, default 30). Detection latency is ~5-6s after the banner because usernoted commits lazily, not because of the watcher.
- Store: `~/.local/share/notiwatchd/notifications.db` — `notifications` table with rec_id, uuid, bundle_id, title/subtitle/body, delivered_at, presented, style, matched rule, urgency, actions, per-action results JSON, raw request JSON.
- Socket: `~/.local/state/notiwatchd/sock` broadcasts every event as one NDJSON line to all connected subscribers (Hammerspoon or anything else can `nc -U` it).
- Config: `~/.config/notiwatchd/config.json` (mise-symlinked from `mise/config/notiwatchd/config.json`), hot-reloaded on mtime change and on SIGHUP. Current first-match routing sends Abby Messer questions through `urgent-messages` at critical urgency before the generic high-urgency Messages rule.

## Rules and actions

First matching rule wins. `match` fields: `bundle_id` (exact, string or array = any-of), `title`/`subtitle`/`body` (case-insensitive regex, string or array). Absent field = wildcard. Unmatched notifications get `default_actions` (default `["log"]`).

Actions: `log` (stdout only), `ignore` (record + broadcast, no routing; suppresses all other actions in the rule), `ntfy` / `ntfy:phone` / `ntfy:telegram` (exec `bin/ntfy send` with title, body, urgency, bundle ID, and no source prefix), `exec:<cmd>` (`/bin/sh -c`, event JSON on stdin), `webhook:<url>` (POST event JSON), `dismiss` (AX-close the still-visible banner/alert, see below).

Action results are recorded per-notification in the store's `action_results` JSON column: `--once` waits for sinks before inserting; daemon mode inserts immediately and patches results in via UPDATE when the sinks finish (all store access stays on the main queue).

### Hammerspoon routing and suppression

The `ntfy` action passes source identity to Hammerspoon so it can render and suppress HUDs in context.

It passes `-b <bundle-id> -S` to `bin/ntfy`. The bundle ID selects the HUD app icon and identifies the source app; `-S` keeps the raw notification title, usually the sender, for focused-window matching. `bin/ntfy` forwards both values to `lib.notifications.send`.

`routeNotification` uses the shared `C.notifier.urgencyDisplay` map, matching native redirects: high and critical notifications render centered with background dimming, and critical urgency keeps its configured phone route. `checkAttention` skips the local HUD in two additional cases:

- `watchers.media-presence` reports an active screen share through its exported `M.state` snapshot.
- The source app is frontmost and its focused window title matches the notification sender. A different conversation or window still receives the HUD.

Display, idle, and tmux-pane checks still run through the same attention path. Remote channels retain their own routing rules when the local HUD is suppressed. Hammerspoon now loads `media-presence`; the obsolete Sequoia AX `notification` watcher is retired because Tahoe no longer exposes the subroles it matched.

### The dismiss action (Tahoe AX route)

`dismiss` removes a still-on-screen banner/alert by performing the notification element's SwiftUI Close/Clear All custom action in the NotificationCenter process's AX tree — the only write path we have, since the usernoted DB is read-only for us.

Tahoe (26.6.2) NC AX structure, discovered with `.local_scripts/nc-ax-probe.swift` (probe kept uncommitted per `.local_scripts/` convention): `AXWindow subrole=AXSystemDialog "Notification Center"` → `AXGroup subrole=AXHostingView` → … → `AXGroup id=AXNotificationListItems` → per-notification `AXGroup` with subrole `AXNotificationCenterAlertStack` (stacked; children are `AXStaticText id=title/body`). The element's `AXDescription` concatenates app name, title, body (e.g. "Login Items, App Background Activity, …, stacked"). Close/Clear All are NSAccessibilityCustomActions whose AX action *names* are literal `Name:…\nTarget:…\nSelector:(null)` strings — match by `AXUIElementCopyActionDescription` (`Close` / `Clear All` / `Clear`) instead of the name, then `AXUIElementPerformAction`.

The daemon targets the banner by checking the AXDescription contains the event's title or body (case-insensitive) under any `AXNotificationCenter*` subrole element. Dismissing a stacked element clears the whole stack. Result strings recorded in `action_results`: `ok`, `ax-not-trusted`, `nc-not-running`, `no-title-or-body`, `not-on-screen`, `no-actions`, `no-close-action`, `ax-error=N`. Persistent alerts (`style=2`, e.g. BTM "App Background Activity") sit on screen indefinitely, so usernoted's lazy ~5-6s commit is no race; transient banners may already be gone (`not-on-screen`).

Validated live 2026-09-01: BTM alert triggered by bootstrapping a throwaway launchd agent was auto-cleared by the `background-activity-noise` rule (`actions: ["dismiss"]`) with `{"dismiss":"ok"}` recorded.

## Build, packaging, TCC

Reading the usernoted group container requires Full Disk Access, and TCC pins grants to the executable, so notiwatchd is compiled to a stable signed binary following the [[miccheck]] pattern instead of running as an interpreted script.

An interpreted `#!/usr/bin/swift` script would attribute the FDA grant to the Swift interpreter. Source and build script are colocated with the config in `mise/config/notiwatchd/` (only launchd-executed or manually-run entrypoints live in `bin/`). `mise/config/notiwatchd/notiwatchd-build` compiles to `~/.dotfiles/bin/notiwatchd` (gitignored artifact) with a stable codesign identifier (`com.megadots.notiwatchd`, Developer ID if available, ad-hoc fallback), `mise run setup:notiwatchd` wraps it, and `bin/notiwatchd-launchd` is the LaunchAgent entrypoint (`com.megadots.notiwatchd` in `mise/config/mise/global_config.toml`, RunAtLoad + KeepAlive). The compiled binary needs two one-time TCC grants in System Settings > Privacy & Security: Full Disk Access (read the usernoted store; daemon exits 1 with instructions when missing) and Accessibility (the `dismiss` action; recorded as `ax-not-trusted` when missing). With ad-hoc signing (no Developer ID identity) both grants die on every rebuild; re-toggle the entries off/on after `mise run setup:notiwatchd`. Ticket `dot-34nv` tracks a stable self-signed identity and signing-sandbox evaluation.

CLI flags: `--once` (drain and exit), `--replay N` (rewind high-water for testing), `--verbose`, and `--config/--store/--socket/--source` path overrides.

## Status and remaining work

Core notification watching, actions, and Hammerspoon routing work on Tahoe 26.6.2.

Validated live 2026-08-31/2026-09-01: DB watch + decode, rule matching, own-store recording, socket broadcast, `--once`/`--replay`, launchd agent + FDA + Accessibility grants, `dismiss` action end-to-end (BTM alert auto-cleared), and high/critical center-and-dim presentation.

Not yet done: stable non-ad-hoc signing (`dot-34nv`) and live validation of engagement and screen-share HUD suppression.
