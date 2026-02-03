{
  config,
  pkgs,
  username,
  hostname,
  ...
}: {
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = "Seth Messer";
        email = "seth@megalithic.io";
      };
      ui = {
        # paginate = "never";
        default-command = "log";
        pager = "${pkgs.delta}/bin/delta";
        diff-formatter = ":git";
        # diff-formatter = "nvim "$LOCAL" "$REMOTE" +"CodeDiff file $LOCAL $REMOTE""$LOCAL\" \"$REMOTE\"";
        graph.style = "curved";
        should-sign-off = true;
        show-cryptographic-signatures = true;
      };
      signing = {
        behavior = "own";
        backend = "ssh";
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICyxphJ0fZhJP6OQeYMsGNQ6E5ZMVc/CQdoYrWYGPDrh";
        backends.ssh = {
          program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
          allowed-signers = "${config.home.homeDirectory}/.ssh/allowed_signers";
        };
      };

      # Auto-update stale workspaces when switching between them
      # Critical for jj workspace workflow with multiple concurrent working copies
      snapshot.auto-update-stale = true;

      colors = {
        commit_id = "magenta";
        change_id = "cyan";
        "working_copy empty" = "green";
        "working_copy placeholder" = "red";
        "working_copy description placeholder" = "yellow";
        "working_copy empty description placeholder" = "green";
        prefix = {
          bold = true;
          fg = "cyan";
        };
        rest = {
          bold = false;
          fg = "bright black";
        };
        "node elided" = "yellow";
        "node working_copy" = "green";
        "node conflict" = "red";
        "node immutable" = "red";
        "node normal" = {bold = false;};
        "node" = {bold = false;};
      };
      # git = {
      #   sign-on-push = true;
      #   write-change-id-header = true;
      # };
      aliases = {
        # Basic shortcuts
        s = ["status"];
        l = ["log"];
        ll = ["log" "-T" "builtin_log_compact_full_description"];
        d = ["diff"];
        rb = ["rebase"];
        b = ["bookmark"];
        g = ["git"];
        push = ["git" "push"];
        dv = ["desc"];
        dm = ["desc" "-m"];
        main = ["bookmark" "move" "main" "--to" "@"];
        # Advances closest bookmark to parent commit
        tug = ["bookmark" "move" "--from" "closest_bookmark(@-)" "--to" "@-"];

        # ─────────────────────────────────────────────────────────────
        # Workflow aliases (using jj util exec for multi-command ops)
        # ─────────────────────────────────────────────────────────────

        # jj up [branch] - Fetch and rebase onto origin (default: main)
        up = ["util" "exec" "--" "bash" "-c" ''
          set -euo pipefail
          jj git fetch
          jj rebase -d "''${1:-main}@origin"
        '' ""];

        # jj feat <bookmark-name> - Create new feature branch from main@origin
        feat = ["util" "exec" "--" "bash" "-c" ''
          set -euo pipefail
          if [[ -z "$1" ]]; then
            echo "Usage: jj feat <bookmark-name>" >&2
            exit 1
          fi
          jj git fetch
          jj new main@origin -m "feat: $1"
          jj bookmark create "$1" -r @
          echo "Created feature branch: $1"
        '' ""];

        # jj feat-here <bookmark-name> - Create feature branch from current position (no fetch)
        feat-here = ["util" "exec" "--" "bash" "-c" ''
          set -euo pipefail
          if [[ -z "$1" ]]; then
            echo "Usage: jj feat-here <bookmark-name>" >&2
            exit 1
          fi
          jj new -m "feat: $1"
          jj bookmark create "$1" -r @
          echo "Created feature branch: $1 (from current position)"
        '' ""];

        # jj co <branch> - Smart checkout: fetch, switch to branch (or create if missing)
        # Aliases: checkout, switch
        # Priority: 1) origin branch, 2) local bookmark, 3) create new from main@origin
        co = ["util" "exec" "--" "bash" "-c" ''
          set -euo pipefail
          if [[ -z "$1" ]]; then
            echo "Usage: jj co <branch-name>" >&2
            exit 1
          fi

          jj git fetch

          # Check if branch exists on origin (use valid template, check for output)
          if jj log -r "$1@origin" --no-graph -T 'commit_id.short()' 2>/dev/null | grep -q .; then
            echo "Switching to remote branch: $1@origin"
            jj new "$1@origin"
            jj bookmark track "$1@origin" 2>/dev/null || true
          # Check if local bookmark exists
          elif jj log -r "$1" --no-graph -T 'commit_id.short()' 2>/dev/null | grep -q .; then
            echo "Switching to local bookmark: $1"
            jj new "$1"
          else
            # Create new branch from main@origin
            echo "Branch $1 not found, creating from main@origin..."
            jj new main@origin -m "feat: $1"
            jj bookmark create "$1" -r @
            echo "Created new branch: $1"
          fi
        '' ""];
        checkout = ["co"];
        switch = ["co"];

        # jj pr-fix ["msg"] - New commit on PR branch, describe, push with confirmation
        # (Note: "fix" is a built-in jj command for code formatters)
        pr-fix = ["util" "exec" "--" "bash" "-c" ''
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
          if [[ -n "$1" ]]; then
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
        '' ""];

        # jj fixup - Squash into parent commit on PR branch, push with confirmation
        fixup = ["util" "exec" "--" "bash" "-c" ''
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
        '' ""];
      };
      revsets = {
        log = "current_work";
      };
      revset-aliases = {
        "stack()" = "ancestors(reachable(@, mutable()), 2)";
        "stack(x)" = "ancestors(reachable(x, mutable()), 2)";
        "stack(x, n)" = "ancestors(reachable(x, mutable()), n)";
        "current_work" = "trunk()..@ | @..trunk() | trunk() | @:: | fork_point(trunk() | @)";
        "closest_bookmark(to)" = "heads(::to & bookmarks())";
      };
      template-aliases = {
        "format_short_id(id)" = "id.shortest()";
        "abbreviate_timestamp_suffix(s, suffix, abbr)" = ''
          if(
              s.ends_with(suffix),
              s.remove_suffix(suffix) ++ label("timestamp", abbr)
          )
        '';
        "abbreviate_relative_timestamp(s)" = ''
          coalesce(
              abbreviate_timestamp_suffix(s, " millisecond", "ms"),
              abbreviate_timestamp_suffix(s, " second", "s"),
              abbreviate_timestamp_suffix(s, " minute", "m"),
              abbreviate_timestamp_suffix(s, " hour", "h"),
              abbreviate_timestamp_suffix(s, " day", "d"),
              abbreviate_timestamp_suffix(s, " week", "w"),
              abbreviate_timestamp_suffix(s, " month", "mo"),
              abbreviate_timestamp_suffix(s, " year", "y"),
              s
          )
        '';
        "format_timestamp(timestamp)" = ''
          coalesce(
              if(timestamp.after("1 minute ago"), label("timestamp", "<=1m")),
              abbreviate_relative_timestamp(timestamp.ago().remove_suffix(' ago').remove_suffix('s'))
          )
        '';
      };
      templates = {
        # pad_end(4, format_short_change_id_with_hidden_and_divergent_info(self)),
        log = ''
          if(root,
            format_root_commit(self),
            label(if(current_working_copy, "working_copy"),
              concat(
                separate(" ",
                  pad_end(4, format_short_change_id(change_id)),
                  if(empty, label("empty", "(empty)")),
                  if(description,
                    description.first_line(),
                    label(if(empty, "empty"), description_placeholder),
                  ),
                  bookmarks,
                  tags,
                  working_copies,
                  if(git_head, label("git_head", "HEAD")),
                  if(conflict, label("conflict", "conflict")),
                  if(config("ui.show-cryptographic-signatures").as_boolean(),
                    format_short_cryptographic_signature(signature)),
                  format_timestamp(commit_timestamp(self)),
                ) ++ "\n",
              ),
            )
          )
        '';
        log_node = ''
          label("node",
            coalesce(
              if(!self, label("elided", "~")),
              if(current_working_copy, label("working_copy", "@")),
              if(conflict, label("conflict", "×")),

              if(immutable, label("immutable", "*")),
              label("normal", "·")
            )
          )
        '';
        draft_commit_description = ''
          concat(
            coalesce(description, default_commit_description, "\n"),
            if(
              config("ui.should-sign-off").as_boolean() && !description.contains("Signed-off-by: " ++ author.name()),
              "\nSigned-off-by: " ++ author.name() ++ " <" ++ author.email() ++ ">",
            ),
            surround(
              "\nJJ: This commit contains the following changes:\n", "",
              indent("JJ:     ", diff.stat(72)),
            ),
            "\nJJ: ignore-rest\n",
            diff.git(),
          )
        '';
      };
    };
  };
}
