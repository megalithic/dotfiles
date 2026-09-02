#!/usr/bin/env bash
# Copy a browser profile to an isolated cache dir for agent use.
# Usage: copy-profile.sh [helium|brave]  (default: helium)
set -euo pipefail

CACHE_DIR="${HOME}/.cache/agent-web/profile-copy"
SOURCE="${1:-helium}"

case "$SOURCE" in
helium)
  PROFILE_DIR="${HOME}/Library/Application Support/net.imput.helium"
  ;;
brave)
  PROFILE_DIR="${HOME}/Library/Application Support/BraveSoftware/Brave-Browser-Nightly"
  ;;
*)
  echo "Usage: copy-profile.sh [helium|brave]" >&2
  exit 1
  ;;
esac

if [ ! -d "$PROFILE_DIR" ]; then
  echo "✗ Profile not found: $PROFILE_DIR" >&2
  exit 1
fi

# Clean previous copy
rm -rf "$CACHE_DIR"
mkdir -p "$CACHE_DIR"

echo "Copying $SOURCE profile to $CACHE_DIR..."

# Copy essential profile dirs (skip caches, GPU state, large blobs)
rsync -a --delete \
  --exclude='Service Worker/' \
  --exclude='Cache/' \
  --exclude='Code Cache/' \
  --exclude='GPUCache/' \
  --exclude='GrShaderCache/' \
  --exclude='ShaderCache/' \
  --exclude='BrowserMetrics/' \
  --exclude='Crashpad/' \
  --exclude='blob_storage/' \
  --exclude='IndexedDB/' \
  --exclude='*.log' \
  --exclude='SingletonLock' \
  --exclude='SingletonCookie' \
  --exclude='SingletonSocket' \
  "$PROFILE_DIR/" "$CACHE_DIR/"

echo "✓ Profile copied to $CACHE_DIR"
echo "  Use the chrome-devtools-profile MCP server to launch with this profile."
