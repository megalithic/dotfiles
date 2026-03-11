-- lua/settings.lua
-- Global settings, variables, and helpers
-- Loaded first, before all other modules

---@alias theme "megaforest" | "megagrove" | "hyper"
vim.g.theme = "megagrove"

---@alias keyhelper "mini.clue" | "whichkey"
vim.g.keyhelper = "whichkey"

-- Notes/Obsidian vault path
vim.g.notes_path = vim.env.NOTES_HOME or (vim.env.HOME .. "/notes")

vim.g.disabled_plugins = { "winbar" }

vim.g.indent_scope_char = "│"
vim.g.indent_char = "┊"
vim.g.virt_column_char = "│"

--- Check if plugin is enabled (not in disabled list)
--- Auto-derives plugin name from calling file if not provided
---@param plugin? string
---@return boolean
function _G.Plugin_enabled(plugin)
  if not plugin then
    local src = debug.getinfo(2, "S").short_src
    plugin = vim.fn.fnamemodify(src, ":t:r")
  end
  if not plugin then return true end
  return not vim.list_contains(vim.g.disabled_plugins or {}, plugin)
end

--- Helper to create augroups with a cleaner syntax
--- @param name string
--- @param commands table[]
function _G.Augroup(name, commands)
  local group = vim.api.nvim_create_augroup(name, { clear = true })
  for _, cmd in ipairs(commands) do
    local opts = {
      group = group,
      pattern = cmd.pattern,
      callback = cmd.command,
    }
    vim.api.nvim_create_autocmd(cmd.event, opts)
  end
end
