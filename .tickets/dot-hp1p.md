---
id: dot-hp1p
status: closed
deps: []
links: []
created: 2026-05-14T20:28:18Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-dylm
tags: [nvim, pi, infrastructure, cleanup, ready-for-development]
---
# cleanup(pi): verify XDG socket migration and remove legacy /tmp artifacts

Migration itself already shipped via `dot-y4vm`. This ticket now covers post-migration verification and cleanup so current nvim↔pi vision plan starts from clean state.

Scope:
- Verify active code paths use `PI_STATE_DIR=~/.local/state/pi` with `sockets/` and `manifests/` subdirs.
- Confirm primary consumers (`bridge.ts`, `pinvim.lua`, Hammerspoon interop, `tmux-toggle-pi`, `ftm`, `tell.sh`, nix wrapper/session vars) all point at XDG state, not `/tmp`.
- Inventory any remaining legacy `/tmp/pi-*` sockets or `/tmp/pi-nvim-sockets/*` manifests.
- Remove orphaned legacy artifacts safely.
- If any still-running pi process is bound to legacy `/tmp` socket, identify it and decide whether to restart/migrate it separately rather than silently killing it.
- Re-verify discovery/build flows after cleanup.

Must not break existing Telegram/tell/Hammerspoon/tmux flows. Verify: `just validate home`; confirm active sockets/manifests live under `~/.local/state/pi`; confirm only intentional legacy processes remain under `/tmp`; confirm nvim/Hammerspoon/tmux discovery still resolves correctly.

## Acceptance Criteria

1. Audit confirms current code paths use `PI_STATE_DIR` and XDG-derived `sockets/` + `manifests/` locations; no active implementation code still derives primary pi socket/manifests from `/tmp`.
2. `just validate home` passes after any cleanup changes.
3. Active runtime sockets/manifests for current pi sessions are present under `~/.local/state/pi/sockets/` and `~/.local/state/pi/manifests/`.
4. Orphaned legacy `/tmp/pi-*` sockets and `/tmp/pi-nvim-sockets/*` manifests are removed safely (use `trash`, not `rm`).
5. Any still-running pi process bound to legacy `/tmp` socket is identified explicitly; ticket notes record whether it was intentionally left running, restarted, or migrated with user approval.
6. Post-cleanup verification shows nvim/Hammerspoon/tmux/tell discovery still resolves active pi instances from XDG state.


## Notes

**2026-05-15T00:15:54Z**

Audit result: XDG migration already shipped via dot-y4vm. Verified PI_STATE_DIR in nix + active consumers (bridge.ts, pinvim.lua, Hammerspoon interop, tmux-toggle-pi, ftm, tell.sh). just validate home passed. Cleaned orphan legacy artifacts with trash: /tmp/pi-pi-xhzj-test-1.sock and /tmp/pi-nvim-sockets/* (empty dir removed). Remaining legacy runtime artifact: /tmp/pi-thistle-rose-agent.sock still held open by long-running pi pid 73624 (elapsed 6+ days). Needs explicit user decision to restart/migrate/kill that process.

**2026-05-15T12:42:58Z**

Final verification: legacy /tmp pi sockets/manifests removed; lsof shows no /tmp/pi* or pi-nvim-sockets handles. Active pi sockets/manifests remain under ~/.local/state/pi/{sockets,manifests}: pi-mega-agent, pi-mega--fish, pi-rx-agent. just validate home passed.
