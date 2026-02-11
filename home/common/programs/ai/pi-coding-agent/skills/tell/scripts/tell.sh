#!/usr/bin/env bash
# tell.sh - Tell another agent to do something
#
# Usage:
#   tell.sh SESSION "task description"           # Tell a pi agent
#   tell.sh --agent claude "task description"    # Delegate to external agent (background)
#   tell.sh --agent claude -v "task"              # Run in visible tmux window
#   tell.sh --agent opencode "task description"
#   tell.sh --agent aider "task description"
#   tell.sh --status TASK_ID
#   tell.sh --update TASK_ID "update message"
#   tell.sh --done TASK_ID "completion message"
#   tell.sh --list
#   tell.sh --watch TASK_ID                      # Watch task output live
#   tell.sh --kill TASK_ID                       # Kill a running task
#
set -euo pipefail

TASKS_DIR="${HOME}/.pi/tasks"
SOCKET_DIR="${TMPDIR:-/tmp}/pi-agent-sockets"
mkdir -p "$TASKS_DIR" "$SOCKET_DIR"

SOCKET="$SOCKET_DIR/tasks.sock"

# Supported external agents and their commands
declare -A AGENT_COMMANDS=(
  [claude]="claude --dangerously-skip-permissions"
  [opencode]="opencode"
  [aider]="aider --yes-always"
  [codex]="codex --full-auto"
)

# ===========================================================================
# Pi Socket Functions (for window-aware multi-instance support)
# ===========================================================================
# Socket pattern: /tmp/pi-{session}-{window}.sock
# One socket per tmux window, allows multiple pi instances per session

# Get all pi sockets for a session
# Returns newline-separated list of socket paths
get_pi_sockets() {
  local session="$1"
  ls /tmp/pi-${session}-*.sock 2>/dev/null || true
}

# Get the "best" pi socket for a session
# Priority: 1. agent window, 2. window 0, 3. first available
get_best_pi_socket() {
  local session="$1"
  local sockets
  sockets=$(get_pi_sockets "$session")
  
  [[ -z "$sockets" ]] && return 1
  
  # Prefer agent window
  local agent_socket="/tmp/pi-${session}-agent.sock"
  if [[ -S "$agent_socket" ]]; then
    echo "$agent_socket"
    return 0
  fi
  
  # Then window 0
  local win0_socket="/tmp/pi-${session}-0.sock"
  if [[ -S "$win0_socket" ]]; then
    echo "$win0_socket"
    return 0
  fi
  
  # Otherwise first available
  echo "$sockets" | head -1
}

# Send message to pi via socket
# Returns 0 on success, 1 on failure
#
# Uses jq -cn for compact single-line JSON output.
# The --arg flag handles all JSON escaping (newlines → \n, quotes escaped, etc.)
# Pipes directly to nc -N (close on EOF) for reliable delivery.
send_to_pi_socket() {
  local socket_path="$1"
  local message="$2"
  local msg_type="${3:-tell}"
  
  [[ ! -S "$socket_path" ]] && return 1
  
  # Get session name for 'from' field (fallback to tmux query or 'unknown')
  local from_session="${PI_SESSION:-}"
  if [[ -z "$from_session" ]]; then
    from_session=$(tmux display-message -p '#S' 2>/dev/null || echo "unknown")
  fi
  
  # Build and send compact JSON in one pipeline
  jq -cn \
    --arg type "$msg_type" \
    --arg text "$message" \
    --arg from "$from_session" \
    --argjson ts "$(date +%s)" \
    '{type: $type, text: $text, from: $from, timestamp: $ts}' \
  | nc -N -U "$socket_path" 2>/dev/null
  
  # Return nc's exit status (PIPESTATUS[1] is nc in the pipeline)
  return "${PIPESTATUS[1]:-$?}"
}

