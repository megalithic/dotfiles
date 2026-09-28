---
description: Force-resync an env branch or its PR to latest main, preserving the empty marker commit
---

Resync target `$1` (branch name, PR number, or PR URL — required) to the latest `origin/main`, replicating the team's established force-push pattern. Follow these steps in order.

## Background: the pattern

Env branches (staging, sandbox, dev, UAT, demo, or any other long-lived deploy branch) are kept as: **entire latest `main` history + one empty "marker" commit on top** (e.g. a commit titled `Staging` with no diff). The marker commit keeps the PR open/diffable (≥1 commit vs base) — without it, GitHub auto-closes the PR once head equals base, killing the PR and its review app. Never drop the marker. Refreshing means: rewrite the branch to latest main + re-cherry-picked marker commit, then force-push with a lease. The marker's original author is preserved; the committer becomes whoever refreshed.

## 1. Resolve the target

- If `$1` is empty → **ask** which branch or PR to target.
- If `$1` is a number or PR URL → resolve the head branch:
  ```bash
  gh pr view $1 --json headRefName,baseRefName,state,url
  ```
  Use `headRefName` as the branch. Confirm base is `main` and state is `OPEN`.
- Otherwise → `$1` is the branch name. Optionally find its PR: `gh pr list --head <branch> --state open`.

## 2. Verify the pattern holds

```bash
git fetch origin main <branch>
git log --oneline origin/main..origin/<branch>
git diff --quiet origin/<branch>~1 origin/<branch> && echo "EMPTY MARKER" || echo "HAS DIFF"
```

- Expect exactly **one** commit ahead of main, and it must be an **empty** commit (the marker).
- Record the marker commit SHA (`git rev-parse origin/<branch>`) — call it `OLD_SHA`. It is both the lease value and the cherry-pick source.
- **STOP and ask** if: more than one commit ahead, the top commit has a diff, or the branch is not behind main at all (nothing to do). Never force-push over real commits.

## 3. Rebuild the branch (detached, no local branches touched)

```bash
git checkout --detach origin/main
git cherry-pick --allow-empty OLD_SHA
```

Verify: `git log --oneline -3` shows marker commit on top of latest main tip.

## 4. Force-push with lease

```bash
git push --force-with-lease=<branch>:OLD_SHA origin HEAD:<branch>
```

- The lease guarantees the push fails if a teammate moved the branch meanwhile — safe, no clobbering.
- If the lease fails: re-fetch and restart from step 2.

## 5. Verify and clean up

```bash
git checkout -  # back to previous branch
git log --oneline origin/main..origin/<branch>   # exactly the one marker commit
git log --oneline origin/<branch>..origin/main   # empty (0 behind)
gh pr view <PR#> --json state,headRefOid          # OPEN, head = new marker SHA
```

Report: old SHA → new SHA, PR link, confirm main was never touched (only `<branch>` ref moved).
