local api = vim.api

local cmp = require("cmp")
local luasnip = require("luasnip")
local utils = require("mega.utils")
local t = mega.replace_termcodes

local M = {
  sources = {},
}

local function setup_luasnip()
  local types = require("luasnip.util.types")
  luasnip.config.set_config({
    history = true,
    updateevents = "TextChangedI",
    store_selection_keys = "<Tab>",
    ext_opts = {
      -- [types.insertNode] = {
      --   passive = {
      --     hl_group = "Substitute",
      --   },
      -- },
      [types.choiceNode] = {
        active = {
          virt_text = { { "choiceNode", "IncSearch" } },
        },
      },
    },
    enable_autosnippets = true,
  })

  -- TODO: we want to do our own luasnippets .. se this link for more details of
  -- how we might want to do this: https://youtu.be/Dn800rlPIho

  --- <tab> to jump to next snippet's placeholder
  local function on_tab()
    return luasnip.jump(1) and "" or utils.t("<Tab>")
  end

  --- <s-tab> to jump to next snippet's placeholder
  local function on_s_tab()
    return luasnip.jump(-1) and "" or utils.t("<S-Tab>")
  end

  local opts = { expr = true, remap = true }
  imap("<Tab>", on_tab, opts)
  smap("<Tab>", on_tab, opts)
  imap("<S-Tab>", on_s_tab, opts)
  smap("<S-Tab>", on_s_tab, opts)
end

local function setup_cmp()
  -- [nvim-cmp] --
  local has_words_before = function()
    local line, col = unpack(api.nvim_win_get_cursor(0))
    return col ~= 0 and api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
  end

  local function tab(fallback)
    if cmp.visible() then
      cmp.select_next_item()
    elseif luasnip and luasnip.expand_or_locally_jumpable() then
      luasnip.expand_or_jump()
    elseif has_words_before() then
      cmp.complete()
    else
      fallback()
    end
  end

  local function shift_tab(fallback)
    if cmp.visible() then
      cmp.select_prev_item()
    elseif luasnip and luasnip.jumpable(-1) then
      luasnip.jump(-1)
    else
      fallback()
    end
  end

  --cmp source setups
  require("cmp_nvim_lsp").setup()
  -- require("cmp_git").setup({
  --   filetypes = { "gitcommit", "NeogitCommitMessage" },
  -- })

  M.sources.buffer = {
    name = "buffer",
    option = {
      keyword_length = 5,
      max_item_count = 5, -- only show up to 5 items.
      get_bufnrs = function()
        return vim.api.nvim_list_bufs()
      end,
    },
  }
  M.sources.search = {
    sources = cmp.config.sources({
      { name = "nvim_lsp_document_symbol" }, -- initiate with `@`
    }, {
      M.sources.buffer,
      -- { name = "fuzzy_buffer" },
    }),
  }

  cmp.setup({
    view = {
      entries = "custom",
    },
    experimental = {
      -- ghost_text = {
      --   hl_group = "LineNr",
      -- },
      ghost_text = false,
      -- horizontal_search = true,
      -- native_menu = false, -- false == use fancy floaty menu for now
    },
    completion = {
      keyword_length = 1,
    },
    snippet = {
      expand = function(args)
        luasnip.lsp_expand(args.body)
      end,
    },
    -- window = {
    --   completion = {
    -- border = mega.get_border(),
    --   },
    --   documentation = {
    -- border = mega.get_border(),
    --   },
    -- },
    documentation = {
      border = mega.get_border(),
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
    -- see more configured sources in ftplugins/<filetype>.lua
    sources = cmp.config.sources({
      { name = "luasnip" },
      { name = "nvim_lsp" },
      -- { name = "nvim_lsp_signature_help" },
      { name = "path" },
      { name = "emmet_ls" },
    }, {
      M.sources.buffer,
      -- { name = "fuzzy_buffer" },
    }),
    formatting = {
      deprecated = true,
      -- fields = { "kind", "abbr", "menu" }, -- determines order of menu items
      format = function(entry, item)
        item.kind = mega.icons.lsp.kind[item.kind]

        if entry.source.name == "nvim_lsp" then
          item.menu = entry.source.source.client.name
        else
          item.menu = ({
            luasnip = "[lsnip]",
            nvim_lua = "[lua]",
            nvim_lsp = "[lsp]",
            -- nvim_lsp_signature_help = "[sig]",
            orgmode = "[org]",
            path = "[path]",
            buffer = "[buf]",
            spell = "[spl]",
            emoji = "[emo]",
          })[entry.source.name] or entry.source.name
        end

        return item
      end,
    },
  })
  cmp.setup.cmdline("/", M.sources.search)
  cmp.setup.cmdline("?", M.sources.search)
  cmp.setup.cmdline(":", {
    sources = cmp.config.sources({
      -- { name = "fuzzy_path" },
      { name = "path" },
    }, {
      -- { name = "cmdline" },
      { name = "cmdline", keyword_pattern = [=[[^[:blank:]\!]*]=] },
    }),
  })

  -- If you want insert `(` after select function or method item
  local cmp_autopairs = require("nvim-autopairs.completion.cmp")
  cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

  cmp.setup.filetype("gitcommit", {
    sources = {
      { name = "cmp_git" },
      M.sources.buffer,
      { name = "spell" },
      { name = "emoji" },
    },
    -- sources = cmp.config.sources({
    --   { name = "cmp_git" },
    -- }, {
    --   { name = "buffer" },
    -- }),
  })
end

setup_luasnip()
setup_cmp()

return M
