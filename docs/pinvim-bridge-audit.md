# Pinvim / bridge audit

## Scope

Ticket: `dot-3t42` — research only. Do not delete `bridge.ts` here.

Audited files:

- `home/common/programs/pi-coding-agent/extensions/bridge.ts`
- `home/common/programs/pi-coding-agent/extensions/pinvim.ts`
- `home/common/programs/pi-coding-agent/extensions/notify.ts`
- `home/common/programs/pi-coding-agent/skills/tell/scripts/tell.sh`
- `config/hammerspoon/lib/interop/pi.lua`
- `config/hammerspoon/lib/interop/pi-gateway.lua`
- `config/hammerspoon/lib/notifications/init.lua`
- `config/hammerspoon/lib/notifications/send.lua`
- `config/hammerspoon/lib/interop/telegram.lua`
- `config/nvim/lua/pinvim.lua`
- `config/nvim/after/plugin/pi_legacy.lua`
- `bin/ntfy`
- `bin/tmux-toggle-pi`
- `bin/ftm`
- `home/common/programs/pi-coding-agent/default.nix`

Verification search used:

```bash
rg -n "bridge|PI_SOCKET|PI_STATE_DIR|manifests|pi-.*\.sock|type.?=.?(telegram|tell)|telegram|tell|pinvim|pisock" home/common/programs/pi-coding-agent config bin docs -g '!**/node_modules/**'
```

## Current `bridge.ts` status

`bridge.ts` is now legacy-only and disabled unless `PI_BRIDGE_LEGACY_SOCKET=1`.

Current behavior if enabled:

- listens on `${PI_STATE_DIR}/sockets/pi-{session}-{window}.sock`, or `PI_SOCKET` override
- writes `${PI_STATE_DIR}/manifests/{socket-basename}.info`
- accepts newline-delimited JSON
- returns `{ ok: true }` or `{ ok: false, error }`
- handles `ping` with `{ ok: true, type: "pong" }`
- handles `{ type: "telegram", text, source?, timestamp? }`
- handles `{ type: "tell", text, from?, timestamp? }`
- rejects nvim/pinvim-owned frames: `hello`, `heartbeat`, `prompt`, `explicit_send`, `editor_state`, `editor_disconnect`
- still formats no-`type` legacy nvim payloads, but this path should not receive traffic after pinvim cutover

`pinvim.ts` now owns primary socket by default and also currently accepts `telegram`, `tell`, and legacy no-`type` nvim payloads for compatibility.

## Consumers inventory

### 1. Nvim / pinvim new path

Files:

- `config/nvim/lua/pinvim.lua`
- `home/common/programs/pi-coding-agent/extensions/pinvim.ts`
- `config/nvim/after/plugin/pinvim.lua`
- `bin/pinvim-protocol-smoke`

Current payloads:

- `{ type: "hello", protocol: "pinvim.peer.v1", peer, capabilities }`
- `{ type: "heartbeat", protocol: "pinvim.peer.v1", peerId, sentAt }`
- `{ type: "ping" }`
- `{ type: "prompt", message }`
- `{ type: "explicit_send", context }`

Socket/manifest dependency:

- uses `${PI_STATE_DIR}/sockets/pi-{session}-{window}.sock`
- uses `${PI_STATE_DIR}/manifests/*.info` for target discovery
- `PI_SOCKET` override supported
- ephemeral sockets use `-eph-...` suffix and manifest `ephemeral: true`

Pi APIs used:

- `pi.on("session_start" | "session_switch" | "session_shutdown")`
- `pi.sendUserMessage(...)`
- `ctx.ui.notify(...)`
- `ctx.ui.setStatus(...)`
- `ctx.isIdle()` through `deliverMessage`
- `pi.registerCommand(...)`

Replacement owner:

- keep in `pinvim.ts`
- extract shared socket/manifest helpers only if two or more focused extensions need same code

Migration risk: medium.

- primary cutover already happened
- remaining risk is compatibility shims in `pinvim.ts`: `telegram`, `tell`, and no-`type` nvim payloads
- remove only after Hammerspoon/tell/legacy nvim callers move or are confirmed dead

### 2. Nvim legacy path

Files:

- `config/nvim/after/plugin/pi_legacy.lua`
- `home/common/programs/pi-coding-agent/extensions/pinvim_legacy.ts`

Current payloads:

