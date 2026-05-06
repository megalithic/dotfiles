---
id: dot-easu
status: open
deps: []
links: [dot-ji0m]
created: 2026-05-06T14:01:14Z
type: task
priority: 3
assignee: Seth Messer
tags: [upstream, external-coordination]
---
# Upstream: file PR at JJGO/pi-internet to regenerate package-lock.json

pi-internet's checked-in package-lock.json has malformed entries (peer deps without resolved/integrity) that block nix buildNpmPackage migration in dot-ji0m.

Steps:
1. Fork JJGO/pi-internet
2. rm package-lock.json && npm install --package-lock-only --include=peer
3. Verify all entries have resolved + integrity
4. Open PR
5. Once merged, unblock dot-ji0m and bump pinned commit

Affected packages:
- node_modules/unpdf (1.4.0) — has optional peer dep @napi-rs/canvas
- node_modules/zod-to-json-schema (3.25.2) — peer: true entry

