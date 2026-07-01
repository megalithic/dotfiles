---
id: dot-gbcl
status: closed
deps: [dot-83ld, dot-uiyi, dot-p1ak]
links: []
created: 2026-06-30T16:20:51Z
type: task
priority: 2
assignee: [REDACTED]
tags: [ready-for-development]
---

# Validate first signed local source build

Build and install signed Helium from source fork, verifying the full pipeline works end-to-end before dotfiles switch.

In ~/code/oss/helium-macos:

1. mise run build — produces build/helium\_<version>\_macos.dmg
2. spctl --assess --type execute out/Default/Helium.app — verify Gatekeeper accepts or shows expected notarization status
3. Copy to /Applications and launch — verify it works
4. Check 1Password can Add Browser for this signed app (manual step in 1Password GUI)

If build fails: document missing env vars, tools, or dependencies. Fix and retry. The first build will download Chromium source (~30GB) and toolchain — this is expected and slow.

Cert name: Developer ID Application: [REDACTED]
Team ID: [REDACTED]

## Acceptance Criteria

1. mise run build completes without error and produces a .dmg
2. spctl assessment passes or gives expected non-notarized result (not an error)
3. App launches from /Applications successfully
4. Any build failures are diagnosed and fixed (or documented as known issues)
