default:
  @just --list

# mise-owned config commands
up:
  mise run up

# update and upgrade homebrew packages
[macos]
update-brew:
  brew update && brew upgrade

# ===========================================================================
# Security scanning
# ===========================================================================

# Scan Git history and the working tree for secrets before pushing.
# Usage: just scan
scan:
  #!/usr/bin/env bash
  set -uo pipefail
  rc=0

  echo ":: betterleaks - scanning Git history..."
  MISE_AUTO_INSTALL=false mise exec betterleaks -- betterleaks git --redact --verbose . || rc=$?

  echo ":: betterleaks - scanning working tree..."
  MISE_AUTO_INSTALL=false mise exec betterleaks -- betterleaks dir --redact --verbose . || rc=$?

  if [[ $rc -eq 0 ]]; then
    echo ":: scan complete - no findings."
  else
    echo ":: scan found issues (exit $rc) - review output before pushing." >&2
  fi
  exit $rc
