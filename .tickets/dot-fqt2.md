---
id: dot-fqt2
status: open
deps: []
links: []
created: 2026-04-22T16:17:56Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-fsxj
tags: [ready-for-development]
---
# Add jj-aware conventional-commit rule to sentinel.ts

Add a new guard rule to extensions/sentinel.ts that blocks commit messages not matching conventional-commit format. Must cover BOTH jj and git invocations.

## Matched patterns

- jj desc -m "..."
- jj describe -m "..."
- jj commit -m "..."
- jj dm "..." (our alias)
- git commit -m "..."
- git commit -S -m "..."

## Regex for message body

^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(\S+\))?: .+

## Block mode

Hard block (CONFIRM level) per decision Q4 — user must type 'override' to bypass. Mirror the UX of existing sentinel block rules (e.g. 'jj-commit-no-msg' at sentinel.ts:337).

## Reason text

'⚠️ Non-conventional commit message\n\nFormat: type(optional-scope): description\nTypes: feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert\nExample: jj dm "feat(tickets): add work-tickets.sh"'

## Files

- ~/.dotfiles/home/common/programs/ai/pi-coding-agent/extensions/sentinel.ts — add new guard object to guards[] array
- Reference implementation: /tmp/otahontas-nix/home/configs/pi-coding-agent/extensions/guardrails.ts lines ~22-65 (blockNonConventionalCommits)

## Acceptance Criteria

1. New guard 'conventional-commit' exists in sentinel.ts guards[] array
2. Regex correctly matches: jj desc -m, jj describe -m, jj commit -m, jj dm, git commit -m, git commit -S -m
3. Regex tolerates mixed quoting (single, double) and optional -S flag
4. Valid messages pass: 'feat: foo', 'fix(auth): bar', 'chore(deps): baz'
5. Invalid messages block: 'added stuff', 'Fix: thing', 'WIP', no prefix
6. Block is CONFIRM level (user can override with 'override' keyword)
7. 'just validate home' + 'just home' pass
8. Manual test in pi session: 'jj dm "WIP"' via bash tool triggers confirm; 'jj dm "feat: test"' passes

