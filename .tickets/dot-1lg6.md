---
id: dot-1lg6
status: open
deps: [dot-yjzp]
links: []
created: 2026-05-01T21:20:46Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-r5vb
tags: [ready-for-development, nvim, jj, difftool]
---
# nvim Step 6: Port iofq :Diffedit wrapper + wire built-in nvim.difftool

Port iofq's ':Diffedit' wrapper for 'jj diffedit --tool difftool' and activate the built-in 'nvim.difftool' plugin (Neovim 0.12+). Includes a jj-aware qflist FileType autocmd (replaces iofq's git-coupled version).

Plan: ~/.local/share/pi/plans/dotfiles/nvim-jj-iofq-port_PLAN.md (Step 6)
Depends on: dot-yjzp (Step 2 — appends to lua/utils/jj.lua)
Note: ':Diffedit' won't fully work end-to-end until Step 7 (dot-XXXX) adds the jj merge-tools.difftool entry to nix.

References:
- ~/.cache/pi-internet/github-repos/iofq/nvim.nix@master/nvim/after/lua/iofq/jj.lua
- ~/.cache/pi-internet/github-repos/iofq/nvim.nix@master/nvim/after/plugin/autocmd.lua (lines 32-101)
- https://neovim.io/doc/user/plugins/#standard-plugin-list (nvim.difftool API)

## What
- Pre-flight: confirm 'nvim --version | head -1' reports >= 0.12 (required for nvim.difftool)
- Append to 'config/nvim/lua/utils/jj.lua':
  - 'M.diffedit(opts)' → vim.fn.jobstart('jj diffedit --tool difftool ' .. (opts.args or ''))
  - 'M.is_jj_diffedit_open()' → checks vim.fn.getqflist({0})[1].user_data.diff; if absent, force-deletes any /tmp/jj-diff* buffers; returns 0/1
  - 'vim.api.nvim_create_user_command("Diffedit", M.diffedit, { nargs = "*" })'
- Decide and add 'vim.cmd.packadd("nvim.difftool")' in either 'config/nvim/init.lua' or 'config/nvim/after/plugin/init.lua' (whichever already does packadd-style setup; pick one and document in code comment)
- Create new file 'config/nvim/after/plugin/jj_difftool.lua' (cleaner than appending to autocmds.lua) containing the FileType=qf augroup adapted from iofq, BUT:
  - REMOVE all 'git diff --quiet', 'git ls-files', 'git restore --staged', 'git add' calls
  - Highlight all qflist entries with 'Added' (no staging concept in jj) — leave a 'TODO: integrate jj squash -i for staging' comment
  - DROP the 'gh' keymap entirely (no jj equivalent for stage-toggle)
  - Keep the conflict-marker → qflist scanner ONLY IF testing shows our existing unclash-based flow is insufficient; otherwise omit entirely (we have unclash)

## Why
- ':Diffedit' lets you launch jj's interactive hunk-edit flow from nvim, opening the difftool side-by-side
- nvim.difftool ships with nvim 0.12+ (no plugin spec needed, just packadd) and provides ':DiffTool {left} {right}' + qflist integration
- The qflist autocmd polishes the review UI when a difftool session populates qflist with user_data.diff entries

## Acceptance Criteria

1. 'nvim --version | head -1' reports >= 0.12
2. 'config/nvim/lua/utils/jj.lua' contains M.diffedit, M.is_jj_diffedit_open, and the 'Diffedit' user command registration
3. 'rg "packadd.*nvim.difftool" config/nvim/' returns exactly 1 match
4. Manual: ':DiffTool /tmp/a /tmp/b' (after 'mkdir -p /tmp/a /tmp/b && echo x > /tmp/a/f && echo y > /tmp/b/f') opens a side-by-side diff with a qflist
5. Manual: ':Diffedit' is a registered command ('nvim -c ":command Diffedit" -c qa' shows it). End-to-end run depends on Step 7's nix config landing.
6. 'rg "git diff --quiet|git restore|git ls-files|git add --" config/nvim/after/plugin/jj_difftool.lua' returns no matches (jj-aware, not git-coupled)
7. Manual: ':lua require([[utils.jj]]).is_jj_diffedit_open()' callable, returns 0 outside the flow
8. No regressions: ':lua require([[mini.diff]])' still works, prior steps' acceptance still pass

