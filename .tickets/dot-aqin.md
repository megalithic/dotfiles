---
id: dot-aqin
status: closed
deps: []
links: []
created: 2026-04-22T16:17:28Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-fsxj
tags: [ready-for-development]
---
# Port extensions/restricted-write.ts from otahontas/nix

Copy extensions/restricted-write.ts from /tmp/otahontas-nix/home/configs/pi-coding-agent/extensions/restricted-write.ts to home/common/programs/ai/pi-coding-agent/extensions/restricted-write.ts. File is self-contained — registers two tools (write-task, write-plan) scoped to plans/task.md and plans/plan.md. Copy verbatim, no changes needed. Enables subagents to write their own output files.

Files:
- Source: /tmp/otahontas-nix/home/configs/pi-coding-agent/extensions/restricted-write.ts
- Dest: ~/.dotfiles/home/common/programs/ai/pi-coding-agent/extensions/restricted-write.ts
- Auto-discovered by default.nix (no nix changes needed per AGENT CONTEXT header)

## Acceptance Criteria

1. File exists at dest path with identical contents to upstream
2. 'just validate home' passes
3. After 'just home', 'pi' starts cleanly and 'write-task' + 'write-plan' tools appear in tool list (check via any subagent invocation or tool introspection)
4. Writing to plans/../etc/passwd via write-task returns error (path traversal blocked)
5. Writing to plans/task.md via write-task creates file with expected content



---

**🔒 CLOSED-AS-SUPERSEDED 2026-04-28**

Absorbed by megadots ticket `meg-lp2m` (parent `meg-yblr` Stage 1 + blocks `meg-u3i3` Stage 2). Single tracker carries the obligation; substance preserved in `meg-lp2m` body. Source: `~/.local/share/pi/plans/megadots/cross-repo-status.md`.
