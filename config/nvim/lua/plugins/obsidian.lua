-- Helper functions for template substitutions
local function get_notes_home() return vim.env.NOTES_HOME or (vim.env.HOME .. "/iclouddrive/Documents/_notes") end

--- Find the most recent daily note before today
--- Returns the path and filename of the previous daily note
---@return string|nil path Full path to previous daily note
---@return string|nil filename Just the filename (e.g., "20260105")
local function find_previous_daily_note()
  local notes_home = get_notes_home()
  local daily_dir = notes_home .. "/daily"

  -- Get today's date info
  local today = os.date("%Y%m%d")
  local year = os.date("%Y")

  -- Find all daily notes, sorted by name (which is date-based)
  local handle = io.popen(string.format("find '%s' -name '*.md' -type f 2>/dev/null | sort -r", daily_dir))
  if not handle then return nil, nil end

  local result = handle:read("*a")
  handle:close()

  -- Find the first note that's before today
  for path in result:gmatch("[^\n]+") do
    local filename = path:match("([^/]+)%.md$")
    if filename and filename < today then return path, filename end
  end

  return nil, nil
end

--- Extract incomplete tasks from a daily note file
---@param path string Path to the daily note
---@return string tasks Formatted task list or default tasks
local function extract_incomplete_tasks(path)
  local f = io.open(path, "r")
  if not f then
    -- Default tasks if no previous note
    return "- [ ] DAILY CHORES #life\n- [ ] Read book chapter #life"
  end

  local content = f:read("*a")
  f:close()

  -- Find ## Tasks section content (between ## Tasks and next ## or end)
  local tasks_section = content:match("## Tasks\n(.-)\n## ") or content:match("## Tasks\n(.*)$")
  if not tasks_section then return "- [ ] DAILY CHORES #life\n- [ ] Read book chapter #life" end

  -- Extract incomplete tasks (- [ ] but not - [x], - [/], - [-], etc.)
  local incomplete = {}
  for line in tasks_section:gmatch("[^\n]+") do
    -- Match only unchecked tasks: "- [ ]" (space inside brackets)
    if line:match("^%s*%- %[ %]") then
      -- Replace "tomorrow" with "today" in migrated tasks
      local cleaned = line:gsub("tomorrow", "today")
      table.insert(incomplete, cleaned)
    end
  end

  if #incomplete == 0 then return "- [ ] DAILY CHORES #life\n- [ ] Read book chapter #life" end

  return table.concat(incomplete, "\n")
end

--- Read Shade's context.json file
---@return table|nil context The parsed context or nil
local function read_shade_context()
  local state_dir = vim.env.HOME .. "/.local/state/shade"
  local context_path = state_dir .. "/context.json"

  local f = io.open(context_path, "r")
  if not f then return nil end

  local content = f:read("*a")
  f:close()

  local ok, ctx = pcall(vim.json.decode, content)
  if not ok then return nil end

  return ctx
end

--- Sanitize string for use in filename
---@param str string
---@param max_len? number Maximum length (default 30)
---@return string sanitized
local function sanitize_for_filename(str, max_len)
  if not str or str == "" then return "" end
  max_len = max_len or 30

  local result = str
    :lower()
    :gsub("[%.:/]", "-") -- dots/colons/slashes to dashes
    :gsub("%s+", "-") -- spaces to dashes
    :gsub("[^a-z0-9%-]", "") -- remove non-alphanumeric
    :gsub("%-+", "-") -- collapse multiple dashes
    :gsub("^%-", "") -- trim leading dash
    :gsub("%-$", "") -- trim trailing dash

  -- Truncate at word boundary if too long
  if #result > max_len then result = result:sub(1, max_len):gsub("%-[^%-]*$", "") end

  return result
end

