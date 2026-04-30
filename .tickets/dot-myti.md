---
id: dot-myti
status: open
deps: []
links: []
created: 2026-04-30T14:17:02Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-wo6i
tags: [nix, refactor, sync]
---
# Refactor: Rename settings-sync.nix → sync.nix, relocate to programs/sync/

Rename and relocate sync module:
- From: home/common/modules/settings-sync.nix
- To: home/common/programs/sync/default.nix

Rationale: Better organization, aligns with other programs, clearer naming.

Steps:
1. Create home/common/programs/sync/default.nix
2. Move settings-sync.nix content
3. Update imports in home/common/default.nix
4. Test with 'just validate'
5. Commit with jj describe

