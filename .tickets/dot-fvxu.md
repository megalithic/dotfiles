---
id: dot-fvxu
status: in_progress
deps: []
links: []
created: 2026-05-19T13:22:47Z
type: task
priority: 2
assignee: Seth Messer
parent: dot-jqme
tags: [ready-for-development]
---
# Lazy-load heavy Neovim plugins and reduce Treesitter render overhead

Optimize Neovim startup and first-file render by lazy-loading heavy plugins and reducing Treesitter startup/render overhead. Recent profiling after pinvim quick wins shows pinvim no longer blocks startup, but several plugins still load eagerly or on every file read.

Profile findings:
- smart-splits.nvim: ~6-10ms, currently lazy=false in config/nvim/lua/plugins/init.lua.
- fff.nvim / fff-snacks.nvim: ~4-9ms, currently eager in config/nvim/lua/plugins/snacks/init.lua.
- refer.nvim: can pull blink.cmp, ~5-15ms, currently no lazy trigger in config/nvim/lua/plugins/refer.lua.
- unclash.nvim: ~1-3ms, currently lazy=false in config/nvim/lua/plugins/git.lua.
- nvim-ts-autotag: ~3ms on file read in config/nvim/lua/plugins/treesitter.lua.
- vim-matchup: ~3-4ms on BufReadPost in config/nvim/lua/plugins/treesitter.lua.
- treesitter-context: small load cost but ongoing scroll/render cost.
- rainbow-delimiters: ongoing Treesitter render cost.
- nvim-treesitter.install.install(parsers) runs during startup/init.

Relevant files:
- config/nvim/lua/plugins/treesitter.lua
- config/nvim/lua/plugins/init.lua
- config/nvim/lua/plugins/snacks/init.lua
- config/nvim/lua/plugins/refer.lua
- config/nvim/lua/plugins/git.lua
- config/nvim/lua/plugins/lsp/init.lua (only if blink/refer lazy-loading affects completion integration)

## Acceptance Criteria

1. smart-splits.nvim, fff.nvim, fff-snacks.nvim, refer.nvim, and unclash.nvim no longer load during empty-buffer startup unless explicitly triggered.
2. Existing keymaps/commands for smart-splits, fff/fff-snacks, refer, and unclash still work after lazy-loading.
3. Treesitter parser install/update no longer runs during normal startup; explicit update/build path remains available.
4. nvim-ts-autotag only loads for relevant filetypes or InsertEnter, not every file read.
5. vim-matchup, rainbow-delimiters, and treesitter-context are evaluated; each is either lazy/restricted/disabled or documented as intentionally kept.
6. nvim --headless --startuptime /tmp/nvim-start +qa shows top eager plugin blockers reduced, with before/after summary recorded in ticket notes or commit message.
7. nvim --headless +qa exits cleanly with no stderr.
8. nvim --headless +'sleep 600m' +qa exits cleanly with no stderr.
9. stylua succeeds on touched Lua files.

