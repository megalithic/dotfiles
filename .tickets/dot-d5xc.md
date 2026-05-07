---
id: dot-d5xc
status: closed
deps: []
links: []
created: 2026-05-07T16:46:07Z
type: chore
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Deprecate web-search skill (subsumed by pi-internet extension)

The web-search skill wraps ddgr for DuckDuckGo search. The pi-internet extension
already provides a web_search tool with multi-provider support (Brave, Kagi, Tavily)
plus fetch_url and web_research capabilities. The skill is fully redundant.

Steps:
1. Remove web-search skill directory from home/common/programs/pi-coding-agent/skills/web-search/
2. Update AGENTS.md: remove 'Use web-search skill first (ddg)' instruction
3. If ddgr-only fallback is desired for rate-limit scenarios, add as fallback provider in pi-internet settings
4. Remove web-search from available_skills in system prompt sources if referenced

Files: home/common/programs/pi-coding-agent/skills/web-search/
       home/common/programs/pi-coding-agent/sources/GLOBAL_AGENTS.md (if web-search referenced)

## Acceptance Criteria

1. web-search skill directory removed
2. AGENTS.md no longer references web-search skill or ddg preference
3. pi-internet web_search tool still works (search for something, verify results)
4. just validate home passes


## Notes

**2026-05-07T18:37:59Z**

Removed web-search skill (SKILL.md, search.sh), removed ddgr package dependency, updated GLOBAL_AGENTS.md to remove web-search reference. Verified pi-internet web_search tool working with Brave provider. All acceptance criteria met.
