---
id: dot-0jhu
status: closed
deps: [dot-pgs1]
links: []
created: 2026-05-18T13:40:31Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Smoke-test llama.cpp launchd service on megabookpro

Apply the Home Manager llama.cpp changes on megabookpro and verify launchd activation, server health, OpenAI-compatible endpoints, and memory behavior with conservative 32GB settings. File hints: home/common/programs/llama-cpp-local.nix, home/megabookpro.nix, home/common/services.nix, ~/Library/Logs/llama.cpp.

## Acceptance Criteria

1. just home --skip-sync completes without launchd bootout/bootstrap errors.
2. launchctl print gui/501/org.nix-community.home.llama-cpp-local (or actual label) shows the llama.cpp service loaded/running.
3. curl http://127.0.0.1:18080/health succeeds.
4. curl http://127.0.0.1:18080/v1/models succeeds and shows expected model aliases once models are present.
5. A small OpenAI-compatible chat completion against a Gemma alias succeeds.
6. Memory pressure is observed during first model load and no Jetsam/OOM behavior occurs with conservative settings.

## Notes

**2026-05-19T14:54:06Z**

Use launchd label org.nix-community.home.llama-cpp (agent attr: launchd.agents.llama-cpp) unless Nix eval shows a different generated label. Service source is home/common/services.nix; module/options source is home/common/programs/llama-cpp-local/default.nix.

**2026-06-01T16:38:31Z**

Started. First step: refactor llama.cpp launchd service/log-dir ownership from home/common/services.nix into home/common/programs/llama-cpp-local/default.nix; keep llama-cpp-local name and programs.llamaCppLocal option.

**2026-06-01T16:40:49Z**

Refactor + smoke test complete on megabookpro. Moved launchd.agents.llama-cpp and llama.cpp log-dir activation into home/common/programs/llama-cpp-local/default.nix; home/common/services.nix now keeps shared launchd plumbing plus espanso. Validation: alejandra formatted files; just validate home passed; lat_check passed; just home --skip-sync completed and activated makeLlamaCppDirs/setupLaunchAgents. Service: launchctl print gui/501/org.nix-community.home.llama-cpp shows state=running, pid=84788, args include --models-dir ~/.local/share/llama.cpp/models, --models-max 1, -c 8192, --parallel 1, q8_0 KV, flash-attn on. API: /health returned {status:ok}; /v1/models returned 6 model IDs including qwen3.6, deepseek14b, gemma4; chat completion with gemma4 returned Ok. Memory: memory_pressure free percentage 55% after gemma4 load; no llama.cpp Jetsam/OOM seen in checked logs.