- no-`type` nvim payload: `{ file?, range?, selection?, lsp?, task? }`
- old live-context frames: `editor_state`, `editor_disconnect`
- may use `PI_SOCKET`, manifests, tmux-derived socket names

Socket/manifest dependency:

- `PI_SOCKET` first
- `${PI_STATE_DIR}/manifests/*.info`
- tmux socket pattern fallback

Pi APIs used:

- formerly `bridge.ts` formatted payloads into text
- now `pinvim.ts` rejects live-context frames and only retains no-`type` compatibility

Replacement owner:

- delete/disable legacy plugin after `dot-s3l8`
- no new extension needed

Migration risk: low to medium.

- `config/nvim/lua/settings.lua` keeps `pi_legacy` disabled during bootstrap work
- risk only if old commands or buffer-local targets still route through this file

### 3. Hammerspoon Telegram forwarder

Files:

- `config/hammerspoon/lib/interop/pi.lua`
- `config/hammerspoon/lib/notifications/init.lua`
- `config/hammerspoon/lib/notifications/send.lua`
- `config/hammerspoon/lib/interop/telegram.lua`

Current payloads:

- `pi.forwardMessage(text, source)` sends:
  - `{ type: "telegram", text, source, timestamp }`
- `pi.sendToSession(session, text, source, window?)` sends same payload

Socket/manifest dependency:

- direct socket scan only, no manifest read
- `${PI_STATE_DIR}/sockets/pi-{session}-{window}.sock`
- excludes `-eph-` sockets
- tracks `lastActiveSession` and `lastActiveWindow`
- default target session: `mega`
- persistent `hs.socket` connection pool with response parsing

Pi APIs used:

- via socket only
- target extension calls `pi.sendUserMessage(...)`
- target extension may call `ctx.ui.notify(...)`

Replacement owner:

- `hs.ts` if this becomes broader Hammerspoon ingress
- `ntfy.ts` if Telegram is treated as notification/reply transport
- recommendation: make `hs.ts` minimal socket ingress for Hammerspoon-originated commands, and keep Telegram-specific behavior in `ntfy.ts`/notification layer

Migration risk: high.

- current remote-control flow depends on socket accepting `telegram`
- `notify.ts` suppresses notifications based on `📱 **Telegram message:**` prefix
- Hammerspoon still names `bridge.ts` in comments/docs
- bridge disabled means traffic currently lands on `pinvim.ts`; removing compatibility there before replacement breaks Telegram-to-pi

### 4. Hammerspoon pi-gateway / RPC route

Files:

- `config/hammerspoon/lib/interop/pi-gateway.lua`
- `config/hammerspoon/lib/notifications/init.lua`

Current payloads:

- not a direct `bridge.ts` JSON payload path in audited code
- routes Telegram through `pi-gateway` and `pi --mode rpc` / tell-style delegation when enabled

Socket/manifest dependency:

- no direct `PI_STATE_DIR/sockets/pi-*.sock` dependency observed in `pi-gateway.lua`
- uses Telegram module and state/history paths under `~/.local/share/pi/telegram` and `~/.local/state/pi/telegram`

Pi APIs used:

- external pi CLI/RPC, not extension socket API in current file

Replacement owner:

- `hs.ts` for Hammerspoon command ingress, or tell/delegation owner if this remains task-routing logic

Migration risk: medium.

- not direct bridge coupling, but overlaps Telegram/tell responsibilities
- needs explicit decision to avoid two remote-ingress paths

### 5. Telegram / `ntfy`

Files:

- `bin/ntfy`
- `home/common/programs/pi-coding-agent/extensions/notify.ts`
- `config/hammerspoon/lib/notifications/send.lua`
- `config/hammerspoon/lib/interop/telegram.lua`

Current payloads:

- `bin/ntfy` sends outbound notifications, optionally `--telegram`
- Hammerspoon Telegram replies to pi use `{ type: "telegram", text, source, timestamp }` through `config/hammerspoon/lib/interop/pi.lua`
- `notify.ts` watches user messages with prefix `📱 **Telegram message:**`

Socket/manifest dependency:

- `bin/ntfy` has no bridge socket dependency
- Hammerspoon reply forwarding uses pi sockets directly

Pi APIs used:

- `notify.ts` listens to pi message/session events and shells out to `~/bin/ntfy`
- bridge/pinvim ingress uses `pi.sendUserMessage(...)`

Replacement owner:

