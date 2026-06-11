---
id: dot-l8d4
status: closed
deps: 4:1:deps: [, dot-0v6y]
links: []
created: 2026-06-11T11:38:03Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Expose Pi pair state in manifests and diagnostics

Mirror pair ownership state in status outputs without making files authoritative. File hints: home/common/programs/pi-coding-agent/extensions/pinvim.ts (buildPinvimPeerIdentity, writeInfoManifestNow, renderInfoLines, /pinvim-info, /pinvim-status, /pinvim-health, /pinvim-doctor).

## Acceptance Criteria

1. Pi manifest includes pairId, pairedNvimId, pairedInstanceId, claimState, claimable, lastPeerHeartbeatAt, lastClaimAt, and lastRejectReason when available
2. /pinvim-info, /pinvim-status, /pinvim-health, and /pinvim-doctor show paired/waiting/claimable/rejected state
3. Output makes clear manifests are mirror/status data, not ownership authority
4. Existing pinvim behavior still validates with devenv shell -- just validate home
