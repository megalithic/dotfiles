-- lua/plugins/github.lua
-- GitHub review plugins

return {
  -- justinmk/guh.nvim — minimal GitHub PR/issue/CI viewer + reviewer.
  -- Used for the `pr` review scope in pinvim review workflows.
  -- Requires: Nvim 0.13+, `gh` CLI authenticated.
  -- Optional: vim-fugitive (git), diffs.nvim (diff hl), render-markdown.nvim.
  {
    "justinmk/guh.nvim",
    cmd = "Guh",
    keys = {
      { "<leader>ghp", "<cmd>Guh<cr>", desc = "github: status / PRs / issues" },
      { "<leader>gh.", "<cmd>Guh .<cr>", desc = "github: object at cursor" },
    },
  },
}
