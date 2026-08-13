---
name: spp-updates
description: Summarize the latest provider portal (SPP) updates merged to main in the EVIRTSHEALTH/rx repo but not yet deployed to production, by comparing the production build's git SHA (from https://rx.strivepharmacy.com/api/version) against origin/main and filtering to provider_portal-related PRs. For each un-deployed SPP PR it prints the number, GitHub URL, title, and Asana link (omitted when the PR description has none). Use when the user asks "spp updates", "provider portal updates", "what's new in the provider portal", "latest spp changes", "spp prod diff", or "what spp work is pending release". Output is a plain formatted list only — makes no code changes and opens nothing.
---

# SPP updates — un-deployed provider portal PRs between production and main

Produces a summarized list of provider portal (SPP) pull requests that are
merged into `main` but not yet running in production, by diffing the production
build's git SHA against `origin/main` and keeping only provider_portal-related
PRs.

## Prerequisites

- `gh` CLI authenticated for the `EVIRTSHEALTH/rx` repo.
- Run from inside the `rx` repository checkout.

## Workflow

### 1. Resolve the production SHA

Fetch the live build metadata and read the `git_sha` field:

```bash
curl -s https://rx.strivepharmacy.com/api/version
```

The JSON looks like `{"git_branch":"...","git_date":"...","git_sha":"0ba74103","git_tag":"..."}`.
Capture `git_sha` (an abbreviated commit, ~8 chars) — this is the deployed commit.

### 2. Refresh main and confirm the SHA is reachable

```bash
git fetch origin main --quiet
git cat-file -t <prod_sha>
```

If `git cat-file` does not print `commit`, the local repo doesn't have that
object yet — run `git fetch origin` (all refs) and retry. If it still can't be
found, stop and tell the user the prod SHA isn't in the repo (likely a
force-push or an unfetched commit) rather than guessing.

### 3. Collect the un-deployed PR numbers

List the commits on `main` that are ahead of production and pull the
squash-merge PR numbers out of the commit subjects (one per subject):

```bash
git log --pretty=tformat:%s <prod_sha>..origin/main | grep -oE '\(#[0-9]+\)' | tr -d '(#)'
```

Preserve this order — `git log` returns newest-first, which is the order to
print. Keep it de-duplicated but stable (don't sort). Commits without a `(#NNN)`
marker (direct pushes, merge commits) simply won't contribute a PR and can be
ignored; if there are commits ahead but *zero* PR numbers, say so.

### 4. Fetch PR details and filter to provider_portal PRs

For every PR number, in order:

```bash
gh pr view <num> --json number,title,url,body,author,files
```

Run the `gh` calls concurrently where possible to keep it fast.

Keep a PR when **any** of these match (union):

1. **Title tag:** title contains `[spp]` (case-insensitive).
2. **Files touched:** any changed file path starts with one of:
   - `lib/rx/provider_portal/`
   - `lib/rx_web/provider_portal/`
   - `test/rx/provider_portal/`
   - `test/rx_web/provider_portal/`
3. **SPP author:** the PR author login is one of:
   - `megalithic`
   - `r-icarus`
   <!-- TODO: add Philip's GitHub handle once he's in the EVIRTSHEALTH org -->

Discard PRs matching none of the three. If nothing survives the filter, report
that main is ahead of production but contains no provider portal changes.

**Asana link:** extract the first Asana URL from the PR body:

```bash
gh pr view <num> --json body -q .body | grep -oiE 'https://app\.asana\.com/[^ )]*' | head -1
```

If this is empty, the PR has no Asana link — **omit the `Asana Link:` line
entirely** for that PR (do not print an empty or placeholder line).

### 5. Print the summary

Emit each PR as a block, newest-first, separated by a line of 40 `─` (U+2500)
characters. Exact format:

```text
PR: #980 (https://github.com/EVIRTSHEALTH/rx/pull/980)
Title: [spp] align Patient and Provider views
Asana Link: https://app.asana.com/0/0/1234567890
────────────────────────────────────────
PR: #987 (https://github.com/EVIRTSHEALTH/rx/pull/987)
Title: [spp] move version badge into drawer
Asana Link: https://app.asana.com/0/0/1234567891
```

Rules for the output:

- One block per PR, in `git log` order (newest first).
- The `Asana Link:` line is present only when the PR body contained an Asana
  URL; otherwise the block is just the `PR:` and `Title:` lines.
- Use the separator line between blocks, not after the last one.
- Output the list only — no preamble, no trailing commentary, unless the user
  asked a follow-up question.

## Edge cases

- **Nothing ahead:** if `git log <prod_sha>..origin/main` is empty, report that
  production is up to date with `main`.
- **Ahead but no SPP work:** if commits are ahead but no PR passes the filter,
  say main is ahead of production with N PRs, none provider portal-related.
- **Version endpoint unreachable:** if the `curl` fails or returns no
  `git_sha`, stop and report it; do not fall back to a hardcoded SHA.
