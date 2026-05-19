---
id: dot-06iy
status: open
deps: [dot-hq7c]
links: []
created: 2026-05-18T13:40:31Z
type: feature
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Route Pi local models through llama.cpp

Replace Pi local provider definitions with a single llama.cpp OpenAI-compatible provider at http://127.0.0.1:18080/v1. Update model scopes so local aliases reference llama.cpp instead of Ollama/oMLX while leaving cloud subscription presets intact. File hints: home/common/programs/pi-coding-agent/models.json, settings.json, multi-pass.json, home/common/programs/pi-coding-agent/AGENTS.md.

## Acceptance Criteria

1. models.json defines a llamacpp provider using OpenAI-compatible API at http://127.0.0.1:18080/v1.
2. settings.json local model entries/scopes reference llama.cpp aliases instead of ollama/omlx models.
3. Cloud subscription providers and presets remain unchanged.
4. python -m json.tool validates models.json, settings.json, and multi-pass.json if modified.
5. just validate home passes.


## Notes

**2026-05-19T14:54:06Z**

Resume point after dot-hq7c: Nix service/package wiring is on llama.cpp, but Pi config still references old local providers. Current remaining source refs: models.json has ollama/omlx providers; settings.json enabledModels/model scopes include ollama/omlx; stop-hook still calls ollama gemma4:e4b/e2b (handled by dot-02c4); bin/llm-pull still supports ollama/omlx only (handled by dot-pgs1). Next work should start here.
