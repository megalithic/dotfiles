---
name: tell
description: "Delegate tasks to other agents - pi sessions or external agents (claude, opencode, aider). Non-blocking with task tracking and completion notifications."
---

# Tell / Delegate

Delegate tasks to other agents. Works with both pi agent sessions and external agents (Claude Code, opencode, aider).

**Auto-notification:** When a delegated task completes, you'll be notified via:
1. **ntfy** - Push notification to your devices
2. **Session message** - `[TASK_RESULT:id]` sent to your pi session

## Tell a pi agent

Send a task to another pi agent running in a tmux session:

```bash
./scripts/tell.sh mega "fix the failing tests in src/auth"
./scripts/tell.sh rx "review PR #42 and leave comments"
```

**Explicit window targeting** with `session:window` syntax:

```bash
./scripts/tell.sh rx:agent "do something"    # Target rx session, agent window
./scripts/tell.sh mega:0 "do something"      # Target mega session, window 0
```

**Multi-instance support:** If a session has multiple pi instances (e.g., `mega:0` and `mega:agent`), the tell skill will:
1. If `session:window` specified → use that socket directly
2. Otherwise try socket first (cleaner, no shell pollution)
3. Prefer the `agent` window socket, then window `0`, then any available
4. Fall back to tmux `send-keys` if no socket available

Socket pattern: `/tmp/pi-{session}-{window}.sock`

## Delegate to external agents (yolo mode)

Spawn an external agent in a tmux session to handle a task:

```bash
./scripts/tell.sh --agent claude "run the user-story-sync skill"
./scripts/tell.sh --agent opencode "fix the failing tests in src/auth"
./scripts/tell.sh --agent aider "refactor the database module"
```

**Supported agents:**
- `claude` - Claude Code (runs with `--dangerously-skip-permissions`)
- `opencode` - OpenCode
- `aider` - Aider (runs with `--yes-always`)
- `codex` - Codex CLI (runs with `--full-auto`)

Returns immediately. The agent runs in a background tmux session.

## Task management

```bash
./scripts/tell.sh --list                    # List all tasks
./scripts/tell.sh --status TASK_ID          # Check task status & output
./scripts/tell.sh --watch TASK_ID           # Watch external task live
./scripts/tell.sh --kill TASK_ID            # Kill a running external task
```

## When you receive a task (pi agents)

You'll see: `[TASK:abc123 from mega] do the thing`

Send updates:
```bash
./scripts/tell.sh --update abc123 "halfway done"
./scripts/tell.sh --done abc123 "finished, all tests pass"
```

## Attach to external agent session

For interactive debugging, attach directly:

```bash
tmux -S /tmp/pi-agent-sockets/tasks.sock attach -t task-abc123-claude
```

Detach with `Ctrl+b d`.

## Completion notifications

When a task completes (either external agent or pi agent calling `--done`):

1. **ntfy notification** sent with task summary
2. **Message sent to delegator's session**: 
   ```
   [TASK_RESULT:abc123] claude completed: Task finished successfully
   Original task: run the user-story-sync skill...
   ```

This lets you fire-and-forget tasks and get notified when they're done.

## Examples

```bash
# Tell specific window in a session
./scripts/tell.sh rx:agent "review the changes and suggest improvements"

# Auto-select best window (prefers 'agent', then '0')
./scripts/tell.sh mega "run the test suite"

# Delegate to Claude Code
./scripts/tell.sh --agent claude "run the user-story-sync skill"

# Check what's happening
./scripts/tell.sh --list
./scripts/tell.sh --status abc123
```
