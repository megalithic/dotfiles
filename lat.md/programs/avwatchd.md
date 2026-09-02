# avwatchd

`bin/avwatchd` is a single-file interpreted Swift daemon that observes native and browser AV state, fuses it into one presence snapshot, publishes NDJSON, and focuses known meeting or playing-media targets.

It runs as mise LaunchAgent `dev.mise.com.megadots.avwatchd` and listens on `~/.local/state/avwatchd/sock`. Policy remains in consumers: [[miccheck#Presence integration|miccheckd]] forces push-to-talk, while Hammerspoon observes transitions and exposes sharing state so [[notiwatchd#Rules and actions#Hammerspoon routing and suppression|notification routing]] can suppress local HUDs. Hammerspoon does not pause Music or change Focus/DND from avwatchd events.

## Architecture

Native layers stay inside `avwatchd`:

- CoreAudio process objects report microphone use and owner bundle IDs.
- CoreMediaIO reports whether any camera is active; it does not attribute camera owners.
- Exact Slack and Zoom microphone-owner bundle IDs create native meeting presence.
- A persistent `log stream` child watches `replayd` ScreenCaptureKit start, heartbeat, stop, and screenshot markers. Screenshot markers cancel pending starts. A 25-second heartbeat timeout clears abandoned OS capture state.

Browser state comes from `avwatchweb`, the local Manifest V3 extension under `mise/config/avwatchweb/`. `bin/helium-launch` loads it with `--load-extension`; its stable manifest key produces extension ID `ogfaajbfamngmlmkppahdpkoliobdemk`.

`main-hook.js` runs in the page MAIN world at `document_start`. It wraps `getDisplayMedia` and `getUserMedia`, observes track start, enabled, mute, unmute, and ended state, and listens for media-element play, pause, and end events. On supported meeting hosts, a debounced `MutationObserver` checks only exact Leave/End control selectors. It never scans body text, participant names, titles, media URLs, or Media Session metadata.

`bridge.js` validates MAIN-world messages in the isolated extension world. `service-worker.js` replaces payload tab identity and URL with `sender.tab` values, stores per-tab state in `chrome.storage.session`, and connects to native host `com.megadots.avwatchd`. `config.json` controls native host name, supported meeting origins/prefixes, playback observation, metadata policy, and reconnect delay.

The extension never enumerates tabs. Tab navigation and close events remove state. Service-worker restart restores session storage; native reconnect sends reset plus a full snapshot. Browser restart clears session storage and browser-assigned tab/window IDs. Extension reload cannot recover an already-running page realm without reloading that page; this is the intentional no-enumeration limit.

## Native messaging

Chrome launches `bin/avwatchd` with the calling extension origin; `--native-host` provides an explicit test mode.

Native mode validates the exact origin and extension ID. Frames contain a four-byte little-endian JSON length followed by at most 1 MiB of UTF-8 JSON.

The first extension frame is `hello` with protocol version 1 and a UUID session nonce. Every later frame must carry that nonce and an allowed type: `reset`, `snapshot`, `event`, `tab-reset`, `tab-removed`, or `focus-result`. The host keeps one Unix socket connection to the daemon, reconnects every two seconds, and emits native `status` frames. A successful reconnect makes the extension send reset plus snapshot again.

The daemon registers each native client and accepts browser messages only from that client and nonce. Native disconnect clears browser state. Tab snapshots contain only tab/window IDs, URL, meeting state, display-share state, user-media audio/video state, and active playback kinds.

Focus commands travel back over the registered native connection. The daemon chooses one known tab and sends its exact tab/window IDs. The extension calls `chrome.tabs.update(tabId, {active:true})` and `chrome.windows.update(windowId, {focused:true})`; no target or tab scan occurs.

## State fusion

Browser meeting state is `idle`, `lobby`, or `joined`.

Native apps resolve as `joined`; Athena may use `camera-active` when camera state and a known Athena tab provide the fallback. Joined browser tabs win over lobby tabs, and browser meetings win over native meeting owners for focus.

Browser display sharing and OS capture remain separate:

- `browserTabSharing`: a page-owned `getDisplayMedia` stream has live tracks.
- `osCaptureSharing`: `replayd` reports sustained ScreenCaptureKit capture.
- `sharing`: aggregate compatibility field.
- `sharingSource`: `none`, `browser-tab`, `os-capture`, or `both`.

A screenshot is neither browser-tab sharing nor sustained OS capture. No avwatchd path calls ScreenCaptureKit, Accessibility, `CGWindowList`, System Events, or Control Center, so it adds no Screen Recording prompt.

Playback state records only active state, media kind, tab/window IDs, and tab URL. It sends no page title, media source URL, page contents, participant names, or Media Session metadata.

## Socket protocol

`~/.local/state/avwatchd/sock` uses newline-delimited JSON. Every event carries the full version 2 presence snapshot.

Events include mic, camera, meeting, sharing, playback, state-change, and five-second heartbeat lines. Heartbeats let persistent consumers expire stale state without polling `get`.

Compatibility fields remain: `micActive`, `micOwners`, `cameraActive`, `inMeeting`, `meetingState`, `sharing`, `meetingApp`, `meetingURL`, `meetingTitle`, `meetingTargetId`, `inAppMic`, and `inAppCamera`. Version 2 adds sharing-source fields, exact meeting tab/window IDs, and playback state/URL/kind/tab/window IDs. Participant names were removed.

Commands:

- `{"cmd":"get"}` returns the current snapshot.
- `{"cmd":"focus"}` focuses the selected browser meeting tab or native Slack/Zoom app.
- `{"cmd":"focus-playback"}` focuses the selected playing-media tab.

## Consumers

`mise/config/hammerspoon/watchers/avwatchd.lua` keeps one `hs.socket` subscription.

It seeds with `get`, applies every event/heartbeat, reconnects after disconnect, and clears `M.state` after 15 seconds without data. It has no transition side effects. `mise/config/hammerspoon/lib/notifications/send.lua` reads exported `M.state.sharing` for HUD suppression.

Meeting, microphone, camera, and sharing changes produce observational Hammerspoon logs through a logger bound to `avwatchd`. Each transition includes daemon event/time plus meeting, app, target, and sharing context; microphone logs also include owners, and sharing logs include browser-tab and OS-capture state. Initial snapshots and state expiry/disconnects are logged. Unchanged state and five-second heartbeats are not logged, preserving evidence for native-host reset/snapshot churn without heartbeat noise.

[[miccheck#Presence integration|miccheckd]] seeds and subscribes through the same socket. An active seed or `inMeeting` transition forces push-to-talk. It reconnects every five seconds and ignores an idle first seed.

Hyper+z sends `focus` to avwatchd. Browser focus uses stored IDs; Slack and Zoom use `NSRunningApplication.activate(options: [])`.

## Setup and migration

`mise run setup:avwatchd` installs avwatchweb native messaging.

The Helium manifest lives at `~/Library/Application Support/net.imput.helium/NativeMessagingHosts/com.megadots.avwatchd.json`. It uses an absolute daemon path and allows only avwatchweb's stable extension origin.

Before the new agent starts, setup stops `dev.mise.com.megadots.media-presenced`, waits until launchd removes it, then trashes its stale socket and old cache logs. This ordering prevents the old process from unlinking or rebinding the new socket. `mise run up` runs setup before applying LaunchAgents. `mise run setup:helium` also runs setup and reminds the user to restart Helium.

The new LaunchAgent writes no stdout event log and sends low-volume diagnostics to `~/Library/Logs/avwatchd.log`. The executable uses `#!/usr/bin/swift`; it has no build step.

Helium keeps `--remote-debugging-port=9223` only for [[helium#Browser automation|chrome-devtools-attach]]. avwatchd has no CDP, target enumeration, or runtime DOM evaluation dependency.

## Validation

Automated smoke test: `node mise/config/avwatchweb/smoke-test.mjs`.

It exercises native framing, session registration, state fusion, schema rejection, direct focus routing, heartbeat delivery, and bridge-exit cleanup. Swift type checks use `/usr/bin/swiftc -typecheck - < bin/avwatchd` and `/usr/bin/swiftc -typecheck bin/miccheck.swift`.

Manual checks still require live browser/app interaction: Meet join/leave, tab-share start/stop, playback play/pause/end, exact focus with many tabs, each component restart, and confirmation that System Settings adds no Screen Recording request. Extension reload recovery requires reloading active pages by design.
