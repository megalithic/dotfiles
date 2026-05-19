---
id: dot-psb2
status: closed
deps: [dot-rfst]
links: []
created: 2026-05-18T13:40:31Z
type: feature
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Switch host local inference settings to llama.cpp

Enable programs.llamaCppLocal on megabookpro and rxbookpro with conservative per-host defaults. Disable old local backends where llama.cpp replaces them. Preserve and update comments explaining the 32GB megabookpro memory constraints and rxbookpro 64GB tuning assumptions. File hints: home/megabookpro.nix, home/rxbookpro.nix.

## Acceptance Criteria

1. home/megabookpro.nix enables programs.llamaCppLocal with modelsMax = 1, ctxSize = 8192, parallel = 1, q8 KV cache, flash attention, and disables services.ollamaAgent/programs.omlx as appropriate.
2. home/rxbookpro.nix enables programs.llamaCppLocal with initial modelsMax = 2, ctxSize = 32768, parallel = 2, q8 KV cache, flash attention, and disables old local inference backends as appropriate.
3. Existing memory constraint comments are updated to explain the llama.cpp migration and conservative defaults.
4. alejandra --check home/megabookpro.nix home/rxbookpro.nix passes.
5. just validate home passes.


## Notes

**2026-05-19T12:20:08Z**

Switched host local inference defaults to llama.cpp. megabookpro uses one 8K q8_0/flash-attn slot and rxbookpro uses two 32K q8_0/flash-attn slots; Ollama and oMLX agents disabled on both hosts. Verified alejandra, just validate home, rxbookpro activation build, and Nix option evals.
