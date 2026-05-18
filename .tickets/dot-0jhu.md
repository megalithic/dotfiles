---
id: dot-0jhu
status: open
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

