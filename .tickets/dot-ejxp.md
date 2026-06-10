---
id: dot-ejxp
status: closed
deps: [dot-qppi]
links: []
created: 2026-05-06T16:40:47Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Update megabookpro.nix with new memory settings and pinning

In home/megabookpro.nix, update programs.omlx settings (around line 13-36).
Increase max_model_memory from '20GB' to '24GB' (allows Qwen27B with KV headroom).
Keep max_process_memory at 75% (= 24GB, good for two medium models).
Update modelSettings.models: remove old 35B/26B keys, add new keys with is_pinned and ttl_seconds.
Pin Qwen3.6-27B-4bit (is_pinned=true, ttl_seconds=null, primary model).
TTL DeepSeek14B (is_pinned=false, ttl_seconds=600, reasoning specialist).
TTL Gemma-e4b (is_pinned=false, ttl_seconds=600, vision/light).

See home/megabookpro.nix programs.omlx section.

## Acceptance Criteria

1. Syntax valid: 'just validate' passes
2. max_model_memory updated to '24GB': 'grep max_model_memory home/megabookpro.nix'
3. New model keys present: grep 'Qwen3.6-27B-4bit' && grep 'DeepSeek-R1-Distill' && grep 'gemma-4-e4b-it-4bit'
4. Pinning correct: Qwen has 'is_pinned = true', others have 'is_pinned = false'
5. TTLs set: Qwen has 'ttl_seconds = null', others have 'ttl_seconds = 600'

## Notes

**2026-05-06T20:18:25Z**

Completed 2026-05-06. Updated megabookpro.nix omlx section:

- max_model_memory: 20GB → 24GB (fits Qwen27B 14.95GB + 25% KV headroom)
- Removed old Qwen3.6-35B-A3B-4bit and gemma-4-26b-a4b-it-4bit
- Added Qwen3.6-27B-4bit (pinned, TTL null), DeepSeek-R1-Distill-Qwen-14B-4bit (TTL 600), gemma-4-e4b-it-4bit (TTL 600)
- Updated header comment to reference dot-hny3 strategy + budget note
  just validate home passes.
