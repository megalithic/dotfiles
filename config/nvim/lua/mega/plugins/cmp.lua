return {
  "hrsh7th/nvim-cmp",
  event = { "InsertEnter" },
  dependencies = {
    { "saadparwaiz1/cmp_luasnip", cond = vim.g.snipper == "luasnip" },
    {
      "hrsh7th/cmp-vsnip",
      dependencies = {
        {
          "hrsh7th/vim-vsnip",
          event = "InsertEnter",
          cond = vim.g.snipper == "vsnip",
          init = function()
            vim.g.vsnip_snippet_dir = vim.fn.fnamemodify(vim.env.MYVIMRC, ":p:h") .. "/snippets"
            vim.g.vsnip_filetypes = {
              typescript = { "javascript" },
              typescriptreact = { "javascript" },
              javascriptreact = { "javascript" },
            }
          end,
        },
      },
    },
    { "hrsh7th/cmp-buffer" },
    { "hrsh7th/cmp-nvim-lsp" },
    { "hrsh7th/cmp-nvim-lua" },
    { "hrsh7th/cmp-path" },
    { "hrsh7th/cmp-emoji" },
    { "f3fora/cmp-spell" },
    { "hrsh7th/cmp-cmdline", event = { "CmdlineEnter" } },
    { "hrsh7th/cmp-nvim-lsp-signature-help" },
    { "hrsh7th/cmp-nvim-lsp-document-symbol" },
    { "lukas-reineke/cmp-rg" },
    { "davidsierradz/cmp-conventionalcommits" },
    -- { "dmitmel/cmp-cmdline-history"},
    -- { "kristijanhusak/vim-dadbod-completion"},
  },
  init = function() vim.opt.completeopt = { "menu", "menuone", "noselect", "noinsert" } end,
  config = function()
    local cmp = require("cmp")

    local fmt = string.format
    local api = vim.api

    local function esc(cmd) return vim.api.nvim_replace_termcodes(cmd, true, false, true) end

    -- [nvim-cmp] --
    local has_words_before = function()
      local line, col = unpack(api.nvim_win_get_cursor(0))
      return col ~= 0 and api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
    end

    local tab = nil
    local shift_tab = nil

    if vim.g.snipper == "luasnip" then
      -- [luasnip] --
      local ok_ls, ls = mega.require("luasnip")
      tab = function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif ok_ls and ls and ls.expand_or_locally_jumpable() then
          ls.expand_or_jump()
        elseif has_words_before() then
          cmp.complete()
        else
          fallback()
        end
      end

      shift_tab = function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif ok_ls and ls and ls.jumpable(-1) then
          ls.jump(-1)
        else
          fallback()
        end
      end
    elseif vim.g.snipper == "vsnip" then
      -- [vsnip] --
      tab = function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif vim.fn["vsnip#jumpable"](1) > 0 then
          vim.fn.feedkeys(esc("<Plug>(vsnip-jump-next)"), "")
        elseif has_words_before() then
          cmp.complete()
        -- elseif vim.fn["vsnip#expandable"]() > 0 then
        --   vim.fn.feedkeys(esc("<Plug>(vsnip-expand)"), "")
        -- elseif require("copilot.suggestion").is_visible() then
        --   require("copilot.suggestion").accept()
        else
          fallback()
        end
      end

      shift_tab = function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif vim.fn["vsnip#jumpable"](-1) == 1 then
          vim.fn.feedkeys(esc("<Plug>(vsnip-jump-prev)"), "")
        else
          fallback()
        end
      end
    end

    local cmp_window = {
      border = "none",
      winhighlight = table.concat({
        "Normal:NormalFloat",
        "FloatBorder:FloatBorder",
        "CursorLine:Visual",
        "Search:None",
      }, ","),
    }

    cmp.setup({
      -- experimental = { ghost_text = {
      --   hl_group = "LspCodeLens",
      -- } },
      matching = {
        disallow_partial_fuzzy_matching = false,
      },
      enabled = function()
        if vim.bo.buftype == "prompt" or vim.g.started_by_firenvim then return false end

        return true
      end,
      preselect = cmp.PreselectMode.None,
      entries = { name = "custom", selection_order = "near_cursor" },
      completion = {
        keyword_length = 1,
        get_trigger_characters = function(trigger_characters)
          return vim.tbl_filter(function(char) return char ~= " " end, trigger_characters)
        end,
      },
      snippet = {
        expand = function(args)
          if vim.g.snipper == "luasnip" then
            ls.lsp_expand(args.body)
          elseif vim.g.snipper == "vsnip" then
            vim.fn["vsnip#anonymous"](args.body)
          end
        end,
      },
      window = {
        completion = {
          winhighlight = table.concat({
            "Normal:NormalFloat",
            "FloatBorder:FloatBorder",
            "CursorLine:Visual",
            "Search:None",
          }, ","),
          zindex = 1001,
          col_offset = 0,
          border = mega.get_border(),
          side_padding = 1,
        },
        documentation = cmp.config.window.bordered(cmp_window),
      },
      mapping = {
        ["<Tab>"] = cmp.mapping(tab, { "i", "s", "c" }),
        ["<S-Tab>"] = cmp.mapping(shift_tab, { "i", "s", "c" }),
        ["<C-n>"] = cmp.mapping(tab, { "i", "s", "c" }),
        ["<C-p>"] = cmp.mapping(shift_tab, { "i", "s", "c" }),
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-y>"] = cmp.mapping.confirm({ select = true }),
        ["<CR>"] = function(fallback)
          if vim.g.snipper == "luasnip" then
            cmp.mapping.confirm({ select = false })
          elseif vim.g.snipper == "vsnip" then
            if vim.fn["vsnip#expandable"]() ~= 0 then
              vim.fn.feedkeys(esc("<Plug>(vsnip-expand)"), "")
              return
            end
            return cmp.mapping.confirm({ select = false, behavior = cmp.ConfirmBehavior.Replace })(fallback)
          end
        end,
        ["<C-e>"] = cmp.mapping.abort(),
      },
      formatting = {
        deprecated = true,
        fields = { "abbr", "kind", "menu" },
        format = function(entry, item)
          if item.kind == "Color" and entry.completion_item.documentation then
            local _, _, r, g, b = string.find(entry.completion_item.documentation, "^rgb%((%d+), (%d+), (%d+)")
            if r then
              local color = string.format("%02x", r) .. string.format("%02x", g) .. string.format("%02x", b)
              local hl_group = "Tw_" .. color
              if vim.fn.hlID(hl_group) < 1 then vim.api.nvim_set_hl(0, hl_group, { fg = "#" .. color }) end
              item.kind = ""
              item.kind_hl_group = hl_group
            end
          else
            item.kind = fmt("%s %s", mega.icons.lsp.kind[item.kind], item.kind)
          end

          -- local max_length = 20
          local max_length = math.floor(vim.o.columns * 0.5)
          item.abbr = #item.abbr >= max_length and string.sub(item.abbr, 1, max_length) .. mega.icons.misc.ellipsis
            or item.abbr

          if entry.source.name == "nvim_lsp" then
            item.menu = entry.source.source.client.name
          else
            item.menu = ({
              nvim_lsp = "[lsp]",
              -- luasnip = "[lsnip]",
              vsnip = "[vsnip]",
              nvim_lua = "[nlua]",
              nvim_lsp_signature_help = "[sig]",
              path = "[path]",
              -- rg = "[rg]",
              buffer = "[buf]",
              spell = "[spl]",
              neorg = "[neorg]",
              cmdline = "[cmd]",
              cmdline_history = "[cmdhist]",
              emoji = "[emo]",
            })[entry.source.name] or entry.source.name
          end

          return item
        end,
      },
      sources = cmp.config.sources({
        -- { name = "nvim_lsp_signature_help" },
        { name = "vsnip" },
        -- { name = "luasnip" },
        { name = "nvim_lsp" },
        { name = "path", option = { trailing_slash = true } },
      }, {
        {
          name = "buffer",
          keyword_length = 4,
          options = {
            get_bufnrs = function() return vim.tbl_map(vim.api.nvim_win_get_buf, vim.api.nvim_list_wins()) end,
          },
        },
        { name = "spell" },
      }),
    })

    cmp.setup.cmdline({ "/", "?" }, {
      -- view = {
      --   entries = { name = "custom", direction = "bottom_up" },
      -- },
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({ { name = "nvim_lsp_document_symbol" } }, { { name = "buffer" } }),
    })

    cmp.setup.cmdline(":", {
      sources = cmp.config.sources({
        { name = "cmdline", keyword_pattern = [=[[^[:blank:]\!]*]=] },
        { name = "path" },
        -- { name = "cmdline_history", priority = 10, max_item_count = 3 },
      }),
    })

    cmp.setup.filetype({ "gitcommit", "NeogitCommitMessage" }, {
      sources = {
        { name = "conventionalcommits" },
        { name = "path" },
      },
      { name = "buffer" },
    })

    -- cmp.setup.filetype({"lua"}, {
    --   sources = {
    --     { name = "luasnip" },
    --     { name = "nvim_lua" },
    --     { name = "nvim_lsp" },
    --     { name = "path" },
    --   },
    --   { name = "buffer" },
    -- })

    -- cmp.setup.filetype({ "sql", "mysql", "plsql" }, {
    --   sources = {
    --     { name = "vim-dadbod-completion" },
    --   },
    -- })

    cmp.setup.filetype({ "dap-repl", "dapui_watches" }, {
      sources = {
        { name = "dap" },
      },
    })

    -- require("cmp.entry").get_documentation = function(self)
    --   local item = self:get_completion_item()
    --   if item.documentation then return require("mega.utils").format_markdown(item.documentation) end
    --   return {}
    -- end
  end,
}
