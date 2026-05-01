---
id: dot-cfj5
status: open
deps: []
links: [dot-r5vb]
created: 2026-05-01T20:17:26Z
type: feature
priority: 2
assignee: Seth Messer
tags: [nvim, jj, mini.diff, research]
---
# nvim: port jj/mini.diff patterns from iofq/nvim.nix

Evaluate iofq/nvim.nix's jj integration and port the missing pieces into our nvim config without losing the capabilities we already have.

Research + audit doc: ~/.local/share/pi/plans/dotfiles/nvim-jj-iofq-port_TASK.md
Backup of currently-touched files: ~/.local/share/pi/plans/dotfiles/nvim-jj-iofq-port/backup/

## What we have (config/nvim/)
- lua/plugins/jj.lua — krisajenkins/neojj + JulianNymark/neojjit (NicolasGB/jj.nvim spec is commented out)
- lua/plugins/mini/diff.lua — custom mini.diff source factory with jj + hg + git, base-rev switching (:MiniJJDiff/:MiniJJPDiff), debounced fs_event, hunk nav (]h/[h), reset (<leader>hr), textobject (ih), overlay toggle (<leader>gd)
- lua/utils/vcs.lua — get_jj_root / get_hg_root with caching
- lua/plugins/snacks/jj.lua — snacks picker over 'jj diff --config ui.diff-formatter=:git'
- after/plugin/statusline.lua — async jj cache (change_id/bookmarks/conflict), Augroup mega.ui.statusline.jj, suppresses git seg in jj repos
- lua/themes/{megaforest,megagrove}.lua — StJj* highlights
- lua/icons.lua — mega.ui.icons.jj = { symbol='◇', conflict=...}
- plugin/autocmds.lua — jjdescription excluded from trim-on-save
- lua/plugins/whichkey.lua — <localleader>g group label 'git/jj'

## What iofq has that we don't
- :Diffedit wrapper around 'jj diffedit --tool difftool' (lua/iofq/jj.lua)
- Conflict markers <<<<<<< → qflist autocmd (autocmd.lua:78-101)
- <leader>j* keymap namespace via NicolasGB/jj.nvim: ja=annotate, jf=status, jj=log, jh=file_history, jd=open_vdiff{rev='trunk()'}, je=Diffedit
- '.jj' added to blink.cmp ripgrep project_root_marker
- Bundled nvim.difftool plugin (packadd)

## What we should NOT lose
- Custom mini.diff factory + hg parity
- Base-rev switching commands
- Debounced fs_event (iofq fires every event)
- Existing hunk keymaps and view glyphs

## Plan sketch (refine via /plan)
1. Decide: replace neojj+neojjit with NicolasGB/jj.nvim, or coexist
2. Add ported :Diffedit user-command (research whether to author the difftool script too)
3. Add conflict-marker → qflist BufWinEnter autocmd (keep wo.diff guard, or relax)
4. Add <leader>j* keymaps wired to jj.nvim pickers/cmds (or our snacks picker for status)
5. Add '.jj' to blink.cmp ripgrep project_root_marker (currently disabled but mark for completeness)
6. Decide on bundled nvim.difftool (packadd) — is the upstream plugin even available outside nix?
7. Verify: NVIM_APPNAME=next nvim — open a jj repo, confirm signs render, :MiniJJDiff still works, new keymaps respond, conflict autocmd fires on synthetic <<<<<<< marker

## Open questions (see TASK.md §3)
1. Replace or coexist with neojj/neojjit?
2. <leader>j* namespace vs extending <localleader>g 'git/jj' group?
3. Author difftool script in ~/.config/jj/config.toml?
4. Conflict autocmd: keep wo.diff guard?
5. Keep is_jj_diffedit_open if we don't author the difftool script?
6. Snacks jj diff picker vs jj.nvim picker.status?

## Acceptance criteria
1. Backup exists at ~/.local/share/pi/plans/dotfiles/nvim-jj-iofq-port/backup/ (DONE — see above)
2. /plan run produces a step-by-step PLAN.md with one ticket per step
3. After implementation: NVIM_APPNAME=next nvim opens cleanly in a jj repo, mini.diff signs still appear, :MiniJJDiff still works, and any new keymaps/commands listed in the plan are wired up
4. All open questions in TASK.md §3 have an answer recorded in the PLAN.md notes section before any code changes are committed

