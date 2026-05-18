---
id: dot-rfst
status: open
deps: []
links: []
created: 2026-05-18T13:40:30Z
type: feature
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Add llama.cpp local inference Home Manager module

Add a new Home Manager module for llama.cpp local inference. It should install/use pkgs.llama-cpp, create model/log directories, and define a user launchd agent for llama-server bound to 127.0.0.1:18080. Use router mode with --models-dir, --models-max, q8 KV cache, flash attention, and host-tunable options. File hints: home/common/programs/llama-cpp-local.nix, home/common/default.nix, home/common/services.nix for launchd patterns and current activation override. Read home/AGENTS.md before editing.

## Acceptance Criteria

1. home/common/programs/llama-cpp-local.nix defines programs.llamaCppLocal options for enable, package, host, port, modelDir, modelsMax, ctxSize, parallel, cache types, flash attention, and extraArgs.
2. Module config creates required model/log directories and a launchd agent using llama-server on 127.0.0.1:18080 when enabled.
3. home/common/default.nix imports the new module.
4. alejandra --check home/common/programs/llama-cpp-local.nix passes.
5. just validate home passes.

