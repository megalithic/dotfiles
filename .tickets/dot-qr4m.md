---
id: dot-qr4m
status: open
deps: []
links: []
created: 2026-04-17T17:09:26Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Investigate pi-multi-pass extension for profile-based provider/model/auth management

Investigate the pi-multi-pass extension (installed at ~/.pi/agent/extensions/pi-multi-pass/) to understand its capabilities and determine how to configure it for a dual-profile setup.

Goals:
- Two profiles: 'rx' (work) and 'personal'
- Each profile specifies available providers (including synthetic provider via pi-synthetic-provider, and ollama) and models per provider
- Each profile defines fallback chains (e.g., if tokens exhausted or rate-limited on primary, fall to secondary provider/model)
- Each profile has its own auth config (different Anthropic/Claude Code subscriptions, API keys per provider)
- Custom footer (custom-footer.ts) shows active profile name on line 1, left of provider/model display

Relevant files:
- ~/.pi/agent/extensions/pi-multi-pass/ — extension source + README
- ~/.pi/agent/extensions/pi-multi-pass/README.md — docs
- ~/.pi/agent/extensions/custom-footer.ts — existing footer extension
- ~/.pi/agent/extensions/pi-synthetic-provider/ — synthetic provider extension
- ~/.pi/agent/extensions/model-quota.ts — may relate to quota/fallback logic
- ~/.dotfiles/home/common/programs/ai/pi-coding-agent/ — nix module managing these extensions

Investigation should produce:
1. Summary of pi-multi-pass capabilities and config schema
2. Gap analysis: what it supports vs what's needed
3. Proposed config structure for rx + personal profiles
4. Plan for custom-footer integration (showing active profile)
5. Any upstream changes or new extensions needed

## Acceptance Criteria

1. pi-multi-pass README.md and extension source fully reviewed
2. Document produced with: capabilities summary, config schema, supported provider types
3. Gap analysis identifies what works out-of-box vs needs custom work for: profiles, per-profile providers/models, fallback chains, per-profile auth
4. Proposed JSON/config structure drafted for dual-profile setup
5. Custom footer integration approach documented (how to show profile name in footer line 1)
6. Findings written to plans/ for future implementation tickets

