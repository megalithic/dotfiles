#!/usr/bin/env bash
# Update npm package lockfiles and nix hashes for pi-coding-agent packages.
#
# Usage:
#   update-npm-pkg.sh [package-name] [version]   # update one package to version
#   update-npm-pkg.sh [package-name]              # update one package to latest
#   update-npm-pkg.sh                             # update all packages (current versions)
#
# Package name can be either the directory name (e.g., "pi") or the npm
# package name (e.g., "pi-coding-agent", "@mariozechner/pi-coding-agent").
#
# Examples:
#   just update-npm pi 0.67.6              # set pi to 0.67.6
#   just update-npm pi-coding-agent 0.67.6 # same thing (resolved via PNAME_MAP)
#   just update-npm pi                     # update pi to latest from npm
#   just update-npm                        # update all (current versions)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_BASE="$SCRIPT_DIR/../packages"
NIX_FILE="$SCRIPT_DIR/../default.nix"

# Map package dir names to their nix variable names (for npmDepsHash patching).
# AGENT CONTEXT: when adding a new package to packages/, also add it here.
# Format: [dir_name]="pname_in_nix" (pname must match the pname = "..." in default.nix)
declare -A PNAME_MAP=(
  [pi]="pi-coding-agent"
  [pi-mcp-adapter]="pi-mcp-adapter"
  [pi-internet]="pi-internet"

  [pi-agent-browser]="pi-agent-browser"
  [pi-synthetic-provider]="pi-synthetic-provider"
  [pi-diff-review]="pi-diff-review"
)

# Build reverse map: npm package name -> directory name
# Also handles scoped packages (strips @scope/ prefix for matching)
declare -A REVERSE_PNAME_MAP
for dir_name in "${!PNAME_MAP[@]}"; do
  npm_name="${PNAME_MAP[$dir_name]}"
  REVERSE_PNAME_MAP["$npm_name"]="$dir_name"
done

# Resolve a user-provided name to a package directory name.
# Accepts: directory name ("pi"), pname ("pi-coding-agent"), or
# full npm scoped name ("@mariozechner/pi-coding-agent").
resolve_pkg_name() {
  local input="$1"

  # Direct directory name match
  if [[ -d "$PKG_BASE/$input" ]]; then
    echo "$input"
    return
  fi

  # Strip @scope/ prefix if present
  local stripped="${input##*/}"

  # Reverse lookup: npm package name -> directory name
  if [[ -n "${REVERSE_PNAME_MAP[$stripped]:-}" ]]; then
    echo "${REVERSE_PNAME_MAP[$stripped]}"
    return
  fi

  # Try with original input (in case scoped name is in map)
  if [[ -n "${REVERSE_PNAME_MAP[$input]:-}" ]]; then
    echo "${REVERSE_PNAME_MAP[$input]}"
    return
  fi

  return 1
}

update_package() {
  local pkg_dir="$1"
  local target_version="${2:-}"
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

  # Get the npm dependency name from package.json
  local dep_name
  dep_name=$(jq -r '.dependencies | to_entries[0] | .key' "$pkg_dir/package.json")

  # Read current dep version from package.json
  local dep_version
  dep_version=$(jq -r '.dependencies | to_entries[0] | .value' "$pkg_dir/package.json")

  # If target version requested, resolve it ("latest" or specific)
  if [[ -n "$target_version" ]]; then
    if [[ "$target_version" == "latest" ]]; then
      echo "📦 $pkg_name — fetching latest version from npm..."
      target_version=$(npm view "$dep_name" version 2>/dev/null)
      if [[ -z "$target_version" ]]; then
        echo "   ✗ failed to fetch latest version for $dep_name"
        return 1
      fi
    fi

    if [[ "$dep_version" == "$target_version" ]]; then
      echo "📦 $pkg_name ($dep_version) — already at requested version"
    else
      echo "📦 $pkg_name ($dep_version → $target_version)"
      # Update package.json with new version
      jq --arg name "$dep_name" --arg ver "$target_version" \
        '.dependencies[$name] = $ver' "$pkg_dir/package.json" > "$pkg_dir/package.json.tmp" \
        && mv "$pkg_dir/package.json.tmp" "$pkg_dir/package.json"
      dep_version="$target_version"
    fi
  else
    echo "📦 $pkg_name ($dep_version)"
  fi

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
  # Resolve package name (supports dir name, pname, or scoped npm name)
  pkg_input="$1"
  resolved_name=$(resolve_pkg_name "$pkg_input") || true

  if [[ -z "$resolved_name" ]]; then
    echo "Error: unknown package: $pkg_input"
    echo "Available packages (dir name → npm name):"
    for d in "$PKG_BASE"/*/; do
      dn="$(basename "$d")"
      echo "  $dn → ${PNAME_MAP[$dn]:-unknown}"
    done
    exit 1
  fi

  target="$PKG_BASE/$resolved_name"
  version="${2:-}"

  # If no version given for a single package, fetch latest
  if [[ -z "$version" ]]; then
    version="latest"
  fi

  update_package "$target" "$version"
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
