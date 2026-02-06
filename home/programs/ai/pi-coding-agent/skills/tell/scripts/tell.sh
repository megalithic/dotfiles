#!/usr/bin/env bash
# tell.sh - Tell another pi agent to do something
#
# Usage:
#   tell.sh SESSION "task description"
#   tell.sh --status TASK_ID
#   tell.sh --update TASK_ID "update message"
#   tell.sh --done TASK_ID "completion message"
#   tell.sh --list
#
set -euo pipefail

TASKS_DIR="${HOME}/.pi/tasks"
mkdir -p "$TASKS_DIR"

# Get current session context
get_context() {
  if [[ -n "${TMUX:-}" ]]; then
    tmux display-message -p '#S:#I:#P'
  else
    echo "unknown"
  fi
}

# Generate short task ID
gen_id() {
  head -c 4 /dev/urandom | xxd -p
}

# Send task to another session
cmd_tell() {
  local target="$1"
  shift
  local message="$*"
  
  if [[ -z "$target" ]] || [[ -z "$message" ]]; then
    echo "Usage: tell.sh SESSION \"task description\"" >&2
    exit 1
  fi
  
  # Check target session exists
  if ! tmux has-session -t "$target" 2>/dev/null; then
    echo "Error: session '$target' not found" >&2
    echo "Available sessions:" >&2
    tmux list-sessions -F '  #{session_name}' 2>/dev/null || echo "  (none)"
    exit 1
  fi
  
  local task_id
  task_id=$(gen_id)
  local from_ctx
  from_ctx=$(get_context)
  local created
  created=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  # Create task file
  cat > "${TASKS_DIR}/${task_id}.json" << EOF
{
  "id": "${task_id}",
  "from": "${from_ctx}",
  "to": "${target}",
  "status": "pending",
  "task": $(jq -n --arg t "$message" '$t'),
  "created": "${created}",
  "updates": []
}
EOF

  # Build the prompt for the receiving agent
  local prompt="[TASK:${task_id} from ${from_ctx%%:*}] ${message}

IMPORTANT: This is a delegated task. You must:
1. Work on this task
2. Send updates periodically: \`~/.pi/agent/skills/delegate/scripts/tell.sh --update ${task_id} \"your progress\"\`
3. When done: \`~/.pi/agent/skills/delegate/scripts/tell.sh --done ${task_id} \"summary\"\`"

  # Send to target session (find the active pane, send the prompt)
  tmux send-keys -t "${target}" "$prompt" Enter
  
  echo "Task ${task_id} sent to ${target}"
  echo "Check status: tell.sh --status ${task_id}"
}

# Update task status
cmd_update() {
  local task_id="$1"
  shift
  local message="$*"
  local task_file="${TASKS_DIR}/${task_id}.json"
  
  if [[ ! -f "$task_file" ]]; then
    echo "Error: task ${task_id} not found" >&2
    exit 1
  fi
  
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local from_ctx
  from_ctx=$(get_context)
  
  # Add update to task file
  local tmp
  tmp=$(mktemp)
  jq --arg msg "$message" --arg time "$now" --arg from "$from_ctx" \
    '.status = "in_progress" | .updates += [{"time": $time, "from": $from, "message": $msg}]' \
    "$task_file" > "$tmp" && mv "$tmp" "$task_file"
  
  echo "Updated task ${task_id}"
}

# Mark task done
cmd_done() {
  local task_id="$1"
  shift
  local message="$*"
  local task_file="${TASKS_DIR}/${task_id}.json"
  
  if [[ ! -f "$task_file" ]]; then
    echo "Error: task ${task_id} not found" >&2
    exit 1
  fi
  
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local from_ctx
  from_ctx=$(get_context)
  
  # Mark complete
  local tmp
  tmp=$(mktemp)
  jq --arg msg "$message" --arg time "$now" --arg from "$from_ctx" \
    '.status = "done" | .completed = $time | .updates += [{"time": $time, "from": $from, "message": ("DONE: " + $msg)}]' \
    "$task_file" > "$tmp" && mv "$tmp" "$task_file"
  
  echo "Task ${task_id} marked done"
  
  # Notify the originator
  local orig_session
  orig_session=$(jq -r '.from' "$task_file" | cut -d: -f1)
  if [[ -n "$orig_session" ]] && tmux has-session -t "$orig_session" 2>/dev/null; then
    ntfy send -t "Task ${task_id} complete" -m "$message" 2>/dev/null || true
  fi
}

# Show task status
cmd_status() {
  local task_id="$1"
  local task_file="${TASKS_DIR}/${task_id}.json"
  
  if [[ ! -f "$task_file" ]]; then
    echo "Error: task ${task_id} not found" >&2
    exit 1
  fi
  
  echo "=== Task ${task_id} ==="
  jq -r '"Status: \(.status)\nFrom: \(.from)\nTo: \(.to)\nCreated: \(.created)\n\nTask: \(.task)\n\nUpdates:"' "$task_file"
  jq -r '.updates[] | "  [\(.time)] \(.message)"' "$task_file" 2>/dev/null || echo "  (none)"
}

# List all tasks
cmd_list() {
  echo "=== Active Tasks ==="
  for f in "${TASKS_DIR}"/*.json; do
    [[ -f "$f" ]] || continue
    jq -r '"[\(.id)] \(.status) | \(.from) → \(.to) | \(.task | .[0:50])..."' "$f" 2>/dev/null
  done
}

# Main
case "${1:-}" in
  --status|-s)
    shift
    cmd_status "$@"
    ;;
  --update|-u)
    shift
    cmd_update "$@"
    ;;
  --done|-d)
    shift
    cmd_done "$@"
    ;;
  --list|-l)
    cmd_list
    ;;
  --help|-h)
    echo "Usage:"
    echo "  tell.sh SESSION \"task\"     - Send task to another agent"
    echo "  tell.sh --status ID        - Check task status"
    echo "  tell.sh --update ID \"msg\"  - Update task progress"
    echo "  tell.sh --done ID \"msg\"    - Mark task complete"
    echo "  tell.sh --list             - List all tasks"
    ;;
  *)
    cmd_tell "$@"
    ;;
esac
