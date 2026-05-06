#!/usr/bin/env bash
# Update package versions and nix hashes for pi-coding-agent packages.
#
# Three build patterns are supported, each with its own update path:
#
#   1. WRAPPER + buildNpmPackage (PNAME_MAP)
#      Local packages/<name>/package.json + lockfile, single npm dep.
#      → bumps dep version in package.json, regens lockfile, prefetches hash.
#
#   2. fetchFromGitHub + buildNpmPackage (GITHUB_NPM_PKG_MAP)
#      e.g., pi-mcp-adapter. Bumps GitHub rev, src hash, npmDepsHash. If
#      upstream lacks lockfile at the new tag, falls back to vendored
#      lockfile in patches/ (existing pattern for pi-mcp-adapter).
#
#   3. fetchFromGitHub + stdenvNoCC (GITHUB_NO_DEPS_PKG_MAP)
#      e.g., pi-multi-pass. Bumps GitHub rev + src hash only.
#
#   4. fetchurl (npm tarball) + stdenvNoCC (FETCHURL_PKG_MAP)
#      e.g., pi-synthetic-provider. Bumps npm tarball URL + hash only.
#
# Usage:
#   update-npm-pkg.sh [package-name] [version]   # update one package to version
#   update-npm-pkg.sh [package-name]              # update one package to latest
#   update-npm-pkg.sh                             # update all packages
#
# Examples:
#   just update-npm pi 0.73.0           # set pi to 0.73.0
#   just update-npm pi-multi-pass        # update pi-multi-pass to latest GitHub release
#   just update-npm                      # update all (current versions)
#
# AGENT CONTEXT: when adding a new package, add it to ONE of the four maps
# below based on its build pattern, then update default.nix.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_BASE="$SCRIPT_DIR/../packages"
NIX_FILE="$SCRIPT_DIR/../default.nix"

# ---------------------------------------------------------------------------
# Pattern 1: wrapper + buildNpmPackage
# Format: [dir_name]="pname_in_nix"
# ---------------------------------------------------------------------------
declare -A PNAME_MAP=(
  [pi]="pi-coding-agent"
  [pi-internet]="pi-internet"
  [pi-agent-browser]="pi-agent-browser"
  [pi-diff-review]="pi-diff-review"
)

# ---------------------------------------------------------------------------
# Pattern 2: fetchFromGitHub + buildNpmPackage
# Format: [pkg_name]="owner/repo:vendored_lockfile_relpath"
# vendored_lockfile_relpath empty if upstream provides lockfile at tag.
# ---------------------------------------------------------------------------
declare -A GITHUB_NPM_PKG_MAP=(
  [pi-mcp-adapter]="nicobailon/pi-mcp-adapter:patches/pi-mcp-adapter-2.5.4-package-lock.json"
)

# ---------------------------------------------------------------------------
# Pattern 3: fetchFromGitHub + stdenvNoCC
# Format: [pkg_name]="owner/repo"
# ---------------------------------------------------------------------------
declare -A GITHUB_NO_DEPS_PKG_MAP=(
  [pi-multi-pass]="hjanuschka/pi-multi-pass"
)

# ---------------------------------------------------------------------------
# Pattern 4: fetchurl (npm tarball) + stdenvNoCC
# Format: [pkg_name]="npm_pkg_name" (full scoped name accepted)
# ---------------------------------------------------------------------------
declare -A FETCHURL_PKG_MAP=(
  [pi-synthetic-provider]="@benvargas/pi-synthetic-provider"
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Build reverse map for PNAME_MAP only (other maps use pkg_name directly)
declare -A REVERSE_PNAME_MAP
for dir_name in "${!PNAME_MAP[@]}"; do
  npm_name="${PNAME_MAP[$dir_name]}"
  REVERSE_PNAME_MAP["$npm_name"]="$dir_name"
done

# Determine which map a package belongs to (echoes the map name or empty).
classify_pkg() {
  local name="$1"
  if [[ -n "${PNAME_MAP[$name]:-}" ]]; then echo "wrapper"; return; fi
  if [[ -n "${GITHUB_NPM_PKG_MAP[$name]:-}" ]]; then echo "github-npm"; return; fi
  if [[ -n "${GITHUB_NO_DEPS_PKG_MAP[$name]:-}" ]]; then echo "github-no-deps"; return; fi
  if [[ -n "${FETCHURL_PKG_MAP[$name]:-}" ]]; then echo "fetchurl"; return; fi
  # Reverse lookup for wrapper packages by npm name
  local stripped="${name##*/}"
  if [[ -n "${REVERSE_PNAME_MAP[$stripped]:-}" ]]; then
    echo "wrapper:${REVERSE_PNAME_MAP[$stripped]}"
    return
  fi
  if [[ -n "${REVERSE_PNAME_MAP[$name]:-}" ]]; then
    echo "wrapper:${REVERSE_PNAME_MAP[$name]}"
    return
  fi
  return 1
}

# Get current version from default.nix for a given pname.
get_nix_version() {
  local pname="$1"
  awk -v pname="$pname" '
    $0 ~ "pname = \"" pname "\"" { found=1 }
    found && /version = "/ {
      match($0, /"[^"]+"/)
      print substr($0, RSTART+1, RLENGTH-2)
      exit
    }
  ' "$NIX_FILE"
}

