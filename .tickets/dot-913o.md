---
id: dot-913o
status: closed
deps: []
links: []
created: 2026-05-01T21:19:13Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-r5vb
tags: [ready-for-development, nvim, jj, mini.diff]
---
# nvim Step 1: Refresh mini.diff jj source — adopt madmaxieee bug fix + co2, drop hg

Adopt the new-file fallback bug fix and co2 coroutine helper from madmaxieee/nvim-config; drop hg support entirely. Headline: new untracked files currently show NO mini.diff signs in our config — this is a silent bug we've been carrying.

Plan: ~/.local/share/pi/plans/dotfiles/nvim-jj-iofq-port_PLAN.md (Step 1)
Context: ~/.local/share/pi/plans/dotfiles/nvim-jj-iofq-port.ticket-context.md

## What
- Add 'config/nvim/lua/co2.lua' (verbatim from ~/.cache/pi-internet/github-repos/madmaxieee/nvim-config/lua/co2.lua)
- Edit 'config/nvim/lua/plugins/mini/diff.lua':
  - Remove the entire '-- Mercurial source' block (hg_config, hg_cmd, hg_opts, gen_custom_source.hg)
  - Remove ':MiniHgDiff' / ':MiniHgPDiff' user commands
  - Remove 'local get_hg_root' import
  - Replace jj 'async_get_ref_text' with a co2.wrap coroutine implementing the fallback:
    1. Try 'jj --ignore-working-copy file show -r <base_rev> -- <file>' — on success, callback(stdout)
    2. On failure, try 'jj file show -r @ -- <file>' — on success, callback('') (new file → diff vs empty → full-add render)
    3. If both fail, no callback (file is jj-ignored)
  - Update source list in setup() to: { gen_custom_source.jj(), gen_source.git(), gen_source.save(), gen_source.none() }
- Edit 'config/nvim/lua/utils/vcs.lua': remove get_hg_root, is_hg_root, hg_root_cache (leave get_jj_root)

## Why
- Bug fix: new untracked files currently show no mini.diff highlights (silent regression)
- Drop hg: we don't use mercurial; mirrors madmaxieee 71f08c0
- co2: cleaner async with the new fallback branch (less callback nesting)

## Acceptance Criteria

1. File 'config/nvim/lua/co2.lua' exists and is verbatim copy from madmaxieee
2. 'rg "hg|Mercurial|MiniHg|get_hg_root|is_hg_root" config/nvim/lua/' returns no matches in plugins/mini/diff.lua or utils/vcs.lua
3. 'nvim --headless "+lua print(require([[co2]]))" +qa' exits 0 with no errors
4. 'nvim --headless "+lua require([[mini.diff]]).setup() print(vim.inspect(require([[plugins.mini.diff]])))" +qa' exits 0 (plugin file loads cleanly)
5. Manual: in a jj repo, opening a tracked file shows mini.diff signs in the column
6. Manual REGRESSION TEST: in a jj repo, run 'echo foo > /tmp/newfile-test.txt && cd <jj-repo> && cp /tmp/newfile-test.txt . && nvim newfile-test.txt' — column shows add-signs for the new line(s)
7. ':checkhealth mini.diff' reports 'jj' source attached and does NOT mention 'hg'
8. No regressions to existing mini.diff hunk nav (]h/[h), textobject (ih), reset (<leader>hr), or overlay toggle (<leader>gd)

