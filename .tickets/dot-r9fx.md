---
id: dot-r9fx
status: closed
deps: [dot-fvhz]
links: []
created: 2026-06-25T20:12:53Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Add Worktrunk hook log tailer for services windows

Add a Worktrunk hook log tailer for the tmux services window. The tailer should use `wt config state logs --format=json` and `jq` to find hook output logs for a branch, tail `post-start` and `post-switch` logs, and handle the no-log case with a clear retry loop. It must not start services directly.

File hints: new `bin/wt-tail-logs`, `bin/wt-tmux-target`, Worktrunk logs under `.git/wt/logs/`.

## Acceptance Criteria

1. `bin/wt-tail-logs <branch>` polls `wt config state logs --format=json` and filters `.hook_output[]` by JSON metadata.
2. The tailer selects `post-start` and `post-switch` logs for the requested branch without guessing filesystem paths.
3. No-log state prints a clear waiting message and retries.
4. Existing log files are tailed with `tail -F`.
5. `wt-tmux-target` uses `wt-tail-logs <branch>` for the services window command.
