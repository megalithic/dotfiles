---
id: dot-5peo
status: in_progress
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

