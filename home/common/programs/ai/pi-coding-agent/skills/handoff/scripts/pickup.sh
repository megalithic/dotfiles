#!/usr/bin/env bash
# pickup.sh - Retrieve session handoff for continuation
#
# Usage:
#   pickup.sh                  # Get latest handoff from current session
#   pickup.sh mega             # Get latest handoff from 'mega' session
#   pickup.sh --list           # List all handoffs across all sessions
#   pickup.sh --list mega      # List all handoffs for 'mega' session
#   pickup.sh --file FILE      # Get specific handoff by filename
#
set -euo pipefail

HANDOFFS_DIR="${HOME}/.local/share/pi/handoffs"
SESSION="${PI_SESSION:-$(basename "$PWD")}"

# Parse args
ACTION="get"
TARGET_SESSION=""
SPECIFIC_FILE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --list)
      ACTION="list"
      shift
      ;;
    --file)
      SPECIFIC_FILE="$2"
      shift 2
      ;;
    *)
      TARGET_SESSION="$1"
      shift
      ;;
  esac
done

# Use target session if specified, otherwise current
SESSION="${TARGET_SESSION:-$SESSION}"

list_handoffs() {
  local session_filter="${1:-}"
  
  if [[ ! -d "$HANDOFFS_DIR" ]]; then
    echo "No handoffs found."
    return 0
  fi
  
  echo "Available handoffs:"
  echo ""
  
  if [[ -n "$session_filter" ]]; then
    # List specific session
    local session_dir="${HANDOFFS_DIR}/${session_filter}"
    if [[ ! -d "$session_dir" ]]; then
      echo "  No handoffs for session: ${session_filter}"
      return 0
    fi
    
    echo "Session: ${session_filter}"
    for f in "$session_dir"/*.md; do
      [[ -f "$f" ]] || continue
      local basename=$(basename "$f" .md)
      local title=$(rg -m1 "^# Handoff:" "$f" 2>/dev/null | sed 's/^# Handoff: //' || echo "(untitled)")
      echo "  ${basename}  ${title}"
    done
  else
    # List all sessions
    for session_dir in "$HANDOFFS_DIR"/*/; do
      [[ -d "$session_dir" ]] || continue
      local session_name=$(basename "$session_dir")
      echo "Session: ${session_name}"
      
      # Get most recent 5
      local count=0
      for f in $(ls -t "$session_dir"/*.md 2>/dev/null | head -5); do
        [[ -f "$f" ]] || continue
        local basename=$(basename "$f" .md)
        local title=$(rg -m1 "^# Handoff:" "$f" 2>/dev/null | sed 's/^# Handoff: //' || echo "(untitled)")
        echo "  ${basename}  ${title}"
        ((count++))
      done
      
      local total=$(ls "$session_dir"/*.md 2>/dev/null | wc -l | tr -d ' ')
      if [[ $total -gt 5 ]]; then
        echo "  ... and $((total - 5)) more"
      fi
      echo ""
    done
  fi
}

get_latest_handoff() {
  local session="$1"
  local session_dir="${HANDOFFS_DIR}/${session}"
  
  if [[ ! -d "$session_dir" ]]; then
    echo "No handoffs found for session: ${session}" >&2
    echo "" >&2
    echo "Available sessions:" >&2
    ls -1 "$HANDOFFS_DIR" 2>/dev/null | sed 's/^/  /' >&2 || echo "  (none)" >&2
    exit 1
  fi
  
  # Get most recent file
  local latest=$(ls -t "$session_dir"/*.md 2>/dev/null | head -1)
  
  if [[ -z "$latest" || ! -f "$latest" ]]; then
    echo "No handoff files found in: ${session_dir}" >&2
    exit 1
  fi
  
  echo "📋 Loading handoff: $(basename "$latest")"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  cat "$latest"
  
  # Show current todos if .pi/todos exists in current dir
  show_current_todos
}

show_current_todos() {
  local todos_dir=".pi/todos"
  
  if [[ ! -d "$todos_dir" ]] || ! command -v jq &>/dev/null; then
    return
  fi
  
  local open_todos=""
  local in_progress_todos=""
  
  for f in "$todos_dir"/*.md; do
    [[ -f "$f" ]] || continue
    
    # Extract JSON block (everything before first blank line or ## heading)
    local json_block=$(awk '/^$|^##/{exit} {print}' "$f" 2>/dev/null)
    
    # Parse with jq
    local status=$(echo "$json_block" | jq -r '.status // "open"' 2>/dev/null || echo "open")
    local title=$(echo "$json_block" | jq -r '.title // "(untitled)"' 2>/dev/null || echo "(untitled)")
    
    # Skip closed todos
    [[ "$status" == "closed" ]] && continue
    
    # Get todo ID from filename
    local todo_id=$(basename "$f" .md)
    
    if [[ "$status" == "in_progress" ]]; then
      in_progress_todos+="  🔄 TODO-$todo_id: $title\n"
    else
      open_todos+="  ○ TODO-$todo_id: $title\n"
    fi
  done
  
  if [[ -n "$in_progress_todos" || -n "$open_todos" ]]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 Current todos in working directory:"
    echo ""
    
    if [[ -n "$in_progress_todos" ]]; then
      echo "In progress:"
      echo -e "$in_progress_todos"
    fi
    
    if [[ -n "$open_todos" ]]; then
      echo "Open:"
      echo -e "$open_todos"
    fi
  fi
}

get_specific_handoff() {
  local file="$1"
  
  # If it's a full path, use it directly
  if [[ "$file" == /* ]]; then
    if [[ ! -f "$file" ]]; then
      echo "File not found: $file" >&2
      exit 1
    fi
    cat "$file"
    return
  fi
  
  # Otherwise look in session directory
  local full_path="${HANDOFFS_DIR}/${SESSION}/${file}"
  
  # Add .md if needed
  if [[ ! -f "$full_path" && ! "$full_path" =~ \.md$ ]]; then
    full_path="${full_path}.md"
  fi
  
  if [[ ! -f "$full_path" ]]; then
    echo "File not found: $full_path" >&2
    exit 1
  fi
  
  cat "$full_path"
}

# Execute action
case "$ACTION" in
  list)
    list_handoffs "$SESSION"
    ;;
  get)
    if [[ -n "$SPECIFIC_FILE" ]]; then
      get_specific_handoff "$SPECIFIC_FILE"
    else
      get_latest_handoff "$SESSION"
    fi
    ;;
esac
