local SETTINGS = require("mega.settings")
local icons = SETTINGS.icons
local fmt = string.format

return {
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter *", "CmdlineEnter *" },
    dependencies = {
      {
        "saadparwaiz1/cmp_luasnip",
        cond = vim.g.snipper == "luasnip",
        dependencies = {
          {
            "L3MON4D3/LuaSnip",
            cond = vim.g.snipper == "luasnip",
            build = (function()
              -- Build Step is needed for regex support in snippets.
              -- This step is not supported in many windows environments.
              -- Remove the below condition to re-enable on windows.
              if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then return end
              return "make install_jsregexp"
            end)(),
            dependencies = {
              -- `friendly-snippets` contains a variety of premade snippets.
              --    See the README about individual language/framework/plugin snippets:
              --    https://github.com/rafamadriz/friendly-snippets
              -- {
              --   'rafamadriz/friendly-snippets',
              --   config = function()
              --     require('luasnip.loaders.from_vscode').lazy_load()
              --   end,
              -- },
            },
          },
        },
      },
      {
        "garymjr/nvim-snippets",
        cond = vim.g.snipper == "snippets",
        dependencies = {
          "rafamadriz/friendly-snippets",
        },
        opts = {
          friendly_snippets = false,
          -- extended_filetypes = {
          --   eelixir = { "elixir" },
          -- },
          create_autocmd = true,
          -- search_paths = { vim.fn.stdpath("config") .. "/snippets" },
        },
      },
      { "hrsh7th/cmp-buffer" },
      {
        "tzachar/cmp-fuzzy-buffer",
        dependencies = { "tzachar/fuzzy.nvim" },
      },
      { "hrsh7th/cmp-nvim-lsp" },
      { "hrsh7th/cmp-nvim-lua" },
      { "hrsh7th/cmp-path" },
      { "FelipeLema/cmp-async-path" },
      { "hrsh7th/cmp-cmdline" }, -- event = { "CmdlineEnter" } },
      { "hrsh7th/cmp-nvim-lsp-signature-help" },
      { "hrsh7th/cmp-nvim-lsp-document-symbol" },
      -- { "hrsh7th/cmp-emoji" },
      { "f3fora/cmp-spell" },
      { "lukas-reineke/cmp-rg" },
      { "lukas-reineke/cmp-under-comparator" },
      -- { "davidsierradz/cmp-conventionalcommits" },
      { "dmitmel/cmp-cmdline-history" },
      { "andersevenrud/cmp-tmux", cond = false },
      -- { "kristijanhusak/vim-dadbod-completion"},
    },
    init = function() vim.opt.completeopt = { "menu", "menuone", "noinsert", "noselect" } end,
    config = function()
      local cmp = require("cmp")
      local MIN_MENU_WIDTH, MAX_MENU_WIDTH = 25, math.min(50, math.floor(vim.o.columns * 0.5))

      local has_words_before = function()
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end
      local tab = function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        -- elseif vim.snippet.active() and vim.snippet.jumpable(1) then
        elseif vim.snippet.jumpable(1) then
          -- vim.snippet.jump(1)
          vim.schedule(function() vim.snippet.jump(1) end)
        elseif has_words_before() then
          cmp.complete()
        else
          fallback()
        end
      end
      local shift_tab = function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        -- elseif vim.snippet.active() and vim.snippet.jumpable(-1) then
        elseif vim.snippet.jumpable(-1) then
          -- vim.snippet.jump(-1)
          vim.schedule(function() vim.snippet.jump(-1) end)
        else
          fallback()
        end
      end

      cmp.setup({
        preselect = cmp.PreselectMode.None,
        snippet = {
          expand = function(args) vim.snippet.expand(args.body) end,
        },
        -- NOTE: read `:help ins-completion`
        completion = { completeopt = "menu,menuone,noinsert,noselect" },
        entries = { name = "custom", selection_order = "near_cursor" },
        window = {
          -- TODO:
          -- https://github.com/hrsh7th/nvim-cmp/wiki/Menu-Appearance#how-to-get-types-on-the-left-and-offset-the-menu
          completion = {
            winhighlight = table.concat({
              "Normal:NormalFloat",
              "FloatBorder:FloatBorder",
              "CursorLine:Visual",
              "Search:None",
            }, ","),
            zindex = 1001,
            col_offset = 0,
            border = SETTINGS.border,
            side_padding = 1,
            scrollbar = true,
          },
          documentation = cmp.config.window.bordered({
            border = SETTINGS.border,
            winhighlight = table.concat({
              "Normal:NormalFloat",
              "FloatBorder:FloatBorder",
              "CursorLine:Visual",
              "Search:None",
            }, ","),
          }),
        },
        mapping = cmp.mapping.preset.insert({
          -- Select the [n]ext item
          ["<C-n>"] = cmp.mapping.select_next_item(),
          -- Select the [p]revious item
          ["<C-p>"] = cmp.mapping.select_prev_item(),

          -- Scroll the documentation window [b]ack / [f]orward
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),

          -- Accept ([y]es) the completion.
          --  This will auto-import if your LSP supports it.
          --  This will expand snippets if the LSP sent a snippet.
          ["<C-y>"] = cmp.mapping.confirm({ select = true }),
          ["<C-e>"] = cmp.mapping.abort(),

          ["<CR>"] = function(fallback)
            if vim.g.snipper == "luasnip" then
              cmp.mapping.confirm({ select = false, behavior = cmp.ConfirmBehavior.Replace })(fallback)
            else
              if cmp.visible() then
                -- cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true })
                cmp.mapping.confirm({ select = false, behavior = cmp.ConfirmBehavior.Replace })(fallback)
              else
                fallback()
              end
            end
          end,
          ["<Tab>"] = {
            i = tab,
            s = tab,
            c = function()
              if vim.fn.getcmdline():sub(1, 1) == "!" then
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-z>", true, false, true), "n", false)
                return
              end
              if cmp.visible() then
                cmp.confirm({ select = true })
              else
                cmp.complete()
                cmp.select_next_item()
                cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
              end
            end,
          },
          ["<S-Tab>"] = {
            i = shift_tab,
            s = shift_tab,
            c = function()
              if cmp.visible() then
                cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
              else
                cmp.complete()
              end
            end,
          },
        }),

        formatting = {
          expandable_indicator = true,
          -- deprecated = true,
          -- fields = { "abbr", "kind", "menu" },
          fields = { "abbr", "menu", "kind" },
          maxwidth = MAX_MENU_WIDTH,
          minwidth = MIN_MENU_WIDTH,
          ellipsis_char = icons.misc.ellipsis,
          format = function(entry, item)
            -- -- FIXME: hacky way to deal with not getting completion results for certain lsp clients;
            -- -- presently, in this list of elixir lsp clients, we just want NextLS..
            -- local lsp_client_exclusions = { "lexical", "elixirls-dev", "elixirls" }
            -- if
            --   entry.source.name == "nvim_lsp"
            --   and vim.tbl_contains(lsp_client_exclusions, entry.source.source.client.name)
            -- then
            --   next()
            -- end

            if entry.source.name == "async_path" then
              local icon, hl_group = require("nvim-web-devicons").get_icon(entry:get_completion_item().label)
              if icon then
                item.kind = icon
                item.kind_hl_group = hl_group
              end
            end

            if entry.source.name == "nvim_lsp_signature_help" then
              local parts = vim.split(item.abbr, " ", {})
              local argument = parts[1]
              argument = argument:gsub(":$", "")
              local type = table.concat(parts, " ", 2)
              item.abbr = argument
              if type ~= nil and type ~= "" then item.kind = type end
              item.kind_hl_group = "Type"
            end

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
              item.kind = fmt("%s %s", icons.kind[item.kind], item.kind)
            end

            -- REF: https://github.com/3rd/config/blob/master/home/dotfiles/nvim/lua/modules/completion/nvim-cmp.lua
            item.dup = ({
              buffer = 0,
              path = 0,
              nvim_lsp = 0,
              luasnip = 0,
              vsnip = 0,
              snippets = 0,
            })[entry.source.name] or 0

            -- REF: https://github.com/zolrath/dotfiles/blob/main/dot_config/nvim/lua/plugins/cmp.lua#L45
            -- local max_length = 20
            local max_length = math.floor(vim.o.columns * 0.5)
            item.abbr = #item.abbr >= max_length and string.sub(item.abbr, 1, max_length) .. icons.misc.ellipsis or item.abbr

            item.abbr = string.gsub(item.abbr, "^%s+", "")

            if entry.source.name == "nvim_lsp" then
              item.menu = entry.source.source.client.name
            else
              item.menu = ({
                nvim_lsp = "[lsp]",
                luasnip = "[lsnip]",
                vsnip = "[vsnip]",
                snippets = "[snips]",
                -- codeium = "[code]",
                nvim_lua = "[nlua]",
                nvim_lsp_signature_help = "[sig]",
                async_path = "[path]",
                tmux = "[tmux]",
                rg = "[rg]",
                fuzzy_buffer = "[buf]",
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
        sorting = {
          priority_weight = 2,
          comparators = {
            require("cmp_fuzzy_buffer.compare"),

            cmp.config.compare.offset,
            cmp.config.compare.exact,
            cmp.config.compare.score,

            -- INFO: sort by number of underscores
            function(entry1, entry2)
              local _, entry1_under = entry1.completion_item.label:find("^_+")
              local _, entry2_under = entry2.completion_item.label:find("^_+")
              entry1_under = entry1_under or 0
              entry2_under = entry2_under or 0
              if entry1_under > entry2_under then
                return false
              elseif entry1_under < entry2_under then
                return true
              end
            end,

            cmp.config.compare.kind,
            cmp.config.compare.sort_text,
            cmp.config.compare.length,
            cmp.config.compare.order,
          },
        },
        sources = cmp.config.sources({
          { name = "nvim_lsp_signature_help" },
          { name = "snippets", group_index = 1, max_item_count = 5, keyword_length = 1 },
          { name = "luasnip", group_index = 1, max_item_count = 5, keyword_length = 1 },
          { name = "vsnip", group_index = 1, max_item_count = 5, keyword_length = 1 },
          { name = "nvim_lua" },
          {
            name = "nvim_lsp",
            group_index = 1,
            max_item_count = 35,
            entry_filter = function(entry)
              local kind = entry:get_kind()
              if vim.tbl_contains(vim.g.completion_exclusions, entry.source.source.client.name) then return false end
              return cmp.lsp.CompletionItemKind.Snippet ~= kind
              -- return true
            end,
          },
          { name = "async_path", option = { trailing_slash = true } },
          -- { name = "tmux", option = { all_panes = true } },
        }, {
          {
            name = "fuzzy_buffer",
            option = {
              min_match_length = 3,
              max_matches = 5,
              options = {
                get_bufnrs = function() return vim.tbl_map(vim.api.nvim_win_get_buf, vim.api.nvim_list_wins()) end,
              },
            },
          },
          -- {
          --   name = "buffer",
          --   keyword_length = 4,
          --   max_item_count = 5,
          --   options = {
          --     get_bufnrs = function() return vim.tbl_map(vim.api.nvim_win_get_buf, vim.api.nvim_list_wins()) end,
          --   },
          -- },
          { name = "spell" },
        }),
        -- sources = {
        --   { name = "nvim_lsp" },
        --   { name = "luasnip" },
        --   { name = "path" },
        -- },
      })

      cmp.setup.cmdline({ "/", "?" }, {
        -- view = {
        --   entries = { name = "custom", direction = "bottom_up" },
        -- },
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "nvim_lsp_document_symbol" },
          { name = "fuzzy_buffer", option = { min_match_length = 3 } },
          -- { name = "buffer", option = { min_match_length = 2 } },
        },
      })

      cmp.setup.cmdline(":", {
        -- view = {
        --   entries = { name = "custom", direction = "bottom_up" },
        -- },
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "async_path" },
          -- { name = "path" },
          {
            name = "cmdline",
            keyword_length = 3,
            option = {
              ignore_cmds = { "Man", "!" },
            },
            keyword_pattern = [=[[^[:blank:]\!]*]=],
          },
          -- { name = "cmdline_history", priority = 10, max_item_count = 3 },
        }),
      })

      -- no completion suggestions in a git commit
      cmp.setup.filetype({ "gitcommit", "NeogitCommitMessage" }, {
        sources = {},
      })
    end,
  },
}
