local has_lsp, _ = pcall(require, "lspconfig")
if not has_lsp then
  print("[WARN] lspconfig not found/installed/loaded..")

  return
end

local M = {}

function M.activate()
  vim.cmd([[ set completeopt=menu,menuone,noselect ]])
  vim.cmd [[ set shortmess+=c ]]

  require("lspkind").init()

  -- [ snippets ] --------------------------------------------------------------
  vim.g.vsnip_snippet_dir = vim.fn.stdpath("config") .. "/vsnips"
  -- vim.api.nvim_set_var("vsnip_snippet_dir", vim.fn.stdpath("config") .. "/vsnips")

  -- [ nvim-compe ] ------------------------------------------------------------
  -- TODO/REFS:
  -- https://github.com/elianiva/dotfiles/blob/master/nvim/.config/nvim/lua/plugin/_completion.lua
  -- https://github.com/ahmedelgabri/dotfiles/blob/master/config/.vim/lua/_/completion.lua
  -- https://github.com/YaBoiBurner/dotfiles/blob/dom/.config/nvim/lua/plugins.lua#L104-L154
  local has_compe, compe = pcall(require, "compe")
  if has_compe then
    compe.setup(
      {
        enabled = true,
        debug = false,
        min_length = 1,
        preselect = "disable",
        allow_prefix_unmatch = false,
        throttle_time = 120,
        source_timeout = 200,
        incomplete_delay = 400,
        documentation = true,
        source = {
          nvim_lsp = {menu = "[LSP]", priority = 10, sort = false},
          vsnip = {menu = "[VS]", priority = 10},
          nvim_lua = {menu = "[LUA]", priority = 9},
          path = {menu = "[PATH]", priority = 9},
          treesitter = {menu = "[TS]", priority = 9},
          buffer = {menu = "[BUF]", priority = 8},
          spell = {menu = "[SPL]"},
          orgmode = {menu = "[ORG]"}
        }
      }
    )

    if true then
      -- lexima
      -- https://github.com/hrsh7th/nvim-compe/blob/master/README.md#how-to-use-tab-to-navigate-completion-menu
      -- https://github.com/hrsh7th/nvim-compe/blob/master/README.md#mappings (for lexima)
      local t = function(str)
        return vim.api.nvim_replace_termcodes(str, true, true, true)
      end

      local check_back_space = function()
        local col = vim.fn.col(".") - 1
        if col == 0 or vim.fn.getline("."):sub(col, col):match("%s") then
          return true
        else
          return false
        end
      end

      -- Use (s-)tab to:
      --- move to prev/next item in completion menuone
      --- jump to prev/next snippet's placeholder
      _G.tab_complete = function()
        if vim.fn.pumvisible() == 1 then
          return t "<C-n>"
        elseif vim.fn.call("vsnip#available", {1}) == 1 then
          return t "<Plug>(vsnip-expand-or-jump)"
        elseif check_back_space() then
          return t "<Tab>"
        else
          return vim.fn["compe#complete"]()
        end
      end
      _G.s_tab_complete = function()
        if vim.fn.pumvisible() == 1 then
          return t "<C-p>"
        elseif vim.fn.call("vsnip#jumpable", {-1}) == 1 then
          return t "<Plug>(vsnip-jump-prev)"
        else
          return t "<S-Tab>"
        end
      end

      vim.api.nvim_set_keymap("i", "<Tab>", "v:lua.tab_complete()", {expr = true})
      vim.api.nvim_set_keymap("s", "<Tab>", "v:lua.tab_complete()", {expr = true})
      vim.api.nvim_set_keymap("i", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
      vim.api.nvim_set_keymap("s", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})

      -- vim.cmd([[inoremap <silent><expr> <C-Space> compe#complete()]])
      mega.map(
        "i",
        "<CR>",
        [[compe#confirm(lexima#expand('<LT>CR>', 'i'))]],
        {expr = true, noremap = true, silent = true}
      )
      mega.map("i", "<C-e>", [[compe#close('<C-e>')]], {expr = true, noremap = true, silent = true})
      vim.cmd([[inoremap <silent><expr> <C-f>     compe#scroll({ 'delta': +4 })]])
      vim.cmd([[inoremap <silent><expr> <C-d>     compe#scroll({ 'delta': -4 })]])
    end

    if false then
      -- nvim-autopairs
      local npairs = require("nvim-autopairs")
      -- https://github.com/lukas-reineke/dotfiles/blob/master/vim/init.vim#L26-L30
      _G.completion_confirm = function()
        if vim.fn.pumvisible() ~= 0 then
          if vim.fn.complete_info()["selected"] ~= -1 then
            vim.fn["compe#confirm"]()
            return npairs.esc("")
          else
            vim.api.nvim_select_popupmenu_item(0, false, false, {})
            vim.fn["compe#confirm"]()
            return npairs.esc("<c-n>")
          end
        else
          return npairs.check_break_line_char()
        end
      end

      _G.tab = function()
        if vim.fn.pumvisible() ~= 0 then
          return npairs.esc("<C-n>")
        else
          if vim.fn["vsnip#available"](1) ~= 0 then
            vim.fn.feedkeys(string.format("%c%c%c(vsnip-expand-or-jump)", 0x80, 253, 83))
            return npairs.esc("")
          else
            return npairs.esc("<Tab>")
          end
        end
      end

      _G.s_tab = function()
        if vim.fn.pumvisible() ~= 0 then
          return npairs.esc("<C-p>")
        else
          if vim.fn["vsnip#jumpable"](-1) ~= 0 then
            vim.fn.feedkeys(string.format("%c%c%c(vsnip-jump-prev)", 0x80, 253, 83))
            return npairs.esc("")
          else
            return npairs.esc("<C-h>")
          end
        end
      end

      -- Autocompletion and snippets
      -- https://github.com/33kk/dotfiles/blob/master/nvim/lua/plugins/compe.lua#L38-L76
      mega.map("i", "<CR>", "v:lua.completion_confirm()", {expr = true, noremap = true})

      -- NOTE: Order is important. You can't lazy loading lexima.vim.
      -- vim.g.lexima_no_default_rules = true
      -- vim.cmd([[call lexima#set_default_rules()]])
      -- inoremap <silent><expr> <CR>
      -- mega.map("i", "<CR>", "<cmd>compe#confirm(lexima#expand('<LT>CR>', 'i'))", {expr = true, noremap = true})
      mega.map("i", "<Tab>", "v:lua.tab()", {expr = true, noremap = true})
      mega.map("s", "<Tab>", "v:lua.tab()", {expr = true, noremap = true})
      mega.map("i", "<S-Tab>", "v:lua.s_tab()", {expr = true, noremap = true})
      mega.map("s", "<S-Tab>", "v:lua.s_tab()", {expr = true, noremap = true})
    end
  end
end

return M
