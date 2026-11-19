---
name: github
description: "Interact with GitHub using the `gh` CLI. Use `gh issue`, `gh pr`, `gh run`, and `gh api` for issues, PRs, CI runs, and advanced queries. Use when creating a PR or pushing to one: it covers watching CI until green."
---

# GitHub Skill

Use the `gh` CLI to interact with GitHub. Always specify `--repo owner/repo` when not in a git directory, or use URLs directly.

## Pull Requests

Check CI status on a PR:

```bash
gh pr checks 55 --repo owner/repo
```

List recent workflow runs:

```bash
gh run list --repo owner/repo --limit 10
```

View a run and see which steps failed:

```bash
gh run view <run-id> --repo owner/repo
```

View logs for failed steps only:

```bash
gh run view <run-id> --repo owner/repo --log-failed
```

## Writing PR bodies, reviews and comments

Get to the point: no greeting, thanks, praise or friendly intro.

- **Review comments and summaries:** open with the verdict and what blocks merge, then what is good to have, then cleanup and the rest. One item per bullet with `path:line`.
- **PR bodies:** open with what changed and why, then how it was verified, then anything the reviewer must decide or know before merging.
- Show the final text to the user and post only after their explicit OK on it. Post with `--body-file`, so the posted text is exactly what they approved.

## Images in PRs, issues and comments

Attach screenshots with `--attach` (gh 2.99+, on `gh pr create|edit|comment` and `gh issue create|edit|comment`); never commit them or upload them elsewhere. Reference the local file in the body and attach the same file: gh uploads it and rewrites the path. In private repos only people with repo access can see it.

```bash
# body.md: ![Login error state](./login.png)
gh pr create --body-file body.md --attach ./login.png
```

## After creating or pushing to a PR

Watch CI until every check passes. Approvals and review state don't count; only checks, workflows and builds do.

1. Checks can take up to a minute to register after a push. Until then `gh pr checks <pr>` says "no checks reported"; wait and retry rather than treating that as green.
2. Watch to completion: `gh pr checks <pr> --watch --fail-fast --interval 30`. It exits 0 when all checks pass and non-zero on a failure. Runs often take 10+ minutes: in Pi, launch it with `interactive_shell` mode `dispatch` so you are woken when it ends, or use bash with a timeout of at least 30 minutes.
3. On failure, read `gh run view <run-id> --log-failed` and find the cause:
   - Code failure (tests, formatting, lint, compile warnings): fix it, run the same check locally, commit, push, then go back to step 1. Ask before pushing if the user hasn't approved pushes for this task.
   - Infrastructure flake (DNS, network, runner, registry outage): `gh run rerun <run-id> --failed`, then go back to step 2. Tell the user it was a flake.
4. Report the PR as done only when every check passes. Never stop at "CI is running", and never skip or ignore a failing check.

## API for Advanced Queries

The `gh api` command is useful for accessing data not available through other subcommands.

Get PR with specific fields:

```bash
gh api repos/owner/repo/pulls/55 --jq '.title, .state, .user.login'
```

## JSON Output

Most commands support `--json` for structured output. You can use `--jq` to filter:

```bash
gh issue list --repo owner/repo --json number,title --jq '.[] | "\(.number): \(.title)"'
```
