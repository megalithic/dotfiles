# Jujutsu (jj) aliases
{
  # ─────────────────────────────────────────────────────────────
  # Basic shortcuts
  # ─────────────────────────────────────────────────────────────
  s = [ "status" ];
  l = [ "log" ];
  ll = [ "log" "-T" "builtin_log_compact_full_description" ];
  d = [ "diff" ];
  rb = [ "rebase" ];
  b = [ "bookmark" ];
  g = [ "git" ];

  # ─────────────────────────────────────────────────────────────
  # Bookmark management
  # ─────────────────────────────────────────────────────────────
  
  # Moves closest bookmark to current working copy
  here = [ "bookmark" "move" "--from" "closest_bookmark(@)" "--to" "@" ];
  
  # Advances closest bookmark to parent commit
  tug = [ "bookmark" "move" "--from" "closest_bookmark(@-)" "--to" "@-" ];
  
  # Move main to current
  main = [ "bookmark" "move" "main" "--to" "@" ];

  # ─────────────────────────────────────────────────────────────
  # Smart push with guardrails
  # jj push -b <bookmark> [--pr] [other flags]
  # - Checks bookmark (not @) for empty
  # - Auto-adds --allow-new for new bookmarks
  # - --pr flag: push then create PR
  # ─────────────────────────────────────────────────────────────
  push = [
    "util" "exec" "--" "bash" "-c"
    ''
      set -euo pipefail

      # Parse args: extract bookmark and --pr flag
      bookmark=""
      create_pr=false
      pass_args=()
      
      while [[ $# -gt 0 ]]; do
        case "$1" in
          -b|--bookmark)
            bookmark="$2"
            pass_args+=("$1" "$2")
            shift 2
            ;;
          --pr)
            create_pr=true
            shift
            ;;
          *)
            pass_args+=("$1")
            shift
            ;;
        esac
      done

      # Require -b flag
      if [[ -z "$bookmark" ]]; then
        closest=$(jj log -r 'closest_bookmark(@)' --no-graph \
          -T 'self.bookmarks().map(|b| b.name()).join(",")' 2>/dev/null | head -1)
        
        echo "Error: Must specify bookmark with -b <bookmark>" >&2
        if [[ -n "$closest" && "$closest" != "main" ]]; then
          echo "Did you mean: jj push -b $closest" >&2
        fi
        exit 1
      fi

      # Check if bookmark exists and is not empty
      if ! jj log -r "$bookmark" --no-graph -T 'change_id.short()' 2>/dev/null | grep -q .; then
        echo "Error: Bookmark '$bookmark' not found." >&2
        exit 1
      fi

      if jj log -r "$bookmark" --no-graph -T 'if(empty, "true", "false")' | grep -q 'true'; then
        echo "Error: Bookmark '$bookmark' points to an empty commit." >&2
        echo "Make changes and run 'jj dm \"message\"' first." >&2
        exit 1
      fi

      # Check if bookmark needs --allow-new (doesn't exist on remote)
      if ! jj bookmark list --remote origin 2>/dev/null | grep -q "^$bookmark@origin:"; then
        echo "Bookmark '$bookmark' is new, adding --allow-new"
        pass_args+=("--allow-new")
      fi

      # Push
      jj git push "''${pass_args[@]}"

      # Create PR if requested
      if $create_pr; then
        echo ""
        echo "Creating PR..."
        gh pr create --head "$bookmark" --base main --fill
      fi
    ''
    ""
  ];

  # ─────────────────────────────────────────────────────────────
  # Describe + move bookmark
  # jj dv [-b <bookmark>] - via editor
  # jj dm [-b <bookmark>] <message> - with message
  # ─────────────────────────────────────────────────────────────
  dv = [
    "util" "exec" "--" "bash" "-c"
    ''
      set -euo pipefail

      # Parse args: look for -b <bookmark> flag
      bookmark=""
      while [[ $# -gt 0 ]]; do
        case "$1" in
          -b|--bookmark)
            bookmark="$2"
            shift 2
            ;;
          *)
            shift
            ;;
        esac
      done

      jj describe

      # Use explicit bookmark or find closest
      if [[ -z "$bookmark" ]]; then
        bookmark=$(jj log -r 'closest_bookmark(@)' --no-graph \
          -T 'self.bookmarks().map(|b| b.name()).join(",")' 2>/dev/null | head -1)
      fi

      # Move bookmark if found and not main
      if [[ -n "$bookmark" && "$bookmark" != "main" ]]; then
        jj bookmark set "$bookmark" -r @
        echo "Moved bookmark '$bookmark' to @"
      fi
    ''
    ""
  ];

  dm = [
    "util" "exec" "--" "bash" "-c"
    ''
      set -euo pipefail

      # Parse args: look for -b <bookmark> flag
      bookmark=""
      message=""
      while [[ $# -gt 0 ]]; do
        case "$1" in
          -b|--bookmark)
            bookmark="$2"
            shift 2
            ;;
          *)
            message="$1"
            shift
            ;;
        esac
      done

      if [[ -z "$message" ]]; then
        echo "Usage: jj dm [-b <bookmark>] <message>" >&2
        exit 1
      fi

      jj describe -m "$message"

      # Use explicit bookmark or find closest
      if [[ -z "$bookmark" ]]; then
        bookmark=$(jj log -r 'closest_bookmark(@)' --no-graph \
          -T 'self.bookmarks().map(|b| b.name()).join(",")' 2>/dev/null | head -1)
      fi

      # Move bookmark if found and not main
      if [[ -n "$bookmark" && "$bookmark" != "main" ]]; then
        jj bookmark set "$bookmark" -r @
        echo "Moved bookmark '$bookmark' to @"
      fi
    ''
    ""
  ];

  # ─────────────────────────────────────────────────────────────
  # Workflow aliases
  # ─────────────────────────────────────────────────────────────

  # jj up [branch] - Fetch and rebase onto origin (default: main)
  up = [
    "util" "exec" "--" "bash" "-c"
    ''
      set -euo pipefail
      jj git fetch
      jj rebase -d "''${1:-main}@origin"
    ''
    ""
  ];

  # jj feat [-b <bookmark>] [message] - Create new feature branch from main@origin
  feat = [
    "util" "exec" "--" "bash" "-c"
    ''
      set -euo pipefail
      
      bookmark=""
      message=""
      args=()
      
      while [[ $# -gt 0 ]]; do
        case "$1" in
          -b|--bookmark)
            [[ -z "''${2:-}" ]] && echo "Error: -b requires a bookmark name" >&2 && exit 1
            bookmark="$2"
            shift 2
            ;;
          *)
            args+=("$1")
            shift
            ;;
        esac
      done
      
      if [[ ''${#args[@]} -gt 0 ]]; then
        message="''${args[*]}"
      fi
      
      if [[ -z "$bookmark" && -z "$message" ]]; then
        echo "Usage: jj feat [-b <bookmark>] [message]"
        echo "Examples:"
        echo "  jj feat -b my-feat             # Start 'my-feat' from main@origin"
        echo "  jj feat -b my-feat \"wip\"     # Start 'my-feat' with message"
        echo "  jj feat \"wip\"                  # Start on main@origin with message (no bookmark)"
        exit 0
      fi
      
      jj git fetch
      jj new main@origin
      
      if [[ -n "$message" ]]; then
        jj describe -m "$message"
      fi
      
      if [[ -n "$bookmark" ]]; then
        if jj bookmark list | rg -q "^$bookmark:"; then
          jj bookmark set "$bookmark" -r @ -B
          echo "Moved existing bookmark '$bookmark' to @"
        else
          jj bookmark create "$bookmark" -r @
          echo "Created feature bookmark: $bookmark"
        fi
      fi
    ''
    ""
  ];

  # jj feat-here [-b <bookmark>] [message] - Create feature branch from current (no fetch)
  feat-here = [
    "util" "exec" "--" "bash" "-c"
    ''
      set -euo pipefail
      
      bookmark=""
      message=""
      args=()
      
      while [[ $# -gt 0 ]]; do
        case "$1" in
          -b|--bookmark)
            [[ -z "''${2:-}" ]] && echo "Error: -b requires a bookmark name" >&2 && exit 1
            bookmark="$2"
            shift 2
            ;;
          *)
            args+=("$1")
            shift
            ;;
        esac
      done
      
      if [[ ''${#args[@]} -gt 0 ]]; then
        message="''${args[*]}"
      fi
      
      if [[ -z "$bookmark" && -z "$message" ]]; then
        echo "Usage: jj feat-here [-b <bookmark>] [message]"
        echo "Examples:"
        echo "  jj feat-here -b my-feat         # Start 'my-feat' from current"
        echo "  jj feat-here \"wip\"              # Continue with message (no bookmark)"
        exit 0
      fi
      
      jj new
      
      if [[ -n "$message" ]]; then
        jj describe -m "$message"
      fi
      
      if [[ -n "$bookmark" ]]; then
        if jj bookmark list | rg -q "^$bookmark:"; then
          jj bookmark set "$bookmark" -r @ -B
          echo "Moved existing bookmark '$bookmark' to @ (from current position)"
        else
          jj bookmark create "$bookmark" -r @
          echo "Created feature bookmark: $bookmark (from current position)"
        fi
      fi
    ''
    ""
  ];

  # jj co <branch> - Smart checkout: fetch, switch to branch (or create if missing)
  co = [
    "util" "exec" "--" "bash" "-c"
    ''
      set -euo pipefail
      if [[ -z "''${1:-}" ]]; then
        echo "Usage: jj co <branch-name>" >&2
        exit 1
      fi

      # Capture previous position before switching
      prev_bookmark=$(jj log -r @ --no-graph -T 'local_bookmarks.join(", ")' 2>/dev/null)
      prev_change=$(jj log -r @ --no-graph -T 'change_id.shortest()' 2>/dev/null)

      jj git fetch

      # Check if branch exists on origin
      if jj log -r "$1@origin" --no-graph -T 'commit_id.short()' 2>/dev/null | grep -q .; then
        echo "Switching to remote branch: $1@origin"
        jj new "$1@origin"
        jj bookmark track "$1@origin" 2>/dev/null || true
      # Check if local bookmark exists
      elif jj log -r "$1" --no-graph -T 'commit_id.short()' 2>/dev/null | grep -q .; then
        echo "Switching to local bookmark: $1"
        jj new "$1"
        echo "Ready to work on top of $1"
      else
        # Create new branch from main@origin
        echo "Branch $1 not found, creating from main@origin..."
        jj new main@origin -m "feat: $1"
        jj bookmark create "$1" -r @
        echo "Created new branch: $1"
      fi

      # Show previous position for easy return
      if [[ -n "$prev_bookmark" ]]; then
        echo "Previous position: $prev_bookmark ($prev_change)"
      else
        echo "Previous position: $prev_change (no bookmark)"
      fi
    ''
    ""
  ];
  checkout = [ "co" ];
  switch = [ "co" ];

  # jj pr-fix ["msg"] - New commit on PR branch, describe, push with confirmation
  pr-fix = [
    "util" "exec" "--" "bash" "-c"
    ''
      set -euo pipefail

      # Find closest bookmark (PR branch)
      bookmark=$(jj log -r 'closest_bookmark(@)' --no-graph \
        -T 'self.bookmarks().map(|b| b.name()).join(",")' 2>/dev/null | head -1)

      if [[ -z "$bookmark" || "$bookmark" == "main" ]]; then
        echo "Error: No feature bookmark found. Create one first:" >&2
        echo "  jj bookmark create <name>" >&2
        exit 1
      fi

      echo "Working on bookmark: $bookmark"

      # Create new commit and describe
      jj new
      if [[ -n "''${1:-}" ]]; then
        jj describe -m "$1"
      else
        jj describe
      fi

      # Move bookmark to new commit
      jj bookmark move "$bookmark" --to @

      # Confirm push
      echo ""
      jj log -r "$bookmark"
      echo ""
      read -p "Push $bookmark to origin? [y/N] " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        jj git push --bookmark "$bookmark"
      else
        echo "Skipped push. Run: jj git push --bookmark $bookmark"
      fi
    ''
    ""
  ];

  # jj fixup - Squash into parent commit on PR branch, push with confirmation
  fixup = [
    "util" "exec" "--" "bash" "-c"
    ''
      set -euo pipefail

      # Check we have changes
      if jj log -r @ --no-graph -T 'if(empty, "true", "false")' | grep -q 'true'; then
        echo "Error: Current change is empty, nothing to squash" >&2
        exit 1
      fi

      # Find bookmark on parent (where we're squashing into)
      bookmark=$(jj log -r 'closest_bookmark(@-)' --no-graph \
        -T 'self.bookmarks().map(|b| b.name()).join(",")' 2>/dev/null | head -1)

      if [[ -z "$bookmark" || "$bookmark" == "main" ]]; then
        echo "Error: No feature bookmark on parent commit" >&2
        exit 1
      fi

      echo "Squashing into bookmark: $bookmark"
      jj squash

      # Confirm push
      echo ""
      jj log -r "$bookmark"
      echo ""
      read -p "Push $bookmark to origin? [y/N] " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        jj git push --bookmark "$bookmark"
      else
        echo "Skipped push. Run: jj git push --bookmark $bookmark"
      fi
    ''
    ""
  ];

  # jj pr [--base <branch>] [gh-args...] - Push bookmark and create GitHub PR
  pr = [
    "util" "exec" "--" "bash" "-c"
    ''
      set -euo pipefail

      # Parse args: extract --base, collect rest for gh
      base="main"
      gh_args=()
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --base)
            base="$2"
            shift 2
            ;;
          *)
            gh_args+=("$1")
            shift
            ;;
        esac
      done

      # Find closest bookmark
      bookmark=$(jj log -r 'closest_bookmark(@)' --no-graph \
        -T 'self.bookmarks().map(|b| b.name()).join(",")' 2>/dev/null | head -1)

      if [[ -z "$bookmark" ]]; then
        echo "Error: No bookmark found. Create one first:" >&2
        echo "  jj bookmark create <name>" >&2
        exit 1
      fi

      if [[ "$bookmark" == "main" ]]; then
        echo "Error: Can't create PR from main. Create a feature bookmark first:" >&2
        echo "  jj feat <name>" >&2
        exit 1
      fi

      echo "Creating PR for bookmark: $bookmark (base: $base)"

      # Push the bookmark first
      echo "Pushing $bookmark..."
      jj git push -b "$bookmark"

      # Create the PR (--fill uses commit info for title/body)
      gh pr create --head "$bookmark" --base "$base" --fill "''${gh_args[@]}"
    ''
    ""
  ];

  # jj done - Clean up after PR merged: delete bookmark, switch to main, fetch & rebase
  done = [
    "util" "exec" "--" "bash" "-c"
    ''
      set -euo pipefail

      # Get current bookmark
      bookmark=$(jj log -r @ --no-graph \
        -T 'self.bookmarks().map(|b| b.name()).join(",")' 2>/dev/null | head -1)

      if [[ -z "$bookmark" || "$bookmark" == "main" ]]; then
        echo "Error: Not on a feature bookmark (current: ''${bookmark:-none})" >&2
        exit 1
      fi

      echo "Cleaning up after merged PR..."
      echo "  Deleting bookmark: $bookmark"
      jj bookmark delete "$bookmark"

      echo "  Switching to main..."
      jj edit main

      echo "  Fetching latest..."
      jj git fetch

      echo "  Rebasing main onto origin..."
      jj rebase -d main@origin -r main

      echo "Done! You're now on main at the latest."
    ''
    ""
  ];
}
