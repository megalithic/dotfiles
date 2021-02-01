local has_lsp, _ = pcall(require, "lspconfig")
if not has_lsp then
  print("[WARN] lspconfig not found/installed/loaded..")

  return
end

local M = {}

function M.activate()
  vim.cmd([[ set completeopt=menu,menuone,noselect ]])
  vim.cmd [[ set shortmess+=c ]]

  -- [ snippets ] --------------------------------------------------------------
  vim.g.vsnip_snippet_dir = vim.fn.stdpath("config") .. "/vsnips"
  -- vim.api.nvim_set_var("vsnip_snippet_dir", vim.fn.stdpath("config") .. "/vsnips")

  -- [ nvim-completion ] --------------------------------------------------------------
  local has_completion, completion = pcall(require, "completion")
  if has_completion then
    local chain_complete_list = {
      default = {
        {complete_items = {"lsp", "snippet"}},
        {complete_items = {"ts"}},
        {complete_items = {"buffers"}},
        {complete_items = {"path"}, triggered_only = {"./", "/"}},
        {mode = "<c-p>"},
        {mode = "<c-n>"}
        -- {mode = "dict"},
        -- {mode = "spel"}
      },
      string = {
        {complete_items = {"path"}, triggered_only = {"./", "/"}},
        {complete_items = {"buffers"}}
      },
      comment = {}
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
      ["vim-vsnip"] = mega.utf8(0xf68e) .. " [vs1]",
      ["vsnip"] = mega.utf8(0xf68e) .. " [vs2]",
      Snippet = mega.utf8(0xf68e) .. " [s]",
      Text = mega.utf8(0xf52b) .. " [text]",
      Buffers = mega.utf8(0xf64d) .. " [buff]",
      TypeParameter = mega.utf8(0xf635) .. " [type]"
    }

    completion.on_attach(
      {
        chain_complete_list = chain_complete_list,
        customize_lsp_label = customize_lsp_label,
        enable_auto_popup = 1,
        enable_auto_signature = 1,
        auto_change_source = 1,
        enable_auto_paren = 1,
        enable_auto_hover = 1,
        completion_auto_change_source = 1,
        completion_enable_fuzzy_match = 1,
        completion_enable_snippet = "vim-vsnip",
        completion_trigger_on_delete = 0,
        completion_trigger_keyword_length = 1,
        completio_sorting = "none",
        max_items = 10,
        sorting = "none", -- 'alphabet'
        matching_strategy_list = {"exact", "substring", "fuzzy"},
        matching_smart_case = 1,
        completion_items_priority = {
          ["vim-vsnip"] = 0
        }
      }
    )
  end

  -- [ nvim-compe ] ------------------------------------------------------------
  -- TODO/REFS:
  -- https://github.com/elianiva/dotfiles/blob/master/nvim/.config/nvim/lua/plugin/_completion.lua
  -- https://github.com/ahmedelgabri/dotfiles/blob/master/config/.vim/lua/_/completion.lua
  local has_compe, compe = pcall(require, "compe")
  if has_compe then
    compe.setup(
      {
        enabled = true,
        debug = false,
        min_length = 1,
        preselect = "enable",
        allow_prefix_unmatch = false,
        throttle_time = 120,
        source_timeout = 200,
        incomplete_delay = 400,
        source = {
          vsnip = true,
          nvim_lsp = true,
          nvim_lua = true,
          buffer = true,
          path = true,
          spell = true
        }
      }
    )
  end
end
return M
