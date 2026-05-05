---
id: dot-g8dx
status: open
deps: [dot-j9q6]
links: []
created: 2026-05-05T12:23:15Z
type: feature
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Migrate stop-hook gatekeeper from ollama-native to omlx OpenAI-compat API

Rewrite the stop-hook gatekeeper to use the OpenAI-compatible /v1/chat/completions endpoint against omlx/gemma4 instead of the Ollama-native /api/chat endpoint. Add server-side forced_ct_kwargs to prevent thinking re-enable on the gatekeeper model.

This is Phase 3 of the oMLX migration plan. Must happen before Phase 4 (default flip) so the gatekeeper isn't broken when ollama is disabled.

**Files:**
- home/common/programs/pi-coding-agent/extensions/stop-hook.ts — rename LOCAL_GATEKEEPER_PROVIDER to omlx, LOCAL_GATEKEEPER_MODEL_ID to gemma4, rewrite askOllamaGatekeeper to askOmlxGatekeeper using OpenAI-compat POST to http://127.0.0.1:8000/v1/chat/completions with model/messages/max_tokens/temperature=0, drop think:false and options.num_predict, parse data.choices[0].message.content
- home/common/programs/omlx/default.nix — add chat_template_kwargs.enable_thinking=false and forced_ct_kwargs=["enable_thinking"] to gemma4 model_settings so server blocks thinking override

**Key change:** The Ollama-native API uses `think: false` and `options.num_predict` which have no OpenAI-compat equivalent. oMLX handles thinking via per-model chat_template_kwargs (enable_thinking) instead.

## Acceptance Criteria

1. stop-hook.ts has LOCAL_GATEKEEPER_PROVIDER = "omlx" and LOCAL_GATEKEEPER_MODEL_ID = "gemma4"
2. stop-hook.ts no longer references :11434/api/chat, think:false, or options.num_predict
3. stop-hook.ts posts to http://127.0.0.1:8000/v1/chat/completions with OpenAI-compat body
4. gemma4 model_settings has chat_template_kwargs.enable_thinking=false and forced_ct_kwargs=["enable_thinking"]
5. When omlx is running: stop-hook gatekeeper fires using local omlx/gemma4
6. When omlx is killed: cloud fallback (anthropic/claude-haiku-4-5) fires correctly
7. TS compiles without errors (tsc --noEmit or just lint)
8. just validate passes

