-- lua/plugins/obsidian.lua
-- obsidian.nvim configuration
--
-- Note: obsidian.nvim includes its own LSP server (obsidian-ls)
-- which auto-attaches to buffers in Obsidian vaults

--- Lazy-load interop only when needed for template substitutions
local function get_shade() return require("utils.interop").shade end

--- Find all daily notes before today, sorted most recent first
---@return table[] Array of {path, filename} sorted descending by date
local function find_all_previous_daily_notes()
  local notes_path = vim.g.notes_path
  local daily_dir = notes_path .. "/daily"
  local today = os.date("%Y%m%d")

  -- Use vim.fn.glob for native file discovery (no shell dependency)
  local pattern = daily_dir .. "/**/*.md"
  local all_files = vim.fn.glob(pattern, false, true)

  -- Filter and sort: find all notes before today
  local files = {}
  for _, path in ipairs(all_files) do
    local filename = path:match("([^/]+)%.md$")
    if filename and filename < today then table.insert(files, { path = path, filename = filename }) end
  end

  table.sort(files, function(a, b) return a.filename > b.filename end)

  return files
end

--- Find the most recent daily note before today
---@return string|nil path Full path to previous daily note
---@return string|nil filename Just the filename (e.g., "20260105")
local function find_previous_daily_note()
  local files = find_all_previous_daily_notes()
  if #files > 0 then return files[1].path, files[1].filename end
  return nil, nil
end

--- Extract incomplete tasks from a daily note file
---@param path string Path to the daily note
---@return string|nil tasks Formatted task list, or nil if none found
local function extract_incomplete_tasks(path)
  local f = io.open(path, "r")
  if not f then return nil end

  local content = f:read("*a")
  f:close()

  -- Find ## Tasks section
  local tasks_section = content:match("## Tasks\n(.-)\n## ") or content:match("## Tasks\n(.*)$")
  if not tasks_section then return nil end

  -- Extract incomplete tasks (- [ ] with space inside brackets)
  local incomplete = {}
  for line in tasks_section:gmatch("[^\n]+") do
    if line:match("^%s*%- %[ %]") then
      local cleaned = line:gsub("tomorrow", "today")
      table.insert(incomplete, cleaned)
    end
  end

  if #incomplete == 0 then return nil end

  return table.concat(incomplete, "\n")
end

--- Find incomplete tasks from the most recent day that has them
---@return string tasks Formatted task list (empty string if none found anywhere)
local function find_migrated_tasks()
  local previous_notes = find_all_previous_daily_notes()

  for _, note in ipairs(previous_notes) do
    local tasks = extract_incomplete_tasks(note.path)
    if tasks then return tasks end
  end

  return ""
end

--- Build capture context callout from Shade context
---@return string
local function build_capture_context()
  local shade = get_shade()
  local ctx = shade.get_context()
  if not ctx then return "" end

  local lines = {}

  if ctx.appName and ctx.appName ~= "" then table.insert(lines, string.format("> - **App:** %s", ctx.appName)) end
  if ctx.windowTitle and ctx.windowTitle ~= "" then
    table.insert(lines, string.format("> - **Window:** %s", ctx.windowTitle))
  end
  if ctx.url and ctx.url ~= "" then table.insert(lines, string.format("> - **URL:** %s", ctx.url)) end
  if ctx.filePath and ctx.filePath ~= "" then table.insert(lines, string.format("> - **File:** `%s`", ctx.filePath)) end
  local lang = ctx.detectedLanguage or ctx.filetype
  if lang and lang ~= "" then table.insert(lines, string.format("> - **Language:** %s", lang)) end

  if #lines == 0 then return "" end

  return "> [!info]- Capture Context\n" .. table.concat(lines, "\n")
end

--- Build capture selection as code block
---@return string
local function build_capture_selection()
  local shade = get_shade()
  local ctx = shade.get_context()
  if not ctx or not ctx.selection or ctx.selection == "" then return "" end

  local lang = ctx.detectedLanguage or ctx.filetype or ""
  return string.format("```%s\n%s\n```", lang, ctx.selection)
end

--- Get image filename from Shade context
---@return string
local function get_image_filename()
  local shade = get_shade()
  local ctx = shade.get_context()
  if ctx and ctx.imageFilename and ctx.imageFilename ~= "" then return ctx.imageFilename end
  return string.format("capture-%s.png", os.date("%Y%m%d%H%M%S"))
end

