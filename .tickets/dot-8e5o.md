---
id: dot-8e5o
status: closed
deps: []
links: []
created: 2026-04-22T16:19:18Z
type: chore
priority: 1
assignee: Seth Messer
parent: dot-fsxj
tags: [ready-for-development]
---
# Remove pi-interactive-subagents extension (HazAT)

Decision Q1-A from dot-fsxj: abandon pi-interactive-subagents. It's too heavy (async tmux panes, bundled planner/scout/worker/reviewer/visual-tester agents that conflict with our researcher/planner) and doesn't integrate with work-tickets.sh synchronous pi -p loop.

## Steps

1. Check how it was installed: 'ls ~/.pi/agent/extensions/pi-interactive-subagents/' — installed via 'pi install git:github.com/HazAT/pi-interactive-subagents'
2. Uninstall: 'pi uninstall pi-interactive-subagents' (or whatever the command is — check 'pi --help')
3. If uninstall command doesn't exist: remove directory manually with 'trash ~/.pi/agent/extensions/pi-interactive-subagents'
4. Scan for references: rg 'pi-interactive-subagents|HazAT' ~/.dotfiles ~/.pi — remove or update each
5. Check if settings.json or any config references its agents (planner, scout, worker, reviewer, visual-tester) or commands (/iterate) — clean up

## Files likely affected

- ~/.pi/agent/extensions/pi-interactive-subagents/ (entire dir)
- ~/.pi/agent/settings.json (check for extension config)
- home/common/programs/ai/pi-coding-agent/*.md (check any prompts/skills mentioning /iterate or HazAT agents)

## Replacement

Our bundled extensions/subagent/ (index.ts + agents.ts) is already installed and handles synchronous subagent spawning — that's what task-pipeline.ts uses. No new extension needed.

## Acceptance Criteria

1. 'ls ~/.pi/agent/extensions/pi-interactive-subagents' returns 'No such file or directory'
2. 'rg HazAT ~/.dotfiles ~/.pi/agent/' returns no hits
3. 'rg pi-interactive-subagents ~/.dotfiles ~/.pi/agent/' returns no hits
4. 'pi' starts cleanly without missing-extension errors
5. Bundled subagent tool still works: 'subagents_list' returns 'planner' and 'researcher' agents
6. No references to /iterate command in any prompt/skill (or references removed)



---

**🔒 CLOSED-AS-SUPERSEDED 2026-04-28**

Absorbed by megadots ticket `meg-lp2m` (parent `meg-yblr` Stage 1 + blocks `meg-u3i3` Stage 2). Single tracker carries the obligation; substance preserved in `meg-lp2m` body. Source: `~/.local/share/pi/plans/megadots/cross-repo-status.md`.
