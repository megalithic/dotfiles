---
id: dot-y4vm
status: closed
deps: []
links: []
created: 2026-05-13T20:48:05Z
type: feature
priority: 1
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---
# Move pi sockets and manifests into XDG state directories

Implement Step 1 from ~/.local/share/pi/plans/dotfiles/nvim-pi-custom-vision_PLAN.md. Move pi runtime state out of /tmp and into XDG state roots. Define PI_STATE_DIR once in home/common/programs/pi-coding-agent/default.nix, then derive socket and manifest paths in home/common/programs/pi-coding-agent/extensions/bridge.ts, config/nvim/after/plugin/pi.lua, config/hammerspoon/lib/interop/pi.lua, bin/tmux-toggle-pi, bin/ftm, and home/common/programs/pi-coding-agent/skills/tell/scripts/tell.sh if still active. Keep PI_SOCKET override for explicit targeting.

## Acceptance Criteria

1. `PI_STATE_DIR` is defined in nix config and consumers derive `sockets/` and `manifests/` paths from it instead of hardcoding `/tmp`, `PI_SOCKET_DIR`, or `PI_SOCKET_PREFIX`.
2. Primary and ephemeral pi sockets are created under `~/.local/state/pi/sockets/` and discovery manifests under `~/.local/state/pi/manifests/`.
3. Nvim discovery, Hammerspoon forwarding, tmux pane targeting, ftm status, and tell routing still work with the new paths.
4. Normal startup no longer creates new `/tmp/pi-*.sock` or `/tmp/pi-nvim-sockets/*.info` artifacts.
5. `just validate home` passes, plus targeted syntax checks (`luac -p` and `bash -n`) stay clean for touched files.


## Notes

**2026-05-14T03:45:23Z**

Moved pi runtime sockets to PI_STATE_DIR/sockets and manifests to PI_STATE_DIR/manifests. Updated pinvim wrapper, bridge, nvim discovery, Hammerspoon forwarding, tmux toggle, ftm, and tell routing. Verified bash/lua syntax, nvim headless, and just validate home.
