-- REF:
-- - https://github.com/ViViDboarder/vim-settings/blob/master/neovim/lua/lazy/obsidian.lua
-- - https://github.com/joelazar/nvim-config/blob/main/lua/plugins/obsidian.lua

-- Pattern definitions: each entry contains a pattern and optional default time values
local patterns = {
  {
    name = "ISO datetime",
    pattern = "^(%d%d%d%d)-(%d%d)-(%d%d)[T ](%d%d):(%d%d)",
    defaults = {},
  },
  {
    name = "compact datetime",
    pattern = "^(%d%d%d%d)(%d%d)(%d%d)(%d%d)(%d%d)$",
    defaults = {},
  },
  {
    name = "ISO date",
    pattern = "^(%d%d%d%d)-(%d%d)-(%d%d)$",
    defaults = { hour = 0, min = 0 },
  },
}

-- Parse date strings and convert to YYYYMMDDHHMM timestamp format
-- Supported formats:
--   - ISO datetime: "2025-01-01T00:00" or "2025-01-01 00:00"
--   - Compact datetime: "202501010000"
--   - ISO date only: "2025-01-01" (time defaults to 00:00)
local function convert_date(date_string)
  local year, month, day, hour, min

  -- Try each pattern until one matches
  for _, config in ipairs(patterns) do
    local captures = { date_string:match(config.pattern) }
    if #captures > 0 then
      year, month, day = captures[1], captures[2], captures[3]
      hour = captures[4] or config.defaults.hour
      min = captures[5] or config.defaults.min
      break
    end
  end

  if not year then return nil end

  -- Create date table for os.time
  local date_table = {
    year = tonumber(year),
    month = tonumber(month),
    day = tonumber(day),
    hour = tonumber(hour) or 0,
    min = tonumber(min) or 0,
    sec = 0,
  }

  -- Convert to timestamp
  local timestamp = os.time(date_table)

  -- Format using os.date
  return os.date("%Y%m%d%H%M", timestamp)
end

return {
  "obsidian-nvim/obsidian.nvim",
  version = "*", -- recommended, use latest release instead of latest commit
  -- lazy = true,
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
      min_chars = 1,
      -- create_new = false,
    },
    -- Preserve custom frontmatter fields (source_app, source_url, created, etc.)
    -- Without this, obsidian.nvim strips custom fields when it manages frontmatter
    -- note_frontmatter_func = function(note)
    --   if note.title then note:add_alias(note.title) end
    --
    --   local out = { id = note.id, aliases = note.aliases, tags = note.tags }
    --
    --   -- CRITICAL: Preserve all custom fields from captures
    --   if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
    --     for k, v in pairs(note.metadata) do
    --       out[k] = v
    --     end
    --   end
    --
    --   return out
    -- end,

    frontmatter = {
      sort = { "id", "title", "date", "aliases", "tags" },
      -- Customize the frontmatter data.
      ---@return table
      func = function(note)
        -- -- NOTE: `note.id` is NOT frontmatter id but rather the name of the note, for the frontmatter it's note.metadata.id
        -- local out = {
        --   aliases = note.aliases,
        --   tags = note.tags,
        -- }
        --
        -- -- `note.metadata` contains any manually added fields in the frontmatter.
        -- -- So here we just make sure those fields are kept in the frontmatter.
        -- if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
        --   for k, v in pairs(note.metadata) do
        --     out[k] = v
        --   end
        -- end
        --
        -- if not note.metadata.title then out.title = note.title or note.id end
        --
        -- -- Add the title of the note as an alias.
        -- note:add_alias(note.title or note.id)
        --
        -- local validated_id = tostring(convert_date(note.id))
        -- -- We run this at the end so we have access to metadata too
        -- out.id = validated_id ~= "nil" and validated_id
        --   or tostring(convert_date(note.metadata.date or os.date("%Y%m%d%H%M")))
        --
        -- return out

        if note.title then note:add_alias(note.title) end

        local out = { id = note.id, aliases = note.aliases, tags = note.tags }

        -- CRITICAL: Preserve all custom fields from captures
        if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
          for k, v in pairs(note.metadata) do
            out[k] = v
          end
        end

        return out
      end,
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

    picker = { name = "snacks.pick" },
    -- picker = {
    --   name = "snacks.pick",
    --   note_mappings = {
    --     new = "<C-n>", -- Create new note from query
    --     insert_link = "<C-l>", -- Insert [[link]] to selected note
    --   },
    --   tag_mappings = {
    --     tag_note = "<C-t>", -- Add tag(s) to current note
    --     insert_tag = "<C-l>", -- Insert #tag at cursor
    --   },
    -- },

    -- Smart keybindings for markdown files (via callbacks, not deprecated mappings)
    callbacks = {
      enter_note = function(client, note)
        local api = require("obsidian.api")

        -- Smart action: follows links OR toggles checkboxes based on context
        vim.keymap.set(
          "n",
          "<cr>",
          function() return api.smart_action() or "<CR>" end,
          { buffer = true, expr = true, desc = "Obsidian smart action" }
        )

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
