---
id: dot-5ec8
status: closed
deps: [dot-wlne]
links: []
created: 2026-05-06T16:40:58Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Rebuild nix darwin + home-manager to apply config changes

Apply all nix changes from previous steps.
Run 'just validate' first to check both darwin and home-manager derivations without switching (catch errors early).
Then run 'just rebuild' to switch (or 'just home' if darwin doesn't need update).
Nix activation scripts will write new ~/.omlx/settings.json and ~/.omlx/model_settings.json.

See justfile for rebuild targets.

## Acceptance Criteria

1. Validate passes: 'just validate' returns success
2. Rebuild succeeds: 'just rebuild' completes without error
3. Settings written: 'jq .model.max_model_memory ~/.omlx/settings.json' returns '24GB'
4. Model settings updated: 'jq '.models | keys' ~/.omlx/model_settings.json' lists new model keys

## Notes

**2026-05-06T20:24:10Z**

Completed 2026-05-06. just validate + just home both pass.
Activation wrote new settings:

- ~/.omlx/settings.json: max_model_memory=24GB
- ~/.omlx/model_settings.json: Qwen3.6-27B-4bit, DeepSeek-R1-Distill-Qwen-14B-4bit, gemma-4-e4b-it-4bit
  Darwin rebuild skipped (no system changes in this chain).
