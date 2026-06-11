---
id: dot-so9c
status: open
deps: 4:1:deps: [, dot-0v6y]
links: []
created: 2026-06-11T11:38:03Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Disable normal Pi manifest auto-repair adoption

Gate broad Pi-side manifest/cwd/root repair scanning to diagnostics/manual use only. File hints: home/common/programs/pi-coding-agent/extensions/pinvim.ts (shouldAutoScanNvimPeers, scanNvimPeers, refreshRepairCandidate, peerAllowedForSocket, /pinvim-doctor).

## Acceptance Criteria

1. Normal parent Pi sessions do not auto-adopt Nvim peers from manifest/root/cwd scanning
2. /pinvim-doctor can still force candidate scanning for diagnostics
3. Root/cwd scoring is not part of peer acceptance
4. Editor-service lookup remains available for status/context, not ownership
5. Existing pinvim behavior still validates with devenv shell -- just validate home