- `ntfy.ts` should own notification-send behavior plus Telegram conversation suppression markers
- inbound Telegram can either stay Hammerspoon→`hs.ts` or become Hammerspoon→`ntfy.ts`; pick one before deleting compatibility from `pinvim.ts`

Migration risk: high.

- duplicate-notification suppression depends on exact message prefix
- remote workflow expects immediate ack via `~/bin/ntfy send ... --telegram`
- moving prefix/message format requires coordinated `notify.ts` update

### 6. Tell / delegation

Files:

- `home/common/programs/pi-coding-agent/skills/tell/scripts/tell.sh`
- existing follow-up tickets: `dot-f5le`, `dot-ljr6`, `dot-mlnl`, `dot-wj8z`, `dot-wo9v`

Current payloads:

- pi-to-pi task send:
  - `{ type: "tell", text, from, timestamp }`
- completion/result send uses same `type: "tell"`
- fallback path injects text with `tmux send-keys`
- external-agent delegation stores task JSON in `~/.pi/tasks/*.json`

Socket/manifest dependency:

- direct socket scan only, no manifests
- `${PI_STATE_DIR}/sockets/pi-{session}-{window}.sock`
- excludes `-eph-` sockets
- prefers `agent` window, then `0`, then first socket
- resolves window name/index using tmux

Pi APIs used:

- target extension calls `pi.sendUserMessage(payload.text)`
- target extension may notify UI with `Task from ${from}`

Replacement owner:

- focused `tell.ts` extension should own `type: "tell"`, task lifecycle events, socket auth, structured result passing, and future GC
- `tell.sh` should target either `tell.ts` socket route or a dedicated command/RPC surface, not shared pinvim socket long term

Migration risk: high.

- delegation depends on clean socket delivery to avoid shell prompt pollution
- fallback `tmux send-keys` remains, but less safe and less reliable
- socket auth/GC follow-ups already exist and should happen before broadening ingress

### 7. `tmux-toggle-pi`

File:

- `bin/tmux-toggle-pi`

Current payloads:

- no JSON socket payloads
- sets environment for spawned panes:
  - `PI_SOCKET=$sock`
  - `PI_EPHEMERAL=1` for `--new`

Socket/manifest dependency:

- parses `${PI_STATE_DIR}/sockets/pi-{session}-{window}.sock`
- parses ephemeral `${PI_STATE_DIR}/sockets/pi-{session}-{window}-eph-*.sock`
- maps socket basename back to tmux window
- finds panes by title `π*`, window name, process env, or `lsof`

Pi APIs used:

- none directly
- relies on `pinvim` wrapper and pi extension to create socket/manifests

Replacement owner:

- `tmux.ts` only if pi needs to expose session/pane discovery APIs
- otherwise keep as CLI helper and share socket-name parser docs/helpers

Migration risk: medium.

- comments still say `bridge.ts resolveSocket()` honors `PI_SOCKET`; now `pinvim.ts` does
- socket naming is coupling point; changing naming without updating this breaks toggle, bell, ephemeral pane discovery

### 8. `ftm`

File:

- `bin/ftm`

Current payloads:

- none

Socket/manifest dependency:

- checks `${PI_STATE_DIR}/sockets/pi-${session}-*.sock`
- excludes `-eph-`
- displays `π` indicator in session picker
- ctrl-v runs `tmux-toggle-pi`

Pi APIs used:

- none

Replacement owner:

- CLI helper can stay independent
- optional `tmux.ts`/registry ticket may replace raw socket scan with ranked session registry

Migration risk: low.

- only needs stable socket existence convention or registry replacement

### 9. Wrapper / manifests / session discovery

Files:

- `home/common/programs/pi-coding-agent/default.nix`
- `home/common/programs/pi-coding-agent/extensions/pinvim.ts`
- `home/common/programs/pi-coding-agent/extensions/bridge.ts`
- `config/nvim/lua/pinvim.lua`
- `config/nvim/after/plugin/pi_legacy.lua`

Current payloads:

- none; this is environment/discovery layer

Socket/manifest dependency:

- wrapper exports `PI_STATE_DIR`
- wrapper exports `PI_SESSION`
- `pinvim.ts` derives socket and writes manifest
- `bridge.ts` can still write same shape if legacy env flag enabled
- manifests include `socket`, `cwd`, `pid`, `session`, `window`, `pane`, `ephemeral`, `startedAt`; `pinvim.ts` also writes `owner: "pinvim.ts"`

Pi APIs used:

- extension lifecycle events for manifest write/cleanup

Replacement owner:

