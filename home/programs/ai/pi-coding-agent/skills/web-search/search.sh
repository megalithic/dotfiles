#!/usr/bin/env bash
# Web search using ddgr (DuckDuckGo CLI)
# Falls back to brave-search if ddgr fails

set -euo pipefail

NUM=5
TIME=""
SITE=""
QUERY=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [options] "query"

Options:
  -n <num>   Number of results (default: 5, max: 25)
  -t <span>  Time filter: d (day), w (week), m (month), y (year)
  -w <site>  Limit to specific site
  -h         Show this help

Examples:
  $(basename "$0") "nix flake update"
  $(basename "$0") -n 10 "rust async await"
  $(basename "$0") -t w "latest news topic"
  $(basename "$0") -w reddit.com "neovim tips"
EOF
  exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n)
      NUM="$2"
      shift 2
      ;;
    -t)
      TIME="$2"
      shift 2
      ;;
    -w)
      SITE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage
      ;;
    *)
      QUERY="$1"
      shift
      ;;
  esac
done

if [[ -z "$QUERY" ]]; then
  echo "Error: No search query provided" >&2
  usage
fi

# Build ddgr command
CMD=(ddgr --np --json -n "$NUM")
[[ -n "$TIME" ]] && CMD+=(-t "$TIME")
[[ -n "$SITE" ]] && CMD+=(-w "$SITE")
CMD+=("$QUERY")

# Run ddgr and format output
JSON=$("${CMD[@]}" 2>/dev/null) || {
  echo "ddgr failed, falling back to brave-search..." >&2
  BRAVE_SCRIPT="$HOME/.pi/agent/skills/brave-search/search.js"
  if [[ -x "$BRAVE_SCRIPT" ]] || [[ -f "$BRAVE_SCRIPT" ]]; then
    BRAVE_CMD=("$BRAVE_SCRIPT" "$QUERY" -n "$NUM")
    # Map time filter to brave freshness
    case "$TIME" in
      d) BRAVE_CMD+=(--freshness pd) ;;
      w) BRAVE_CMD+=(--freshness pw) ;;
      m) BRAVE_CMD+=(--freshness pm) ;;
      y) BRAVE_CMD+=(--freshness py) ;;
    esac
    exec node "${BRAVE_CMD[@]}"
  else
    echo "Error: brave-search fallback not available" >&2
    exit 1
  fi
}

# Format JSON output
echo "$JSON" | jq -r '
  to_entries | .[] |
  "--- Result \(.key + 1) ---",
  "Title: \(.value.title)",
  "URL: \(.value.url)",
  "Snippet: \(.value.abstract)",
  ""
'
