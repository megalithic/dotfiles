-- FIXME: does this need to be moved to after/ftplugin/lua.lua instead?
-- REF: https://github.com/akinsho/dotfiles/commit/2b552db145205d66acf6e8eac56c2130496f5e60

if true then return end

local fmt = string.format
local fn = vim.fn

if not mega then return end

local function find(word, ...)
  for _, str in ipairs({ ... }) do
    local match_start, match_end = string.find(word, str)
    if match_start then return str, match_start, match_end end
  end
end

local function open_help(tag) mega.wrap_err(vim.cmd.help, tag) end

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

  local match, _, end_idx = find(word, "api.", "vim.api.")
  if match and end_idx then return open_help(word:sub(end_idx + 1)) end

  match, _, end_idx = find(word, "fn.", "vim.fn.")
  if match and end_idx then return open_help(word:sub(end_idx + 1) .. "()") end

  match, _, end_idx = find(word, "^vim.(%w+)")
  if match and end_idx then return open_help(word:sub(1, end_idx)) end

  if callback then return callback() end

  vim.lsp.buf.hover()
end

-- mega.ftplugin_conf("nvim-surround", function(surround)
--   local get_input = function(prompt)
--     local ok, input = pcall(vim.fn.input, fmt("%s: ", prompt))

--     if not ok then return end
--     return input
--   end

--   surround.buffer_setup({
--     surrounds = {
--       l = { add = { "function () ", " end" } },
--       F = {
--         add = function()
--           return {
--             { fmt("local function %s() ", get_input("Enter a func name")) },
--             { " end" },
--           }
--         end,
--       },
--       i = {
--         add = function()
--           return {
--             { fmt("if %s then ", get_input("Enter a condition")) },
--             { " end" },
--           }
--         end,
--       },
--       t = {
--         add = function()
--           return {
--             { fmt("{ %s = { ", get_input("Enter a field name")) },
--             { " }}" },
--           }
--         end,
--       },
--     },
--   })
-- end)

local ok_ms, ms = mega.require("mini.surround")
local ok_mai, mai = mega.require("mini.surround")
if ok_ms and ok_mai then
  vim.b.minisurround_config = {
    custom_surroundings = {
      s = { input = { "%[%[().-()%]%]" }, output = { left = "[[", right = "]]" } },
      a = {
        input = { "function%(.-%).-end", "^function%(%)%s?().-()%s?end$" },
        output = { left = "function() ", right = " end" },
      },
    },
  }

  vim.b.miniai_config = {
    custom_textobjects = {
      s = { "%[%[().-()%]%]" },
    },
  }
end

nnoremap("gK", keyword, { buffer = 0 })

vim.opt_local.textwidth = 100
vim.opt_local.formatoptions:remove("o")
