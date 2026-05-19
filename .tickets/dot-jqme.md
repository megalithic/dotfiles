---
id: dot-jqme
status: open
deps: []
links: []
created: 2026-05-19T13:22:47Z
type: epic
priority: 2
assignee: Seth Messer
---
# Improve Neovim startup/render performance

Improve Neovim startup time, first-file render time, and pinvim transport responsiveness. This epic groups two focused work streams: lazy-loading heavy Neovim/Treesitter plugins, and completing pinvim async/caching cleanup across nvim, pi extension, and tmux wrapper.

Relevant files:
- config/nvim/lua/plugins/treesitter.lua
- config/nvim/lua/plugins/init.lua
- config/nvim/lua/plugins/snacks/init.lua
- config/nvim/lua/plugins/refer.lua
- config/nvim/lua/plugins/git.lua
- config/nvim/lua/pinvim.lua
- home/common/programs/pi-coding-agent/extensions/pinvim.ts
- home/common/programs/pi-coding-agent/extensions/bridge.ts
- bin/pimux

## Acceptance Criteria

1. Child tickets cover plugin/Treesitter lazy-load work and pinvim async transport cleanup.
2. Each child ticket has clear file hints and independently verifiable acceptance criteria.
3. Before/after Neovim startuptime summaries are captured in child ticket work or commit notes.
4. Epic can be closed when child tickets are closed.

