Shows the shown conversation's pull request in the composer status line: `#123`, coloured by its state, linking to it.

The PR comes from `~/bin/rwt pr`, the same lookup `rwt status`, `rwt prune` and the pi footer use (one `gh pr list --head <branch>`, cached 60 s per worktree). It runs in the conversation's workspace or cwd; a checkout on its default branch, without a PR, or outside git shows nothing.

Colours: yellow checks running, blue waiting (draft or review), green ready to merge, red failed checks or conflicts, purple merged, grey closed. Dimmed when gh was unreachable and the chip shows the last known state. Hover for checks and review.

It refreshes when the conversation starts or finishes a run, on window focus and every two minutes.

## Action

`pr-status/pr` (no arguments): the `rwt pr` object, or null.

## Reload

After a change lands, compare this extension's `server.loadedAt` in `ultimate.extensions()` with the commit time; restart the host only if it did not reload.
