---
id: dot-7f3k
status: closed
deps: [dot-aqin, dot-9el2, dot-fqt2, dot-vta8, dot-6jlp, dot-2ymj, dot-4ck0, dot-z8ku, dot-8e5o, dot-1r2i, dot-08ij]
links: []
created: 2026-04-22T16:20:02Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-fsxj
tags: [ready-for-development]
---
# End-to-end smoke test: just validate, just home, work-tickets dry run

Final verification after all child tickets land. No code changes expected — just exercise the full pipeline.

## Steps

1. 'just validate' in ~/.dotfiles — both darwin and home variants pass
2. 'just home' — applies all new extensions/skills/scripts
3. Verify installations:
   - which work-tickets (should return Nix profile path)
   - ls ~/.pi/agent/extensions/ticket-vcs.ts (via symlink resolution)
   - ls ~/.pi/agent/extensions/restricted-write.ts (same)
   - pi-interactive-subagents dir gone
   - checkpoint.ts gone
4. Create a trivial throwaway ticket in ~/.dotfiles:
   tk create 'Test work-tickets smoke' -d 'Add a blank line to README.md as a no-op change' --acceptance '1. README.md has one extra blank line; 2. no other files modified' --tags ready-for-development
5. Run 'work-tickets' in ~/.dotfiles
6. Observe the full lifecycle:
   - tk start fires ticket-vcs hook → jj feat <id> runs
   - pi -p worker reads ticket, makes change, runs verification
   - commit step uses 'jj dm "feat(README): add blank line (closes <id>)"' (sentinel allows it)
   - tk close fires ticket-vcs hook → suggests commit if not done (no-op here)
   - verification pass runs in second pi -p
   - final review summarizes log
   - stop_hook removes ~/.pi/state/current-ticket.json
7. Roll back smoke-test changes: jj abandon the smoke commit, tk abandon the smoke ticket

## Verification commands

- jj log --limit 5 — confirm one feature bookmark created + abandoned
- tk closed --limit 3 — confirm smoke ticket shows as closed

## On failure

If any step fails, reopen the relevant child ticket with a note pointing to the failure. Do not close this smoke-test ticket until all children pass.

## Acceptance Criteria

1. 'just validate' passes for both darwin and home
2. 'just home' completes successfully
3. All path checks in step 3 above return expected results
4. Throwaway ticket completes full lifecycle: open → in_progress → closed with verification
5. jj bookmark created automatically via ticket-vcs hook
6. Commit message matches conventional format (sentinel didn't block)
7. Final review output mentions 1 completed, 0 skipped
8. Rollback steps (jj abandon, etc.) clean repo state
9. No lingering state files in ~/.pi/state/ after session ends



---

**🔒 CLOSED-AS-SUPERSEDED 2026-04-28**

Absorbed by megadots ticket `meg-lp2m` (parent `meg-yblr` Stage 1 + blocks `meg-u3i3` Stage 2). Single tracker carries the obligation; substance preserved in `meg-lp2m` body. Source: `~/.local/share/pi/plans/megadots/cross-repo-status.md`.
