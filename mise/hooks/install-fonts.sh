#!/bin/sh
# Postinstall hook for [tools."github:ryanoasis/nerd-fonts"]: copy the
# extracted font files into ~/Library/Fonts so macOS apps can use them.
# Idempotent: only copies fonts that are missing or changed.
# mise runs postinstall with the tool install dir as cwd and exposes it as
# MISE_TOOL_INSTALL_PATH; fall back to cwd for manual runs.
set -eu

src="${MISE_TOOL_INSTALL_PATH:-$PWD}"
dest="$HOME/Library/Fonts"
mkdir -p "$dest"

copied=0
for f in "$src"/*.ttf "$src"/*.otf; do
  [ -e "$f" ] || continue
  base=$(basename "$f")
  if ! cmp -s "$f" "$dest/$base" 2>/dev/null; then
    cp -f "$f" "$dest/$base"
    copied=$((copied + 1))
  fi
done
echo "install-fonts: $copied font(s) copied to $dest"
