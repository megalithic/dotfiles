#!/usr/bin/env bash
# Update nix hashes for pi-coding-agent extension packages.
#
# Core pi-coding-agent is not vendored here anymore. It comes from
# pkgs.pi-coding-agent from the shared nixpkgs input.
# Use `nix flake update nixpkgs` to move that package forward.
#
# Active local package specs live in packages/*.nix and use:
#   fetchFromGitHub + buildNpmPackage
#
# Usage:
#   update-npm-pkg.sh [package-name] [version]   # update one package to version
#   update-npm-pkg.sh [package-name]             # update one package to latest release
#   update-npm-pkg.sh                            # update all active extension packages
#
# Examples:
#   just update-npm pi-web-access
#   just update-npm pi-subagents 0.24.2
#   just update-npm
#
# AGENT CONTEXT: when adding a package here, add it to GITHUB_NPM_PKG_MAP and
# ensure its packages/<name>.nix file is wired into default.nix.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
PKG_BASE="$SCRIPT_DIR/../packages"

# Format: [pkg_name]="owner/repo:vendored_lockfile_relpath"
# vendored_lockfile_relpath is repo-root relative, empty if upstream lockfile is used.
declare -A GITHUB_NPM_PKG_MAP=(
  ["pi-mcp-adapter"]="nicobailon/pi-mcp-adapter:home/common/programs/pi-coding-agent/packages/pi-mcp-adapter-package-lock.json"
  ["pi-subagents"]="nicobailon/pi-subagents:home/common/programs/pi-coding-agent/packages/pi-subagents-package-lock.json"
  ["pi-web-access"]="nicobailon/pi-web-access:"
)

# Removed/stale package wrappers. Keep these names friendly so old invocations do
# not fail with confusing hash errors.
declare -A RETIRED_PKG_MESSAGES=(
  ["pi"]="core pi-coding-agent comes from pkgs.pi-coding-agent; update nixpkgs instead"
  ["pi-coding-agent"]="core pi-coding-agent comes from pkgs.pi-coding-agent; update nixpkgs instead"
  ["pi-agent-browser"]="retired; not wired into default.nix"
  ["pi-diff-review"]="retired; not wired into default.nix"
  ["pi-internet"]="retired; not wired into default.nix"
  ["pi-synthetic-provider"]="retired; not wired into default.nix"
)

get_nix_file() {
  local pkg_name="$1"
  echo "$PKG_BASE/$pkg_name.nix"
}

get_nix_value() {
  local nix_file="$1"
  local key="$2"
  awk -v key="$key" '
    index($0, key " = \"") {
      match($0, /"[^"]+"/)
      print substr($0, RSTART+1, RLENGTH-2)
      exit
    }
  ' "$nix_file"
}

patch_nix_value() {
  local nix_file="$1"
  local key="$2"
  local new_val="$3"
  local old_val
  old_val=$(get_nix_value "$nix_file" "$key")

  if [[ -z $old_val ]]; then
    echo "   ✗ could not find $key in ${nix_file#"$REPO_ROOT"/}"
    return 1
  fi
  if [[ $old_val == "$new_val" ]]; then
    return 0
  fi

  OLD_VAL="$old_val" NEW_VAL="$new_val" python3 - "$nix_file" <<'PY'
import os
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text()
path.write_text(text.replace(os.environ["OLD_VAL"], os.environ["NEW_VAL"], 1))
PY
  echo "   ✓ $key: ${old_val:0:30}... → ${new_val:0:30}..."
}

latest_release() {
  local repo_path="$1"
  gh api "repos/$repo_path/releases/latest" --jq '.tag_name' 2>/dev/null | sed 's/^v//'
}

prefetch_source() {
  local repo_path="$1"
  local version="$2"
  nix flake prefetch "github:$repo_path/v$version" --json 2>/dev/null
}

refresh_vendored_lockfile() {
  local repo_path="$1"
  local version="$2"
  local vendored_lock="$3"
  local source_path="$4"
  REFRESHED_LOCK_PATH=""

  if [[ -z $vendored_lock ]]; then
    if [[ -f $source_path/package-lock.json ]]; then
      REFRESHED_LOCK_PATH="$source_path/package-lock.json"
      return 0
    fi
    if [[ -f $source_path/npm-shrinkwrap.json ]]; then
      REFRESHED_LOCK_PATH="$source_path/npm-shrinkwrap.json"
      return 0
    fi
    echo "   ✗ upstream source has no lockfile"
    return 1
  fi

  local target="$REPO_ROOT/$vendored_lock"
  echo "   ↳ refreshing vendored lockfile..."

  if [[ -f $source_path/package-lock.json ]]; then
    cp "$source_path/package-lock.json" "$target" || return 1
    REFRESHED_LOCK_PATH="$target"
    echo "   ✓ ${vendored_lock#"$REPO_ROOT"/} from upstream lockfile"
    return 0
  fi

  if [[ -f $target ]] && [[ $(jq -r '.version // empty' "$target") == "$version" ]]; then
    REFRESHED_LOCK_PATH="$target"
    echo "   ✓ using existing generated ${vendored_lock#"$REPO_ROOT"/}"
    return 0
  fi

  echo "   ↳ upstream lockfile unavailable; generating vendored lockfile..."
  local workdir
  workdir=$(mktemp -d "${TMPDIR:-/tmp}/${repo_path##*/}.XXXXXX") || return 1
  cp -R "$source_path/." "$workdir/" || {
    trash "$workdir"
    return 1
  }
  chmod -R u+w "$workdir" || {
    trash "$workdir"
    return 1
  }

  if ! (cd "$workdir" && npm install --package-lock-only --ignore-scripts --audit=false --fund=false); then
    echo "   ✗ failed to generate package-lock.json"
    trash "$workdir"
    return 1
  fi

  cp "$workdir/package-lock.json" "$target" || {
    trash "$workdir" || true
    return 1
  }
  REFRESHED_LOCK_PATH="$target"
  trash "$workdir" || true
  echo "   ✓ generated ${vendored_lock#"$REPO_ROOT"/}"
}

