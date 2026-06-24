---
id: dot-zarv
status: open
deps: []
links: []
created: 2026-06-23T23:04:45Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-a9wd
---

# Pi-initiated review: spawn unpaired Nvim that pairs back to originating Pi

Let `/piview` spawn a review Nvim when no editor service is paired, so a bare Pi (no Nvim) can initiate a review session in a new tmux pane/window that then pairs back to the originating Pi.

Recommended approach (A — direct pairing): the bare Pi adopts the target worktree's pinvim registry identity (`parent.id` + deterministic `workspace_id = stable_hash(root)`) for the spawn, launches `nvim +PiReview <scope>` in a new tmux pane with `PI_SOCKET=<this pi socket>` plus matching `PINVIM_PARENT_ID`/`PINVIM_WORKSPACE_ID` env, so the incoming Nvim peer passes `peerAllowedForSocket` via `exactParentRegistry`. Annotations (`gpc`/`:PiFlush`) then flow back to the original Pi over the paired socket.

Alternative (B — tell_pi relay): spawn a self-contained Nvim+pimux Pi (second agent) running `+PiReview`, relay annotations back to the original Pi via `tell_pi`. No pairing changes, but runs a second Pi and needs a relay step.

Relevant files:

- home/common/programs/pi-coding-agent/extensions/nvim-review.ts (spawn fallback when no editor service)
- home/common/programs/pi-coding-agent/extensions/pinvim.ts (peerAllowedForSocket identity rules at ~L1285, buildPinvimPeerIdentity ~L943, socket server startServer ~L1988)
- config/nvim/lua/pinvim.lua (Transport.resolve_socket PI_SOCKET env path ~L765, Registry.setup parent.id reuse ~L913)
- bin/pimux (Nvim→Pi spawn only; needs Pi→Nvim spawn or a new launcher)
- bin/pireview (currently scrubs PI_SOCKET; spawn path needs the opposite)

Risks: touches strict-pairing guarantees from epic dot-a9wd (closed dot-0v6y, dot-eb3t). Must be gated behind an explicit mode (e.g. `PINVIM_SESSION_ROLE=review-host` or `/piview --spawn`) — never change bare-pi defaults. Needs bin/pinvim-protocol-smoke coverage for the adopted-identity claim path.

Open questions to resolve before/refinement:

- Confirm workspace registry `parent.id` reuse is safe when a bare Pi adopts it (no Nvim has written it yet for a fresh worktree).
- Decide gating mode name + whether adoption is scoped to the spawn only or persists for the Pi's lifetime.
- tmux pane vs window; same session required for scoreNvimCandidate session gating.

## Acceptance Criteria

1. `/piview [scope]` (or `/piview --spawn`) spawns `nvim +PiReview <scope>` in a new tmux pane/window in the current Pi tmux session when no editor service is paired.
2. The spawned Nvim connects to the originating Pi's socket (via `PI_SOCKET`) and the pair is accepted by `peerAllowedForSocket` (exact parent registry or pair id), not rejected as a mismatch.
3. `gpc`/`:PiFlush` annotations from the spawned Nvim arrive at the originating Pi over the paired socket, including review scope metadata.
4. A bare Pi that has NOT spawned a review Nvim keeps unchanged default behavior (no registry adoption, no socket stealing).
5. The spawn path is gated behind an explicit mode/flag; it never alters bare-pi pairing defaults.
6. Missing tmux, missing git worktree, or a non-git cwd produce a clear message instead of a crash.
7. `devenv shell -- just home` succeeds.
8. `devenv shell -- nvim --headless '+lua require("pinvim").setup()' +qa` exits 0.
9. `devenv shell -- bin/pinvim-protocol-smoke` passes, plus a new smoke case covers the adopted-identity claim path.
10. Manual: from a bare Pi (no Nvim) in tmux, `/piview uncommitted` opens a review Nvim in a new pane, pairs back, and a `:PiFlush` from that Nvim reaches the original Pi.
11. lat.md documents the Pi-initiated spawn review flow and the explicit gating mode; `lat_check` passes.

## Notes

**2026-06-23T23:50:00Z**

Implemented approach A (direct pairing). `spawnReviewNvim` in `extensions/pinvim.ts` (exposed via `globalThis.pinvimEditorService.spawnReviewNvim`) is the spawn helper; `extensions/nvim-review.ts` falls back to it when no editor service is connected.

Identity adoption: `workspace_id = stableHash16(realpath(root))` replicates Nvim's `stable_hash(normalize_path(resolve_root()))`; `parent.id` is read or created under `$PI_STATE_DIR/pinvim/<workspace_id>/` so the spawned Nvim's `Registry.setup` reuses it; `process.env.PINVIM_PARENT_ID`/`PINVIM_WORKSPACE_ID` are set on the Pi and passed to the spawned `nvim +PiReview <scope>` via `tmux split-window -e`.

Gating: identity adoption only runs in the spawn path (unpaired Pi), re-adopts per spawn, and never alters an already-paired Pi's defaults.

Verified:

- Hash parity: Node `stableHash16` and Nvim `stable_hash` both produce `1b4ccb6a5746dca2` for `~/.dotfiles`.
- `parent.id` reuse: Node writes `parent:<id>`, headless Nvim `Registry.setup` reads the same id (not regenerated), same workspace_id.
- `bin/pinvim-review-spawn-smoke` formalizes the above and passes.
- `just home`, `nvim --headless ... +qa`, `bin/pinvim-protocol-smoke`, `lat_check` all pass.
- Extension loads in pi with no startup errors.

Remaining human gate (AC #10): live tmux `/piview uncommitted` from a bare Pi → spawned Nvim pairs back → `:PiFlush` reaches the original Pi. Requires a real tmux + paired session.

Caveat: during smoke development a buggy first run wrote to the real `~/.local/state/pi` dotfiles registry `parent.id` before `PI_STATE_DIR` isolation was fixed. The id rotated to a new valid value (Nvim reuses it going forward); no corruption, but any currently-paired `~/.dotfiles` session would need a restart to re-match. The committed smoke isolates state.
