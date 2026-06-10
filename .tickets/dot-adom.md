---
id: dot-adom
status: open
deps: [dot-5peo]
links: []
created: 2026-05-06T16:41:18Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Test pi-coding-agent integration and monitor stability

Restart pi-coding-agent to pick up new models.json.
Test agent queries using omlx models.
Monitor for crashes, memory issues, 507 errors over 10-15 minutes of normal use.
Confirm stable operation.

Steps:

1. Reload pi: exit/restart tmux session or reload agent models
2. Test query: ask pi question, specify omlx/qwen3.6 model
3. Test secondary: ask question with omlx/gemma4 (or deepseek if configured)
4. Monitor logs: 'tail -f ~/Library/Logs/omlx/stderr.log' while using agent
5. Let run 10-15 min under normal use
6. Check uptime: 'ps aux | grep omlx' should show no recent restarts

See context file for model aliases and API format.

## Acceptance Criteria

1. Pi agent responds to queries using omlx/qwen3.6
2. Alternative model works: omlx/gemma4 or omlx/deepseek14b responds if available
3. No 507 errors during test: grep -c '507' ~/Library/Logs/omlx/stderr.log is 0 or very low
4. No METAL OOM: grep -i 'metal.\*insufficient\|command buffer execution failed' ~/Library/Logs/omlx/stderr.log is empty
5. Service stable: omlx process uptime > 15 min (ps shows same PID during test)

## Notes

**2026-05-07T13:27:57Z**

REVISED 2026-05-07. Scope changed from omlx to ollama testing on megabookpro.

New acceptance criteria:

1. ollama serve running via launchd (launchctl list | rg ollama shows positive PID)
2. curl http://127.0.0.1:11434/api/tags returns models list
3. qwen3.6:27b responds: curl POST /api/generate with small prompt
4. deepseek-r1:14b responds similarly
5. gemma4:e4b responds similarly
6. No OOM crashes after 15min of alternating model requests
7. pi-coding-agent can use ollama/qwen3.6:27b model (test query)
8. Logs clean: no memory errors in ~/Library/Logs/ollama/stderr.log

Blocked on: just home activation (needs graphical terminal for app management permission).
