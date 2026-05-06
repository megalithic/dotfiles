---
id: dot-piyo
status: open
deps: []
links: []
created: 2026-05-06T20:22:48Z
type: task
priority: 2
assignee: Seth Messer
---
# Evaluate pi-multi-pass for omlx model routing, fallbacks, and per-repo provider config

With the omlx model replacement (dot-hny3 strategy: Qwen27B primary, DeepSeek14B reasoning, Gemma-e4b vision), evaluate how pi-multi-pass can manage:

1. **Provider routing**: omlx (local, free, fast) vs anthropic (cloud, paid, highest quality) vs synthetic/google-vertex — when to use which, per repo
2. **Fallback chains**: omlx/qwen3.6 → anthropic/sonnet → omlx/deepseek14b. If omlx is down or OOM, fall to cloud. If cloud rate-limited, fall to local secondary.
3. **Model presets**: e.g. 'coding-local' (omlx-first), 'coding-premium' (anthropic-first), 'review' (cheap model)
4. **Per-repo affinity**: work repos (~/code/rx/*) use rx subscription + restrict to approved providers. Personal repos use personal sub + allow omlx local. Dotfiles allow everything.
5. **Auth separation**: rx Anthropic key vs personal Anthropic key vs omlx (no key needed)

pi-multi-pass already supports: multiple subs, rotation pools, fallback chains, model presets, project affinity via .pi/multi-pass.json. See README at ~/.pi/agent/extensions/pi-multi-pass/README.md.

Related: dot-qr4m is the broader investigation ticket for multi-pass profiles. This ticket is narrower — focused on the omlx model set and practical configuration for current repos.

Key questions to answer:
- How to add omlx as a 'subscription' in multi-pass (it's keyless localhost, not OAuth)
- Whether pool strategies (round-robin, quota-first) make sense for local+cloud mix
- Best chain config for 32GB megabookpro (omlx may OOM → need cloud fallback)
- Whether .pi/multi-pass.json per repo is the right approach or if presets are better
- How this interacts with models.json provider definitions and settings.json enabledModels

See:
- ~/.pi/agent/extensions/pi-multi-pass/README.md
- home/common/programs/pi-coding-agent/models.json
- home/common/programs/pi-coding-agent/settings.json

## Acceptance Criteria

1. pi-multi-pass README fully reviewed — document how keyless local providers (omlx) register as subscriptions
2. Propose subscription setup: omlx (local), anthropic-personal, anthropic-rx — with labels
3. Propose pool config: at least one pool mixing local+cloud with appropriate strategy
4. Propose fallback chain: omlx/qwen3.6 → cloud → omlx/deepseek14b with trigger conditions documented
5. Propose 2-3 model presets (coding-local, coding-premium, review) with provider+model mappings
6. Propose per-repo .pi/multi-pass.json for at least: one rx work repo, one personal repo, dotfiles
7. Document interaction between multi-pass routing and models.json/settings.json — any conflicts or redundancy
8. Findings written to plans/dotfiles/ for implementation

