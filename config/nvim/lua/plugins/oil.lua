mega.p.oil = {}

local fn = {}
local cache = {}

local icon_file = vim.trim(mega.ui.icons.kind.File)
local icon_dir = vim.trim(mega.ui.icons.kind.Folder)
local permission_hlgroups = setmetatable({
  ["-"] = "OilPermissionNone",
  ["r"] = "OilPermissionRead",
  ["w"] = "OilPermissionWrite",
  ["x"] = "OilPermissionExecute",
}, {
  __index = function() return "OilDir" end,
})

local type_hlgroups = setmetatable({
  ["-"] = "OilTypeFile",
  ["d"] = "OilTypeDir",
  ["f"] = "OilTypeFifo",
  ["l"] = "OilTypeLink",
  ["s"] = "OilTypeSocket",
}, {
  __index = function() return "OilTypeFile" end,
})

-- =============================================================================
-- Plugin spec
-- =============================================================================

local spec = {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  lazy = false,
  config = function(_, opts)
    -- Clear gitignore cache on refresh
    local refresh = require("oil.actions").refresh
    local original_refresh = refresh.callback
    refresh.callback = function(...)
      cache.gitignore = cache.new_gitignore_cache()
      original_refresh(...)
    end
    require("oil").setup(opts)
  end,
  keys = {
    { "<leader>ef", function() require("oil").open_float() end, mode = "n", desc = "Open file explorer" },
    {
      "<leader>ev",
      function()
        -- vim.cmd([[vertical rightbelow split|vertical resize 60]])
        vim.cmd([[vertical rightbelow split]])
        require("oil").open()
      end,
      desc = "[e]xplore cwd -> oil ([v]split)",
    },
    {
      "<leader>ee",
      function() require("oil").open() end,
      desc = "[e]xplore cwd -> oil ([e]dit)",
    },
  },
  ---@module "oil"
  ---@type oil.SetupOpts
  opts = {
    default_file_explorer = true,
    delete_to_trash = true,
    use_default_keymaps = false,
    skip_confirm_for_simple_edits = true,
    prompt_save_on_select_new_entry = false,
    keymaps = {
      ["g?"] = { "actions.show_help", mode = "n" },
      ["<CR>"] = "actions.select",
      ["<C-v>"] = { "actions.select", opts = { vertical = true } },
      ["<C-s>"] = { "actions.select", opts = { horizontal = true } },
      ["<C-t>"] = { "actions.select", opts = { tab = true } },
      ["gp"] = "actions.preview",
      ["g."] = "actions.toggle_hidden",
      ["<C-u>"] = "actions.preview_scroll_up",
      ["<C-d>"] = "actions.preview_scroll_down",
      ["<localleader>r"] = { "^ct.", mode = "n" },
      ["<M-r>"] = "actions.refresh",
      ["&"] = { "actions.parent", mode = "n" },
      ["_"] = { "actions.open_cwd", mode = "n" },
      ["gs"] = { "actions.change_sort", mode = "n" },
      ["gx"] = { "actions.open_external", mode = "n" },
      ["<C-w>"] = { "<Cmd>w<CR>", mode = "n", desc = "Save changes" },
      ["o"] = { "o", mode = "n", desc = "Create new file" },
      ["<M-h>"] = { "actions.toggle_hidden", mode = "n" },
      ["q"] = { "actions.close", mode = "n" },
      ["<BS>"] = function() require("oil").open() end,
      ["<C-y>a"] = {
        function() fn.copy_path("absolute") end,
        mode = "n",
        desc = "Copy absolute path",
      },
      ["<C-y>r"] = {
        function() fn.copy_path("relative") end,
        mode = "n",
        desc = "Copy relative path",
      },
      ["<C-y>f"] = {
        function() fn.copy_path("filename") end,
        mode = "n",
        desc = "Copy filename",
      },
      ["<C-y>s"] = {
        function() fn.copy_path("filestem") end,
        mode = "n",
        desc = "Copy filestem",
      },
      -- ["<M-p>"] = {
      --   function() fn.add_to_claude(false) end,
      --   mode = { "n", "v" },
      --   desc = "Add to Claude",
      -- },
      -- ["<leader>P"] = {
      --   function() fn.add_to_claude(true) end,
      --   mode = { "n", "v" },
      --   desc = "Add to Claude and close",
      -- },
    },
    view_options = {
      show_hidden = true,
      -- Don't treat dot files as hidden
      is_hidden_file = function() return false end,
      -- Gray out gitignored files and .git directory
      highlight_filename = function(entry)
        local faded = "Comment"
        if entry.name == ".git" then return faded end
        local dir = require("oil").get_current_dir()
        if not dir then return nil end
        if cache.gitignore[dir][entry.name] then return faded end
        return nil
      end,
      columns = {
        {
          "type",
          icons = {
            directory = "d",
            fifo = "f",
            file = "-",
            link = "l",
            socket = "s",
          },
          highlight = function(type_str) return type_hlgroups[type_str] end,
        },
        {
          "permissions",
          highlight = function(permission_str)
            local hls = {}
            for i = 1, #permission_str do
              local char = permission_str:sub(i, i)
              table.insert(hls, { permission_hlgroups[char], i - 1, i })
            end
            return hls
          end,
        },
        { "size", highlight = "Special" },
        { "mtime", highlight = "Number" },
        {
          "icon",
          default_file = icon_file,
          directory = icon_dir,
          add_padding = false,
        },
      },
    },
    float = {
      padding = 2,
      -- max_width and max_height can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
      max_width = 0.6,
      max_height = 0,
      border = { " ", " ", " ", " ", " ", " ", " ", " " },
    },
    preview_win = {
      update_on_cursor_moved = true,
      preview_method = "scratch",
    },
    confirmation = {
      border = "rounded",
    },
  },
}

