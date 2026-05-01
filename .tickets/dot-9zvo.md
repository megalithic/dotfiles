---
id: dot-9zvo
status: open
deps: [dot-yjzp]
links: []
created: 2026-05-01T21:19:46Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-r5vb
tags: [ready-for-development, nvim, jj, snacks]
---
# nvim Step 3: Update snacks jj picker to use --from <base_rev>

Wire the snacks jj diff picker to respect the current mini.diff base revision so the picker stays in sync after ':JJDiff <rev>'. Trivial change.

Plan: ~/.local/share/pi/plans/dotfiles/nvim-jj-iofq-port_PLAN.md (Step 3)
Depends on: dot-yjzp (Step 2 — needs utils/jj.lua to source base_rev)
Reference impl: ~/.cache/pi-internet/github-repos/madmaxieee/nvim-config/lua/plugins/snacks/jj.lua

## What
- Edit 'config/nvim/lua/plugins/snacks/jj.lua':
  - In 'jj_diff_finder', the 'args' table currently ends with ..., 'diff' }. Change to ..., 'diff', '--from', require('utils.jj').config.base_rev }
  - Add 'local jj_config = require("utils.jj").config' near the top (mirror madmaxieee structure)

## Why
- Without --from, the snacks picker always shows working-copy vs immediate parent diff, ignoring user's :JJDiff base. With --from, switching base via :JJDiff updates the picker too.

## Acceptance Criteria

1. 'config/nvim/lua/plugins/snacks/jj.lua' references 'require("utils.jj").config.base_rev' and includes '--from' in the jj args
2. Manual: open a jj repo with pending changes; trigger snacks jj diff picker; entries reflect '@-' base (default)
3. Manual: ':JJDiff @--' then re-trigger picker — entries now reflect '@--' base (different file set / line ranges)
4. Manual: ':JJPDiff' (back to @-) then re-trigger picker — entries match #2 again
5. Steps 1 and 2 acceptance criteria still pass (no regression)

