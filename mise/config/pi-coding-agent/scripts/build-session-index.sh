#!/usr/bin/env bash
set -euo pipefail

SESSIONS_DIR="$HOME/.pi/agent/sessions"
INDEX_FILE="$HOME/.cache/pi-session-index.json"
PARALLEL="${PARALLEL:-8}"

# Staleness check: skip rebuild if index is newer than all session files
if [[ -f $INDEX_FILE ]]; then
  newer=$(find "$SESSIONS_DIR" -name "*.jsonl" -newer "$INDEX_FILE" -print -quit 2>/dev/null || true)
  if [[ -z $newer ]]; then
    echo "Index is up to date, skipping rebuild."
    exit 0
  fi
fi

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Prefilter files with user messages using rg
rg -l '"role":"user"' "$SESSIONS_DIR/" 2>/dev/null >"$TMPDIR/files.txt" || true

file_count=$(wc -l <"$TMPDIR/files.txt" | tr -d ' ')
if [[ $file_count -eq 0 ]]; then
  echo "No session files with user messages found."
  exit 0
fi

# Extract a single session entry as JSON using a single jq invocation
extract_entry() {
  local file="$1"
  local basename
  basename=$(basename "$file")

  # Date from filename: 2026-01-18T08-25-52...
  local date="${basename:0:10}"

  # Project from parent directory: --Users-otahontas-Code-mindler--
  local dirpath
  dirpath=$(dirname "$file")
  local dirname
  dirname=$(basename "$dirpath")
  # Strip leading/trailing -- and replace internal -- with /
  local project
  project="${dirname#--}"
  project="${project%--}"
  project="${project//--//}"

  # Single jq pass: extract title and content, output entry JSON
  jq -c '
    # Collect user texts, assistant texts, and compaction summaries
    [inputs |
      if .type=="message" and .message.role=="user" then
        (.message.content | if type == "array" then [.[] | select(.type=="text") | .text] else [.] end)
      elif .type=="message" and .message.role=="assistant" then
        (.message.content | if type == "array" then [.[] | select(.type=="text") | .text] else [.] end)
      elif .type=="compaction" then
        [.summary // empty]
      else
        []
      end
    ] | flatten as $texts |
    # Title = first user message text
    ($texts | map(select(length > 0)) | .[0] // "") | .[0:200] as $title |
    # Content = all texts joined
    ($texts | map(select(length > 0)) | join("\n")) | .[0:3000] as $content |
    select($title | length > 0) |
    {date: $date, project: $project, title: $title, content: $content, path: $path}
  ' --arg date "$date" --arg project "$project" --arg path "$file" "$file" 2>/dev/null || true
}

export -f extract_entry

# Process files in parallel
xargs -P "$PARALLEL" -I{} bash -c 'extract_entry "{}"' <"$TMPDIR/files.txt" >"$TMPDIR/entries.jsonl" 2>/dev/null

# Wrap into final index JSON
mkdir -p "$(dirname "$INDEX_FILE")"
jq -s \
  --arg built "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{version:2, built:$built, entries:.}' \
  "$TMPDIR/entries.jsonl" >"$INDEX_FILE"

count=$(jq '.entries | length' "$INDEX_FILE")
echo "Index built: $count entries written to $INDEX_FILE"