# Get current rev from default.nix for a given pname (looks for `rev = "..."`).
get_nix_rev() {
  local pname="$1"
  awk -v pname="$pname" '
    $0 ~ "pname = \"" pname "\"" { found=1 }
    found && /rev = "/ {
      match($0, /"[^"]+"/)
      print substr($0, RSTART+1, RLENGTH-2)
      exit
    }
  ' "$NIX_FILE"
}

# Patch a "key = \"..\"" entry in default.nix scoped to a pname block.
# Strategy: awk locates the pname line + first matching key after it; sed replaces.
patch_nix_value() {
  local pname="$1"
  local key="$2"
  local new_val="$3"
  local old_val
  old_val=$(awk -v pname="$pname" -v key="$key" '
    $0 ~ "pname = \"" pname "\"" { found=1 }
    found && $0 ~ key " = \"" {
      match($0, /"[^"]+"/)
      print substr($0, RSTART+1, RLENGTH-2)
      exit
    }
  ' "$NIX_FILE")

  if [[ -z "$old_val" ]]; then
    echo "   ✗ could not find $key for pname=$pname in default.nix"
    return 1
  fi
  if [[ "$old_val" == "$new_val" ]]; then
    return 0
  fi
  # Use | as sed delimiter (hashes contain /)
  sed -i '' "s|$old_val|$new_val|" "$NIX_FILE"
  echo "   ✓ $key: ${old_val:0:30}... → ${new_val:0:30}..."
}

# Convert a base32 nix hash to SRI sha256 format.
to_sri() {
  nix hash convert --to sri --hash-algo sha256 "$1" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Pattern 1: wrapper + buildNpmPackage (existing logic)
# ---------------------------------------------------------------------------
update_wrapper_package() {
  local pkg_dir="$1"
  local target_version="${2:-}"
  local pkg_name
  pkg_name="$(basename "$pkg_dir")"
  local pname="${PNAME_MAP[$pkg_name]:-}"

  if [[ -z "$pname" ]]; then
    echo "⚠ Unknown wrapper package: $pkg_name"
    return
  fi
  if [[ ! -f "$pkg_dir/package.json" ]]; then
    echo "⚠ No package.json in $pkg_dir, skipping"
    return
  fi

  local dep_name dep_version
  dep_name=$(jq -r '.dependencies | to_entries[0] | .key' "$pkg_dir/package.json")
  dep_version=$(jq -r '.dependencies | to_entries[0] | .value' "$pkg_dir/package.json")

  if [[ -n "$target_version" ]]; then
    if [[ "$target_version" == "latest" ]]; then
      echo "📦 $pkg_name — fetching latest version from npm..."
      target_version=$(npm view "$dep_name" version 2>/dev/null)
      [[ -z "$target_version" ]] && { echo "   ✗ failed to fetch latest"; return 1; }
    fi
    if [[ "$dep_version" == "$target_version" ]]; then
      echo "📦 $pkg_name ($dep_version) — already at requested version"
    else
      echo "📦 $pkg_name ($dep_version → $target_version)"
      jq --arg n "$dep_name" --arg v "$target_version" \
        '.dependencies[$n] = $v' "$pkg_dir/package.json" > "$pkg_dir/package.json.tmp" \
        && mv "$pkg_dir/package.json.tmp" "$pkg_dir/package.json"
      dep_version="$target_version"
    fi
  else
    echo "📦 $pkg_name ($dep_version) [wrapper]"
  fi

  echo "   ↳ updating lockfile..."
  (cd "$pkg_dir" && npm install --package-lock-only --ignore-scripts 2>/dev/null)
  [[ ! -f "$pkg_dir/package-lock.json" ]] && { echo "   ✗ no lockfile"; return 1; }

  echo "   ↳ computing npmDepsHash..."
  local new_hash
  new_hash=$(nix shell nixpkgs#prefetch-npm-deps -c prefetch-npm-deps "$pkg_dir/package-lock.json" 2>/dev/null)
  [[ -z "$new_hash" ]] && { echo "   ✗ hash compute failed"; return 1; }

  patch_nix_value "$pname" "npmDepsHash" "$new_hash"
}

# ---------------------------------------------------------------------------
# Pattern 2: fetchFromGitHub + buildNpmPackage
# ---------------------------------------------------------------------------
update_github_npm_package() {
  local pkg_name="$1"
  local target_version="${2:-}"
  local spec="${GITHUB_NPM_PKG_MAP[$pkg_name]}"
  local repo_path="${spec%%:*}"          # owner/repo
  local vendored_lock="${spec##*:}"      # patches/...lock.json (optional)
  [[ "$vendored_lock" == "$repo_path" ]] && vendored_lock=""

  local current_version current_rev
  current_version=$(get_nix_version "$pkg_name")
  current_rev=$(get_nix_rev "$pkg_name")

  if [[ -z "$target_version" || "$target_version" == "latest" ]]; then
    echo "📦 $pkg_name — fetching latest release from GitHub..."
    target_version=$(gh api "repos/$repo_path/releases/latest" --jq '.tag_name' 2>/dev/null | sed 's/^v//')
    [[ -z "$target_version" ]] && { echo "   ✗ failed to fetch latest tag"; return 1; }
  fi

  if [[ "$current_version" == "$target_version" && "$current_rev" == "v$target_version" ]]; then
    echo "📦 $pkg_name ($current_version) — already at requested version [github-npm]"
    return 0
  fi

  echo "📦 $pkg_name ($current_version → $target_version) [github-npm]"

  echo "   ↳ prefetching src hash..."
  local prefetch_json src_hash
  prefetch_json=$(nix shell nixpkgs#nix-prefetch-github -c \
    nix-prefetch-github "${repo_path%/*}" "${repo_path##*/}" --rev "v$target_version" 2>/dev/null)
  src_hash=$(echo "$prefetch_json" | jq -r .hash)
  [[ -z "$src_hash" || "$src_hash" == "null" ]] && { echo "   ✗ src prefetch failed"; return 1; }

  patch_nix_value "$pkg_name" "version" "$target_version"
  patch_nix_value "$pkg_name" "rev" "v$target_version"
  patch_nix_value "$pkg_name" "hash" "$src_hash"

  if [[ -n "$vendored_lock" ]]; then
    echo "   ⚠ vendored lockfile in use ($vendored_lock)"
    echo "     → if upstream changed deps, manually regenerate this lockfile"
  fi

  echo "   ↳ computing npmDepsHash via fake-hash build..."
  patch_nix_value "$pkg_name" "npmDepsHash" "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
  local build_log new_hash
  build_log=$(cd "$SCRIPT_DIR/../../../.." && just validate home 2>&1 || true)
  new_hash=$(echo "$build_log" | grep -oE 'got: *sha256-[A-Za-z0-9+/=]+' | head -1 | awk '{print $2}')
  [[ -z "$new_hash" ]] && { echo "   ✗ failed to extract real hash from build log"; return 1; }
  patch_nix_value "$pkg_name" "npmDepsHash" "$new_hash"
}

# ---------------------------------------------------------------------------
# Pattern 3: fetchFromGitHub + stdenvNoCC
# ---------------------------------------------------------------------------
update_github_no_deps_package() {
  local pkg_name="$1"
  local target_version="${2:-}"
  local repo_path="${GITHUB_NO_DEPS_PKG_MAP[$pkg_name]}"

  local current_version current_rev
  current_version=$(get_nix_version "$pkg_name")
  current_rev=$(get_nix_rev "$pkg_name")

  if [[ -z "$target_version" || "$target_version" == "latest" ]]; then
    echo "📦 $pkg_name — fetching latest release from GitHub..."
    target_version=$(gh api "repos/$repo_path/releases/latest" --jq '.tag_name' 2>/dev/null | sed 's/^v//')
    [[ -z "$target_version" ]] && { echo "   ✗ failed to fetch latest tag"; return 1; }
  fi

  if [[ "$current_version" == "$target_version" && "$current_rev" == "v$target_version" ]]; then
    echo "📦 $pkg_name ($current_version) — already at requested version [github-no-deps]"
    return 0
  fi

  echo "📦 $pkg_name ($current_version → $target_version) [github-no-deps]"
  echo "   ↳ prefetching src hash..."
  local prefetch_json src_hash
  prefetch_json=$(nix shell nixpkgs#nix-prefetch-github -c \
    nix-prefetch-github "${repo_path%/*}" "${repo_path##*/}" --rev "v$target_version" 2>/dev/null)
  src_hash=$(echo "$prefetch_json" | jq -r .hash)
  [[ -z "$src_hash" || "$src_hash" == "null" ]] && { echo "   ✗ prefetch failed"; return 1; }

  patch_nix_value "$pkg_name" "version" "$target_version"
  patch_nix_value "$pkg_name" "rev" "v$target_version"
  patch_nix_value "$pkg_name" "hash" "$src_hash"
}

# ---------------------------------------------------------------------------
# Pattern 4: fetchurl (npm tarball) + stdenvNoCC
# ---------------------------------------------------------------------------
update_fetchurl_package() {
  local pkg_name="$1"
  local target_version="${2:-}"
  local npm_name="${FETCHURL_PKG_MAP[$pkg_name]}"

  local current_version
  current_version=$(get_nix_version "$pkg_name")

  if [[ -z "$target_version" || "$target_version" == "latest" ]]; then
    echo "📦 $pkg_name — fetching latest version from npm..."
    target_version=$(npm view "$npm_name" version 2>/dev/null)
    [[ -z "$target_version" ]] && { echo "   ✗ npm view failed"; return 1; }
  fi

  if [[ "$current_version" == "$target_version" ]]; then
    echo "📦 $pkg_name ($current_version) — already at requested version [fetchurl]"
    return 0
  fi

  echo "📦 $pkg_name ($current_version → $target_version) [fetchurl]"
  # Build tarball URL: handles scoped pkg (@scope/name → @scope/name/-/name-version.tgz)
  local short_name="${npm_name##*/}"
  local new_url="https://registry.npmjs.org/${npm_name}/-/${short_name}-${target_version}.tgz"

  echo "   ↳ prefetching tarball hash..."
  local raw_hash sri_hash
  raw_hash=$(nix-prefetch-url "$new_url" 2>/dev/null | tail -1)
  [[ -z "$raw_hash" ]] && { echo "   ✗ prefetch failed"; return 1; }
  sri_hash=$(to_sri "$raw_hash")

  patch_nix_value "$pkg_name" "version" "$target_version"
  patch_nix_value "$pkg_name" "url" "$new_url"
  patch_nix_value "$pkg_name" "hash" "$sri_hash"
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
dispatch_update() {
  local name="$1"
  local version="${2:-}"
  local kind
  kind=$(classify_pkg "$name") || {
    echo "Error: unknown package: $name"
    return 1
  }

  case "$kind" in
    wrapper) update_wrapper_package "$PKG_BASE/$name" "$version" ;;
    wrapper:*)
      local resolved="${kind#wrapper:}"
      update_wrapper_package "$PKG_BASE/$resolved" "$version" ;;
    github-npm) update_github_npm_package "$name" "$version" ;;
    github-no-deps) update_github_no_deps_package "$name" "$version" ;;
    fetchurl) update_fetchurl_package "$name" "$version" ;;
    *) echo "Error: unhandled kind '$kind'"; return 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
if [[ $# -gt 0 ]]; then
  dispatch_update "$1" "${2:-}"
else
  echo "Updating all packages..."
  echo
  # Wrapper packages (iterate dirs)
  for pkg_dir in "$PKG_BASE"/*/; do
    name="$(basename "$pkg_dir")"
    [[ -n "${PNAME_MAP[$name]:-}" ]] && update_wrapper_package "$pkg_dir" ""
    echo
  done
  # GitHub + buildNpmPackage
  for name in "${!GITHUB_NPM_PKG_MAP[@]}"; do
    update_github_npm_package "$name" ""
    echo
  done
  # GitHub + stdenvNoCC
  for name in "${!GITHUB_NO_DEPS_PKG_MAP[@]}"; do
    update_github_no_deps_package "$name" ""
    echo
  done
  # fetchurl + stdenvNoCC
  for name in "${!FETCHURL_PKG_MAP[@]}"; do
    update_fetchurl_package "$name" ""
    echo
  done
fi

echo "Done. Run 'just home' to rebuild."
