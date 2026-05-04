---
id: dot-j34v
status: closed
deps: [dot-1lg6]
links: []
created: 2026-05-01T21:21:04Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-r5vb
tags: [ready-for-development, nix, jj, difftool]
---
# nvim Step 7: Author jj difftool config in nix (home/common/programs/jj/default.nix)

Add the 'merge-tools.difftool' entry to home-manager jj settings so 'jj diffedit --tool difftool' (used by ':Diffedit' from Step 6) actually launches nvim's difftool plugin.

Plan: ~/.local/share/pi/plans/dotfiles/nvim-jj-iofq-port_PLAN.md (Step 7)
Depends on: dot-1lg6 (Step 6 — :Diffedit wrapper expects this nix entry to make the cli work)
Reference: 'home/common/programs/jj/default.nix' (currently 73 LOC, no merge-tools entry)
Neovim docs: https://neovim.io/doc/user/plugins/#standard-plugin-list (example for git, adapted for jj)

## What
- Edit 'home/common/programs/jj/default.nix', add to 'programs.jujutsu.settings':
  "merge-tools" = {
    difftool = {
      program = "nvim";
      diff-args = [ "-c" "packadd nvim.difftool" "-d" "$left" "$right" ];
    };
  };
- Place the block between 'snapshot.auto-update-stale' and 'remotes.origin.auto-track-bookmarks' OR adjacent to the existing 'templates' block — pick the location that reads well in context.
- Run 'just validate home' to confirm the home-manager build succeeds
- Run 'just home' to apply (note in commit message that this is required for Step 6 keymap to work end-to-end)

## Why
- jj's '--tool difftool' resolves to whatever's defined under merge-tools.<name> — without this entry, ':Diffedit' errors with 'no such tool'
- Using nvim.difftool (built-in in nvim 0.12+) keeps everything in one editor, no external diff tool needed

## Acceptance Criteria

1. 'rg -n "merge-tools" home/common/programs/jj/default.nix' shows the new block
2. 'just validate home' succeeds (no nix eval errors)
3. After 'just home': 'jj config get merge-tools.difftool.program' outputs 'nvim'
4. After 'just home': 'jj config get-list merge-tools.difftool.diff-args' outputs '-c', 'packadd nvim.difftool', '-d', '$left', '$right' (in some form — verify the array round-trips)
5. Manual end-to-end: in a jj repo with pending changes, 'jj diffedit --tool difftool' (from cli) opens nvim with side-by-side diff via packadd nvim.difftool
6. Manual end-to-end: inside an existing nvim, ':Diffedit' triggers the same flow via the wrapper from Step 6
7. Existing programs.jujutsu.settings (user, ui, signing, snapshot, remotes, colors, templates, aliases) unchanged — diff is purely additive

