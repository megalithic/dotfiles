---
id: dot-hny3
status: closed
deps: [dot-zpzk]
links: []
created: 2026-05-06T16:40:33Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Plan model replacement strategy and memory tuning

Decide final models: Qwen3.6-27B-4bit (~13GB), DeepSeek-R1-Distill-Qwen-14B-4bit (~7GB), gemma-4-e4b-it-4bit (~3GB).
Verify models exist on mlx-community HF.
Estimate memory: 23GB weights + 25% headroom on any two = ~24GB total.
Plan which old models to keep/delete (delete after new ones verified).
Document decision: which to download, which to remove, why this combo for 32GB.

See context file for memory math.

## Acceptance Criteria

1. Confirmed mlx-community/Qwen3.6-27B-4bit exists (curl to HF API or browser)
2. Confirmed DeepSeek-R1-Distill-Qwen-14B-4bit exists
3. Confirmed gemma-4-e4b-it-4bit exists
4. Memory budget math checked: weights + headroom fits 32GB
5. Decision documented: which models to download/delete and in what order


## Notes

**2026-05-06T20:13:42Z**

Model replacement strategy decided 2026-05-06.

**Models chosen (verified on mlx-community HF):**
| Model | Safetensors | Load cost (w/ 25% KV) | Role |
|-------|------------|----------------------|------|
| Qwen3.6-27B-4bit | 14.95GB | 18.69GB | Primary coding/reasoning (pinned) |
| DeepSeek-R1-Distill-Qwen-14B-4bit | 7.73GB | 9.66GB | Reasoning specialist (TTL 600s) |
| gemma-4-e4b-it-4bit | 4.85GB | 6.06GB | Vision + lightweight (TTL 600s) |

**Memory budget (M2 Max 32GB):**
- max_process_memory: 75% = 24GB
- Qwen27B pinned: 18.69GB → 5.3GB spare for one secondary
- Qwen + Gemma-e4b: 24.75GB (borderline, may need reduced context window)
- Qwen + DeepSeek14B: 28.35GB (DOES NOT FIT — mutually exclusive with Qwen)
- Only one secondary at a time alongside Qwen

**Settings changes:**
- max_model_memory: keep 20GB (fits Qwen w/ headroom, forces eviction before 2nd model)
- Qwen27B: pinned, TTL null, max_context_window 32768
- DeepSeek14B: unpinned, TTL 600s, max_context_window 32768
- Gemma-e4b: unpinned, TTL 600s, max_context_window 16384 (reduced to stay in budget)

**Migration order:**
1. Download Qwen3.6-27B-4bit (~15GB)
2. Download gemma-4-e4b-it-4bit (~5GB)
3. Download DeepSeek-R1-Distill-Qwen-14B-4bit (~8GB)
4. Verify all three load + respond
5. Delete old Qwen3.6-35B-A3B-4bit (20GB) and gemma-4-26b-a4b-it-4bit (15GB)
   Total disk freed: ~35GB; new total: ~28GB

**Why this combo:**
- Qwen27B is dense 27B (not MoE) — better per-param quality at 4bit than MoE 35B at 4bit
- DeepSeek14B is reasoning-specialized distillation — good for complex planning
- Gemma-e4b is tiny vision model — covers multimodal without RAM pressure
- All three can exist on disk (~28GB) but only 1-2 in RAM at once

**Ghost entry:** Remove gemma-4-26b-a4b-it-8bit from model_settings (no files, never will have on 32GB)
