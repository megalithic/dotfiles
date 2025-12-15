-- REF:
-- - https://github.com/ViViDboarder/vim-settings/blob/master/neovim/lua/lazy/obsidian.lua
-- - https://github.com/joelazar/nvim-config/blob/main/lua/plugins/obsidian.lua

return {
  "obsidian-nvim/obsidian.nvim",
  version = "*", -- recommended, use latest release instead of latest commit
  lazy = true,
  ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "hrsh7th/nvim-cmp",
    "nvim-treesitter/nvim-treesitter",
  },
  ---@module 'obsidian'
  ---@type obsidian.config.ClientOpts
  opts = {
    workspaces = {
      {
        name = "notes",
        path = vim.env.NOTES_HOME,
      },
    },

    daily_notes = {
      folder = "daily",
    },
    completion = {
      -- Enables completion using nvim_cmp
      nvim_cmp = vim.g.completer == "cmp",
      -- Enables completion using blink.cmp
      blink = vim.g.completer == "blink",
      -- Trigger completion at 2 chars.
      min_chars = 0,

      create_new = true,
    },
    note_id_func = function(title)
      local suffix = ""
      if title ~= nil then
        -- If title is given, transform it into valid file name.
        suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", "")
      else
        -- If title is nil, just add 4 random uppercase letters to the suffix.
        for _ = 1, 4 do
          suffix = suffix .. string.char(math.random(65, 90))
        end
      end
      return suffix
    end,
    picker = {
      -- REF: https://github.com/obsidian-nvim/obsidian.nvim/blob/main/lua/obsidian/config/init.lua#L36
      name = "snacks.pick",
    },
    checkbox = {},
    ui = {
      -- use render-markdown instead for these
      enable = false,
      bullets = {},
      external_link_icon = {},
    },
  },
}
