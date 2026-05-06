---
id: dot-qppi
status: closed
deps: [dot-hny3]
links: []
created: 2026-05-06T16:40:40Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Update omlx/default.nix with new model definitions

In home/common/programs/omlx/default.nix, update defaultModelSettings.models (around line 45-85).
Remove: Qwen3.6-35B-A3B-4bit, gemma-4-26b-a4b-it-4bit, gemma-4-26b-a4b-it-8bit
Add: Qwen3.6-27B-4bit, DeepSeek-R1-Distill-Qwen-14B-4bit, gemma-4-e4b-it-4bit
Keep sampling presets: Qwen uses qwen3-r-code (0.6 temp), DeepSeek uses reasoning defaults (1.0 temp), Gemma uses gemma4 preset (1.0 temp).
Adjust max_context_window if models differ from current (expect 32768 for all three).

See home/common/programs/omlx/default.nix lines 40-90.

## Acceptance Criteria

1. Syntax valid: 'nix flake check' passes or 'just validate' succeeds
2. Old model keys removed: grep -v 'Qwen3.6-35B-A3B-4bit' home/common/programs/omlx/default.nix | grep -v 'gemma-4-26b'
3. New model keys added: grep 'Qwen3.6-27B-4bit' && grep 'DeepSeek-R1-Distill' && grep 'gemma-4-e4b-it-4bit'
4. Sampling settings preserved: each model has temperature, top_p, top_k per preset
5. model_alias fields correct: qwen3.6, deepseek14b, gemma4


## Notes

**2026-05-06T20:15:22Z**

Completed 2026-05-06. Updated defaultModelSettings.models in omlx/default.nix:

Removed: Qwen3.6-35B-A3B-4bit, gemma-4-26b-a4b-it-4bit, gemma-4-26b-a4b-it-8bit
Added:
- Qwen3.6-27B-4bit (alias qwen3.6, 14.95GB, qwen3-r-code preset, reasoning+specprefill)
- DeepSeek-R1-Distill-Qwen-14B-4bit (alias deepseek14b, 7.73GB, reasoning defaults)
- gemma-4-e4b-it-4bit (alias gemma4, 4.85GB, gemma4 preset, 16K context, thinking locked off)

Also updated header pull-model comments with new sizes.
just validate home passes.
