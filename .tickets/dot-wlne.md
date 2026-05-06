---
id: dot-wlne
status: closed
deps: [dot-ejxp]
links: []
created: 2026-05-06T16:40:52Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Update pi-coding-agent models.json with new aliases

In home/common/programs/pi-coding-agent/models.json, review and update omlx provider section.
Ensure qwen3.6 and gemma4 aliases still work with new models.
Add deepseek14b alias for DeepSeek-R1-Distill-Qwen-14B-4bit if adding reasoning to available models.
Update contextWindow and maxTokens if models differ (expect 32768/65536 for all three).
Keep reasoning flags: Qwen true, DeepSeek true, Gemma false.

See home/common/programs/pi-coding-agent/models.json omlx section.

## Acceptance Criteria

1. JSON syntax valid: 'jq . home/common/programs/pi-coding-agent/models.json > /dev/null && echo ok'
2. Aliases exist: jq '.providers.omlx.models[].id' lists at least qwen3.6 and gemma4
3. Reasoning flags correct: qwen3.6 and deepseek14b have reasoning=true, gemma4 has reasoning=false
4. Context windows set: each model has contextWindow field (32768 or 65536)
5. maxTokens set: each model has maxTokens field (8192)


## Notes

**2026-05-06T20:22:06Z**

Completed 2026-05-06. Updated pi-coding-agent config:

models.json:
- Added deepseek14b entry (reasoning=true, contextWindow=32768, thinkingFormat=deepseek)
- qwen3.6 contextWindow: 65536 → 32768 (matches 27B model max_context_window)
- gemma4 contextWindow: 32768 → 16384 (matches reduced budget in default.nix)

settings.json:
- Added omlx/deepseek14b to enabledModels list

just validate home passes.
