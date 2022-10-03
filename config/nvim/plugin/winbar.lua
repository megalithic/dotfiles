if not mega then return end
if not vim.g.enabled_plugin["winbar"] then return end

local H = require("mega.utils.highlights")

local M = {}

_G.__winbar = M

vim.opt.laststatus = 3
-- vim.opt.winbar = [[%=%#WhiteSpace#%*%#SnapSelect#%f%*%#WhiteSpace#%*]]

local function get_filepath_parts()
  local base = vim.fn.expand("%:~:.:h")
  local filename = vim.fn.expand("%:~:.:t")
  local prefix = (vim.fn.empty(base) == 1 or base == ".") and "" or base .. "/"

  return { base, filename, prefix }
end

local function update_filepath_highlights()
  if vim.bo.modified then
    H.group("StatusLineFilePath", { link = "DiffChange" })
    H.group("StatusLineNewFilePath", { link = "DiffChange" })
  else
    H.group("StatusLineFilePath", { link = "User6" })
    H.group("StatusLineNewFilePath", { link = "User4" })
  end

  return ""
end

local function filepath()
  local parts = get_filepath_parts()
  local prefix = parts[3]
  local filename = parts[2]

  update_filepath_highlights()

  local line = string.format("%s%%*%%#StatusLineFilePath#%s", prefix, filename)

  if vim.fn.empty(prefix) == 1 and vim.fn.empty(filename) == 1 then line = "%#StatusLineNewFilePath# %f %*" end

  return string.format("%%4*%s%%*", line)
end

function M.get_active_winbar()
  if vim.bo.filetype == "help" or vim.bo.filetype == "man" then return "" end

  local line = table.concat({
    "%=",
    -- '%#WhiteSpace#%*',
    filepath(),
    "%*",
    -- '%#WhiteSpace#%*'
  })

  return line
end

function M.get_inactive_winbar()
  if vim.bo.filetype == "help" or vim.bo.filetype == "man" then return "" end

  local line = table.concat({
    "%=",
    -- '%#WhiteSpace#%*',
    "%#LineNr#",
    "%f",
    "%*",
    -- '%#WhiteSpace#%*'
  })

  return line
end

function M.active() vim.api.nvim_win_set_option(0, "winbar", [[%!luaeval("__winbar.get_active_winbar()")]]) end

function M.inactive() vim.api.nvim_win_set_option(0, "winbar", [[%!luaeval("__winbar.get_inactive_winbar()")]]) end

function M.activate()
  mega.augroup("MyWinbar", {
    {
      event = { "WinEnter", "BufEnter" },
      pattern = { "*" },
      command = __winbar.active,
    },
    {
      event = { "WinLeave", "BufLeave" },
      pattern = { "*" },
      command = __winbar.inactive,
    },
  })
end

__winbar.activate()
