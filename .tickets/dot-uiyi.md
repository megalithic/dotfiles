---
id: dot-uiyi
status: open
deps: [dot-4zab]
links: []
created: 2026-06-30T16:20:38Z
type: feature
priority: 2
assignee: [REDACTED]
tags: [ready-for-development]
---

# Move Widevine injection into source build

Create ~/code/oss/helium-macos/inject_widevine.sh — a reusable script that downloads Firefox Widevine metadata, verifies CRX SHA-512, extracts CRX3 ZIP payload, and installs CDM into built app before signing.

Port logic from current nix derivation (pkgs/helium-browser.nix):

1. Fetch https://hg.mozilla.org/mozilla-central/raw-file/tip/toolkit/content/gmp-sources/widevinecdm.json
2. Parse vendors.gmp-widevinecdm.platforms.Darwin_aarch64-gcc3 for fileUrl, hashValue, version
3. Download .crx from Google CDN
4. Compute CRX3 ZIP offset: 12 + little-endian uint32 at byte 8 (magic Cr24 + version + header_len)
5. dd skip header, unzip
6. Copy to Helium.app/Contents/Frameworks/Helium Framework.framework/Versions/<ver>/Libraries/WidevineCdm/
7. Verify SHA-512 of downloaded CRX against hashValue

Then modify ~/code/oss/helium-macos/build.sh to call inject_widevine.sh after ninja -C out/Default chrome chromedriver and before sign_and_package_app.sh.

Requirements: bash, curl, jq (for JSON parsing), python3 (for LE uint32 decoding), dd, unzip, sha512sum.

## Acceptance Criteria

1. Built app contains Libraries/WidevineCdm/\_platform_specific/mac_arm64/libwidevinecdm.dylib before signing
2. Bad SHA-512 hash fails the build with clear error
3. codesign --verify --deep --verbose=4 out/Default/Helium.app passes after signing
4. Script can run standalone for testing: ./inject_widevine.sh path/to/Helium.app
