---
id: dot-1iip
status: open
deps: 4:1:deps: 4:1:deps: [, dot-xwa4, dot-j262]
links: []
created: 2026-06-10T00:34:22Z
type: feature
priority: 2
assignee: Seth Messer
tags: [shade-next, phase-2]
---

# shade-next: Hammerspoon launch-prefilled via bindAppChord -> URL/socket prefill

Use the now-registered shade-next:// URL scheme (and/or the control socket) so a Hyper chord launches/toggles shade-next pre-filled with input, not just toggled. Extend the Hammerspoon integration (config/hammerspoon/shade_next.lua + hyper.lua bindAppChord) so a binding can carry a prefill payload, e.g. open 'shade-next://prefill?text=...&route=pi&focus=1' or send a socket prefill to an already-running instance. Provide at least one concrete default binding example (e.g. hyper+p -> open prefilled for a pi: handoff). Reuse the Nix-generated fragment (~/.local/share/hammerspoon/fragments/shade-next.lua) for app/scheme data; keep current shade untouched and use bin/hs-reload to reload.

## Acceptance Criteria

1. A Hammerspoon helper/binding can launch or focus shade-next with the input pre-filled (via shade-next:// prefill or socket prefill).
2. At least one documented default chord opens shade-next prefilled (route optional), focusing the input.
3. Already-running instance is reused (socket prefill) rather than spawning duplicates where possible.
4. Lua syntax-checked; just validate home passes; reloaded via bin/hs-reload.
5. Current shade bindings/workflow untouched.
