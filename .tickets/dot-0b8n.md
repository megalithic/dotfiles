---
id: dot-0b8n
status: open
deps: [dot-gx9h, dot-wu29, dot-gvyg]
links: []
created: 2026-06-30T16:21:28Z
type: task
priority: 2
assignee: [REDACTED]
tags: [ready-for-development]
---

# Update lat.md Helium docs for source-fork architecture

Update ~/.dotfiles/lat.md/programs/helium.md to reflect the new architecture after source-fork changes.

Replace current model:

- Old: 'Nix injects Widevine/ad-hoc signs helpers'
- New: 'source build (megalithic/helium-macos) injects Widevine and signs; ~/.dotfiles consumes signed artifact as thin nix package'

Sections to update:

- Declarative Darwin build: remove Widevine injection and helper re-signing details from nix section; add reference to inject_widevine.sh in source build; note that nix package is now a thin consumer
- Home Manager install: update rsync activation comments to reflect source-signed artifact (no more ad-hoc signing concerns)
- Hammerspoon launch path: update fish function note about Widevine-injected bundle (now always has Widevine from source)
- Add new section or note: 1Password manual Add Browser step (team ID [REDACTED])
- Add note about remoteDebuggingPort option in mkChromiumBrowser
- Add note about managed preferences activation

Run lat_check after edits — must pass.

## Acceptance Criteria

1. lat_check passes with no errors
2. Docs describe source build as Widevine/signing owner and nix as thin consumer
3. 1Password manual step is documented
4. Remote debugging port option is documented
5. Managed preferences are documented