# Select pi socket interactively if multiple exist
# Uses fzf if available, otherwise prints list
select_pi_socket() {
  local session="$1"
  local sockets
  sockets=$(get_pi_sockets "$session")
  
  local count
  count=$(echo "$sockets" | wc -l | tr -d ' ')
  
  if [[ "$count" -eq 0 ]]; then
    return 1
  elif [[ "$count" -eq 1 ]]; then
    echo "$sockets"
    return 0
  fi
  
  # Multiple sockets - need to select
  if command -v fzf &>/dev/null; then
    echo "$sockets" | fzf --prompt="Select pi instance: " --height=10
  else
    echo "Multiple pi instances in session ${session}:" >&2
    echo "$sockets" | nl >&2
    echo "Using first available (or specify with --window)" >&2
    echo "$sockets" | head -1
  fi
}


# Get the pane running pi in a tmux session
# Returns pane_id or empty string if not found

# Resolve a window identifier (name or index) to a socket path
# Tries in order:
#   1. Direct match: /tmp/pi-{session}-{window}.sock
#   2. If window is numeric, look up window name and try that
#   3. If window is a name, look up window index and try that
# Returns socket path or empty string
resolve_pi_socket() {
  local session="$1"
  local window="$2"
  
  # 1. Try direct match first
  local direct_socket="/tmp/pi-${session}-${window}.sock"
  if [[ -S "$direct_socket" ]]; then
    echo "$direct_socket"
    return 0
  fi
  
  # 2. If window looks like a number, look up the window name
  if [[ "$window" =~ ^[0-9]+$ ]]; then
    local win_name
    win_name=$(tmux list-windows -t "$session" -F '#{window_index}:#{window_name}' 2>/dev/null | \
      rg "^${window}:" | cut -d: -f2 | tr -d ' ')
    if [[ -n "$win_name" ]]; then
      local name_socket="/tmp/pi-${session}-${win_name}.sock"
      if [[ -S "$name_socket" ]]; then
        echo "$name_socket"
        return 0
      fi
    fi
  else
    # 3. Window is a name, look up the index
    local win_index
    win_index=$(tmux list-windows -t "$session" -F '#{window_index}:#{window_name}' 2>/dev/null | \
      rg ":${window}$" | cut -d: -f1)
    if [[ -n "$win_index" ]]; then
      local index_socket="/tmp/pi-${session}-${win_index}.sock"
      if [[ -S "$index_socket" ]]; then
        echo "$index_socket"
        return 0
      fi
    fi
  fi
  
  # Not found
  return 1
}

get_pi_pane() {
  local session="$1"
  local pane_id
  
  # Look for pane running 'pi' command (pi runs as node)
  pane_id=$(tmux list-panes -t "$session" -F '#{pane_id} #{pane_current_command}' 2>/dev/null \
    | awk '/ (pi|node)$/ {print $1; exit}')
  
  # If not found by command, try window name 'pi'
  if [[ -z "$pane_id" ]]; then
    pane_id=$(tmux list-panes -t "${session}:pi" -F '#{pane_id}' 2>/dev/null | head -1)
  fi
  
  # If still not found, try window named 'agent'
  if [[ -z "$pane_id" ]]; then
    pane_id=$(tmux list-panes -t "${session}:agent" -F '#{pane_id}' 2>/dev/null | head -1)
  fi
  
  echo "$pane_id"
}


# Send bell to a tmux window (triggers bell flag in status line)
# Usage: notify_tmux_bell "session:window" or "session:window:pane"
notify_tmux_bell() {
  local target="$1"
  [[ -z "$target" ]] && return 1
  
  # Extract session:window from target (ignore pane if present)
  local session_window="${target%:*}"  # strip last :component if 3 parts
  if [[ "$target" == *:*:* ]]; then
    # Format is session:window:pane - extract session:window
    session_window="${target%:*}"
  else
    # Format is session:window or just session
    session_window="$target"
  fi
  
  # Get the pane's tty and write BEL character
  local tty
  tty=$(tmux display -p -t "$session_window" '#{pane_tty}' 2>/dev/null) || return 1
  printf '\a' > "$tty" 2>/dev/null
}

