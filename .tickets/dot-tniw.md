---
id: dot-tniw
status: closed
deps: 4:1:deps: 4:1:deps: [, dot-itag, dot-ks5d]
links: []
created: 2026-06-11T11:38:03Z
type: task
priority: 2
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Add focused checks for strict pinvim pairing helpers

Cover strict pairing decision logic where practical without full tmux UI. File hints: home/common/programs/pi-coding-agent/extensions/pinvim.ts helper extraction/test-adjacent checks; bin/pimux helper checks or temporary .local_scripts/ probes if no harness exists.

## Acceptance Criteria

1. Exact pair acceptance is covered by an automated or scripted check
2. Unpaired same-window, stale 20s, dead pid, live mismatch, other window/session, and non-tmux exact-only cases are covered where practical
3. Explicit target no-ownership-rewrite and fill_prompt no-claim behavior are checked or documented for manual verification
4. If no durable harness exists, implementation records commands/checklist and does not commit messy temporary scripts
5. Existing home validation passes with devenv shell -- just validate home
