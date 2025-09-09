-- REF:
--
-- https://github.com/ViViDboarder/vim-settings/blob/master/neovim/lua/lazy/obsidian.lua
--

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
        path = "~/Documents/_notes",
        -- path = vim.g.notes_path,
      },

      --         {
      --           name = "notes",
      --           path = vim.env.OBSIDIAN_VAULT_DIR,
      --         },
      -- {
      --   name = "work",
      --   path = "~/vaults/work",
      -- },
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
      name = "telescope.nvim",
    },
    checkbox = {},
    ui = {
      -- use render-markdown instead for these
      enable = false,
      bullets = {},
      external_link_icon = {},
    },
  },
  -- config = function(_, opts)
  --   require("obsidian.nvim").setup(opts)

  --   -- vim.api.nvim_create_autocmd("User", {
  --   --   pattern = "ObsidianNoteEnter",
  --   --   callback = function(evt)
  --   --     vim.keymap.set("n", "<leader>ch", "<cmd>Obsidian toggle_checkbox<cr>", {
  --   --       buffer = ev.buf,
  --   --       desc = "Toggle checkbox",
  --   --     })
  --   --   end,
  --   -- })
  -- end,
}
-- return {
--   "epwalsh/obsidian.nvim",
--   -- the obsidian vault in this default config  ~/obsidian-vault
--   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand':
--   -- event = { "bufreadpre " .. vim.fn.expand "~" .. "/my-vault/**.md" },
--   event = { "BufReadPre  */obsidian-vault/*.md" },
--   dependencies = {
--     "nvim-lua/plenary.nvim",
--     "hrsh7th/nvim-cmp",
--     "nvim-telescope/telescope.nvim",
--     {
--       "AstroNvim/astrocore",
--       opts = {
--         mappings = {
--           n = {
--             ["gf"] = {
--               function()
--                 if require("obsidian").util.cursor_on_markdown_link() then
--                   return "<Cmd>ObsidianFollowLink<CR>"
--                 else
--                   return "gf"
--                 end
--               end,
--               desc = "Obsidian Follow Link",
--             },
--           },
--         },
--       },
--     },
--   },
--   opts = {
--     dir = vim.env.HOME .. "/obsidian-vault", -- specify the vault location. no need to call 'vim.fn.expand' here
--     use_advanced_uri = true,
--     finder = "telescope.nvim",

--     templates = {
--       subdir = "templates",
--       date_format = "%Y-%m-%d-%a",
--       time_format = "%H:%M",
--     },

--     note_frontmatter_func = function(note)
--       -- This is equivalent to the default frontmatter function.
--       local out = { id = note.id, aliases = note.aliases, tags = note.tags }
--       -- `note.metadata` contains any manually added fields in the frontmatter.
--       -- So here we just make sure those fields are kept in the frontmatter.
--       if note.metadata ~= nil and require("obsidian").util.table_length(note.metadata) > 0 then
--         for k, v in pairs(note.metadata) do
--           out[k] = v
--         end
--       end
--       return out
--     end,

--     -- Optional, by default when you use `:ObsidianFollowLink` on a link to an external
--     -- URL it will be ignored but you can customize this behavior here.
--     follow_url_func = vim.ui.open or function(url) require("astrocore").system_open(url) end,
--   },
-- }