# Notify the delegator that a task is complete
notify_delegator() {
  local task_id="$1"
  local task_file="${TASKS_DIR}/${task_id}.json"
  local message="${2:-Task completed}"
  
  [[ -f "$task_file" ]] || return 0
  
  local from_ctx to_agent task_desc
  from_ctx=$(jq -r '.from' "$task_file")
  to_agent=$(jq -r '.to' "$task_file")
  task_desc=$(jq -r '.task | .[0:80]' "$task_file")
  local from_session="${from_ctx%%:*}"
  
  # Send notification via ntfy
  if command -v ntfy &>/dev/null; then
    ntfy send -t "Task ${task_id} complete" -m "${to_agent}: ${message}" 2>/dev/null || true
  elif [[ -x ~/bin/ntfy ]]; then
    ~/bin/ntfy send -t "Task ${task_id} complete" -m "${to_agent}: ${message}" 2>/dev/null || true
  fi
  
  # Ring tmux bell on originator's window (shows bell icon in status line)
  if [[ -n "$from_ctx" ]] && [[ "$from_ctx" != "unknown" ]]; then
    notify_tmux_bell "$from_ctx"
  fi
  
  # Send result to originating pi instance
  # Try socket first (cleaner), fall back to tmux send-keys
  if [[ -n "$from_ctx" ]] && [[ "$from_ctx" != "unknown" ]]; then
    local completion_msg="[TASK_RESULT:${task_id}] ${to_agent} completed: ${message}

Original task: ${task_desc}..."
    
    # Extract session:window from from_ctx (format: session:window:pane)
    local from_session_window
    if [[ "$from_ctx" == *:*:* ]]; then
      # Strip pane, keep session:window
      from_session_window="${from_ctx%:*}"
    else
      from_session_window="$from_ctx"
    fi
    local from_session="${from_ctx%%:*}"
    
    # Try to find and use pi socket for this window
    local from_socket
    from_socket=$(resolve_pi_socket "${from_session}" "${from_session_window#*:}" 2>/dev/null) || from_socket=""
    
    if [[ -n "$from_socket" ]] && [[ -S "$from_socket" ]]; then
      # Send via socket (delivers as message to pi, not raw shell)
      send_to_pi_socket "$from_socket" "$completion_msg" "tell"
    elif tmux has-session -t "$from_session" 2>/dev/null; then
      # Fallback: send-keys to specific window (not just session)
      tmux send-keys -t "$from_session_window" "$completion_msg" Enter 2>/dev/null || \
        tmux send-keys -t "$from_session" "$completion_msg" Enter 2>/dev/null || true
    fi
  fi
}

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

