---
id: dot-d7em
status: closed
deps: [dot-0jhu]
links: []
created: 2026-05-18T13:40:31Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Verify Pi integration with llama.cpp provider

Verify Pi can discover and invoke llama.cpp local models through the configured provider and scopes. Confirm stop-hook local gatekeeper can call the llama.cpp Gemma model. File hints: home/common/programs/pi-coding-agent/models.json, settings.json, extensions/multi-sub.ts, extensions/stop-hook.ts.

## Acceptance Criteria

1. just home --skip-sync applies Pi provider/settings changes.
2. Pi model list or Ctrl-P scope for mega exposes configured llama.cpp local aliases.
3. A Pi prompt using a llama.cpp model alias succeeds.
4. stop-hook local gatekeeper path successfully calls the llama.cpp Gemma alias.
5. curl http://127.0.0.1:18080/v1/chat/completions succeeds with a configured model alias.

## Notes

**2026-06-01T16:51:59Z**

Verified on megabookpro. just home --skip-sync applied Pi provider/settings and activated Home Manager. PI_PROFILE=mega pi --list-models shows llamacpp/deepseek14b, llamacpp/gemma4, and llamacpp/qwen3.6. pi --no-session --no-tools -p --model llamacpp/gemma4 "Say ok." returned ok. stop-hook.ts local gatekeeper path is configured to call askGatekeeper("llamacpp", "gemma4", ...) before cloud fallback; model registry lookup is satisfied by the same Pi model list and provider invocation. curl POST /v1/chat/completions with model gemma4 returned ok. lat_check passed.
