---
id: dot-pgs1
status: closed
deps: [dot-02c4]
links: []
created: 2026-05-18T13:40:31Z
type: feature
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Add llama.cpp GGUF support to llm-pull

Extend bin/llm-pull with a llamacpp backend for downloading or dry-running Hugging Face GGUF model targets into the llama.cpp model directory. Match aliases used by the llama.cpp server and Pi config. File hints: bin/llm-pull, bin/AGENTS.md.

## Acceptance Criteria

1. bin/llm-pull help documents -b llamacpp and its aliases.
2. llm-pull -b llamacpp --dry-run qwen3.6 resolves to unsloth/Qwen3.6-27B-GGUF with Q4_K_M target under XDG_DATA_HOME/llama.cpp/models.
3. dry-run aliases exist for deepseek14b, gemma4, gemma4:e2b, and rx optional Gemma 26B / Qwen 35B variants.
4. Existing ollama/omlx backend references are removed or explicitly marked obsolete; default backend is llama.cpp after migration.
5. bin/llm-pull --help succeeds and shellcheck passes if available.

## Notes

**2026-05-19T14:54:06Z**

Ollama/oMLX service/package wiring is already removed. When adding llamacpp backend, make llama.cpp the default or document old backends as obsolete; do not assume /opt/homebrew/omlx or ollama binary exists.

**2026-05-30T13:38:55Z**

Completed: llm-pull now defaults to the llamacpp backend, downloads Q4_K_M GGUF targets into XDG_DATA_HOME/llama.cpp/models, creates alias symlinks for Pi/llama-server IDs, supports dry-run aliases for qwen3.6/deepseek14b/gemma4/gemma4:e2b/gemma26b/qwen35b rx variants, and marks ollama/omlx backends obsolete. Verified help, qwen3.6 dry-run target, alias dry-runs, shellcheck, treefmt, lat_check, reviewer pass, and just validate home.
