return {
  "2kabhishek/seeker.nvim",
  dependencies = { "folke/snacks.nvim" },
  cmd = { "Seeker" },
  keys = {
    -- { "<leader>fa", ":Seeker files<CR>", desc = "Seek Files" },
    -- { "<leader>ff", ":Seeker git_files<CR>", desc = "Seek Git Files" },
    { "<leader>a", ":Seeker grep<CR>", desc = "Seek Grep" },
    -- {
    --   "<leader>A",
    --   mode = { "n", "x", "v" },
    --   function() require("snacks").picker.grep_word() end,
    --   desc = "grep cursor/selection",
    -- },
  },
  opts = {
    picker_provider = "snacks", -- Picker provider: 'snacks' or 'telescope' (default: 'snacks')
    toggle_key = "<C-r>", -- Key to toggle between modes (default)
    picker_opts = {},
  }, -- Required unless you call seeker.setup() manually, add your configs here
}
