Seth's open provider_portal pull requests in merge order, with draft, CI and review state, and manual gates that stay unknown until he confirms them.

## Panel

**My PRs** (right panel, or ⌘K → "My PRs") asks GitHub when it opens and when you press Refresh; it never polls.

- **Order:** a pull request whose base branch is another one's head is stacked on it: it follows its parent, indented. Pull requests on `main` start stacks, oldest number first. Nothing is read from PR bodies.
- **Per row:** number (opens GitHub), title, `draft`, CI rolled up from every check (`fail` wins; `pass` only when every check succeeded, was neutral or skipped; anything else, such as running or stale, is `pending`; opens the checks tab), the review decision (empty on stacked branches, which have no review rule until retargeted), `next:` who approves (the requested users and teams, or `non-author` when none are named; never the author; `unknown` when GitHub gives no review decision; hidden once approved; hovering names the author), `conflicts` or `behind base`, and the conversation working on that branch (a worktree on the branch or at its head commit; the topmost, most recently active one).
- **Review comments:** `N to act` (asks for a change) and `N to answer` (asks a question), then `unresolved/total` threads; hovering lists each item, and the tags open the first one. Waiting on Seth: the last comment of each unresolved thread that is not outdated and not his own, plus review bodies and PR comments by others since he last commented. Rules decide first (`rule` in `lib.ts`): bots, thanks, LGTM and emoji need nothing; a suggestion block, `[P1]`-style finding, `nit:`, or a request in the opening sentence (please, should, can you…) is a change; a sentence ending in `?` is a question; an approval's write-up needs nothing. What no rule decides goes to the `tiny` family's model (marked `*`) once per comment version, cached by comment id + `updatedAt` in the `spp-prs.judged` document; with no model it counts as a question. On stacked branches with no review decision, others' latest reviews give `changes requested`, `approved` or `commented`.
- **Gates:** what GitHub cannot know, such as "after #12: run the migration" on #13. A gate shows on the pull request it holds back as `unknown` until Seth presses **confirm**; it disappears once that pull request is no longer open.

The panel gives no "ready to merge" verdict: CI, review and gates stay separate.

## Actions

- `list` → `{status: 'ok', at, rows}` (each row carries `author` and `next: {state: 'awaiting' | 'approved' | 'unknown', requested}`, from `gh pr list`'s `author` and `reviewRequests`) or `{status: 'setup', reason}` when `gh` is missing or signed out. Read-only: one `gh pr list --author @me`, one `gh api graphql` query for review threads, reviews and comments (rows lose `feedback` if it fails), and one `git worktree list` in the project root. Nothing is posted to GitHub.
- `addGate {blocks, after?, text}` → the gate, added as `unknown` (text 1–200 characters). Agents may call it: `await ultimate.action('spp-prs', 'addGate', {blocks: 13, after: 12, text: 'run the migration'})`. The same `blocks`, `after` and text returns the existing gate.
- `confirmGate {id}` and `removeGate {id}` are user-only (`userActions`): codemode calls are rejected, so only Seth's click confirms.

Gates live in the `spp-prs.gates` document on the root conversation; agents read it with `ultimate.doc('spp-prs.gates', 1)`.

## Deploying

Versioned in dotfiles at `home/code/work/strive/provider_portal/.ultimate/extensions/spp-prs/` and linked per file by `mise run update:dotfiles`. After a change lands, compare `server.loadedAt` for `spp-prs` in `ultimate.extensions()` with the commit time; restart the provider_portal Ultimate with `mega` (with Seth's OK) only if it did not reload. Type-check with `node ~/code/oss/ultimate/scripts/check-extension.ts <this folder>`.
