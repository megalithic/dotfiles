---
id: dot-rn9o
status: open
deps: [dot-d7em]
links: []
created: 2026-05-18T13:40:31Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Tune llama.cpp defaults on rxbookpro

On rxbookpro, verify actual hardware and tune llama.cpp defaults beyond the initial conservative settings only after memory tests pass. File hints: home/rxbookpro.nix and llama.cpp logs under ~/Library/Logs/llama.cpp.

## Acceptance Criteria

1. system_profiler SPHardwareDataType SPDisplaysDataType output is captured or summarized for rxbookpro CPU/GPU/memory/macOS.
2. home/rxbookpro.nix defaults are adjusted based on observed hardware, starting from modelsMax = 2, ctxSize = 32768, parallel = 2.
3. alejandra --check home/rxbookpro.nix passes.
4. just validate home and just home --skip-sync pass on rxbookpro.
5. curl http://127.0.0.1:18080/v1/models succeeds on rxbookpro.
6. Long-context smoke test passes without unacceptable memory pressure before raising toward 65K context or parallel = 3.

