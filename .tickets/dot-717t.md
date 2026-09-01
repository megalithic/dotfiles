---
id: dot-717t
status: in_progress
deps: []
links: []
created: 2026-06-26T21:03:08Z
type: epic
priority: 1
assignee: Seth Messer
tags: [avwatchd, swift, hammerspoon, helium, meetings, ready-for-development]
---

# Replace media-presenced with avwatchd and browser extension signals

Rename `bin/media-presenced` to `bin/avwatchd` and replace its Helium CDP meeting layer with a dotfiles-managed Manifest V3 extension plus Chrome native messaging. Keep CoreAudio, CoreMediaIO, and `replayd` as native-app and OS capture layers. Preserve daemon ownership of observation, state fusion, publication, and focus; keep mic mode, Music, Focus/DND, and notification HUD policy in consumers.

Relevant files: `bin/media-presenced`, `bin/miccheck.swift`, `bin/helium-launch`, `bin/smoke-test-macos.sh`, `mise/config/hammerspoon/watchers/media-presence.lua`, `mise/config/hammerspoon/bindings.lua`, `mise/config/hammerspoon/lib/notifications/send.lua`, `mise/config/mise/global_config.toml`, `mise/tasks/setup-helium`, and `lat.md/programs/media-presence.md`.

## Design

- Use `~/.local/state/avwatchd/sock` and `com.megadots.avwatchd`. Migrate safely from the old LaunchAgent and socket without letting stale agents unlink or own the new socket. Clients may fall back to the old socket only during migration.
- Install one local Helium MV3 extension from the dotfiles repo. Inject a MAIN-world `document_start` hook that wraps `getDisplayMedia`, reports capture start, and reports every returned video track's `ended` event. Keep page metadata limited to supported meeting state and media element playback state; never send page text, participant names, or unrelated tab data.
- Use extension service-worker state keyed by tab ID. Remove state on navigation, tab close, host disconnect, extension restart, and browser restart. Seed/reconcile active tabs after service-worker or native-host reconnect without broad DOM traversal.
- Implement `avwatchd --native-host` as a Chrome native-messaging stdio bridge. Validate extension message schema and origin fields, apply Chrome's 4-byte native framing, forward NDJSON to daemon socket, reconnect with bounded backoff, and return command results to extension.
- Track browser meeting, browser-tab share, playback, and exact tab/window IDs in `avwatchd`. Focus known meeting or playing-media tabs through extension `tabs.update` and `windows.update`; focus native apps through `NSRunningApplication`.
- Replace Hammerspoon polling with one persistent socket subscriber. Seed with `{"cmd":"get"}`, expire state after disconnect timeout, restore DND on stale state, and preserve notification HUD suppression through exported watcher state.
- Remove CDP code from `avwatchd` after extension state reaches parity. Keep Helium port 9223 only for browser tooling documented in `lat.md/programs/helium.md`.
- Keep `replayd` state separate from browser-tab sharing. Screenshots must never produce sustained sharing state or Screen Recording prompts.

## Acceptance criteria