# Delegate to external agent (claude, opencode, aider, etc.)
cmd_agent() {
  local agent="$1"
  shift
  local message="$*"
  
  if [[ -z "$agent" ]] || [[ -z "$message" ]]; then
    echo "Usage: tell.sh --agent AGENT \"task description\"" >&2
    echo "Supported agents: ${!AGENT_COMMANDS[*]}" >&2
    exit 1
  fi
  
  # Check if agent is supported
  if [[ -z "${AGENT_COMMANDS[$agent]:-}" ]]; then
    echo "Error: unknown agent '$agent'" >&2
    echo "Supported agents: ${!AGENT_COMMANDS[*]}" >&2
    exit 1
  fi
  
  # Check if agent binary exists
  local agent_bin="${AGENT_COMMANDS[$agent]%% *}"
  if ! command -v "$agent_bin" &>/dev/null; then
    echo "Error: '$agent_bin' not found in PATH" >&2
    exit 1
  fi
  
  local task_id
  task_id=$(gen_id)
  local from_ctx
  from_ctx=$(get_context)
  local created
  created=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local session_name="task-${task_id}-${agent}"
  
  # Create task file
  cat > "${TASKS_DIR}/${task_id}.json" << EOF
{
  "id": "${task_id}",
  "from": "${from_ctx}",
  "to": "${agent}",
  "type": "external",
  "session": "${session_name}",
  "socket": "${SOCKET}",
  "status": "running",
  "task": $(jq -n --arg t "$message" '$t'),
  "created": "${created}",
  "updates": []
}
EOF

  # Build the command
  local agent_cmd="${AGENT_COMMANDS[$agent]}"
  local full_cmd="$agent_cmd -p $(printf '%q' "$message"); echo '[TASK_COMPLETE]'; sleep 2"
  
  # Create tmux session and run agent
  tmux -S "$SOCKET" new-session -d -s "$session_name" -c "$(pwd)"
  tmux -S "$SOCKET" send-keys -t "$session_name" "$full_cmd" Enter
  
  # Spawn background watcher to detect completion and notify delegator
  (
    while tmux -S "$SOCKET" has-session -t "$session_name" 2>/dev/null; do
      local output
      output=$(tmux -S "$SOCKET" capture-pane -p -t "$session_name" -S -500 2>/dev/null || true)
      
      if echo "$output" | grep -q '\[TASK_COMPLETE\]'; then
        # Save output
        echo "$output" > "${TASKS_DIR}/${task_id}.output"
        
        # Update task status
        local tmp now
        tmp=$(mktemp)
        now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        jq --arg time "$now" '.status = "done" | .completed = $time' "${TASKS_DIR}/${task_id}.json" > "$tmp" && mv "$tmp" "${TASKS_DIR}/${task_id}.json"
        
        # Notify the delegator
        notify_delegator "$task_id" "Task finished successfully"
        
        # Kill the session after a short delay
        sleep 2
        tmux -S "$SOCKET" kill-session -t "$session_name" 2>/dev/null || true
        break
      fi
      
      sleep 3
    done
  ) &>/dev/null &
  
  echo "Task ${task_id} delegated to ${agent}"
  echo ""
  echo "You'll be notified when complete."
  echo ""
  echo "Monitor: tell.sh --watch ${task_id}"
  echo "Status:  tell.sh --status ${task_id}"
  echo "Kill:    tell.sh --kill ${task_id}"
  echo ""
  echo "Or attach directly:"
  echo "  tmux -S $SOCKET attach -t $session_name"
}

# Send task to another pi session
# Send task to another pi session
# Tries socket first (cleaner), falls back to tmux send-keys
cmd_tell() {
  local target="$1"
  shift
  local message="$*"
  
  if [[ -z "$target" ]] || [[ -z "$message" ]]; then
    echo "Usage: tell.sh SESSION[:WINDOW] \"task description\"" >&2
    echo "Examples:" >&2
    echo "  tell.sh mega \"do something\"        # Auto-select best window" >&2
    echo "  tell.sh rx:agent \"do something\"    # Target specific window" >&2
    echo "  tell.sh rx:0 \"do something\"        # Target window 0" >&2
    exit 1
  fi
  
  # Parse session:window format
  local session window
  if [[ "$target" == *:* ]]; then
    session="${target%%:*}"
    window="${target#*:}"
  else
    session="$target"
    window=""
  fi
  
  # Check target session exists
  if ! tmux has-session -t "$session" 2>/dev/null; then
    echo "Error: session '$session' not found" >&2
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
  "type": "pi",
  "status": "pending",
  "task": $(jq -n --arg t "$message" '$t'),
  "created": "${created}",
  "updates": []
}
EOF

  # Build the prompt for the receiving pi agent
  local prompt="[TASK:${task_id} from ${from_ctx%%:*}] ${message}

