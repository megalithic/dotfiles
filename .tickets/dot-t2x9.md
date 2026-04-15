---
id: dot-t2x9
status: open
deps: [dot-mmvc]
links: []
created: 2026-04-15T16:36:26Z
type: task
priority: 2
assignee: Seth Messer
parent: dot-42gl
tags: [ready-for-development]
---
# Phase 5: Final trim of repo AGENTS.md and validation

After phases 1-4, repo AGENTS.md should only contain repo-specific content.
Review and trim any remaining bloat. Verify both files against target metrics.

Target metrics:
- GLOBAL_AGENTS.md: ~150 lines, universal content only
- Repo AGENTS.md: ~200 lines, repo-specific content only
- Zero duplicated sections between the two files
- All relocated content findable in its new home

Also verify the inline comments added to default.nix (from earlier in this session)
are consistent with the updated AGENTS.md files.

Files to review:
- home/common/programs/ai/pi-coding-agent/sources/GLOBAL_AGENTS.md
- AGENTS.md (repo root)
- home/common/programs/ai/pi-coding-agent/default.nix (inline comments)
- home/common/programs/ai/pi-coding-agent/AGENTS.md
- config/hammerspoon/AGENTS.md (created in phase 1)

## Acceptance Criteria

1. GLOBAL_AGENTS.md is ≤150 lines (wc -l)
2. Repo AGENTS.md is ≤200 lines (wc -l)
3. No section appears in both files (manual review)
4. All content from original GLOBAL is either in GLOBAL, repo AGENTS.md, a subdirectory AGENTS.md, or inline comments — nothing lost
5. Inline AGENT CONTEXT comments in default.nix are consistent with AGENTS.md
6. just validate passes
7. nix flake check --no-build passes

