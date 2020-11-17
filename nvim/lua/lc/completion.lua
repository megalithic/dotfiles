local has_lsp, _ = pcall(require, "nvim_lsp")
if not has_lsp then
  print("[WARN] nvim_lsp not found/installed/loaded..")

  return
end

local M = {}

local chain_complete_list = {
  default = {
    {complete_items = {"lsp", "snippet"}},
    {complete_items = {"path"}, triggered_only = {"./", "/"}},
    {complete_items = {"buffers"}},
    {complete_items = {"ts"}}
  },
  string = {
    {complete_items = {"path"}, triggered_only = {"./", "/"}},
    {complete_items = {"buffers"}}
  },
  comment = {}
}

local bytemarkers = {{0x7FF, 192}, {0xFFFF, 224}, {0x1FFFFF, 240}}
local function utf8(decimal)
  if decimal < 128 then
    return string.char(decimal)
  end
  local charbytes = {}
  for bytes, vals in ipairs(bytemarkers) do
    if decimal <= vals[1] then
      for b = bytes + 1, 2, -1 do
        local mod = decimal % 64
        decimal = (decimal - mod) / 64
        charbytes[b] = string.char(128 + mod)
      end
      charbytes[1] = string.char(vals[2] + decimal)
      break
    end
  end
  return table.concat(charbytes)
end

local customize_lsp_label = {
  Method = utf8(0xf794) .. " [method]",
  Function = utf8(0xf794) .. " [fun]",
  Variable = utf8(0xf6a6) .. " [var]",
  Field = utf8(0xf6a6) .. " [field]",
  Class = utf8(0xfb44) .. " [class]",
  Struct = utf8(0xfb44) .. " [struct]",
  Interface = utf8(0xf836) .. " [interface]",
  Module = utf8(0xf668) .. " [mod]",
  Property = utf8(0xf0ad) .. " [prop]",
  Value = utf8(0xf77a) .. " [val]",
  Enum = utf8(0xf77a) .. " [enum]",
  Operator = utf8(0xf055) .. " [operator]",
  Reference = utf8(0xf838) .. " [ref]",
  Keyword = utf8(0xf80a) .. " [keyword]",
  Color = utf8(0xe22b) .. " [color]",
  Unit = utf8(0xe3ce) .. " [unit]",
  ["snippets.nvim"] = utf8(0xf68e) .. " [ns]",
  ["vim-vsnip"] = utf8(0xf68e) .. " [vs]",
  Snippet = utf8(0xf68e) .. " [s]",
  Text = utf8(0xf52b) .. " [text]",
  Buffers = utf8(0xf64d) .. " [buff]",
  TypeParameter = utf8(0xf635) .. " [type]"
}

function M.activate()
  -- [ snippets ] --------------------------------------------------------------
  vim.api.nvim_set_var("vsnip_snippet_dir", "~/.dotfiles/nvim/vsnips")

  -- [ nvim-completion ] --------------------------------------------------------------
  local has_completion, completion = pcall(require, "completion")
  if has_completion then
    completion.on_attach(
      {
        chain_complete_list = chain_complete_list,
        customize_lsp_label = customize_lsp_label,
        enable_auto_popup = 1,
        enable_auto_signature = 1,
        auto_change_source = 1,
        enable_auto_hover = 1,
        completion_enable_fuzzy_match = 1,
        completion_enable_snippet = "vim-vsnip",
        completion_trigger_on_delete = 0,
        completion_trigger_keyword_length = 2,
        max_items = 10,
        sorting = "none", -- 'alphabet'
        matching_strategy_list = {"exact", "substring", "fuzzy", "all"}
      }
    )
  end
end

return M
