#!/bin/sh
# Install a macOS .app from a mise-downloaded DMG into /Applications.
#
# mise tool backends (http:, github:) download .dmg assets verbatim — no
# extraction, unlike zip — so the install dir holds a raw DMG. This
# postinstall mounts it and copies the bundle out. It runs only when mise
# installs a new tool version, so an existing app is replaced (= upgrade).
#
# Env (set by mise): MISE_TOOL_INSTALL_PATH, MISE_TOOL_NAME
# Env (optional):    INSTALL_APP_DIR (default /Applications)
set -eu

[ "$(uname -s)" = Darwin ] || exit 0
INSTALL_PATH="${MISE_TOOL_INSTALL_PATH:?install-app: MISE_TOOL_INSTALL_PATH not set (run via mise postinstall)}"
INSTALL_DIR="${INSTALL_APP_DIR:-/Applications}"

DMG=$(find "$INSTALL_PATH" -maxdepth 1 -type f -name '*.dmg' | head -1)
if [ -z "$DMG" ]; then
  # mise renames a single-file release asset to the tool's short name (binary
  # heuristic), dropping the .dmg suffix. Fall back to the largest regular
  # file; hdiutil detects the DMG format from content, not the name.
  DMG=$(find "$INSTALL_PATH" -maxdepth 1 -type f ! -name 'metadata.json' ! -name '.*' -exec du -k {} + | sort -rn | head -1 | cut -f2-)
fi
[ -n "$DMG" ] || {
  echo "install-app: no .dmg or payload file in $INSTALL_PATH" >&2
  exit 1
}

WORKDIR=$(mktemp -d "${TMPDIR:-/tmp}/install-app.XXXXXX")
MOUNTPOINT="$WORKDIR/mnt"
cleanup() {
  [ -d "$MOUNTPOINT" ] && hdiutil detach "$MOUNTPOINT" -quiet 2>/dev/null
  rm -rf "$WORKDIR"
}
trap cleanup EXIT INT TERM

mkdir -p "$MOUNTPOINT"
hdiutil attach "$DMG" -nobrowse -quiet -mountpoint "$MOUNTPOINT"
SRC_APP=$(find "$MOUNTPOINT" -maxdepth 1 -name '*.app' | head -1)
[ -n "$SRC_APP" ] || {
  echo "install-app: no .app in $(basename "$DMG")" >&2
  exit 1
}
APP="$INSTALL_DIR/$(basename "$SRC_APP")"

# Stage a copy outside the mount, detach, then swap into place — replacing
# the target in one move instead of copying file-by-file over a running app.
STAGED="$WORKDIR/$(basename "$SRC_APP")"
cp -R "$SRC_APP" "$STAGED"
hdiutil detach "$MOUNTPOINT" -quiet
rmdir "$MOUNTPOINT" 2>/dev/null || true

mkdir -p "$INSTALL_DIR"
rm -rf "$APP"
mv "$STAGED" "$APP" 2>/dev/null || cp -R "$STAGED" "$APP"
echo "install-app: installed $APP"