1. `bin/avwatchd` replaces `bin/media-presenced`; LaunchAgent, socket/state/log paths, setup tasks, smoke checks, consumers, comments, and docs use `avwatchd` names.
2. Migration setup stops and removes stale `media-presenced` LaunchAgent state and stale socket before starting `avwatchd`; existing miccheck and Hammerspoon clients reconnect without restoring unsafe mic or DND state.
3. Dotfiles-managed Helium MV3 extension installs locally with a stable extension ID and a matching native-host manifest restricted to that ID.
4. MAIN-world `document_start` hook reports tab-share start immediately and stop on track end. Reload, browser restart, extension restart, bridge restart, and daemon restart reconcile or clear stale per-tab state.
5. Extension reports media play, pause, and end with exact tab/window IDs, URL, media kind, and non-sensitive metadata only. It sends no page contents, participant names, or unrelated browsing data.
6. `avwatchd --native-host` validates message version, event type, tab/window IDs, URL scheme/host policy, and source nonce before forwarding framed native messages to the daemon socket. It reconnects after daemon restart without losing stdio framing.
7. `avwatchd` fuses browser events with CoreAudio, CoreMediaIO, native-app mic owners, and `replayd`. Protocol distinguishes browser-tab sharing, OS capture sharing, and screenshots.
8. `{"cmd":"focus"}` selects a known meeting tab directly. Playback focus command selects a known playing-media tab directly. Neither command enumerates tabs or traverses page DOM.
9. Hammerspoon uses a persistent socket subscription, has no 3-second detector, pauses Music on meeting start, controls DND during meeting sharing, clears stale state, and keeps notification HUD suppression behavior.
10. miccheck seeds and subscribes through the renamed socket, forces push-to-talk during active meeting recovery, and handles daemon restart safely.
11. Runtime `avwatchd` code contains no CDP client, target enumeration, or DOM classifier. Helium debugging port remains only for other documented tooling.
12. Focused automated checks cover native framing, schema rejection, per-tab cleanup, state fusion, stale-state expiry, direct focus routing, and migration paths; existing tests still pass.
13. Live checks cover Meet join/leave, tab-share start/stop, media play/pause/end, many-tab direct focus, component restarts, no broad traversal, and no new Screen Recording prompt. Any manual-only result is recorded in ticket notes.
14. `lat.md/programs/avwatchd.md` documents architecture, protocol, setup, permissions, performance constraints, migration, and validation; `lat check` passes.

## Notes

**2026-06-30T17:50Z**

Migrated daemon source to one editable Swift script at `bin/media-presenced`; removed SwiftPM/nix package path. Home-manager LaunchAgent then pointed directly at the script.

**2026-06-28T01:49Z**

Implemented initial Hammerspoon socket consumer and hyper+z focus command. Later work moved miccheck policy into miccheck's direct socket subscriber.

**2026-07-07T12:44Z**

Validated Helium CDP startup and native Slack mic-owner detection. Subsequent testing validated Zoom focus and `replayd` heartbeat sharing.

**2026-09-01T18:00Z**

Re-scoped ticket around `avwatchd`, local Helium extension, native messaging, event-driven consumers, direct tab focus, and CDP removal. Browser-tab sharing cannot be observed through `replayd`, ScreenCaptureKit stream inventory, or Control Center. A bounded browser-chrome AX probe was fast but cannot provide reliable media state and is excluded from runtime design.

**2026-09-01T18:52:34Z**

2026-09-01 implementation: renamed daemon/socket/LaunchAgent to avwatchd; added avwatchweb MV3 extension, generated native-host setup, framed --native-host bridge, browser state fusion/direct focus, event-driven Hammerspoon subscriber, miccheck migration, stale-agent/socket/log-child cleanup, protocol v2 sharing-source/playback fields, and CDP removal. Automated Swift/JS/JSON/shell checks and avwatchweb smoke pass. Live-validated old-agent migration, daemon/miccheck/Hammerspoon/bridge/Helium restarts, extension load with expected ID, heartbeat subscriber state, one replayd child after restart, and browser playback play/pause plus exact focus. Manual live Meet join/leave and interactive getDisplayMedia tab-share start/stop remain; no ScreenCaptureKit/AX/CGWindow APIs were added, so no new Screen Recording permission path exists.

**2026-09-01T19:01:16Z**

2026-09-01 final validation: reviewer issues fixed (SIGPIPE/slow-client bounds, replayd chunk buffering, private socket permissions, single native session, media-removal playback cleanup). Live-validated Hammerspoon 15s stale expiry/reconnect and playback cleanup when a playing element is removed. Playback observation on all HTTP(S) tabs is intentional and configurable with playbackEnabled; only active state, kind, tab/window IDs, and URL leave the extension.