--- Generate descriptor from context for capture filenames
---@param ctx table|nil
---@return string
local function generate_descriptor_from_context(ctx)
  if not ctx then return "capture" end

  -- Try window title first
  if ctx.windowTitle and ctx.windowTitle ~= "" then
    local snippet = ctx.windowTitle
      :gsub("%s*[%-–—|·]%s*[A-Z][%w%s]*$", "")
      :gsub("^https?://[^/]+/", "")
      :lower()
      :gsub("[^a-z0-9%s]", "")
      :gsub("%s+", "-")
      :sub(1, 25)
    if #snippet >= 3 then return snippet end
  end

  -- Try domain + language
  local domain = nil
  if ctx.url then
    local host = ctx.url:match("https?://([^/]+)")
    if host then domain = host:gsub("^www%.", ""):match("^([^%.]+)") end
  end
  local lang = ctx.detectedLanguage or ctx.filetype

  if domain and lang then
    return string.format("%s-%s", domain, lang:lower())
  elseif domain then
    return domain
  elseif lang then
    return lang:lower()
  end

  -- Try app type
  if ctx.appType and ctx.appType ~= "other" then return ctx.appType end

  return "capture"
end

--- Generate zettel-style note ID with descriptor from Shade context
--- Note: title param is ignored for captures; we use context instead
---@param _ string|nil Unused (obsidian.nvim passes title)
---@return string
local function generate_capture_note_id(_)
  local zettel = os.date("%Y%m%d%H%M")
  local shade = get_shade()
  local ctx = shade.get_context()
  local descriptor = generate_descriptor_from_context(ctx)

  if descriptor and descriptor ~= "" then return string.format("%s-%s", zettel, descriptor) end
  return zettel
end

return {
  "obsidian-nvim/obsidian.nvim",
  cond = not vim.g.started_by_firenvim,
  version = "*",
  event = "VeryLazy",
  -- Obsidian command triggers plugin load (uses subcommands: Obsidian today, Obsidian new, etc.)
  cmd = { "Obsidian" },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  ---@module 'obsidian'
  ---@type obsidian.config.ClientOpts
  opts = {
    workspaces = {
      { name = "notes", path = vim.g.notes_path },
    },
    daily_notes = {
      enabled = true,
      folder = "daily",
      date_format = "%Y/%Y%m%d",
      template = "daily.md",
    },
    templates = {
      enabled = true,
      folder = "templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
      substitutions = {
        date_id = function() return os.date("%Y%m%d") end,
        timestamp = function() return os.date("%Y-%m-%dT%H:%M:%S") end,
        migrated_tasks = find_migrated_tasks,
        yesterday_link = function()
          local _, prev_filename = find_previous_daily_note()
          if prev_filename then
            return string.format("[Previous daily note (%s)](%s.md)", prev_filename, prev_filename)
          end
          return ""
        end,
        capture_context = build_capture_context,
        capture_selection = build_capture_selection,
        image_filename = get_image_filename,
      },
      customizations = {
        ["capture-text"] = {
          notes_subdir = "captures",
          note_id_func = generate_capture_note_id,
        },
        ["capture-image"] = {
          notes_subdir = "captures",
          note_id_func = generate_capture_note_id,
        },
      },
    },
    attachments = {
      folder = "assets",
    },
    completion = {
      blink = true,
      nvim_cmp = false,
      min_chars = 0,
    },
    picker = { name = "snacks.pick" },
    link = { style = "wiki" },
    legacy_commands = false, -- Use new command style: `Obsidian backlinks` not `ObsidianBacklinks`
    -- Checkbox cycling order for smart_action <CR>
    -- Matches custom states in render-markdown.nvim and notes.lua
    checkbox = {
      order = { " ", "-", ".", "x" }, -- unchecked → todo → started → done
      create_new = true, -- create checkbox on non-list lines
    },
    -- Disable obsidian.nvim UI - render-markdown.nvim handles rendering
    ui = {
      enable = false,
      hl_groups = {},
      bullets = {},
      external_link_icon = {},
    },
    frontmatter = {
      sort = { "id", "title", "date", "aliases", "tags" },
      func = function(note)
        if note.title then note:add_alias(note.title) end

        local out = { id = note.id, aliases = note.aliases, tags = note.tags }

        -- Preserve all custom fields from captures
        if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
          for k, v in pairs(note.metadata) do
            out[k] = v
          end
        end

        return out
      end,
    },
    note_id_func = function(title)
      if title then return title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", "") end
      -- Random suffix if no title
      local suffix = ""
      for _ = 1, 4 do
        suffix = suffix .. string.char(math.random(65, 90))
      end
      return suffix
    end,
    -- Keybindings via callbacks (not deprecated mappings)
    callbacks = {
      enter_note = function()
        local api = require("obsidian.api")

        -- <CR>: Smart action - follow link OR toggle checkbox OR fold heading
        vim.keymap.set(
          "n",
          "<cr>",
          function() return api.smart_action() or "<CR>" end,
          { buffer = true, expr = true, desc = "obsidian: smart action" }
        )

        -- gf: Follow wiki link under cursor
        vim.keymap.set("n", "gf", function()
          if api.cursor_link() then
            api.follow_link()
          else
            vim.cmd("normal! gf")
          end
        end, { buffer = true, desc = "obsidian: go to file" })

        -- gn: Rename note
        vim.keymap.set("n", "gn", "<cmd>Obsidian rename<cr>", { buffer = true, desc = "obsidian: rename note" })
      end,
    },
  },
}
