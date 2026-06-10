---
id: dot-zpzk
status: closed
deps: []
links: []
created: 2026-05-06T16:40:28Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Audit current oMLX state and model inventory

Verify current models on disk (Qwen3.6-35B-A3B-4bit ~20GB, gemma-4-26b-a4b-it-4bit ~15GB = 35.2GB total).
Check runtime settings in ~/.omlx/settings.json (max_model_memory, max_process_memory).
Review model_settings.json (pinning config, TTLs).
Confirm nix overrides in home/megabookpro.nix vs home/common/programs/omlx/default.nix.

See ~/.omlx/, home/megabookpro.nix, home/common/programs/omlx/default.nix

## Acceptance Criteria

1. Command 'du -sh ~/.local/share/omlx/models/\*/' shows ~20GB Qwen and ~15GB Gemma
2. 'jq .model.max_model_memory ~/.omlx/settings.json' returns '20GB'
3. 'jq '.models | keys' ~/.omlx/model_settings.json' lists Qwen and Gemma keys
4. 'grep -A5 programs.omlx home/megabookpro.nix' shows current overrides documented

## Notes

**2026-05-06T20:10:01Z**

Audit complete 2026-05-06. Findings:

**Models on disk:**

- Qwen3.6-35B-A3B-4bit: 20GB
- gemma-4-26b-a4b-it-4bit: 15GB
- Total: 35GB (exceeds 32GB RAM)

**Runtime settings (~/.omlx/settings.json):**

- max_model_memory: 20GB
- max_process_memory: 75% (=24GB)
- hot_cache: 2GB, ssd_cache: 40GB
- port: 8000, scheduler: 4 concurrent

**Model settings (~/.omlx/model_settings.json):**

- Qwen: pinned, TTL null, 32K context, thinking=true, qwen3-r-code sampling (temp 0.6)
- Gemma 4bit: unpinned, TTL 600s, 32K context, thinking=false
- Gemma 8bit: defined in nix but NOT on disk (ghost entry)

**Nix overrides (home/megabookpro.nix):**

- programs.omlx.settings: max_model_memory=20GB, hot_cache=2GB, ssd_cache=40GB, max_process_memory=75%
- programs.omlx.modelSettings.models: Qwen pinned, Gemma TTL 600s

**Active issues:**

- 507 errors: Gemma requests fail (pinned Qwen uses 19.95GB, can't free for 15.26GB Gemma)
- METAL OOM crash: Qwen with real context exceeds 32GB → kIOGPUCommandBufferCallbackErrorOutOfMemory
- omlx service exit code -6 (crash loop, launchd restarts)
- gemma-4-26b-a4b-it-8bit defined in model_settings but no files on disk
