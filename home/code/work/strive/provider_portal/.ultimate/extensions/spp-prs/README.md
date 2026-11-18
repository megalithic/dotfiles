Seth's open provider_portal pull requests in merge order, with draft, CI and review state, and manual gates that stay unknown until he confirms them.

## Panel

**My PRs** (right panel, or ⌘K → "My PRs") asks GitHub when it opens and when you press Refresh; it never polls.

- **Order:** a pull request whose base branch is another one's head is stacked on it: it follows its parent, indented. Pull requests on `main` start stacks, oldest number first. Nothing is read from PR bodies.
- **Per row:** number (opens GitHub), title, `draft`, CI rolled up from every check (`fail` wins, then `running`; opens the checks tab), the review decision (empty on stacked branches, which have no review rule until retargeted), `conflicts` or `behind base`, and the conversation working on that branch (a worktree on the branch or at its head commit; the topmost, most recently active one).
- **Gates:** what GitHub cannot know, such as "after #12: run the migration" on #13. A gate shows on the pull request it holds back as `unknown` until Seth presses **confirm**; it disappears once that pull request is no longer open.

The panel gives no "ready to merge" verdict: CI, review and gates stay separate.

## Actions

- `list` → `{status: 'ok', at, rows}` or `{status: 'setup', reason}` when `gh` is missing or signed out. Read-only: one `gh pr list --author @me` and one `git worktree list` in the project root.
- `addGate {blocks, after?, text}` → the gate, added as `unknown` (text 1–200 characters). Agents may call it: `await ultimate.action('spp-prs', 'addGate', {blocks: 13, after: 12, text: 'run the migration'})`. The same `blocks`, `after` and text returns the existing gate.
- `confirmGate {id}` and `removeGate {id}` are user-only (`userActions`): codemode calls are rejected, so only Seth's click confirms.

Gates live in the `spp-prs.gates` document on the root conversation; agents read it with `ultimate.doc('spp-prs.gates', 1)`.

## Deploying

Versioned in dotfiles at `home/code/work/strive/provider_portal/.ultimate/extensions/spp-prs/` and linked per file by `mise run update:dotfiles`. Edits to the dotfiles copies do not reload the running provider_portal Ultimate: stop and start it with `mega` (with Seth's OK). Type-check with `node ~/code/oss/ultimate/scripts/check-extension.ts <this folder>`.
