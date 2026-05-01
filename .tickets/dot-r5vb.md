---
id: dot-r5vb
status: open
deps: []
links: [dot-cfj5]
created: 2026-05-01T20:29:08Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-cfj5
tags: [nvim, jj, mini.diff, research]
---
# nvim: refresh mini.diff (madmaxieee) + adopt NicolasGB/jj.nvim + iofq Diffedit difftool

Port iofq/nvim.nix's :Diffedit + jj difftool integration, swap our jj plugin to NicolasGB/jj.nvim, and refresh our mini.diff source against the latest madmaxieee/nvim-config (which ours was originally modeled on).

Research + audit: ~/.local/share/pi/plans/dotfiles/nvim-jj-iofq-port_TASK.md
Backup: ~/.local/share/pi/plans/dotfiles/nvim-jj-iofq-port/backup/
Supersedes earlier scoping ticket: dot-cfj5

## Confirmed direction
- Use NicolasGB/jj.nvim (drop krisajenkins/neojj + JulianNymark/neojjit)
- Port iofq's :Diffedit + 'jj diffedit --tool difftool' + the qf review autocmd
- Refresh mini.diff against madmaxieee upstream
- Skip iofq's <<<<<<< → qflist autocmd (we already use unclash.nvim with richer conflict tooling)
- Keymap layout decided during /plan — see TASK.md §3 for full inventory and §4.4 strawmen

## madmaxieee changes to evaluate (TASK.md §2.2)
1. Bug fix: new-file fallback (file missing from base rev → check working copy → empty ref text vs no ref text). Real bug we currently carry.
2. base_rev centralized in utils/jj.lua, commands renamed :JJDiff / :JJPDiff (was :MiniJJ*)
3. co2 coroutine helper (lua/co2.lua) for cleaner async
4. File split: mini-diff/{init,jj-source,make-source}.lua
5. HG support REMOVED upstream (we still have it — decision needed)
6. Snacks jj picker uses --from <base_rev> (keeps picker in sync after :JJDiff <rev>)
7. should_enable runs once at setup (replaces source with no-op stub outside jj repos)
8. New: <leader>fx → unclash.snacks.pick() — pick from conflicting files

## iofq surfaces to port (TASK.md §1)
- :Diffedit user command + jobstart('jj diffedit --tool difftool ...')
- is_jj_diffedit_open() helper (cleans /tmp/jj-diff* buffers)
- Difftool/qf review augroup (FileType=qf) — note: iofq's version is git-coupled, must be jj-aware for us
- '.jj' added to blink.cmp project_root_marker
- nvim.difftool packadd — needs investigation (may be internal/bundled fork)
- Author ~/.config/jj/config.toml [merge-tools.difftool] entry to drive nvim correctly

## Skip
- iofq's BufWinEnter <<<<<<< → qflist autocmd (redundant with unclash.nvim)

## Keymap conflicts to resolve
- <leader>j taken by treesj.toggle (single key) → iofq's <leader>j* namespace would clobber. Strawman A uses <localleader>j* (free). Strawman B promotes to <leader>j* and moves treesj.
- <leader>h is global replace-word + parent of <leader>hr (mini.diff reset) — works via which-key longest-prefix but feels brittle. Note in plan, leave as-is unless user wants change.
- <leader>gd is mini.diff toggle_overlay; iofq's <leader>jd is vdiff vs trunk — no clash if we land on <localleader>jd.

## Open questions (TASK.md §5)
1. hg: drop or keep?
2. Keymap layout: A (<localleader>j*) or B (<leader>j* + relocate treesj)?
3. Command names: :JJDiff/:JJPDiff or keep :MiniJJ* prefix?
4. co2 coroutine helper: adopt?
5. File split for mini.diff: monolith vs split?
6. Author difftool config in this ticket or follow-up?
7. nvim.difftool plugin: source it, write minimal driver, or skip?
8. <leader>fx unclash.snacks.pick(): pull in?
9. Rebind freed <leader>gs / <leader>gl after dropping neojj/neojjit?

## Acceptance criteria
1. Backup exists at ~/.local/share/pi/plans/dotfiles/nvim-jj-iofq-port/backup/ (DONE)
2. /plan output is a step-by-step PLAN.md, one ticket per step, dependencies wired
3. All 9 open questions answered in PLAN.md notes section before any code lands
4. After implementation: NVIM_APPNAME=next nvim opens cleanly in a jj repo, mini.diff signs render including for new files (regression test for the madmaxieee bug fix), :MiniJJDiff (or :JJDiff) still switches base rev, snacks jj picker reflects current base rev, jj.nvim keymaps respond, :Diffedit launches a usable hunk-edit flow
5. Conflict resolution flow via unclash still works end-to-end (no regression)
6. Old neojj/neojjit specs removed; no dangling references in lua/plugins/

