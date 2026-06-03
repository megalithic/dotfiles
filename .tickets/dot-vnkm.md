---
id: dot-vnkm
status: open
deps: 4:1:deps: [, dot-msws]
links: []
created: 2026-06-03T20:11:03Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Pass pinvim parent identity env through wrapper and pimux

Plan Step 4. Wrapper and pimux preserve/forward PINVIM_PARENT_ID, PINVIM_WORKSPACE_ID, PINVIM_INSTANCE_ID, PINVIM_SESSION_ID, PINVIM_SESSION_ROLE, PINVIM_REGISTRY_ROOT, PINVIM_NVIM_LISTEN_ADDRESS, PI_SOCKET, PI_EPHEMERAL. Create $PI_STATE_DIR/pinvim. Existing aliases (p, pis, pisock) unchanged. Files: home/common/programs/pi-coding-agent/default.nix, bin/pimux.

## Acceptance Criteria

1. just home passes
2. Env vars reach spawned Pi via pimux split/join
3. Aliases p, pis, pisock still work
4. $PI_STATE_DIR/pinvim exists after wrapper invocation
