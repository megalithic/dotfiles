-- FIXME: does this need to be moved to after/ftplugin/lua.lua instead?
-- REF: https://github.com/akinsho/dotfiles/commit/2b552db145205d66acf6e8eac56c2130496f5e60

local fmt = string.format
local fn = vim.fn

if not mega then return end

local function find(word, ...)
  for _, str in ipairs({ ... }) do
    local match_start, match_end = string.find(word, str)
    if match_start then return str, match_start, match_end end
  end
end

--- Stolen from nlua.nvim this function attempts to open
--- vim help docs if an api or vim.fn function otherwise it
--- shows the lsp hover doc
--- @param word string
--- @param callback function
local function keyword(word, callback)
  local original_iskeyword = vim.bo.iskeyword

  vim.bo.iskeyword = vim.bo.iskeyword .. ",."
  word = word or fn.expand("<cword>")

  vim.bo.iskeyword = original_iskeyword

  -- TODO: This is a sub par work around, since I usually rename `vim.api` -> `api` or similar
  -- consider maybe using treesitter in the future
  local api_match = find(word, "api", "vim.api")
  local fn_match = find(word, "fn", "vim.fn")
  if api_match then
    local _, finish = string.find(word, api_match .. ".")
    local api_function = string.sub(word, finish + 1)

    vim.cmd(string.format("help %s", api_function))
    return
  elseif fn_match then
    local _, finish = string.find(word, fn_match .. ".")
    if not finish then return end
    local api_function = string.sub(word, finish + 1) .. "()"

    vim.cmd(string.format("help %s", api_function))
    return
  elseif callback then
    callback()
  else
    vim.lsp.buf.hover()
  end
end

-- Iterator that splits a string o a given delimiter
local function split(str, delim)
  delim = delim or "%s"
  return string.gmatch(str, fmt("[^%s]+", delim))
end

-- Find the proper directory separator depending
-- on lua installation or OS.
local function dir_separator()
  -- Look at package.config for directory separator string (it's the first line)
  if package.config then
    return string.match(package.config, "^[^\n]")
  elseif fn.has("win32") == 1 then
    return "\\"
  else
    return "/"
  end
end

-- Search for lua traditional include paths.
-- This mimics how require internally works.
local function include_paths(fname, ext)
  ext = ext or "lua"
  local sep = dir_separator()
  local paths = string.gsub(package.path, "%?", fname)
  for path in split(paths, "%;") do
    if fn.filereadable(path) == 1 then return path end
  end
end

-- Search for nvim lua include paths
local function include_rtpaths(fname, ext)
  ext = ext or "lua"
  local sep = dir_separator()
  local rtpaths = vim.api.nvim_list_runtime_paths()
  local modfile, initfile = fmt("%s.%s", fname, ext), fmt("init.%s", ext)
  for _, path in ipairs(rtpaths) do
    -- Look on runtime path for 'lua/*.lua' files
    local path1 = table.concat({ path, ext, modfile }, sep)
    if fn.filereadable(path1) == 1 then return path1 end
    -- Look on runtime path for 'lua/*/init.lua' files
    local path2 = table.concat({ path, ext, fname, initfile }, sep)
    if fn.filereadable(path2) == 1 then return path2 end
  end
end

-- Global function that searches the path for the required file
function Find_required_path(module)
  -- Look at package.config for directory separator string (it's the first line)
  local sep = string.match(package.config, "^[^\n]")
  -- Properly change '.' to separator (probably '/' on *nix and '\' on Windows)
  local fname = fn.substitute(module, "\\.", sep, "g")
  local f
  ---- First search for lua modules
  f = include_paths(fname, "lua")
  if f then return f end
  -- This part is just for nvim modules
  f = include_rtpaths(fname, "lua")
  if f then return f end
end

-- Set options to open require with gf
vim.opt_local.include = [[\v<((do|load)file|require)\s*\(?['"]\zs[^'"]+\ze['"]]
vim.opt_local.includeexpr = "v:lua.Find_required_path(v:fname)"

nnoremap("gK", keyword, { buffer = 0 })

-- vim.schedule(function()
mega.ftplugin_conf("nvim-surround", function(surround)
  local get_input = function(prompt)
    local ok, input = pcall(vim.fn.input, fmt("%s: ", prompt))

    if not ok then return end
    return input
  end

  surround.buffer_setup({
    surrounds = {
      l = { add = { "function () ", " end" } },
      F = {
        add = function()
          return {
            { fmt("local function %s() ", get_input("Enter a function name")) },
            { " end" },
          }
        end,
      },
      i = {
        add = function()
          return {
            { fmt("if %s then ", get_input("Enter a condition")) },
            { " end" },
          }
        end,
      },
      t = {
        add = function()
          return {
            { fmt("{ %s = { ", get_input("Enter a field name")) },
            { " }}" },
          }
        end,
      },
    },
  })
end)
-- end)

-- vim.opt_local.textwidth = 100
-- vim.opt_local.formatoptions:remove("o")
