---
id: dot-yjzp
status: closed
deps: [dot-913o]
links: []
created: 2026-05-01T21:19:32Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-r5vb
tags: [ready-for-development, nvim, jj, mini.diff]
---
# nvim Step 2: Move base-rev commands to lua/utils/jj.lua, rename to :JJDiff / :JJPDiff

Centralize jj base_rev configuration in 'lua/utils/jj.lua' and rename the user commands from ':MiniJJDiff'/':MiniJJPDiff' to ':JJDiff'/':JJPDiff' (matches madmaxieee upstream). Extract a 'reload_all(name)' helper from the inline disable/enable loop.

Plan: ~/.local/share/pi/plans/dotfiles/nvim-jj-iofq-port_PLAN.md (Step 2)
Depends on: dot-913o (Step 1 — needs the refactored jj source / reload helper)

## What
- Create 'config/nvim/lua/utils/jj.lua' mirroring ~/.cache/pi-internet/github-repos/madmaxieee/nvim-config/lua/utils/jj.lua structure:
  - 'M.config = { base_rev = "@-" }'
  - ':JJDiff <rev>' user command — validates rev with 'jj log -r <rev> --no-graph -T ""', sets M.config.base_rev, calls 'make_source.reload_all("jj")' (require pcalled)
  - ':JJPDiff' toggles between '@-' and '@--'
  - 'M.find_root(path)' — re-export 'utils.vcs.get_jj_root' (or move the impl)
- Edit 'config/nvim/lua/plugins/mini/diff.lua':
  - Remove inline ':MiniJJDiff' / ':MiniJJPDiff' user commands and inline 'jj_config'
  - Read base_rev from 'require("utils.jj").config.base_rev'
  - Extract 'make_source.reload_all(name)' as a helper next to make_diff_source factory (so utils/jj.lua can call it)

## Why
- Match upstream naming convention (easier to adopt future patches from madmaxieee)
- Decouple base_rev state from the mini.diff plugin file (snacks picker also needs it — see Step 3)

## Acceptance Criteria

1. 'config/nvim/lua/utils/jj.lua' exists with M.config, :JJDiff, :JJPDiff, M.find_root
2. 'rg ":MiniJJDiff|:MiniJJPDiff|MiniJJ" config/nvim/' returns no matches
3. ':JJDiff' and ':JJPDiff' commands exist after nvim startup ('nvim -c ":command JJDiff" -c qa' shows the command)
4. ':MiniJJDiff' returns 'Not an editor command' (renamed)
5. Manual: in a jj repo, ':JJDiff @--' notifies 'jj: reference rev is set to @--', mini.diff signs re-attach reflecting 2-back base
6. Manual: ':JJPDiff' toggles between '@-' and '@--' (notifies each transition)
7. ':JJDiff bogus_rev' notifies 'jj: bogus_rev is not a valid rev' and does not change base
8. Step 1 acceptance criteria still pass (no regression)