- shared `socket-manifest` helper if duplication grows
- `tmux.ts` or future registry can own ranked session discovery

Migration risk: medium.

- many clients rely on socket naming, not manifest schema
- bridge and pinvim share socket path; enabling both can conflict

## Focused extension split

Recommended split:

- `pinvim.ts`
  - owns nvim↔pi socket protocol
  - owns `hello`, `hello_ack`, `heartbeat`, `ping`, `prompt`, `explicit_send`
  - owns pinvim status/footer and explicit context formatting
  - should drop `telegram`, `tell`, and no-`type` legacy handlers after replacements land

- `hs.ts`
  - owns Hammerspoon-originated ingress that is not nvim
  - accepts explicit Hammerspoon source metadata
  - may expose `telegram` as temporary compatibility if `ntfy.ts` does not own inbound Telegram

- `tmux.ts`
  - owns session/window/pane registry only if pi needs a first-class API
  - otherwise keep tmux logic in CLI scripts and add shared socket-name parser tests/docs
  - likely future home for parked pi registry/MRU (`dot-p2ad`, `dot-oiky`, `dot-8n53`)

- `ntfy.ts`
  - owns outbound notification routing through `~/bin/ntfy`
  - owns Telegram conversation suppression state currently in `notify.ts`
  - coordinates exact inbound marker/prefix if Telegram remains Hammerspoon-originated

- tell/delegation owner (`tell.ts`)
  - owns `type: "tell"`
  - owns structured task result passing, task status, auth, GC
  - aligns with existing follow-ups: `dot-f5le`, `dot-ljr6`, `dot-mlnl`, `dot-wj8z`, `dot-wo9v`

- shared socket/manifest utility
  - extract only after second focused extension needs same code
  - candidate funcs: `detectTmux`, `resolveSocket`, `writeInfoManifest`, `cleanupInfoManifest`, `isEphemeralSocket`, `parsePiSocketName`

## Remove now vs keep until replacements

Can remove/stop relying on immediately after `dot-klla`:

- `bridge.ts` nvim handshake ownership — already rejected in code
- `bridge.ts` live-context handling — rejects `editor_state` / `editor_disconnect`
- any new pinvim product behavior in `bridge.ts`
- docs/comments saying bridge is primary nvim socket owner

Must remain until replacement tickets land:

- `pinvim.ts` compatibility handlers for `telegram` and `tell`, because Hammerspoon and tell currently send to same socket path
- socket naming convention `${PI_STATE_DIR}/sockets/pi-{session}-{window}.sock`
- manifest schema enough for nvim discovery
- `notify.ts` Telegram prefix suppression or equivalent state in `ntfy.ts`
- `tell.sh` fallback while `tell.ts` is not implemented
- `bridge.ts` file itself as opt-in escape hatch (`PI_BRIDGE_LEGACY_SOCKET=1`) until users confirm no legacy clients

Can remove only after explicit follow-ups:

- no-`type` legacy nvim payload support in `pinvim.ts` after `dot-s3l8`
- `telegram` handling in `pinvim.ts` after `hs.ts`/`ntfy.ts` owns inbound Telegram
- `tell` handling in `pinvim.ts` after `tell.ts` owns delegation ingress
- `bridge.ts` entirely after above removals plus search shows no `bridge.ts` client docs/code remain

## Follow-up tickets

Existing tickets that cover clear slices:

- `dot-oiky` — rank pi session discovery by root, tmux, recency
- `dot-p2ad` — parked tmux pi registry and MRU tracking
- `dot-8n53` — restore previous pi targets from nvim MRU history
- `dot-vnmm` — structured editor context envelopes
- `dot-f5le` — add `tell.ts` for task monitoring + coordination
- `dot-ljr6` — structured tell result passing
- `dot-mlnl` — tell dependency queueing
- `dot-wj8z` — tell GC + socket authentication
- `dot-wo9v` — tell docs update
- `dot-s3l8` — remove temporary nvim↔pi protocol compatibility shims

New tickets created from this audit:

- `dot-d6wm` — Add Hammerspoon ingress extension for Telegram-to-pi routing
- `dot-gew8` — Split ntfy/Telegram notification semantics from pinvim socket ingress
- `dot-a07u` — Retire bridge.ts after focused ingress replacements land

## Verification

- `rg` command above found all direct bridge/socket consumers listed here.
- `tk dep cycle` passes with no dependency cycles after follow-up ticket creation.
