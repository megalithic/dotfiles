---
id: dot-xolt
status: open
deps: [dot-w2ut]
links: []
created: 2026-06-30T16:21:48Z
type: task
priority: 2
assignee: [REDACTED]
tags: [ready-for-development]
---

# Manual: add custom Helium build to 1Password trusted browsers

MANUAL STEP — no code changes required.

After the signed Helium build is in /Applications/Helium.app (signed with team ID [REDACTED]), add it to 1Password's trusted browser list:

1. Open/unlock 1Password for Mac
2. Settings → Browser → Add Browser
3. Select /Applications/Helium.app
4. Confirm the prompt (1Password warns additional browsers get full access)

The app must be code-signed by Apple (Developer ID), which the source build handles with cert 'Developer ID Application: [REDACTED]'.

Official docs: https://support.1password.com/additional-browsers/

No CLI or programmatic method exists for Mac — this is GUI-only.

## Acceptance Criteria

1. Helium appears in 1Password Settings → Browser list
2. 1Password extension in Helium connects to desktop app
3. Autofill works in custom Helium build
