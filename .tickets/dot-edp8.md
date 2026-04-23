---
id: dot-edp8
status: in_progress
deps: []
links: []
created: 2026-04-23T12:25:36Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-kts9
tags: [nvim, pi, tmux, ephemeral, ready-for-development]
---
# Implement <localleader>pn: isolated ephemeral pi tmux split

Implement `<localleader>pn` in config/nvim/after/plugin/pi.lua to spawn an
ephemeral pi instance in a new tmux split, fully isolated from any existing
pi/nvim pairs. Currently a stub emits "not yet implemented" (pi.lua:2214).

## Background

All plumbing exists (see parent dot-kts9):
- `tmux-toggle-pi` handles singleton agent-window lifecycle (--ensure, --socket, --bell)
- `pinvim` wrapper exports PI_SOCKET_DIR/PREFIX/SESSION and launches pi
- bridge.ts `resolveSocket()` honors PI_SOCKET env override (line 87)
- bridge.ts writes `.info` manifest at /tmp/pi-nvim-sockets/{session}.info
- pi.lua supports `vim.b.pi_target_socket` buffer-local override (line 218)
- Socket discovery: cwd → tmux-session pattern → newest-mtime fallback

None of this currently supports a throwaway side-by-side pi without
colliding with the primary per-window pi for the same tmux session.

## Isolation requirement (CRITICAL)

Ephemeral pi must be a sealed channel between the spawning nvim buffer and
its dedicated pi pane. No message, context, status, or discovery artifact
may leak to or from:
- The session's primary pi (pi-{session}-{window}.sock)
- Any other ephemeral pi started from a different nvim buffer
- Any other nvim instance in the same tmux session or same cwd
- Any Hammerspoon/telegram/tell forwarder not explicitly pointed at it

## Design

## Architecture

### Socket naming
Unique path per ephemeral: `/tmp/pi-{session}-{window}-eph-{epoch}-{pid}.sock`
Passed to bridge.ts via PI_SOCKET env override. Never collides with the
session's primary socket.

### Manifest isolation (bridge.ts)
Current `.info` filename keyed by session name collides when multiple pis
run in one tmux session. Fix: key manifest by socket basename, e.g.
`/tmp/pi-nvim-sockets/{socket-basename}.info`. Include `ephemeral: true`
flag in the manifest payload so discovery can filter it out of
cwd-based auto-discovery (ephemerals only reachable via explicit socket
target, never via cwd scan).

### tmux-toggle-pi `--new` flag
New branch, bypasses all agent-window logic:
- Require `--socket PATH` (ephemeral path, caller-provided)
- Split current window 30% right via `tmux split-window -h -l 30%`
- Launch `PI_SOCKET=<path> pinvim` in the new pane
- Do NOT touch AGENT_WINDOW, STATE_FILE, or any singleton state
- Do NOT call `normalize_agent_window` / `break-pane` / `move-window`
- Do NOT write to `/tmp/tmux-agent-toggle-{session}` state file
- Exit immediately (no toggle-off semantics — closing the pane is cleanup)

### Parser updates (tmux-toggle-pi)
`socket_to_window()` and `find_pi_pane_by_socket()` parse
`pi-{session}-{window}.sock`. Update to also recognize
`pi-{session}-{window}-eph-*.sock` (strip `-eph-*` suffix for window name
lookup), so `--bell` and existing `--socket` targeting keep working.
Lsof fallback already handles the worst case.

### nvim-side (pi.lua)
Replace stub at line 2214:
1. Generate unique socket path (epoch+pid suffix).
2. `vim.b.pi_target_socket = <path>` on the current buffer BEFORE spawn so
   any buffer-local send routes only to this ephemeral.
3. `vim.fn.jobstart({ "tmux-toggle-pi", "--new", "--socket", path }, { detach = true })`.
4. Poll for socket file up to ~2s; on success notify, on timeout notify
   + clear `vim.b.pi_target_socket`.
5. Register a `vim.uv.fs_event_start` watcher on the socket; on delete
   (pi pane exit) clear `vim.b.pi_target_socket` and notify.
6. Ephemeral target is strictly buffer-local — no global state mutation,
   no change to any other buffer's target, no change to the session
   picker's default.

### pinvim extension (pi extension side)
pinvim.ts listens for `pinvim:editor_state` events via pi.events. In a
single-process pi instance this is naturally scoped (one pi process =
one bridge.ts socket = one event bus). No change required IF each
ephemeral runs in its own `pinvim` process (which it does — new tmux
pane = new pi process). Verify: editor_state events from buffer A's
pi.lua must only reach buffer A's ephemeral pi, never the primary or
any other ephemeral.

### Hammerspoon/tell forwarders
config/hammerspoon/lib/interop/pi.lua targets "last active session"
socket. Ephemeral sockets must NOT be eligible as "last active" unless
explicitly chosen. Filter: Hammerspoon discovery skips manifests with
`ephemeral: true`.

