local api = vim.api

local cmp = require("cmp")
local luasnip = require("luasnip")
local utils = require("utils")
local t = mega.replace_termcodes

local M = {
  sources = {},
}

local function setup_copilot()
  vim.g.copilot_no_tab_map = true
  vim.g.copilot_assume_mapped = true
  vim.g.copilot_tab_fallback = ""
  vim.g.copilot_filetypes = {
    ["*"] = true,
    gitcommit = false,
    NeogitCommitMessage = false,
  }
  imap("<C-h>", [[copilot#Accept("\<CR>")]], { expr = true, script = true })
end

local function setup_luasnip()
  local types = require("luasnip.util.types")
  luasnip.config.set_config({
    history = false,
    updateevents = "TextChanged,TextChangedI",
    store_selection_keys = "<Tab>",
    ext_opts = {
      [types.insertNode] = {
        passive = {
          hl_group = "Substitute",
        },
      },
      [types.choiceNode] = {
        active = {
          virt_text = { { "choiceNode", "IncSearch" } },
        },
      },
    },
    enable_autosnippets = true,
  })
  require("luasnip/loaders/from_vscode").lazy_load()

  --- <tab> to jump to next snippet's placeholder
  local function on_tab()
    return luasnip.jump(1) and "" or utils.t("<Tab>")
  end
  --- <s-tab> to jump to next snippet's placeholder
  local function on_s_tab()
    return luasnip.jump(-1) and "" or utils.t("<S-Tab>")
  end
  local opts = { expr = true, noremap = false }
  imap("<Tab>", on_tab, opts)
  smap("<Tab>", on_tab, opts)
  imap("<S-Tab>", on_s_tab, opts)
  smap("<S-Tab>", on_s_tab, opts)
end

local function setup_cmp()
  -- [nvim-cmp] --
  local kind_icons = {
    Text = " text", -- Text
    Method = " method", -- Method
    Function = " function", -- Function
    Constructor = " constructor", -- Constructor
    Field = "ﰠ field", -- Field
    Variable = " variable", -- Variable
    Class = " class", -- Class
    Interface = "ﰮ interface", -- Interface
    Module = " module", -- Module
    Property = " property", -- Property
    Unit = " unit", -- Unit
    Value = " value", -- Value
    Enum = "了enum", -- Enum 
    Keyword = " keyword", -- Keyword
    Snippet = " snippet", -- Snippet
    Color = " color", -- Color
    File = " file", -- File
    Reference = " ref", -- Reference
    Folder = " folder", -- Folder
    EnumMember = " enum member", -- EnumMember
    Constant = " const", -- Constant
    Struct = "פּ struct", -- Struct
    Event = "鬒event", -- Event
    Operator = "\u{03a8} operator", -- Operator
    TypeParameter = " type param", -- TypeParameter
  }

  local function feed(key, mode)
    api.nvim_feedkeys(t(key), mode or "", true)
  end

  local function tab(fallback)
    -- local copilot_keys = vim.fn["copilot#Accept"]()
    if cmp.visible() then
      cmp.select_next_item()
      -- elseif copilot_keys ~= "" then -- prioritise copilot over snippets
      --   -- Copilot keys do not need to be wrapped in termcodes
      --   print("copilot! <tab>")
      --   api.nvim_feedkeys(copilot_keys, "i", true)
    elseif luasnip and luasnip.expand_or_locally_jumpable() then
      luasnip.expand_or_jump()
    elseif api.nvim_get_mode().mode == "c" then
      fallback()
    else
      feed("<Plug>(Tabout)")
    end
  end

  local function shift_tab(fallback)
    if cmp.visible() then
      cmp.select_prev_item()
    elseif luasnip and luasnip.jumpable(-1) then
      luasnip.jump(-1)
    elseif api.nvim_get_mode().mode == "c" then
      fallback()
    else
      -- local copilot_keys = vim.fn["copilot#Accept"]()
      -- if copilot_keys ~= "" then
      --   print("copilot! <s-tab>")
      --   feed(copilot_keys, "i")
      -- else
      feed("<Plug>(Tabout)")
      -- end
    end
  end

  --cmp source setups
  require("cmp_nvim_lsp").setup()
  local compare = require("cmp.config.compare")

  M.sources.buffer = {
    name = "buffer",
    option = {
      keyword_length = 3, -- start completion after 5 chars.
      max_item_count = 5, -- only show up to 5 items.
      get_bufnrs = function()
        -- local bufs = {}
        -- for _, win in ipairs(vim.api.nvim_list_wins()) do
        --   bufs[vim.api.nvim_win_get_buf(win)] = true
        -- end
        -- return vim.tbl_keys(bufs)

        return vim.api.nvim_list_bufs()
      end,
    },
  }

  cmp.setup({
    experimental = {
      -- ghost_text = {
      --   hl_group = "LineNr",
      -- },
      ghost_text = false,
      native_menu = false, -- false == use fancy floaty menu for now
    },
    completion = {
      keyword_length = 1,
    },
    snippet = {
      expand = function(args)
        luasnip.lsp_expand(args.body)
      end,
    },
    documentation = {
      border = "rounded",
    },
    mapping = {
      ["<Tab>"] = cmp.mapping(tab, { "i", "s" }),
      ["<S-Tab>"] = cmp.mapping(shift_tab, { "i", "s" }),
      ["<C-b>"] = cmp.mapping.scroll_docs(-4),
      ["<C-f>"] = cmp.mapping.scroll_docs(4),
      ["<C-Space>"] = cmp.mapping.complete(),
      ["<CR>"] = cmp.mapping.confirm({ select = false }),
      ["<C-e>"] = cmp.mapping.close(),
    },
    sources = cmp.config.sources({
      { name = "luasnip" },
      { name = "nvim_lua" },
      { name = "nvim_lsp" },
      { name = "emoji" },
      { name = "path" },
    }, {
      M.sources.buffer,
    }),
    sorting = {
      priority_weight = 1.1,
      comparators = {
        function(...)
          return require("cmp_buffer"):compare_locality(...)
        end,
        compare.offset,
        compare.exact,
        compare.score,
        compare.kind,
        compare.sort_text,
        compare.length,
        compare.order,
      },
    },
    formatting = {
      deprecated = true,
      -- fields = { "kind", "abbr", "menu" }, -- determines order of menu items
      format = function(entry, item)
        item.kind = kind_icons[item.kind]
        item.menu = ({
          luasnip = "[lsnip]",
          nvim_lua = "[lua]",
          nvim_lsp = "[lsp]",
          orgmode = "[org]",
          path = "[path]",
          buffer = "[buf]",
          spell = "[spl]",
          -- calc = "[calc]",
          -- emoji = "[emo]",
        })[entry.source.name]
        return item
      end,
    },
  })
  M.sources.search = {
    sources = cmp.config.sources({
      { name = "nvim_lsp_document_symbol" }, -- initiate with `@`
    }, {
      M.sources.buffer,
    }),
  }
  cmp.setup.cmdline("/", M.sources.search)
  cmp.setup.cmdline("?", M.sources.search)
  cmp.setup.cmdline(":", {
    sources = cmp.config.sources({
      { name = "path" },
    }, {
      { name = "cmdline" },
    }),
  })

  -- If you want insert `(` after select function or method item
  local cmp_autopairs = require("nvim-autopairs.completion.cmp")
  cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
end

M.setup = function()
  -- setup_copilot()
  setup_luasnip()
  setup_cmp()
end

return M
