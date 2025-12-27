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
      date_format = "%Y/%Y%m%d", -- Creates daily/2025/20251224.md
    },
    attachments = {
      img_folder = "assets", -- Store images in vault's assets folder
    },
    completion = {
      blink = true,
      min_chars = 2,
      create_new = true,
    },

    -- Preserve custom frontmatter fields (source_app, source_url, created, etc.)
    -- Without this, obsidian.nvim strips custom fields when it manages frontmatter
    note_frontmatter_func = function(note)
      if note.title then
        note:add_alias(note.title)
      end

      local out = { id = note.id, aliases = note.aliases, tags = note.tags }

      -- CRITICAL: Preserve all custom fields from captures
      if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
        for k, v in pairs(note.metadata) do
          out[k] = v
        end
      end

      return out
    end,

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
      name = "snacks.pick",
      note_mappings = {
        new = "<C-n>",         -- Create new note from query
        insert_link = "<C-l>", -- Insert [[link]] to selected note
      },
      tag_mappings = {
        tag_note = "<C-t>",    -- Add tag(s) to current note
        insert_tag = "<C-l>",  -- Insert #tag at cursor
      },
    },

    -- Smart keybindings for markdown files (via callbacks, not deprecated mappings)
    callbacks = {
      enter_note = function(client, note)
        local api = require("obsidian.api")

        -- Smart action: follows links OR toggles checkboxes based on context
        vim.keymap.set("n", "<cr>", function()
          return api.smart_action() or "<CR>"
        end, { buffer = true, expr = true, desc = "Obsidian smart action" })

        -- gf for wiki links: follow link under cursor
        vim.keymap.set("n", "gf", function()
          local link = api.cursor_link()
          if link then
            api.follow_link()
          else
            -- Fallback to normal gf
            return vim.cmd("normal! gf")
          end
        end, { buffer = true, desc = "Go to file (obsidian)" })
      end,
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
