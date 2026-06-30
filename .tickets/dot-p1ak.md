---
id: dot-p1ak
status: open
deps: [dot-4zab]
links: []
created: 2026-06-30T16:20:45Z
type: bug
priority: 2
assignee: [REDACTED]
tags: [ready-for-development]
---

# Fix helper signing for Widevine compatibility

Ensure Helium Helper.app in sign_and_package_app.sh uses hardened runtime options WITHOUT the library flag, so Google-team-signed Widevine CDM can load.

File: ~/code/oss/helium-macos/sign_and_package_app.sh

Base helper must use --options restrict,runtime,kill (no library) with entitlements/helper-entitlements.plist (which already includes com.apple.security.cs.disable-library-validation).

Other helpers (renderer, GPU, plugin) and main app keep their existing options. Brave and Chromium upstream do the same — library validation on base helper blocks cross-team CDM loading.

If sign_and_package_app.sh already has this fix in-progress (comment mentions it), verify it's complete and correct.

## Acceptance Criteria

1. codesign -d --entitlements :- on base helper shows com.apple.security.cs.disable-library-validation
2. Base helper hardened runtime flags do NOT include library
3. Renderer/GPU/plugin/main app signing unchanged from current
4. DRM content test reaches Widevine load instead of library-validation failure
