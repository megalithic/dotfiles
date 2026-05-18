---
id: dot-dylm
status: open
deps: []
links: [dot-kts9, dot-0oy1]
created: 2026-05-13T20:48:05Z
type: epic
priority: 1
assignee: Seth Messer
parent: dot-0fjk
tags: [ready-for-development]
---
# Build custom nvim+pi vision integration

Seeded from ~/.local/share/pi/plans/dotfiles/nvim-pi-custom-vision_TASK.md and ~/.local/share/pi/plans/dotfiles/nvim-pi-custom-vision_PLAN.md.

Extend primary `pinvim.ts` ↔ `pinvim.lua` link with XDG state directories, explicit peer identity, ranked discovery, parked tmux pi sessions, explicit structured context sends/queues, structured review bundles, and editor-aware policy injection. Borrow capture/ranking ideas from `vision.nvim`, but keep `pinvim.ts` and `config/nvim/lua/pinvim.lua` as semantic owners of nvim↔pi behavior. Current implicit `live_context`/`editor_state` is being removed; future live context must be explicit, same-window/handshaked, pi-acknowledged, and visibly injected in conversation if reintroduced. `bridge.ts` is targeted for deprecation into focused ingress extensions (`pinvim.ts`, possible `hs.ts`, `tmux.ts`, `ntfy.ts`, tell/delegation owner) after current users are inventoried.

Relevant files span `home/common/programs/pi-coding-agent/`, `config/nvim/`, `config/hammerspoon/`, and `bin/`.

## Acceptance Criteria

1. Child tickets exist for all 9 implementation steps in `nvim-pi-custom-vision_PLAN.md`.
2. Planned work preserves `pinvim.ts` ↔ `pinvim.lua` as primary nvim communication path; `vision.nvim` ideas are additive, not a transport replacement.
3. Any remaining `bridge.ts` involvement is temporary shim/legacy support only, not semantic ownership of nvim context, handshake state, review state, or policy decisions; focused replacement extensions are planned.
4. Planned work keeps ephemeral sockets explicit-only and never auto-selects them during discovery; nvim split creation may explicitly switch the current nvim instance to its newly spawned ephemeral socket.
5. Primary nvim split UX spawns a fresh ephemeral pi instance by default, immediately pairs nvim to that new socket, preserves the previous target, restores it when the split closes, and still supports explicit user-driven swapping among active pi instances.
6. Final integrated result is verifiable with `just home`, `nvim --headless '+lua require("pinvim").setup()' +qa`, `bin/pinvim-protocol-smoke`, plus tmux+nvim manual smoke tests for primary pinvim link, explicit send/queue flows, parked flows, ephemeral split/restore flows, explicit target switching, and any still-shimmed non-nvim ingress compatibility.

## Verification

For any implementation change under this pinvim/vision workstream, run:

1. `just home`
2. `nvim --headless '+lua require("pinvim").setup()' +qa`
3. `bin/pinvim-protocol-smoke` — deterministic mock Unix-socket test that asserts nvim sends `hello`, receives `hello_ack`, sends `heartbeat`, receives heartbeat response, and `require("pinvim").setup().health()` reports `ok`.

For research-only tickets, run these before closing any downstream implementation ticket that uses the research.