compute_npm_deps_hash() {
  local nix_file="$1"
  local lock_path="$2"

  echo "   ↳ computing npmDepsHash..."
  local new_hash
  new_hash=$(nix shell nixpkgs#prefetch-npm-deps -c prefetch-npm-deps "$lock_path" 2>/dev/null || true)

  if [[ -z $new_hash ]]; then
    echo "   ✗ failed to compute npmDepsHash"
    return 1
  fi

  patch_nix_value "$nix_file" "npmDepsHash" "$new_hash"
}

update_github_npm_package() {
  local pkg_name="$1"
  local target_version="${2:-}"
  local spec="${GITHUB_NPM_PKG_MAP[$pkg_name]}"
  local repo_path="${spec%%:*}"
  local vendored_lock="${spec#*:}"
  local nix_file
  nix_file="$(get_nix_file "$pkg_name")"

  if [[ ! -f $nix_file ]]; then
    echo "✗ missing ${nix_file#"$REPO_ROOT"/}"
    return 1
  fi

  local current_version current_rev
  current_version=$(get_nix_value "$nix_file" "version")
  current_rev=$(get_nix_value "$nix_file" "rev")

  if [[ -z $target_version || $target_version == "latest" ]]; then
    echo "📦 $pkg_name — fetching latest release from GitHub..."
    target_version=$(latest_release "$repo_path" || true)
    [[ -z $target_version ]] && {
      echo "   ✗ failed to fetch latest release"
      return 1
    }
  fi

  if [[ $current_version == "$target_version" && $current_rev == "v$target_version" ]]; then
    echo "📦 $pkg_name ($current_version) — refreshing hashes"
  else
    echo "📦 $pkg_name ($current_version → $target_version)"
  fi
  echo "   ↳ prefetching src..."
  local prefetch_json src_hash source_path
  prefetch_json=$(prefetch_source "$repo_path" "$target_version" || true)
  src_hash=$(jq -r '.hash // empty' <<<"$prefetch_json")
  source_path=$(jq -r '.storePath // empty' <<<"$prefetch_json")
  [[ -z $src_hash || -z $source_path || $src_hash == "null" || $source_path == "null" ]] && {
    echo "   ✗ src prefetch failed"
    return 1
  }

  local nix_backup lock_backup vendored_abs
  nix_backup=$(mktemp)
  cp "$nix_file" "$nix_backup"
  lock_backup=""
  if [[ -n $vendored_lock ]]; then
    vendored_abs="$REPO_ROOT/$vendored_lock"
    if [[ -f $vendored_abs ]]; then
      lock_backup=$(mktemp)
      cp "$vendored_abs" "$lock_backup"
    fi
  fi

  restore_backups() {
    cp "$nix_backup" "$nix_file"
    if [[ -n $lock_backup ]]; then
      cp "$lock_backup" "$vendored_abs"
    elif [[ -n ${vendored_abs:-} && -f $vendored_abs ]]; then
      trash "$vendored_abs" || true
    fi
  }

  cleanup_backups() {
    trash "$nix_backup" || true
    if [[ -n $lock_backup ]]; then
      trash "$lock_backup" || true
    fi
  }

  if ! refresh_vendored_lockfile "$repo_path" "$target_version" "$vendored_lock" "$source_path"; then
    cleanup_backups
    return 1
  fi

  if ! {
    patch_nix_value "$nix_file" "version" "$target_version" &&
      patch_nix_value "$nix_file" "rev" "v$target_version" &&
      patch_nix_value "$nix_file" "hash" "$src_hash" &&
      compute_npm_deps_hash "$nix_file" "$REFRESHED_LOCK_PATH"
  }; then
    echo "   ✗ update failed; restoring ${nix_file#"$REPO_ROOT"/}"
    restore_backups
    cleanup_backups
    return 1
  fi

  cleanup_backups
}

dispatch_update() {
  local name="$1"
  local version="${2:-}"

  if [[ -n ${GITHUB_NPM_PKG_MAP[$name]:-} ]]; then
    update_github_npm_package "$name" "$version"
    return
  fi

  if [[ -n ${RETIRED_PKG_MESSAGES[$name]:-} ]]; then
    echo "📦 $name — skipped: ${RETIRED_PKG_MESSAGES[$name]}"
    return 0
  fi

  echo "Error: unknown package: $name"
  echo "Known active packages: ${!GITHUB_NPM_PKG_MAP[*]}"
  return 1
}

if [[ $# -gt 0 ]]; then
  dispatch_update "$1" "${2:-}"
else
  echo "Updating active pi extension packages..."
  echo
  for name in $(printf '%s\n' "${!GITHUB_NPM_PKG_MAP[@]}" | sort); do
    update_github_npm_package "$name" ""
    echo
  done
fi

echo "Done. Run 'just home' to rebuild."
