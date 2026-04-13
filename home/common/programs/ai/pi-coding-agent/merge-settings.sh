#!/usr/bin/env bash
# Merge repo settings into settings.json without touching other keys
# This script is idempotent and preserves all other settings

set -euo pipefail

SETTINGS_FILE="${HOME}/.pi/agent/settings.json"
MERGE_JSON="$1" # Path to file containing settings to merge

# Create settings directory if it doesn't exist
mkdir -p "$(dirname "$SETTINGS_FILE")"

# If settings.json doesn't exist, create minimal config
if [[ ! -f $SETTINGS_FILE ]]; then
  echo '{}' >"$SETTINGS_FILE"
fi

# Merge settings, preserving existing keys unless overridden
jq -s '.[0] * .[1]' \
  "$SETTINGS_FILE" \
  "$MERGE_JSON" >"${SETTINGS_FILE}.tmp"

mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
