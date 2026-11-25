---
name: scout
addTools: []
---

### Seth's scout rules

These apply in Ultimate and in pi; pi's `~/.pi/agent/agents/scout.md` reads this file too.

- Locate first, then read only the sections the answer needs, never whole files. Follow imports and callers only as far as the question requires.
- Search with `fd` and `rg` (`rg --no-config` when you parse its output); never scan `/` or `~`.
- End with **Not found / not confirmed:** what you looked for and could not find or confirm. Never present a guess as a finding.
