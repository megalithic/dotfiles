---
id: dot-83ld
status: closed
deps: [dot-4zab]
links: []
created: 2026-06-30T16:20:31Z
type: task
priority: 2
assignee: [REDACTED]
tags: [ready-for-development]
---

# Add mise.toml build environment for helium-macos

Add local build env and tasks for source builds in ~/code/oss/helium-macos/mise.toml.

[tools]: python 3.13, ninja, sccache, jq, quilt (if available via mise)
[env]: PYTHONUNBUFFERED=1, MACOS_CERTIFICATE_NAME, PROD_MACOS_NOTARIZATION_TEAM_ID
[tasks]: deps (pip install httplib2==0.22.0 requests pillow), build (./build.sh arm64), dev-setup (he setup), dev-build (he build), dev-run (he run)

System deps not in mise: Xcode 26 + SDK + Metal toolchain, codesign/notarytool/stapler, greadlink provider, Perl/pkg-dmg/appdmg

## Acceptance Criteria

1. mise tasks lists deps, build, dev-setup, dev-build, dev-run
2. mise run deps installs Python deps without error
3. mise run dev-setup reaches patch/GN setup after submodule init and toolchain availability
