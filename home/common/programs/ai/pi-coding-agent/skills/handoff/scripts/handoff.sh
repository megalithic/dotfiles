#!/usr/bin/env bash
# handoff.sh - Save session state for later pickup
#
# Usage:
#   handoff.sh                           # Interactive: prompts for content
#   handoff.sh --file /path/to/content   # Read content from file
#   handoff.sh --title "brief title"     # Set title (optional)
#
# Creates: ~/.local/share/pi/handoffs/{session}/{timestamp}.md
#
set -euo pipefail

HANDOFFS_DIR="${HOME}/.local/share/pi/handoffs"
SESSION="${PI_SESSION:-$(basename "$PWD")}"
TIMESTAMP=$(date +%Y-%m-%dT%H-%M-%S)
DATETIME=$(date "+%Y-%m-%d %H:%M:%S %Z")

# Parse args
CONTENT_FILE=""
TITLE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --file)
      CONTENT_FILE="$2"
      shift 2
      ;;
    --title)
      TITLE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# Create directory
mkdir -p "${HANDOFFS_DIR}/${SESSION}"

OUTPUT_FILE="${HANDOFFS_DIR}/${SESSION}/${TIMESTAMP}.md"

# Get working directory
WORKING_DIR=$(pwd)

# Get jj status if available
JJ_STATUS=""
if command -v jj &>/dev/null && jj root &>/dev/null 2>&1; then
  JJ_STATUS=$(jj status 2>/dev/null || true)
fi

# Get current bookmark (if any)
# Check @ first, then @- (common case: made changes after creating bookmark)
JJ_BOOKMARK=""
if command -v jj &>/dev/null && jj root &>/dev/null 2>&1; then
  JJ_BOOKMARK=$(jj log -r @ -T 'bookmarks' --no-graph 2>/dev/null | tr ' ' '\n' | head -1 || true)
  if [[ -z "$JJ_BOOKMARK" ]]; then
    # Check parent - bookmark may be there if working on uncommitted changes
    JJ_BOOKMARK=$(jj log -r @- -T 'bookmarks' --no-graph 2>/dev/null | tr ' ' '\n' | head -1 || true)
  fi
fi

# Get recent jj log if available
JJ_LOG=""
if command -v jj &>/dev/null && jj root &>/dev/null 2>&1; then
  JJ_LOG=$(jj log -n 5 -T 'change_id.shortest() ++ "  " ++ description.first_line() ++ "\n"' 2>/dev/null || true)
fi

# Get diff summary if available
JJ_DIFF_STAT=""
if command -v jj &>/dev/null && jj root &>/dev/null 2>&1; then
  JJ_DIFF_STAT=$(jj diff --stat 2>/dev/null || true)
fi

# Get todos from .pi/todos/ in working directory
TODOS_INFO=""
TODOS_DIR=".pi/todos"
if [[ -d "$TODOS_DIR" ]] && command -v jq &>/dev/null; then
  # Count todos
  TOTAL_TODOS=$(ls "$TODOS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
  
  if [[ "$TOTAL_TODOS" -gt 0 ]]; then
    TODOS_INFO="### Todos\n\n"
    
    IN_PROGRESS=""
    OPEN=""
    
    # Get open/in-progress todos (JSON frontmatter at start of file)
    for f in "$TODOS_DIR"/*.md; do
      [[ -f "$f" ]] || continue
      
      # Extract JSON block (everything before first blank line or ## heading)
      JSON_BLOCK=$(awk '/^$|^##/{exit} {print}' "$f" 2>/dev/null)
      
      # Parse with jq
      TODO_STATUS=$(echo "$JSON_BLOCK" | jq -r '.status // "open"' 2>/dev/null || echo "open")
      TODO_TITLE=$(echo "$JSON_BLOCK" | jq -r '.title // "(untitled)"' 2>/dev/null || echo "(untitled)")
      
      # Skip closed todos
      [[ "$TODO_STATUS" == "closed" ]] && continue
      
      # Get todo ID from filename
      TODO_ID=$(basename "$f" .md)
      
      # Format based on status
      if [[ "$TODO_STATUS" == "in_progress" ]]; then
        IN_PROGRESS+="- 🔄 **TODO-$TODO_ID**: $TODO_TITLE\n"
      else
        OPEN+="- ○ TODO-$TODO_ID: $TODO_TITLE\n"
      fi
    done
    
    if [[ -n "$IN_PROGRESS" ]]; then
      TODOS_INFO+="**In progress:**\n$IN_PROGRESS\n"
    fi
    if [[ -n "$OPEN" ]]; then
      TODOS_INFO+="**Open:**\n$OPEN"
    fi
  fi
fi

# Read content from file or stdin
if [[ -n "$CONTENT_FILE" ]]; then
  if [[ ! -f "$CONTENT_FILE" ]]; then
    echo "Error: Content file not found: $CONTENT_FILE" >&2
    exit 1
  fi
  CONTENT=$(cat "$CONTENT_FILE")
else
  # Read from stdin if available, otherwise prompt
  if [[ -t 0 ]]; then
    echo "Enter handoff content (Ctrl+D when done):"
    echo "---"
  fi
  CONTENT=$(cat)
fi

# Set default title if not provided
if [[ -z "$TITLE" ]]; then
  TITLE="Session Handoff"
fi

# Write the handoff document
cat > "$OUTPUT_FILE" << EOF
# Handoff: ${TITLE}

**Session:** ${SESSION}
**Time:** ${DATETIME}
**Working Directory:** ${WORKING_DIR}
**Bookmark:** ${JJ_BOOKMARK:-"(none)"}

${CONTENT}

---

## Auto-captured Context

### Working copy status
\`\`\`
${JJ_STATUS:-"(not in a jj repository)"}
\`\`\`

### Recent commits
\`\`\`
${JJ_LOG:-"(not in a jj repository)"}
\`\`\`

### Uncommitted changes
\`\`\`
${JJ_DIFF_STAT:-"(no changes or not in a jj repository)"}
\`\`\`

$(if [[ -n "$TODOS_INFO" ]]; then echo -e "$TODOS_INFO"; else echo "### Todos\n\n(no .pi/todos directory found)"; fi)
EOF

echo "✓ Handoff saved: ${OUTPUT_FILE}"
echo ""
echo "To pickup later:"
echo "  /pickup ${SESSION}"
