local api = vim.api

local cmp = require("cmp")
local ls = require("luasnip")

-- [nvim-cmp] --
local has_words_before = function()
  local line, col = unpack(api.nvim_win_get_cursor(0))
  return col ~= 0 and api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local function tab(fallback)
  if cmp.visible() then
    cmp.select_next_item()
  elseif ls and ls.expand_or_locally_jumpable() then
    ls.expand_or_jump()
  elseif has_words_before() then
    cmp.complete()
  else
    fallback()
  end
end

local function shift_tab(fallback)
  if cmp.visible() then
    cmp.select_prev_item()
  elseif ls and ls.jumpable(-1) then
    ls.jump(-1)
  else
    fallback()
  end
end

-- local buffer_source = {
--   name = "buffer",
--   option = {
--     keyword_length = 5,
--     max_item_count = 5, -- only show up to 5 items.
--     get_bufnrs = function()
--       return vim.api.nvim_list_bufs()
--     end,
--   },
-- }

local search_sources = {
  view = {
    entries = { name = "custom", direction = "bottom_up" },
  },
  sources = cmp.config.sources({
    { name = "nvim_lsp_document_symbol" },
  }, {
    { name = "buffer" },
  }),
}

local cmp_window = {
  border = mega.get_border(),
  winhighlight = table.concat({
    "Normal:NormalFloat",
    "FloatBorder:FloatBorder",
    "CursorLine:Visual",
    "Search:None",
  }, ","),
}
cmp.setup({
  preselect = cmp.PreselectMode.None,
  view = { entries = "custom" },
  completion = {
    keyword_length = 1,
    get_trigger_characters = function(trigger_characters)
      return vim.tbl_filter(function(char)
        return char ~= " "
      end, trigger_characters)
    end,
  },
  experimental = {
    ghost_text = true,
  },
  snippet = {
    expand = function(args)
      ls.lsp_expand(args.body)
    end,
  },
  window = {
    completion = cmp.config.window.bordered(cmp_window),
    documentation = cmp.config.window.bordered(cmp_window),
  },
  mapping = {
    ["<Tab>"] = cmp.mapping(tab, { "i", "s", "c" }),
    ["<S-Tab>"] = cmp.mapping(shift_tab, { "i", "s", "c" }),
    ["<C-n>"] = cmp.mapping(tab, { "i", "s", "c" }),
    ["<C-p>"] = cmp.mapping(shift_tab, { "i", "s", "c" }),
    ["<C-b>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), { "i", "c" }),
    ["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(4), { "i", "c" }),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm({ select = false }),
    -- ["<C-e>"] = cmp.mapping.close(),
    ["<C-e>"] = function(fallback)
      if cmp.visible() then
        cmp.confirm({ select = true })
        cmp.complete()
      else
        fallback()
      end
    end,
  },
  -- see more configured sources in ftplugins/<filetype>.lua
  sources = cmp.config.sources({
    { name = "luasnip" },
    { name = "nvim_lsp" },
    -- { name = "nvim_lsp_signature_help" },
    { name = "treesitter" },
    -- { name = "buffer", keyword_length = 3 },
    { name = "path" },
    -- { name = "emmet_ls" },
  }, {
    { name = "buffer", keyword_length = 3 },
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
          nvim_lua = "[nlua]",
          nvim_lsp = "[lsp]",
          nvim_lsp_signature_help = "[sig]",
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

cmp.setup.cmdline("/", search_sources)
cmp.setup.cmdline("?", search_sources)
cmp.setup.cmdline(":", {
  sources = cmp.config.sources({
    { name = "cmdline", keyword_pattern = [=[[^[:blank:]\!]*]=] },
  }),
})

-- FT specific cmp configs
cmp.setup.filetype("gitcommit", {
  sources = {
    { name = "cmp_git" },
    { name = "spell" },
    { name = "emoji" },
  },
  { name = "buffer" },
})

cmp.setup.filetype("lua", {
  sources = {
    { name = "luasnip" },
    { name = "nvim_lua" },
    { name = "nvim_lsp" },
    { name = "path" },
  },
  { name = "buffer" },
})

-- If you want insert `(` after select function or method item
local cmp_autopairs = require("nvim-autopairs.completion.cmp")
cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
