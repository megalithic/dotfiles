---
id: dot-z8ku
status: closed
deps: []
links: []
created: 2026-04-22T16:18:51Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-fsxj
tags: [ready-for-development]
---
# Rewrite skills/ticket-worker/SKILL.md: jj-first commit steps with git fallback

Update skills/ticket-worker/SKILL.md step 6 (Commit and close) to be jj-first.

## Files

- Dest: ~/.dotfiles/home/common/programs/ai/pi-coding-agent/skills/ticket-worker/SKILL.md

## Current text (step 6)

'1. Commit using the conventions in the git-commit skill (git commit -S -m "type(scope): description"). If lat.md/ was updated, include those changes in the same commit.'

## New text

'1. Commit using conventional-commit format:
   - If .jj exists: jj dm "type(scope): description" (preferred per AGENTS.md)
   - Else: git commit -S -m "type(scope): description"
   If lat.md/ was updated, include those changes in the same commit.
2. Close the ticket: tk close <id>
3. Add a summary note: tk add-note <id> "Summary of what was done"'

## Rules section

The 'Commit message format' rule at EOF currently says 'Always use conventional commits, single line, GPG-signed, no AI attribution.' Update to clarify:
- jj: no -S needed (jj signs via config if configured)
- git: keep -S flag

## Sentinel compliance

Commit examples must satisfy dot-fqt2 conventional-commit regex. Spot-check: 'feat(auth): add rate limiting' ✓, 'fix(tickets): handle missing deps' ✓.

## Acceptance Criteria

1. Step 6 documents jj-first with git fallback
2. Rules section 'Commit message format' updated for both VCS
3. References to 'git-commit skill' removed (we decided not to create jj-commit skill — rely on sentinel guard per decision Q3 in dot-fsxj)
4. 'just validate home' + 'just home' pass
5. Dry-run: spawn ticket-worker against a trivial ticket in ~/.dotfiles, observe 'jj dm' used, not 'git commit'



---

**🔒 CLOSED-AS-SUPERSEDED 2026-04-28**

Absorbed by megadots ticket `meg-lp2m` (parent `meg-yblr` Stage 1 + blocks `meg-u3i3` Stage 2). Single tracker carries the obligation; substance preserved in `meg-lp2m` body. Source: `~/.local/share/pi/plans/megadots/cross-repo-status.md`.