-- =============================================================================
-- Local helper functions
-- =============================================================================

function fn.parse_gitignore_output(proc)
  local result = proc:wait()
  local ret = {}
  if result.code == 0 then
    for line in vim.gsplit(result.stdout, "\n", { plain = true, trimempty = true }) do
      line = line:gsub("/$", "")
      ret[line] = true
    end
  end
  return ret
end

function cache.new_gitignore_cache()
  return setmetatable({}, {
    __index = function(self, key)
      local proc = vim.system(
        { "git", "ls-files", "--ignored", "--exclude-standard", "--others", "--directory" },
        { cwd = key, text = true }
      )
      local ret = fn.parse_gitignore_output(proc)
      rawset(self, key, ret)
      return ret
    end,
  })
end

cache.gitignore = cache.new_gitignore_cache()

-- FIXME: use pi.lua?!
-- ---@param close boolean
-- function fn.add_to_claude(close)
--   -- Guard: claudecode integration is optional
--   if not mega.p.claudecode or not mega.p.claudecode.add_file then
--     vim.notify("Claude Code integration not available", vim.log.levels.WARN)
--     return
--   end
--
--   local oil = require("oil")
--   local dir = oil.get_current_dir()
--   if not dir then return end
--
--   local mode = vim.fn.mode()
--   local paths = {}
--
--   if mode == "V" or mode == "v" then
--     local start_line = vim.fn.line("v")
--     local end_line = vim.fn.line(".")
--     if start_line > end_line then
--       start_line, end_line = end_line, start_line
--     end
--     for lnum = start_line, end_line do
--       local entry = oil.get_entry_on_line(0, lnum)
--       if entry then table.insert(paths, dir .. entry.name) end
--     end
--     vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
--   else
--     local entry = oil.get_cursor_entry()
--     if entry then table.insert(paths, dir .. entry.name) end
--   end
--
--   for _, path in ipairs(paths) do
--     mega.p.claudecode.add_file(path)
--   end
--
--   if close then
--     oil.close()
--     if mega.p.claudecode.focus then mega.p.claudecode.focus() end
--   end
-- end

---@param fmt "absolute" | "relative" | "filename" | "filestem"
function fn.copy_path(fmt)
  local oil = require("oil")
  local entry = oil.get_cursor_entry()
  if not entry then return end
  local dir = oil.get_current_dir()
  if not dir then return end
  local path = dir .. entry.name
  local result = mega.u.fs.format(path, fmt)
  if result then
    mega.u.clipboard.yank(result)
    vim.notify("Copied: " .. result)
  end
end

return { spec }