### Cleanup
- pi pane exit → bridge.ts `session_shutdown` removes socket + `.info`
  (existing behavior from dot-3fyc AC #6)
- fs_event watcher in pi.lua clears buffer-local target
- No residual files: verify via `ls /tmp/pi-*eph*.sock /tmp/pi-nvim-sockets/*eph*`
  both empty after pane close

## Files

- `bin/tmux-toggle-pi` (add --new branch + parser tweak)
- `config/nvim/after/plugin/pi.lua` (replace stub at ~2214)
- `home/common/programs/ai/pi-coding-agent/extensions/bridge.ts`
  (per-socket `.info` manifest + `ephemeral` flag)
- `config/hammerspoon/lib/interop/pi.lua` (filter ephemeral from
  last-active-session resolution)

## Acceptance Criteria

## Core functionality

1. `<localleader>pn` in nvim spawns a new tmux pane (30% right split of
   current window) running pi, without touching the session's singleton
   agent window.
2. Spawned pi uses a unique socket path
   `/tmp/pi-{session}-{window}-eph-{epoch}-{pid}.sock` passed via
   `PI_SOCKET` env override.
3. `tmux-toggle-pi --new --socket PATH` exists; rejects invocation
   without `--socket`; does not read/write the agent-window state file.
4. `vim.b.pi_target_socket` is set on the spawning buffer to the
   ephemeral socket path before the first send.
5. Ephemeral pane close removes socket + `.info` manifest (verified by
   file listing after exit).
6. fs_event watcher on the socket clears `vim.b.pi_target_socket` when
   the socket disappears; user notified.

## Isolation (CRITICAL — no bleed-over)

7. Running an ephemeral pi alongside the primary pi in the same tmux
   session + same window produces two distinct sockets; sends to the
   ephemeral-targeted buffer arrive ONLY at the ephemeral pane.
8. Two ephemerals spawned from two different buffers (same or different
   nvim instances) get distinct sockets; cross-send test: selection
   sent from buffer A reaches only ephemeral A, never ephemeral B or
   the primary.
9. bridge.ts writes `.info` manifests keyed by socket basename, not
   session name; multiple concurrent pis in one tmux session produce
   multiple manifest files with no clobber.
10. bridge.ts `.info` manifest includes `ephemeral: boolean` flag set
    from env (`PI_EPHEMERAL=1` or derived from socket-name `-eph-`
    marker).
11. pi.lua cwd-based discovery (`discover_socket_by_cwd`) ignores
    manifests where `ephemeral: true`. Ephemeral sockets are reachable
    ONLY via explicit `vim.b.pi_target_socket`, never via auto-discovery
    or `:PiSessions` default selection.
12. `:PiSessions` picker visually distinguishes ephemeral entries
    (e.g., "eph" tag or dim style) and never picks one implicitly.
13. Hammerspoon `lib/interop/pi.lua` lastActiveSession resolution skips
    ephemeral manifests; Telegram/tell forwards never reach an
    ephemeral pi unless user explicitly targets it.
14. pinvim.ts editor_state routing: editor_state from nvim instance A
    reaches only the pi process it was sent to; no shared in-memory
    state across pi processes (validated by inspecting
    `pi.events('pinvim:editor_state')` listeners per-process).
15. A second nvim instance in the same tmux session + same cwd does
    NOT auto-discover another nvim's ephemeral socket (test: open
    nvim B in same cwd while A's ephemeral is live; `:PiStatus` in B
    shows the primary pi, never the ephemeral).
16. Killing an ephemeral pi pane does not affect the primary pi or
    any other ephemeral: primary `:PiStatus` unchanged, other
    ephemerals' buffer-local targets still valid and responsive.
17. `tmux-toggle-pi --bell PATH` rings the correct pane when `PATH`
    is an ephemeral socket (parser handles `-eph-*` suffix, or lsof
    fallback succeeds).

## Regression

18. `<localleader>pp` (primary toggle) behavior unchanged.
19. `<localleader>ps` session picker behavior unchanged (aside from
    optional ephemeral tagging per AC #12).
20. Primary pi socket and `.info` manifest paths unchanged for
    non-ephemeral case (backward compatible).
21. Existing Hammerspoon/Telegram/tell flows unchanged.

## Validation

- Manual: spawn primary pi, spawn ephemeral via `<localleader>pn`,
  send selection from buffer → verify arrival in ephemeral only
  (check agent window footer + ephemeral pane footer).
- Manual: open two nvim instances in same tmux session, each spawns
  an ephemeral; cross-send test; verify isolation.
- Manual: `ls /tmp/pi-*eph*.sock /tmp/pi-nvim-sockets/*eph*.info`
  before/after pane close; assert cleanup.
- `:PiHealth` reports ephemeral sockets as a distinct category,
  flags any stale ephemerals.


## Notes

**2026-04-23T12:41:29Z**

Implemented:
- bridge.ts: per-socket .info manifest ({socket-basename}.info); added ephemeral + window fields; IS_EPHEMERAL detect from PI_EPHEMERAL=1 env or socket name containing -eph-
- bin/tmux-toggle-pi: new --new flag requiring --socket PATH; spawns 30% right split with PI_SOCKET+PI_EPHEMERAL=1 env; does not touch AGENT_WINDOW/state-file; socket_to_window strips -eph-* suffix so --bell still routes correctly
- config/nvim/after/plugin/pi.lua:
  - parse_info_manifest: derives ephemeral flag from manifest or name
  - discover_socket_by_cwd: skips ephemerals in both cwd + same-session passes
  - discover_socket_by_tmux: glob filters out -eph-
  - list_sockets(opts): opts.include_ephemeral; returns {path,ephemeral}[]
  - select_session: shows ephemerals tagged ' · eph'; never auto-picked via discovery
  - PiHealth: marks ephemeral manifests
  - <localleader>pn: unique socket path, set vim.b.pi_target_socket, jobstart tmux-toggle-pi --new, poll for socket (3s), fs_event watcher clears target on socket deletion
- config/hammerspoon/lib/interop/pi.lua:
  - isEphemeralSocket() helper
  - getSocketPath/getActiveSessions/getSessionSockets: skip ephemerals
  - trackLastActive: ignores contexts containing -eph-

Validated: home-manager builds (just validate home), luac -p clean on both lua files, shellcheck clean (pre-existing SC2001 style only), bash -n clean.
