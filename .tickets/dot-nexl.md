---
id: dot-nexl
status: closed
deps: []
links: []
created: 2026-05-14T12:16:08Z
type: task
priority: 0
assignee: Seth Messer
parent: dot-0fjk
tags: [stop-hook, extensions, prompt-engineering]
---

# feat(stop-hook): refine vcs/ticket summaries and model configuration

## Context: Nix-based dotfiles

All work is in `~/.dotfiles`, managed via Nix. **Do not assume npm/pnpm are globally installed.**
Check the top of `~/.dotfiles/home/common/programs/pi-coding-agent/default.nix` for exact build patterns:

1. Simple extensions/skills: Auto-load (no build step).

## What

Top priority extension update.

1. Update STOP_CHECK_PROMPT_BASE in stop-hook.ts to request concise, conversational VCS and Ticket status instead of raw dumps.
2. Add support for configuring the summarizer model (and gatekeeper model) potentially via multi-pass presets.