--- Extract meaningful snippet from window title
--- Removes common suffixes like "- Google Chrome", app names, etc.
---@param window_title string|nil
---@return string|nil snippet 2-3 word snippet or nil
local function extract_title_snippet(window_title)
  if not window_title or window_title == "" then return nil end

  -- Remove common browser/app suffixes
  local cleaned = window_title
    :gsub("%s*[%-–—|·]%s*[A-Z][%w%s]*$", "") -- " - App Name" or " | App"
    :gsub("%s*[%-–—]%s*[A-Z][%w]*%s*[A-Z][%w]*$", "") -- " - Two Words"
    :gsub("^https?://[^/]+/", "") -- leading URLs
    :gsub("^www%.", "")

  -- Take first 2-3 meaningful words only
  local words = {}
  for word in cleaned:gmatch("%S+") do
    if #words < 3 and #word > 1 then table.insert(words, word) end
  end

  if #words == 0 then return nil end

  local snippet = table.concat(words, " ")
  local sanitized = sanitize_for_filename(snippet, 25)

  -- Only return if we got something meaningful (at least 3 chars)
  return (#sanitized >= 3) and sanitized or nil
end

--- Extract domain from URL
---@param url string|nil
---@return string|nil domain without www prefix
local function extract_domain(url)
  if not url then return nil end
  local domain = url:match("https?://([^/]+)")
  if domain then
    domain = domain:gsub("^www%.", "")
    -- Just first part of domain (github.com -> github)
    local short = domain:match("^([^%.]+)")
    return short
  end
  return nil
end

--- Generate a descriptor from context for capture note filenames
--- Priority: window title snippet > domain+language > app type
---@param ctx table|nil Context from context.json
---@return string descriptor Sanitized descriptor or "capture"
local function generate_descriptor_from_context(ctx)
  if not ctx then return "capture" end

  -- Priority 1: Window title snippet
  local snippet = extract_title_snippet(ctx.windowTitle)
  if snippet then return snippet end

  -- Priority 2: Domain + language
  local domain = extract_domain(ctx.url)
  local lang = ctx.detectedLanguage or ctx.filetype

  if domain and lang then
    return string.format("%s-%s", domain, sanitize_for_filename(lang))
  elseif domain then
    return domain
  elseif lang then
    return sanitize_for_filename(lang)
  end

  -- Priority 3: App type (if not "other")
  if ctx.appType and ctx.appType ~= "other" then return ctx.appType end

  return "capture"
end

--- Generate zettel-style note ID with descriptor from context
--- Format: YYYYMMDDHHMM-descriptor (e.g., 202601071520-github-pr)
---@param title string|nil Optional title (ignored for captures, we use context)
---@return string note_id
local function generate_capture_note_id(title)
  local zettel = os.date("%Y%m%d%H%M")
  local ctx = read_shade_context()
  local descriptor = generate_descriptor_from_context(ctx)

  if descriptor and descriptor ~= "" then
    return string.format("%s-%s", zettel, descriptor)
  else
    return zettel
  end
end

return {
  "obsidian-nvim/obsidian.nvim",
  cond = not vim.g.started_by_firenvim,
  version = "*",
  -- lazy = false,
  event = "VeryLazy",
  -- ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim",
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
      template = "daily.md", -- Use our custom daily template
    },
    templates = {
      folder = "templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
      substitutions = {
        -- Date without dashes for IDs (YYYYMMDD format)
        date_id = function() return os.date("%Y%m%d") end,

        -- ISO timestamp for created field
        timestamp = function() return os.date("%Y-%m-%dT%H:%M:%S") end,

        -- Task migration: extract incomplete tasks from previous daily note
        migrated_tasks = function()
          local prev_path = find_previous_daily_note()
          if prev_path then return extract_incomplete_tasks(prev_path) end
          return "- [ ] DAILY CHORES #life\n- [ ] Read book chapter #life"
        end,

        -- Link to yesterday's daily note
        yesterday_link = function()
          local _, prev_filename = find_previous_daily_note()
          if prev_filename then
            return string.format("[Previous daily note (%s)](%s.md)", prev_filename, prev_filename)
          end
          return ""
        end,

        -- Build a collapsible callout with capture context (only non-empty fields)
        -- Renders as a collapsed "> [!info]- Capture Context" block in Obsidian
        capture_context = function()
          local ctx = read_shade_context()
          if not ctx then return "" end

          local lines = {}

          -- Add context fields only if they have values
          if ctx.appName and ctx.appName ~= "" then
            table.insert(lines, string.format("> - **App:** %s", ctx.appName))
          end
          if ctx.windowTitle and ctx.windowTitle ~= "" then
            table.insert(lines, string.format("> - **Window:** %s", ctx.windowTitle))
          end
          if ctx.url and ctx.url ~= "" then table.insert(lines, string.format("> - **URL:** %s", ctx.url)) end
          if ctx.filePath and ctx.filePath ~= "" then
            table.insert(lines, string.format("> - **File:** `%s`", ctx.filePath))
          end
          local lang = ctx.detectedLanguage or ctx.filetype
          if lang and lang ~= "" then table.insert(lines, string.format("> - **Language:** %s", lang)) end

          -- Only return the callout if we have any context
          if #lines == 0 then return "" end

          -- Build the collapsible callout (- makes it collapsed by default)
          return "> [!info]- Capture Context\n" .. table.concat(lines, "\n")
        end,

        -- Selection as code block (for text captures)
        capture_selection = function()
          local ctx = read_shade_context()
          if not ctx or not ctx.selection or ctx.selection == "" then return "" end
          local lang = ctx.detectedLanguage or ctx.filetype or ""
          return string.format("```%s\n%s\n```", lang, ctx.selection)
        end,

        -- For image captures - reads from context.json written by Hammerspoon
        image_filename = function()
          local ctx = read_shade_context()
          if ctx and ctx.imageFilename and ctx.imageFilename ~= "" then return ctx.imageFilename end
          -- Fallback: generate a timestamped name (shouldn't happen if workflow is correct)
          return string.format("capture-%s.png", os.date("%Y%m%d%H%M%S"))
        end,

        ocr_text = function()
          -- OCR text will be injected after creation or left empty
          return ""
        end,
      },
      -- Per-template customizations for capture notes
      -- Uses zettel timestamp + descriptor from context.json
      customizations = {
        -- Template: capture-text.md
        ["capture-text"] = {
          notes_subdir = "captures",
          note_id_func = generate_capture_note_id,
        },
        -- Template: capture-image.md
        ["capture-image"] = {
          notes_subdir = "captures",
          note_id_func = generate_capture_note_id,
        },
      },
    },
    attachments = {
      img_folder = "assets", -- Store images in vault's assets folder
    },
    completion = {
      blink = true,
      nvim_cmp = false,
      min_chars = 0,
    },
    picker = { name = "snacks.pick" },
    preferred_link_style = "wiki",
    ui = {
      enable = false,
      -- Empty hl_groups prevents obsidian.nvim from overriding colorscheme highlights
      -- See: https://github.com/epwalsh/obsidian.nvim/issues/755
      hl_groups = {},
      bullets = {},
      external_link_icon = {},
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
  },
}
