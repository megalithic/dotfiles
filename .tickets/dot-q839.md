---
id: dot-q839
status: open
deps: []
links: []
created: 2026-05-07T16:46:23Z
type: chore
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Clarify chrome-cdp vs web-browser skill usage boundaries

Both chrome-cdp and web-browser skills connect to Chrome via CDP but serve different
use cases. Users (and the agent) can't tell which to use when.

Options (pick one):
A) Merge into one 'browser' skill with sections for each tool
B) Add 'When to use' section to each skill

Recommended: Option B (less disruption, both skills stay self-contained).

- chrome-cdp: inspection, debugging, screenshots, JS eval, a11y tree, network timing
- web-browser: page interaction, form filling, tab management, navigation workflows

Files: home/common/programs/pi-coding-agent/skills/chrome-cdp/SKILL.md
home/common/programs/pi-coding-agent/skills/web-browser/SKILL.md

## Acceptance Criteria

1. Both skills have clear 'When to use this skill' section at top
2. chrome-cdp documents: use for inspection, debugging, screenshots, a11y, JS eval
3. web-browser documents: use for interaction, forms, tab management, navigation
4. Cross-references between the two skills exist
5. just validate home passes
