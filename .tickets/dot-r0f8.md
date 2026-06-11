---
id: dot-r0f8
status: open
deps: 4:1:deps: 4:1:deps: [, dot-satx, dot-0v6y]
links: []
created: 2026-06-11T11:38:03Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Make pimux pane reuse pair-aware

Prevent pimux from focusing or restoring panes owned by another live pair during Nvim invocations. File hints: bin/pimux (PINVIM_FORWARD_ENV, candidate_sockets, find_pi_in_current_window, find_any_parked_pi_pane, find_pane_for_socket, find_preferred_pi_pane, @pimux.active_socket, @pimux.mru_sockets).

## Acceptance Criteria

1. PINVIM_PAIR_ID is forwarded into spawned Pi panes
2. Nvim-invoked pimux skips active/last/MRU/parked panes that belong to another live pair
3. Unpaired same-window panes can be claimed when eligible
4. Other tmux window/session panes are never claimed by normal Nvim path
5. pimux --new child behavior remains explicit-only
6. Existing home validation passes with devenv shell -- just validate home
