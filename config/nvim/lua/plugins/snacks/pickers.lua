-- Custom picker functions for snacks.nvim

local M = {}
local layouts = require("plugins.snacks.layouts")

local function file_surfer()
  Snacks.picker.zoxide({
    confirm = function(picker, item)
      local cwd = item._path
      picker:close()
      vim.fn.chdir(cwd)
      vim.schedule(function() Snacks.picker.files({ filter = { cwd = cwd } }) end)
    end,
  })
end

local function find_associated_files()
  local current_filename = vim.fn.expand("%:t:r")
  local base_name = current_filename:match("^([^.]+)") or current_filename
  local relative_filepath = vim.fn.fnamemodify(vim.fn.expand("%"), ":~:.")

  Snacks.picker.files({
    pattern = base_name,
    exclude = { ".git", relative_filepath },
    matcher = { ignorecase = true },
  })
end

local function buffer_jumps()
  local current_buf = vim.api.nvim_get_current_buf()
  local current_file = vim.api.nvim_buf_get_name(current_buf)

  Snacks.picker({
    prompt = "Buffer Jumps",
    layout = layouts.buffer_layout,
    format = "file",
    main = { current = true },
    finder = function()
      local jumps = vim.fn.getjumplist()[1]
      local items = {}
      for _, jump in ipairs(jumps) do
        local buf = jump.bufnr and vim.api.nvim_buf_is_valid(jump.bufnr) and jump.bufnr or 0
        if buf == current_buf and jump.lnum > 0 then
          local line = vim.api.nvim_buf_get_lines(buf, jump.lnum - 1, jump.lnum, false)[1]
          table.insert(items, 1, {
            buf = buf,
            line = line,
            text = table.concat({ current_file, line }, " "),
            file = current_file,
            pos = { jump.lnum, jump.col },
          })
        end
      end
      return items
    end,
  })
end

local function buffers_and_recent()
  Snacks.picker({
    multi = { "recent", "buffers" },
    format = "buffer",
    matcher = { frecency = true, sort_empty = true, cwd_bonus = true },
    sort = { fields = { "source_id", "score:desc", "frecency:desc" } },
    sources = {
      buffers = {
        finder = "buffers",
        format = "buffer",
        hidden = false,
        unloaded = false,
        current = false,
        sort_lastused = true,
        filter = {},
      },
      recent = { filter = { cwd = true } },
    },
  })
end

local function git_diff_in_file()
  local file = vim.fn.expand("%")
  if file ~= "" then
    Snacks.picker.git_diff({ cmd_args = { "--", file }, staged = false })
  else
    vim.notify("No file in current buffer", vim.log.levels.WARN)
  end
end

local function git_pickaxe(opts)
  opts = opts or {}
  local is_global = opts.global or false
  local current_file = vim.api.nvim_buf_get_name(0)

  if not is_global and (current_file == "" or current_file == nil) then
    vim.notify("Buffer is not a file, switching to global search", vim.log.levels.WARN)
    is_global = true
  end

  local title_scope = is_global and "Global" or vim.fn.fnamemodify(current_file, ":t")

  vim.ui.input({ prompt = "Git Search (-G) in " .. title_scope .. ": " }, function(query)
    if not query or query == "" then return end

    vim.fn.setreg("/", query)
    local old_hl = vim.opt.hlsearch
    vim.opt.hlsearch = true

    local args = {
      "log",
      "-G" .. query,
      "-i",
      "--pretty=format:%C(yellow)%h%Creset %s %C(green)(%cr)%Creset %C(blue)<%an>%Creset",
      "--abbrev-commit",
      "--date=short",
    }
    if not is_global then
      table.insert(args, "--")
      table.insert(args, current_file)
    end

    Snacks.picker({
      title = 'Git Log: "' .. query .. '" (' .. title_scope .. ")",
      finder = "proc",
      cmd = "git",
      args = args,
      transform = function(item)
        local clean_text = item.text:gsub("\27%[[0-9;]*m", "")
        local hash = clean_text:match("^%S+")
        if hash then
          item.commit = hash
          if not is_global then item.file = current_file end
        end
        return item
      end,
      preview = "git_show",
      format = "text",
      on_close = function()
        vim.opt.hlsearch = old_hl
        vim.cmd("noh")
      end,
    })
  end)
end

local function explorer()
  local explorer_pickers = Snacks.picker.get({ source = "explorer" })
  for _, picker in pairs(explorer_pickers) do
    if picker:is_focused() then
      picker:close()
    else
      picker:focus()
    end
  end
  if #explorer_pickers == 0 then Snacks.picker.explorer() end
end

--- Gets the jj root for a buffer or path.
--- Defaults to the current buffer.
---@param path? number|string buffer or path
---@return string?
function M.get_root(path) return require("utils.vcs").get_jj_root(path) end

--- Open the Jujutsu diff picker.
function M.diff() require("plugins.snacks.jj").diff() end

return {
  "folke/snacks.nvim",
  file_surfer = file_surfer,
  find_associated_files = find_associated_files,
  buffer_jumps = buffer_jumps,
  buffers_and_recent = buffers_and_recent,
  git_diff_in_file = git_diff_in_file,
  git_pickaxe = git_pickaxe,
  explorer = explorer,
  diff = M.diff,
  get_root = M.get_root,
}
