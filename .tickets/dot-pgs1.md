---
id: dot-pgs1
status: open
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
4. Existing ollama and omlx backends keep working until removed or intentionally deprecated.
5. bin/llm-pull --help succeeds and shellcheck passes if available.

