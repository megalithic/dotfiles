---
name: tell
description: "Tell another pi agent to do something. Non-blocking with periodic updates."
---

# Tell

Tell another pi agent to do something. You continue working, they send updates.

## Tell an agent

```bash
./scripts/tell.sh SESSION "task description"
```

**Examples:**

```bash
./scripts/tell.sh mega "fix the failing tests in src/auth"
./scripts/tell.sh rx "review PR #42 and leave comments"
./scripts/tell.sh canonize "refactor the database module"
```

Returns immediately. Check progress later.

## Check status

```bash
./scripts/tell.sh --status TASK_ID
./scripts/tell.sh --list
```

## When you receive a task

You'll see: `[TASK:abc123 from mega] do the thing`

Send updates:
```bash
./scripts/tell.sh --update abc123 "halfway done"
./scripts/tell.sh --done abc123 "finished, all tests pass"
```
