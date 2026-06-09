---
id: dot-5peo
status: closed
deps: [dot-4515]
links: []
created: 2026-05-06T16:41:11Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Verify omlx health and test API calls

Restart oMLX service to load new config and models.
Test API: call /v1/chat/completions for each model to verify no HTTP 507 (memory error) or METAL OOM crashes.
Check logs for errors.

Steps:

1. Restart: 'launchctl stop com.jundot.omlx && sleep 2 && launchctl start com.jundot.omlx && sleep 3'
2. Health: 'curl -s http://127.0.0.1:8000/health'
3. Test Qwen: curl POST to /v1/chat/completions with model='qwen3.6', small prompt
4. Test DeepSeek: same with model='deepseek14b' (or full name)
5. Test Gemma: same with model='gemma4'
6. Check logs: 'tail -50 ~/Library/Logs/omlx/stderr.log' for errors

See ~/.omlx/settings.json and context file for API details.

## Acceptance Criteria

1. Service restarted: 'launchctl list | grep omlx' shows positive PID
2. Health check passes: curl to /health returns 200 OK
3. Qwen request succeeds: returns response, no error field
4. DeepSeek request succeeds: returns response, no error field
5. Gemma request succeeds: returns response, no error field
6. Logs clean: 'tail ~/Library/Logs/omlx/stderr.log' shows no 507 or METAL OOM errors

## Notes

**2026-05-07T13:27:11Z**

FAILED 2026-05-07. oMLX crashed entire system during testing.

Qwen3.6-27B-4bit loaded successfully (pinned, ~18.7GB). Health check passed.
First Qwen API call succeeded. When DeepSeek-R1-14B-4bit was requested,
oMLX tried to load it alongside pinned Qwen (18.7 + 9.7 = 28.4GB > 24GB budget).
ProcessMemoryEnforcer didn't prevent it (tracks Metal only, not true RSS).
macOS Jetsam killed the process (vm-compressor-space-shortage), froze system.

Root cause: oMLX Issue #702 — ProcessMemoryEnforcer ignores Python heap,
SSD hot cache buffers, file-backed mappings. Only tracks mx.get_active_memory().
Additional bug: Issue #1060 — VLM memory leak on unload in 0.3.8.

Decision: disable oMLX on megabookpro (32GB), re-enable Ollama as default.
oMLX remains viable for workbookpro (64GB).
