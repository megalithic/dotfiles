---
id: dot-4ck0
status: open
deps: []
links: []
created: 2026-04-22T16:18:51Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-fsxj
tags: [ready-for-development]
---
# Rewrite skills/ticket-creator/SKILL.md: jj-first commit steps with git fallback

Update skills/ticket-creator/SKILL.md to match otahontas's commit-after-create behavior, but jj-first. Auto-detect .jj dir for VCS choice.

## Files

- Source (ref): /tmp/otahontas-nix/home/configs/pi-coding-agent/skills/ticket-creator/SKILL.md (lines 78-79, 125-126, 193-196)
- Dest: ~/.dotfiles/home/common/programs/ai/pi-coding-agent/skills/ticket-creator/SKILL.md

## Changes

Mode 1 (single ticket), after step 3:
- Old: '4. Show the created ticket to the user'
- New: '4. Commit the ticket:
   - If .jj exists: jj dm "feat(tickets): add ticket for <short description>"
   - Else: git add .tickets/ && git commit -S -m "feat(tickets): add ticket for <short description>"
  5. Show the created ticket to the user'

Mode 2 (decompose), after step 6:
- Similar: commit all created tickets in one jj describe + include plans/.ticket-context.md if newly seeded

Mode 4 (refine), after step 6:
- Similar: jj dm "refactor(tickets): refine ticket <id>" or git commit equivalent

## Rule reference

Reference AGENTS.md 'Version Control (Jujutsu)' section: 'Never use git commands — always use jj equivalents'. Our git fallback exists only for repos without jj initialized.

## Commit message format

Must comply with the new sentinel conventional-commit guard (dot-fqt2) — use 'feat(tickets):' or 'refactor(tickets):' prefixes.

## Acceptance Criteria

1. All three modes (1, 2, 4) include commit step with jj-first/git-fallback branching
2. Commit messages in skill examples match conventional-commit format (passes dot-fqt2 sentinel rule)
3. 'just validate home' + 'just home' pass
4. Dry-run test: spawn pi, ask it to 'create a ticket for testing ticket-creator commit step' in ~/.dotfiles (which has .jj) — observe agent runs 'jj dm "feat(tickets): ..."'
5. Reference to AGENTS.md jj section preserved at top of commit section

