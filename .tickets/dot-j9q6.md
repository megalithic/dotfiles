---
id: dot-j9q6
status: open
deps: [dot-bd5i]
links: []
created: 2026-05-05T12:23:10Z
type: feature
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Configure oMLX models + wire pi provider (additive alongside ollama)

Pull Qwen3.6 and Gemma4 models for the current host, configure per-model settings (alias, pinning, TTL, SpecPrefill), add omlx provider to pi models.json, and add omlx models to pi enabledModels. Both ollama and omlx providers remain enabled.

This is Phase 2 of the oMLX migration plan. Models are downloaded ad-hoc (not nix-managed) into XDG data dir. Pi gains omlx provider alongside existing ollama provider.

**Files:**
- home/common/programs/omlx/default.nix — populate programs.omlx.modelSettings defaults (Qwen3.6-35B-A3B-4bit alias qwen3.6, gemma-4-26b-a4b-it-4bit alias gemma4, SpecPrefill, reasoning_parser)
- home/megabookpro.nix — per-model overrides: Qwen is_pinned=false ttl_seconds=1800 max_context_window=32768; gemma4-4bit is_pinned=false ttl_seconds=600
- home/rxbookpro.nix — per-model overrides: Qwen is_pinned=true; gemma4-8bit is_pinned=true max_context_window=65536 (different quant than megabookpro)
- home/common/programs/pi-coding-agent/models.json — add omlx provider (baseUrl http://localhost:8000/v1, api openai-completions) with qwen3.6 (text, reasoning) and gemma4 (text+image) models; keep ollama provider
- home/common/programs/pi-coding-agent/settings.json — add omlx/qwen3.6 and omlx/gemma4 to enabledModels; keep ollama models

**Model picks (from research):**
- megabookpro (32GB): Qwen3.6-35B-A3B-4bit (19GB, ~78 tok/s) + gemma-4-26b-a4b-it-4bit (14.6GB, ~63 tok/s)
- rxbookpro (64GB): Qwen3.6-35B-A3B-4bit (19GB, ~117 tok/s) + gemma-4-26b-a4b-it-8bit (26GB, ~75 tok/s)

**Manual step:** Run omlx-pull qwen3.6 && omlx-pull gemma4 on each host after just home.

## Acceptance Criteria

1. ~/.omlx/model_settings.json contains Qwen3.6-35B-A3B-4bit with model_alias=qwen3.6, reasoning_parser=qwen, enable_thinking=true, specprefill_enabled=true
2. ~/.omlx/model_settings.json contains gemma-4-26b-a4b-it-4bit (or -8bit on rxbookpro) with model_alias=gemma4
3. On megabookpro: Qwen3.6 has is_pinned=false, ttl_seconds=1800, max_context_window=32768
4. On rxbookpro: Qwen3.6 has is_pinned=true; gemma-4-26b-a4b-it-8bit has is_pinned=true, max_context_window=65536
5. pi-coding-agent/models.json has both ollama and omlx providers with correct baseUrl and model entries
6. pi-coding-agent/settings.json enabledModels includes omlx/qwen3.6 and omlx/gemma4 (alongside ollama models)
7. After pulling models: curl -s :8000/v1/models lists qwen3.6 and gemma4 aliases
8. From tmux pane: curl to :8000/v1/chat/completions with model=qwen3.6 returns a valid response
9. just validate passes

