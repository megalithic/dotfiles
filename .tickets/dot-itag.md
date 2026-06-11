---
id: dot-itag
status: open
deps: 4:1:deps: 4:1:deps: [, dot-0v6y, dot-r0f8]
links: []
created: 2026-06-11T11:38:03Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Add pair status probe for pimux reuse decisions

Add a read-only pair status socket probe so pimux does not trust stale manifests when deciding whether a pane is claimable. File hints: home/common/programs/pi-coding-agent/extensions/pinvim.ts (socket protocol handling, ping/hello paths) and bin/pimux (candidate filtering/probing).

## Acceptance Criteria

1. Pi socket supports a read-only pair_status or equivalent response without claiming ownership
2. pimux probes candidate sockets with a short timeout before reuse
3. Live Pi cannot be stolen because a stale manifest says claimable
4. Dead/stale Pi can still be claimed when probe fails or reports claimable
5. Existing pinvim behavior still validates with devenv shell -- just validate home
