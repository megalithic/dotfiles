#!/usr/bin/env bash
set -euo pipefail

# Auto-enter devenv if tk is not on PATH
if ! command -v tk &>/dev/null; then
  # Find project root with devenv.nix
  dir="$(pwd)"
  while [ "$dir" != / ]; do
    [ -f "$dir/devenv.nix" ] && break
    dir="$(dirname "$dir")"
  done
  if [ "$dir" = / ]; then
    echo "Error: no devenv.nix found in any parent directory" >&2
    exit 1
  fi
  cd "$dir"
  exec devenv shell -- "$0" "$@"
fi

TAG="ready-for-development"
COMPLETED=0
SKIPPED=0

VERIFY_PROMPT="Verify the changes made for ticket TICKET. Do the following steps in order:
1. Run 'tk show TICKET' and re-read the acceptance criteria.
2. Run 'git diff HEAD~1' to see what changed.
3. Run the project test and lint commands.
4. Check for common issues: unused imports, debug prints (console.log, print(), fmt.Println), leftover TODO comments in changed lines.
5. If lat.md/ exists in the project, run lat check. If it reports errors, run 'tk reopen TICKET' and add a note with the errors.
If you find any issues: run 'tk reopen TICKET' then 'tk add-note TICKET \"Verification failed: <details>\"'.
If everything looks good: do nothing, the ticket stays closed."

# Load context file if available
CONTEXT=""
if [ -f "plans/.ticket-context.md" ]; then
  CONTEXT=$(cat "plans/.ticket-context.md")
  echo "Loaded context from plans/.ticket-context.md"
fi

# Set up logging — capture all stdout/stderr to log file
LOG_DIR=".tickets/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(date -u +%Y-%m-%dT%H-%M-%S).log"

# Duplicate all output to log file while still printing to terminal
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting ticket runner (tag: $TAG, verification: on)"
# Note: not safe to run concurrently against the same .tickets directory.

while true; do
  # Get next ready ticket with matching tag
  TICKET=$(tk ready -T "$TAG" 2>/dev/null | head -1 | awk '{print $1}')

  if [ -z "$TICKET" ]; then
    echo "No more ready tickets. Done."
    break
  fi

  tk start "$TICKET"
  echo "=== Working on $TICKET ==="

  # Run pi with ticket-worker skill
  WORK_PROMPT="Work on ticket $TICKET using your ticket-worker skill"
  if [ -n "$CONTEXT" ]; then
    WORK_PROMPT="Project context:\n\n$CONTEXT\n\n---\n\n$WORK_PROMPT"
  fi
  PI_STDERR_FILE=$(mktemp)
  if pi -p "$WORK_PROMPT" 2>"$PI_STDERR_FILE"; then
    PI_EXIT=0
  else
    PI_EXIT=$?
  fi
  cat "$PI_STDERR_FILE" >&2
  rm -f "$PI_STDERR_FILE"

  # Check if ticket was closed by the agent
  STATUS=$(tk show "$TICKET" 2>/dev/null | grep '^status:' | awk '{print $2}')

  if [ "$STATUS" = "closed" ]; then
    echo "✅ $TICKET closed — running verification"

    # Run verification pass
    VERIFY_PROMPT_EXPANDED="${VERIFY_PROMPT//TICKET/$TICKET}"
    if pi -p "$VERIFY_PROMPT_EXPANDED"; then
      VERIFY_EXIT=0
    else
      VERIFY_EXIT=$?
    fi

    # Re-check status after verification
    STATUS=$(tk show "$TICKET" 2>/dev/null | grep '^status:' | awk '{print $2}')

    if [ "$STATUS" = "closed" ]; then
      echo "✅ $TICKET verified"
      COMPLETED=$((COMPLETED + 1))
    else
      echo "⚠️  $TICKET reopened during verification (status: $STATUS, pi exit: $VERIFY_EXIT)"
      SKIPPED=$((SKIPPED + 1))
    fi
  else
    echo "⚠️  $TICKET not closed (status: $STATUS, pi exit: $PI_EXIT). Skipping."
    SKIPPED=$((SKIPPED + 1))
  fi

  echo ""
done

echo "Done. Completed: $COMPLETED, Skipped: $SKIPPED"

# Final review: have pi analyze the full log for issues
REVIEW_PROMPT="Review the following work-tickets run log. For each ticket, report:
- Whether it completed and verified successfully
- Any issues found (compilation errors, test failures, verification failures, reopened tickets)
- Any patterns or problems that need follow-up
Keep the report concise. End with a one-line overall status.

Log content:
$(cat "$LOG_FILE")"

echo ""
echo "=== Running final review ==="
if pi -p "$REVIEW_PROMPT"; then
  true
else
  echo "Review agent exited with error (non-fatal)"
fi

echo ""
echo "Log saved to $LOG_FILE"
