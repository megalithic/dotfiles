---
id: dot-sbcv
status: open
deps: []
links: []
created: 2026-05-11T15:14:36Z
type: feature
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Update pi-coding-agent to v0.74.0, migrate to @earendil-works scope

Update the pi wrapper package from @mariozechner/pi-coding-agent@0.73.0 to @earendil-works/pi-coding-agent@0.74.0.
The package was renamed in v0.74.0 when the project moved from mariozechner to earendil-works.

Steps:
1. Edit packages/pi/package.json: change dep from @mariozechner/pi-coding-agent to @earendil-works/pi-coding-agent, version 0.74.0
2. Run 'just update-npm pi 0.74.0' to regenerate lockfile and npmDepsHash
3. Update default.nix installPhase: symlink path changes from node_modules/@mariozechner/pi-coding-agent/ to node_modules/@earendil-works/pi-coding-agent/
4. Update the retry patch TARGET path in installPhase to use @earendil-works
5. Update the AGENT CONTEXT comment at top of default.nix if it references old scope

See home/common/programs/pi-coding-agent/packages/pi/package.json and home/common/programs/pi-coding-agent/default.nix (pi-coding-agent block, lines ~100-130).

## Acceptance Criteria

1. packages/pi/package.json depends on @earendil-works/pi-coding-agent@0.74.0
2. just update-npm pi 0.74.0 succeeds with correct npmDepsHash
3. default.nix installPhase references @earendil-works/pi-coding-agent (not @mariozechner)
4. just validate home builds without error
5. pi --version reports 0.74.0
6. Retry patches apply correctly to the new path

