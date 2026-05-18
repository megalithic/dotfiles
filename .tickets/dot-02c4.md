---
id: dot-02c4
status: open
deps: [dot-06iy]
links: []
created: 2026-05-18T13:40:31Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Update Pi stop-hook gatekeeper to llama.cpp

Change the Pi stop-hook local gatekeeper fallback from Ollama gemma4:e4b/gemma4:e2b to llama.cpp Gemma aliases. Preserve behavior: cheap local gatekeeper first, then fallback path. File hints: home/common/programs/pi-coding-agent/extensions/stop-hook.ts and pi-coding-agent AGENTS.md for extension conventions.

## Acceptance Criteria

1. stop-hook.ts no longer references ollama/gemma4:e4b or ollama/gemma4:e2b for local gatekeeper calls.
2. stop-hook.ts uses configured llama.cpp Gemma aliases matching models.json/settings.json.
3. Existing cloud fallback behavior remains unchanged.
4. Existing Pi extension typecheck/lint/build command, if defined, passes.
5. just validate home passes.

