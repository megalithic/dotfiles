---
id: dot-4mns
status: open
deps: [dot-913o, dot-yjzp, dot-9zvo, dot-0srj, dot-o2jq, dot-1lg6, dot-j34v, dot-wj6e, dot-ljfm]
links: []
created: 2026-05-01T21:22:21Z
type: task
priority: 2
assignee: Seth Messer
parent: dot-r5vb
tags: [ready-for-development, nvim, jj, verification]
---
# nvim Step 10: Smoke test + cleanup verification

End-to-end smoke test of the entire jj/mini.diff/diffedit/keymap port. No code changes — verification only.

Plan: ~/.local/share/pi/plans/dotfiles/nvim-jj-iofq-port_PLAN.md (Step 10)
Depends on: ALL preceding steps (dot-913o, dot-yjzp, dot-9zvo, dot-0srj, dot-o2jq, dot-1lg6, dot-j34v, dot-wj6e, dot-ljfm)

## What
Run all of these in a jj repo with pending changes (use a scratch repo or your dotfiles):

1. Open nvim — confirm no errors
2. Verify mini.diff signs render for tracked files
3. REGRESSION TEST: 'echo new > /tmp/x && cp /tmp/x ./newfile.txt && nvim newfile.txt' — column shows full-add signs
4. ':JJDiff @--' — signs reflect 2-back base, picker reflects too
5. ':JJPDiff' — toggles back to @-
6. Trigger snacks jj diff picker — entries match base_rev
7. <leader>jf, <leader>jl, <leader>ja, <leader>je, <leader>jd, <leader>jh — all respond
8. ':Diffedit' — launches difftool flow (needs Step 7's nix applied)
9. ':Neogit' — opens status buffer
10. <leader>fx — opens unclash conflicts picker (synthesize with 'echo "<<<<<<< HEAD" > c.txt' if needed)
11. <localleader>J — treesj split/join works
12. <leader>gs / <leader>gl / <leader>gb — snacks pickers open
13. ':checkhealth mini.diff' — jj source attached, no hg
14. blink.cmp ripgrep source — completion menu shows [rg] entries

## Cleanup verification

- 'rg "neojj|neojjit|MiniHg|hg_root|get_hg_root|MiniJJDiff|MiniJJPDiff" config/nvim/' returns NO matches
- 'just validate home && just validate darwin' both succeed
- 'jj st' in dotfiles repo — uncommitted changes are sane (no debug artifacts, no leftover .lua.bak files, no console prints)

## Acceptance Criteria

1. nvim opens cleanly in a jj repo (no startup errors)
2. mini.diff signs render for tracked files with pending changes
3. REGRESSION: new untracked file shows mini.diff add-signs in column (the headline bug fix)
4. :JJDiff @-- changes the reference rev; mini.diff signs and snacks picker both reflect it
5. :JJPDiff toggles correctly between @- and @--
6. All 6 jj.nvim keymaps (<leader>j{a,f,l,h,e,d}) respond and open their respective UIs
7. :Diffedit launches the difftool flow end-to-end (requires Step 7 applied via 'just home')
8. :Neogit opens, q closes
9. <leader>fx opens unclash conflicts picker in a repo with conflict markers
10. <localleader>J triggers treesj
11. <leader>gs / <leader>gl / <leader>gb open snacks git_status / git_log / git_branches
12. blink.cmp completion shows [rg]-tagged entries from project files in a jj-only repo
13. ':checkhealth mini.diff' confirms jj source attached, no hg references
14. 'rg "neojj|neojjit|MiniHg|hg_root|get_hg_root|MiniJJDiff|MiniJJPDiff" config/nvim/' returns no matches
15. 'just validate home' and 'just validate darwin' both succeed
16. Existing keymaps (]x/[x, <localleader>c{c,o,i,t,b}, <leader>gco, <leader>gd mini.diff overlay, ]h/[h hunk nav, <leader>hr reset, ih textobject) still work — no regressions

