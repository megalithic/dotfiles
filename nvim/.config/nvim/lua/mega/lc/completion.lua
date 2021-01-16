local has_lsp, _ = pcall(require, "lspconfig")
if not has_lsp then
  print("[WARN] lspconfig not found/installed/loaded..")

  return
end

local M = {}

local chain_complete_list = {
  default = {
    {complete_items = {"lsp", "snippet"}},
    {complete_items = {"path"}, triggered_only = {"./", "/"}},
    {complete_items = {"buffers"}},
    {complete_items = {"ts"}},
    {mode = "<c-p>"},
    {mode = "<c-n>"},
    {mode = "dict"},
    {mode = "spel"}
  },
  string = {
    {complete_items = {"path"}, triggered_only = {"./", "/"}},
    {complete_items = {"buffers"}}
  },
  comment = {
    {complete_items = {"buffers"}}
  }
}

local customize_lsp_label = {
  Method = mega.utf8(0xf794) .. " [method]",
  Function = mega.utf8(0xf794) .. " [fun]",
  Variable = mega.utf8(0xf6a6) .. " [var]",
  Field = mega.utf8(0xf6a6) .. " [field]",
  Class = mega.utf8(0xfb44) .. " [class]",
  Struct = mega.utf8(0xfb44) .. " [struct]",
  Interface = mega.utf8(0xf836) .. " [interface]",
  Module = mega.utf8(0xf668) .. " [mod]",
  Property = mega.utf8(0xf0ad) .. " [prop]",
  Value = mega.utf8(0xf77a) .. " [val]",
  Enum = mega.utf8(0xf77a) .. " [enum]",
  Operator = mega.utf8(0xf055) .. " [operator]",
  Reference = mega.utf8(0xf838) .. " [ref]",
  Keyword = mega.utf8(0xf80a) .. " [keyword]",
  Color = mega.utf8(0xe22b) .. " [color]",
  Unit = mega.utf8(0xe3ce) .. " [unit]",
  ["snippets.nvim"] = mega.utf8(0xf68e) .. " [ns]",
  ["vim-vsnip"] = mega.utf8(0xf68e) .. " [vs]",
  ["vsnip"] = mega.utf8(0xf68e) .. " [vs]",
  Snippet = mega.utf8(0xf68e) .. " [s]",
  Text = mega.utf8(0xf52b) .. " [text]",
  Buffers = mega.utf8(0xf64d) .. " [buff]",
  TypeParameter = mega.utf8(0xf635) .. " [type]"
}

function M.activate()
  -- [ snippets ] --------------------------------------------------------------
  vim.api.nvim_set_var("vsnip_snippet_dir", vim.fn.stdpath("config").."/vsnips")

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
        enable_auto_paren = 1,
        enable_auto_hover = 1,
        completion_enable_fuzzy_match = 1,
        completion_enable_snippet = "vim-vsnip",
        completion_trigger_on_delete = 0,
        completion_trigger_keyword_length = 2,
        completio_sorting = "none",
        max_items = 10,
        sorting = "none", -- 'alphabet'
        matching_strategy_list = {"exact", "substring", "fuzzy"},
        matching_smart_case = 1
      }
    )
  end
end

return M
