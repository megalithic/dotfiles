---
id: dot-f36u
status: in_progress
deps: [dot-y4vm]
links: []
created: 2026-05-13T20:48:05Z
type: feature
priority: 1
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---
# Bootstrap pinvim.lua + fresh pinvim.ts for nvim↔pi peer handshake work

Update Step 2 from ~/.local/share/pi/plans/dotfiles/nvim-pi-custom-vision_PLAN.md to start fresh on both sides of the nvim↔pi boundary. Create a new Neovim plugin entrypoint at config/nvim/after/plugin/pinvim.lua for all new nvim/pi work, living alongside the legacy config/nvim/after/plugin/pi.lua. Keep the new plugin disable-able through config/nvim/lua/settings.lua and the existing `Plugin_enabled()` helper. Verify the legacy `pi` plugin stays unloaded while developing `pinvim.lua`.

On the pi side, rename the current home/common/programs/pi-coding-agent/extensions/pinvim.ts implementation and its extension-specific references to `pinvim_legacy` so a new home/common/programs/pi-coding-agent/extensions/pinvim.ts can be created from a clean slate. Follow pi-coding-agent extension guidance in docs/extensions.md, examples/extensions/, home/common/programs/pi-coding-agent/AGENTS.md, and inline AGENT CONTEXT comments. Research and document idiomatic structure for a custom Neovim after/plugin entrypoint plus a custom pi extension with good performance, readability, maintainability, and clear state boundaries.

Files in scope:
- `config/nvim/lua/settings.lua`
- `config/nvim/after/plugin/pi.lua`
- `config/nvim/after/plugin/pinvim.lua`
- `config/nvim/lua/pinvim/` (new module area if needed)
- `home/common/programs/pi-coding-agent/extensions/bridge.ts`
- `home/common/programs/pi-coding-agent/extensions/pinvim.ts`
- `home/common/programs/pi-coding-agent/extensions/pinvim_legacy.ts`
- related comments/docs in `config/nvim/` and `home/common/programs/pi-coding-agent/`

## Acceptance Criteria

1. New Neovim entrypoint `config/nvim/after/plugin/pinvim.lua` exists, all new Step 2 nvim↔pi work is routed there, and it uses idiomatic guard/bootstrap structure with `Plugin_enabled()` so `pinvim` can be disabled independently of legacy `pi`.
2. Legacy `pi` plugin remains disabled and unloaded during this work. Verification includes a headless check proving `mega.p.pi` is not initialized when `pi` is listed in `vim.g.disabled_plugins`.
3. Existing `home/common/programs/pi-coding-agent/extensions/pinvim.ts` is renamed to `pinvim_legacy`, and extension-specific identifiers or references that would collide with a fresh `pinvim.ts` entrypoint are updated accordingly.
4. Fresh `home/common/programs/pi-coding-agent/extensions/pinvim.ts` scaffold follows pi extension best practices: auto-discovered from `extensions/`, minimal startup side effects, clear typed state, and clean separation from bridge transport details.
5. Ticket work captures the chosen structural guidance for performance and maintainability, including recommended split between thin after/plugin loader, reusable Lua modules, bridge transport, and pi extension state/rendering responsibilities.
6. Handshake work still targets explicit `hello` / `hello_ack` peer metadata with peer id, cwd/root, tmux identity, link mode, and heartbeat timestamps while preserving rollout compatibility.
7. `nvim --headless "+lua print('nvim ok')" +qa` and `just validate home` both pass after the bootstrap/rename work.

