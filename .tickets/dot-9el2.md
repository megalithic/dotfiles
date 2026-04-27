---
id: dot-9el2
status: closed
deps: []
links: []
created: 2026-04-22T16:17:28Z
type: task
priority: 2
assignee: Seth Messer
parent: dot-fsxj
tags: [ready-for-development]
---
# Audit extensions/sentinel.ts for commented-out rules

Read extensions/sentinel.ts top-to-bottom (1062 lines). Identify any commented-out guard rules that were disabled in prior work. For each: decide keep/uncomment/delete. Document findings. rg didn't surface obvious /\* ... \*/ or // blocks containing guard definitions, so this is a manual audit pass.

Files:
- ~/.dotfiles/home/common/programs/ai/pi-coding-agent/extensions/sentinel.ts
- ~/.dotfiles/home/common/programs/ai/pi-coding-agent/extensions/sentinel-rules.json

Look specifically for:
- Guard objects with 'name:' key inside comment blocks
- Disabled entries in the guards[] array at EOF
- Reasons for disabling in surrounding comments

## Acceptance Criteria

1. Written audit in the ticket note listing every commented-out rule found (or 'none found, clean')
2. For each rule: disposition (re-enable, delete comment, keep commented with reason)
3. If any re-enabled: 'just validate home' passes, 'just home' succeeds
4. 'pi' still starts and sentinel loads without errors



---

**🔒 CLOSED-AS-SUPERSEDED 2026-04-28**

Absorbed by megadots ticket `meg-lp2m` (parent `meg-yblr` Stage 1 + blocks `meg-u3i3` Stage 2). Single tracker carries the obligation; substance preserved in `meg-lp2m` body. Source: `~/.local/share/pi/plans/megadots/cross-repo-status.md`.