IMPORTANT: This is a delegated task. You must:
1. Work on this task
2. Send updates periodically: \`tell.sh --update ${task_id} \"your progress\"\`
3. When done: \`tell.sh --done ${task_id} \"summary\"\`"

  # Try socket first (cleaner, doesn't pollute shell)
  local socket_path
  if [[ -n "$window" ]]; then
    # Explicit window specified - resolve it (tries name/index lookup)
    socket_path=$(resolve_pi_socket "$session" "$window")
    if [[ -z "$socket_path" ]]; then
      echo "Warning: No socket found for ${session}:${window}" >&2
      echo "Available sockets:" >&2
      get_pi_sockets "$session" | sed 's/^/  /' >&2
    fi
  else
    # Auto-select best socket for session
    socket_path=$(get_best_pi_socket "$session")
  fi
  
  if [[ -n "$socket_path" ]] && [[ -S "$socket_path" ]]; then
    if send_to_pi_socket "$socket_path" "$prompt" "tell"; then
      local win_display
      win_display=$(basename "$socket_path" .sock | sed "s/^pi-${session}-//")
      echo "Task ${task_id} sent to ${session}:${win_display} via socket"
      echo "Check status: tell.sh --status ${task_id}"
      return 0
    fi
    echo "Warning: Socket send failed, falling back to tmux" >&2
  fi
  
  # Fallback to tmux send-keys
  local pi_pane
  pi_pane=$(get_pi_pane "$session")
  
  if [[ -n "$pi_pane" ]]; then
    tmux send-keys -t "$pi_pane" "$prompt" Enter
    echo "Task ${task_id} sent to ${session} (pane ${pi_pane})"
  else
    # Fallback to session (may go to wrong pane)
    echo "Warning: Could not locate pi pane in ${session}, sending to active pane" >&2
    tmux send-keys -t "${session}" "$prompt" Enter
    echo "Task ${task_id} sent to ${session} (active pane)"
  fi
  echo "Check status: tell.sh --status ${task_id}"
}


# Watch task output live
cmd_watch() {
  local task_id="$1"
  local task_file="${TASKS_DIR}/${task_id}.json"
  
  if [[ ! -f "$task_file" ]]; then
    echo "Error: task ${task_id} not found" >&2
    exit 1
  fi
  
  local task_type
  task_type=$(jq -r '.type // "pi"' "$task_file")
  
  if [[ "$task_type" != "external" ]]; then
    echo "Error: --watch only works for external agent tasks" >&2
    echo "Use tmux attach for pi agent sessions" >&2
    exit 1
  fi
  
  local session_name socket
  session_name=$(jq -r '.session' "$task_file")
  socket=$(jq -r '.socket' "$task_file")
  
  if ! tmux -S "$socket" has-session -t "$session_name" 2>/dev/null; then
    echo "Session $session_name no longer exists"
    echo "Task may have completed. Check: tell.sh --status ${task_id}"
    exit 0
  fi
  
  echo "Watching task ${task_id} (Ctrl+C to stop, output updates every 2s)"
  echo "To attach interactively: tmux -S $socket attach -t $session_name"
  echo "---"
  
  local last_lines=0
  while tmux -S "$socket" has-session -t "$session_name" 2>/dev/null; do
    local output
    output=$(tmux -S "$socket" capture-pane -p -t "$session_name" -S -500 2>/dev/null || true)
    local current_lines
    current_lines=$(echo "$output" | wc -l)
    
    # Print new lines
    if [[ $current_lines -gt $last_lines ]]; then
      echo "$output" | tail -n +$((last_lines + 1))
      last_lines=$current_lines
    fi
    
    # Check for completion
    if echo "$output" | grep -q '\[TASK_COMPLETE\]'; then
      echo ""
      echo "=== Task completed ==="
      
      # Update task status
      local tmp now
      tmp=$(mktemp)
      now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
      jq --arg time "$now" '.status = "done" | .completed = $time' "$task_file" > "$tmp" && mv "$tmp" "$task_file"
      
      # Save output
      echo "$output" > "${TASKS_DIR}/${task_id}.output"
      
      # Notify the delegator
      notify_delegator "$task_id" "Task finished successfully"
      break
    fi
    
    sleep 2
  done
}

# Kill a running task
cmd_kill() {
  local task_id="$1"
  local task_file="${TASKS_DIR}/${task_id}.json"
  
  if [[ ! -f "$task_file" ]]; then
    echo "Error: task ${task_id} not found" >&2
    exit 1
  fi
  
  local task_type
  task_type=$(jq -r '.type // "pi"' "$task_file")
  
  if [[ "$task_type" != "external" ]]; then
    echo "Error: --kill only works for external agent tasks" >&2
    exit 1
  fi
  
  local session_name socket
  session_name=$(jq -r '.session' "$task_file")
  socket=$(jq -r '.socket' "$task_file")
  
  if tmux -S "$socket" has-session -t "$session_name" 2>/dev/null; then
    # Capture final output before killing
    local output
    output=$(tmux -S "$socket" capture-pane -p -t "$session_name" -S -500 2>/dev/null || true)
    echo "$output" > "${TASKS_DIR}/${task_id}.output"
    
    tmux -S "$socket" kill-session -t "$session_name"
    echo "Killed session $session_name"
  else
    echo "Session $session_name not found (may have already ended)"
  fi
  
  # Update status
  local tmp now
  tmp=$(mktemp)
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  jq --arg time "$now" '.status = "killed" | .completed = $time' "$task_file" > "$tmp" && mv "$tmp" "$task_file"
  
  echo "Task ${task_id} marked as killed"
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
  
  # Notify the delegator (sends ntfy + tells originating session)
  notify_delegator "$task_id" "$message"
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
  jq -r '"Status: \(.status)\nType: \(.type // "pi")\nFrom: \(.from)\nTo: \(.to)\nCreated: \(.created)\n\nTask: \(.task)"' "$task_file"
  
  local task_type
  task_type=$(jq -r '.type // "pi"' "$task_file")
  
  if [[ "$task_type" == "external" ]]; then
    local session_name socket
    session_name=$(jq -r '.session' "$task_file")
    socket=$(jq -r '.socket' "$task_file")
    
    if tmux -S "$socket" has-session -t "$session_name" 2>/dev/null; then
      echo ""
      echo "Session: RUNNING"
      echo "Attach:  tmux -S $socket attach -t $session_name"
    else
      echo ""
      echo "Session: ENDED"
      if [[ -f "${TASKS_DIR}/${task_id}.output" ]]; then
        echo ""
        echo "=== Last Output ==="
        tail -50 "${TASKS_DIR}/${task_id}.output"
      fi
    fi
  fi
  
  echo ""
  echo "=== Updates ==="
  jq -r '.updates[] | "  [\(.time)] \(.message)"' "$task_file" 2>/dev/null || echo "  (none)"
}

# List all tasks
cmd_list() {
  echo "=== Tasks ==="
  for f in "${TASKS_DIR}"/*.json; do
    [[ -f "$f" ]] || continue
    local task_id status task_type to task
    task_id=$(jq -r '.id' "$f")
    status=$(jq -r '.status' "$f")
    task_type=$(jq -r '.type // "pi"' "$f")
    to=$(jq -r '.to' "$f")
    task=$(jq -r '.task | .[0:50]' "$f")
    
    # Check if external task is still running
    if [[ "$task_type" == "external" && "$status" == "running" ]]; then
      local session_name socket
      session_name=$(jq -r '.session' "$f")
      socket=$(jq -r '.socket' "$f")
      if ! tmux -S "$socket" has-session -t "$session_name" 2>/dev/null; then
        status="ended?"
      fi
    fi
    
    printf "[%s] %-10s | %-8s | %-10s | %s...\n" "$task_id" "$status" "$task_type" "$to" "$task"
  done
}

# Delegate to external agent in VISIBLE mode (current tmux session)
cmd_agent_visible() {
  local agent="$1"
  shift
  local message="$*"
  
  if [[ -z "$agent" ]] || [[ -z "$message" ]]; then
    echo "Usage: tell.sh --agent AGENT --visible \"task description\"" >&2
    echo "Supported agents: ${!AGENT_COMMANDS[*]}" >&2
    exit 1
  fi
  
  # Must be in a tmux session
  if [[ -z "${TMUX:-}" ]]; then
    echo "Error: --visible requires running inside tmux" >&2
    echo "Use without --visible to run in background socket" >&2
    exit 1
  fi
  
  # Check if agent is supported
  if [[ -z "${AGENT_COMMANDS[$agent]:-}" ]]; then
    echo "Error: unknown agent '$agent'" >&2
    echo "Supported agents: ${!AGENT_COMMANDS[*]}" >&2
    exit 1
  fi
  
  # Check if agent binary exists
  local agent_bin="${AGENT_COMMANDS[$agent]%% *}"
  if ! command -v "$agent_bin" &>/dev/null; then
    echo "Error: '$agent_bin' not found in PATH" >&2
    exit 1
  fi
  
  local task_id
  task_id=$(gen_id)
  local from_ctx
  from_ctx=$(get_context)
  local created
  created=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local window_name="${agent}-${task_id}"
  
  # Create task file
  cat > "${TASKS_DIR}/${task_id}.json" << TASKEOF
{
  "id": "${task_id}",
  "from": "${from_ctx}",
  "to": "${agent}",
  "type": "external-visible",
  "window": "${window_name}",
  "status": "running",
  "task": $(jq -n --arg t "$message" '$t'),
  "created": "${created}",
  "updates": []
}
TASKEOF

  # Build the command - run agent, then wait for user input
  local agent_cmd="${AGENT_COMMANDS[$agent]}"
  local full_cmd
  if command -v script &>/dev/null; then
    # macOS script syntax: script -q /dev/null command (for proper TTY)
    full_cmd="script -q /dev/null $agent_cmd -p $(printf '%q' "$message"); echo ''; echo '=== Task complete. Press Enter to close ==='; read"
  else
    full_cmd="$agent_cmd -p $(printf '%q' "$message"); echo ''; echo '=== Task complete. Press Enter to close ==='; read"
  fi
  
  # Create new window in current session
  tmux new-window -n "$window_name" "bash -c $(printf '%q' "$full_cmd")"
  
  echo "Task ${task_id} started in window '${window_name}'"
  echo ""
  echo "Switch to it with: Ctrl-b n (next) or Ctrl-b w (list)"
  echo "Status: tell.sh --status ${task_id}"
}

# Main
case "${1:-}" in
  --agent|-a)
    shift
    agent="$1"
    shift
    # Check for --visible flag
    if [[ "${1:-}" == "--visible" ]] || [[ "${1:-}" == "-v" ]]; then
      shift
      cmd_agent_visible "$agent" "$@"
    else
      cmd_agent "$agent" "$@"
    fi
    ;;
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
  --watch|-w)
    shift
    cmd_watch "$@"
    ;;
  --kill|-k)
    shift
    cmd_kill "$@"
    ;;
  --help|-h)
    echo "Usage:"
    echo "  tell.sh SESSION \"task\"           - Send task to a pi agent session"
    echo "  tell.sh --agent AGENT \"task\"          - Delegate to external agent (background)"
    echo "  tell.sh --agent AGENT -v \"task\"       - Run in visible tmux window"
    echo ""
    echo "Supported agents: ${!AGENT_COMMANDS[*]}"
    echo ""
    echo "Task management:"
    echo "  tell.sh --status ID              - Check task status"
    echo "  tell.sh --watch ID               - Watch external task output live"
    echo "  tell.sh --kill ID                - Kill a running external task"
    echo "  tell.sh --update ID \"msg\"        - Update task progress (for pi agents)"
    echo "  tell.sh --done ID \"msg\"          - Mark task complete (for pi agents)"
    echo "  tell.sh --list                   - List all tasks"
    ;;
  *)
    cmd_tell "$@"
    ;;
esac
