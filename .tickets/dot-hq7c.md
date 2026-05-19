---
id: dot-hq7c
status: closed
deps: [dot-psb2]
links: []
created: 2026-05-18T13:40:31Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Remove obsolete Ollama and oMLX wiring

Remove no-longer-used Ollama and oMLX package/service plumbing after host configs use llama.cpp. Keep the current Home Manager launchd activation override in home/common/services.nix because macOS 15 rejects launchctl bootout --wait. File hints: home/common/services.nix, home/common/packages.nix, modules/brew.nix, flake.nix, flake.lock, home/common/programs/ollama/default.nix, home/common/programs/omlx/default.nix.

## Acceptance Criteria

1. Ollama launchd agent and services.ollamaAgent option are removed or made unused after llama.cpp replacement.
2. oMLX launchd agent, Homebrew formula, and flake input are removed if no host still uses oMLX.
3. ollama is removed from shared home packages if no longer needed.
4. Current Home Manager launchd activation override remains in place and still avoids launchctl bootout --wait.
5. alejandra --check home/common/services.nix home/common/packages.nix modules/brew.nix flake.nix passes.
6. just validate home passes.


## Notes

**2026-05-19T12:42:15Z**

Removed obsolete Ollama/oMLX Home Manager modules, launchd agents, Homebrew formula/tap input, shared ollama package, host overrides, and stale docs. Kept Home Manager launchd activation override without bootout --wait.
