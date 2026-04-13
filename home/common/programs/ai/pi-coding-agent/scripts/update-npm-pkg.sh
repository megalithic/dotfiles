#!/usr/bin/env bash
# Update npm package lockfiles and nix hashes for pi-coding-agent packages.
#
# Usage:
#   update-npm-pkg.sh [package-name]   # update one package
#   update-npm-pkg.sh                  # update all packages
#
# Workflow:
#   1. Edit version in packages/<name>/package.json
#   2. Run this script (or `just update-npm [name]`)
#   3. Run `just home`
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_BASE="$SCRIPT_DIR/../packages"
NIX_FILE="$SCRIPT_DIR/../default.nix"

# Map package dir names to their nix variable names (for npmDepsHash patching)
# Format: dir_name:pname_in_nix
declare -A PNAME_MAP=(
  [pi]="pi-coding-agent"
  [pi-mcp-adapter]="pi-mcp-adapter"
  [pi-web-access]="pi-web-access"
  [pi-diff]="pi-diff"
  [pi-pretty]="pi-pretty"
  [pi-bash-live-view]="pi-bash-live-view"
  [pi-agent-browser]="pi-agent-browser"
  [pi-multi-pass]="pi-multi-pass"
  [pi-synthetic-provider]="pi-synthetic-provider"
)

update_package() {
  local pkg_dir="$1"
  local pkg_name
  pkg_name="$(basename "$pkg_dir")"
  local pname="${PNAME_MAP[$pkg_name]:-}"

  if [[ -z "$pname" ]]; then
    echo "⚠ Unknown package: $pkg_name (not in PNAME_MAP), skipping"
    return
  fi

  if [[ ! -f "$pkg_dir/package.json" ]]; then
    echo "⚠ No package.json in $pkg_dir, skipping"
    return
  fi

  # Read current dep version from package.json
  local dep_version
  dep_version=$(jq -r '.dependencies | to_entries[0] | .value' "$pkg_dir/package.json")
  echo "📦 $pkg_name ($dep_version)"

  # Update lockfile
  echo "   ↳ updating lockfile..."
  (cd "$pkg_dir" && npm install --package-lock-only --ignore-scripts 2>/dev/null)

  if [[ ! -f "$pkg_dir/package-lock.json" ]]; then
    echo "   ✗ no lockfile generated"
    return 1
  fi

  # Compute new hash
  echo "   ↳ computing hash..."
  local new_hash
  new_hash=$(nix shell nixpkgs#prefetch-npm-deps -c prefetch-npm-deps "$pkg_dir/package-lock.json" 2>/dev/null)

  if [[ -z "$new_hash" ]]; then
    echo "   ✗ failed to compute hash"
    return 1
  fi

  # Find and replace the npmDepsHash for this package in default.nix
  # Strategy: find the line with pname = "<pname>", then find the next npmDepsHash line
  local old_hash
  old_hash=$(awk -v pname="$pname" '
    $0 ~ "pname = \"" pname "\"" { found=1 }
    found && /npmDepsHash/ {
      match($0, /"[^"]+"/)
      print substr($0, RSTART+1, RLENGTH-2)
      exit
    }
  ' "$NIX_FILE")

  if [[ -z "$old_hash" ]]; then
    echo "   ✗ could not find npmDepsHash for pname=$pname in default.nix"
    return 1
  fi

  if [[ "$old_hash" == "$new_hash" ]]; then
    echo "   ✓ hash unchanged"
    return 0
  fi

  # Patch the hash in default.nix
  sed -i '' "s|$old_hash|$new_hash|" "$NIX_FILE"
  echo "   ✓ hash updated: ${old_hash:0:20}... → ${new_hash:0:20}..."
}

# Main
if [[ $# -gt 0 ]]; then
  # Update specific package
  target="$PKG_BASE/$1"
  if [[ ! -d "$target" ]]; then
    echo "Error: package directory not found: $target"
    echo "Available packages:"
    for d in "$PKG_BASE"/*/; do echo "  $(basename "$d")"; done
    exit 1
  fi
  update_package "$target"
else
  # Update all packages
  echo "Updating all npm packages..."
  echo ""
  for pkg_dir in "$PKG_BASE"/*/; do
    update_package "$pkg_dir"
    echo ""
  done
fi

echo "Done. Run 'just home' to rebuild."
