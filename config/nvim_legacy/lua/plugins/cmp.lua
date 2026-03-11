local SETTINGS = require("config.options")
local icons = Icons
local fmt = string.format

--[[ Luasnips if I want it:
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
              {
                "rafamadriz/friendly-snippets",
                config = function() require("luasnip.loaders.from_vscode").lazy_load() end,
              },
            },
            config = function()
              local ls = require("luasnip")
              ls.setup({
                link_children = true,
                link_roots = false,
                keep_roots = false,
                update_events = { "TextChanged", "TextChangedI" },
              })
              local c = ls.choice_node
              ls.choice_node = function(pos, choices, opts)
                P(opts)
                if opts then
                  opts.restore_cursor = true
                else
                  opts = { restore_cursor = true }
                end
                return c(pos, choices, opts)
              end

              vim.cmd.runtime({ args = { "lua/snippets/*.lua" }, bang = true }) -- load custom snippets

              vim.keymap.set({ "i", "x" }, "<C-j>", function()
                if ls.expand_or_jumpable() then ls.expand_or_jump() end
              end, { silent = true, desc = "expand snippet or jump to the next snippet node" })

              vim.keymap.set({ "i", "x" }, "<C-k>", function()
                if ls.jumpable(-1) then ls.jump(-1) end
              end, { silent = true, desc = "previous spot in the snippet" })

              vim.keymap.set({ "i", "x" }, "<C-l>", function()
                if ls.choice_active() then ls.change_choice(1) end
              end, { silent = true, desc = "next snippet choice" })

              vim.keymap.set({ "i", "x" }, "<C-h>", function()
                if ls.choice_active() then ls.change_choice(-1) end
              end, { silent = true, desc = "previous snippet choice" })

              require("luasnip.loaders.from_vscode").lazy_load()
            end,
          },
        },
      },
--]]

return {
  {
    -- "hrsh7th/nvim-cmp",
    --
    -- "yioneko/nvim-cmp",
    -- branch = "perf",
    --
    "iguanacucumber/magazine.nvim",
    cond = vim.g.completer == "cmp",
    name = "nvim-cmp",
    -- event = { "CmdlineEnter *" },
    event = { "InsertEnter *", "CmdlineEnter *" },
    priority = 100,
    dependencies = {
      {
        "xzbdmw/colorful-menu.nvim",
        lazy = true,
        opts = {},
      },
      {
        "petertriho/cmp-git",
        -- dependencies = { "yioneko/nvim-cmp" },
        config = function() require("cmp_git").setup() end,
        init = function() table.insert(require("cmp").get_config().sources, { name = "git" }) end,
      },
      {
        "MattiasMTS/cmp-dbee",
        dependencies = {
          { "kndndrj/nvim-dbee" },
        },
        ft = { "sql", "psql", "mysql", "plsql", "dbee" }, -- optional but good to have
        opts = {}, -- needed
      },
      {
        "garymjr/nvim-snippets",
        cond = vim.g.snipper == "snippets",
        dependencies = {
          "rafamadriz/friendly-snippets",
        },
        opts = {
          friendly_snippets = false,
          create_autocmd = true,
          search_paths = { vim.fn.stdpath("config") .. "/snippets" },
        },
      },
      -- { "hrsh7th/cmp-buffer" },
      {
        "tzachar/cmp-fuzzy-buffer",
        dependencies = { "tzachar/fuzzy.nvim" },
      },
      -- { "hrsh7th/cmp-nvim-lsp" },
      -- { "hrsh7th/cmp-nvim-lua" },
      { "hrsh7th/cmp-path" },
      { "FelipeLema/cmp-async-path" },
      -- { "hrsh7th/cmp-cmdline" }, -- event = { "CmdlineEnter" } },
      { "hrsh7th/cmp-nvim-lsp-signature-help", cond = false },
      { "hrsh7th/cmp-nvim-lsp-document-symbol" },
      -- { "hrsh7th/cmp-emoji" },
      { "f3fora/cmp-spell" },
      { "lukas-reineke/cmp-rg" },
      { "lukas-reineke/cmp-under-comparator" },
      -- { "davidsierradz/cmp-conventionalcommits" },
      { "dmitmel/cmp-cmdline-history" },
      { "andersevenrud/cmp-tmux", cond = false },

      { "iguanacucumber/mag-nvim-lsp", name = "cmp-nvim-lsp", opts = {} },
      { "iguanacucumber/mag-nvim-lua", name = "cmp-nvim-lua" },
      { "iguanacucumber/mag-buffer", name = "cmp-buffer" },
      { "iguanacucumber/mag-cmdline", name = "cmp-cmdline" },

      { url = "https://codeberg.org/FelipeLema/cmp-async-path" }, -- not by me, but better than cmp-path
      -- { "kristijanhusak/vim-dadbod-completion"},
    },
    init = function()
      vim.opt.completeopt = { "menu", "menuone", "noinsert", "noselect" }
      vim.g.autocompletion_enabled = true

      local function toggle_completion()
        local cmp = require("cmp")
        if vim.g.completion_enabled then
          pcall(cmp.setup, { completion = { autocomplete = false } })
        else
          pcall(cmp.setup, { completion = { autocomplete = { cmp.TriggerEvent.TextChanged } } })
        end
        vim.g.completion_enabled = not vim.g.completion_enabled
      end

      vim.api.nvim_create_user_command("ToggleNvimCmp", toggle_completion, {})
    end,
    opts = function()
      local cmp = require("cmp")
      local ls_ok, ls = pcall(require, "luasnip")

      local ELLIPSIS_CHAR = icons.misc.ellipsis
      local MIN_MENU_WIDTH = 25
      -- local MAX_MENU_WIDTH = math.min(30, math.floor(vim.o.columns * 0.5))
      -- local function get_ws(max, len) return (" "):rep(max - len) end

      local has_words_before = function()
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      local function tab(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif ls_ok and ls.expand_or_locally_jumpable() then
          ls.expand_or_jump()
        elseif vim.snippet.active({ direction = 1 }) then
          vim.schedule(function() vim.snippet.jump(1) end)
        elseif has_words_before() then
          cmp.complete()
        else
          fallback()
        end
      end

      local function stab(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif ls_ok and ls.jumpable(-1) then
          ls.jump(-1)
        elseif vim.snippet.active({ direction = -1 }) then
          vim.schedule(function() vim.snippet.jump(-1) end)
        else
          fallback()
        end
      end

      local keymaps = {
        ["<C-n>"] = cmp.mapping.select_next_item(),
        ["<C-p>"] = cmp.mapping.select_prev_item(),
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-y>"] = cmp.mapping.confirm({ select = true }),
        ["<C-e>"] = cmp.mapping.abort(),
        -- ["<C-e>"] = cmp.mapping(function()
        --   if vim.snippet.active({ direction = 1 }) then vim.snippet.stop() end
        --   cmp.mapping.abort()
        -- end, { "i", "s" }),
        ["<CR>"] = cmp.mapping(function(fallback)
          if cmp.core.view:visible() or vim.fn.pumvisible() == 1 then
            if vim.api.nvim_get_mode().mode == "i" then vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<c-G>u", true, true, true), "n", false) end
            if cmp.confirm({ select = false }) then return end
          end

          return fallback()
        end),
        -- ["<CR>"] = cmp.mapping.confirm({
        --   behavior = cmp.ConfirmBehavior.Insert,
        -- }),
        -- ["<CR>"] = cmp.mapping.confirm({
        --   behavior = cmp.ConfirmBehavior.Insert,
        --   select = false,
        -- }),
        -- ["<CR>"] = function(fallback)
        --   if cmp.visible() then
        --     cmp.mapping.confirm({ select = false, behavior = cmp.ConfirmBehavior.Replace })(fallback)
        --   else
        --     fallback()
        --   end
        -- end,
        ["<Tab>"] = {
          i = tab,
          s = tab,
          c = function()
            -- if vim.fn.getcmdline():sub(1, 1) == "!" then
            --   vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-z>", true, false, true), "n", false)
            --   return
            -- end
            if cmp.visible() then
              cmp.confirm({ select = false })
            else
              cmp.complete()
              cmp.select_next_item()
              cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
            end
          end,
        },
        ["<S-Tab>"] = {
          i = stab,
          s = stab,
          c = function()
            if cmp.visible() then
              cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
            else
              cmp.complete()
            end
          end,
        },
      }

      local winhighlight = table.concat({
        "Normal:NormalFloat",
        "FloatBorder:FloatBorder",
        "CursorLine:Visual",
        "Search:None",
      }, ",")

      return {
        performance = {
          debounce = 60,
          throttle = 30,
          fetching_timeout = 500,
          filtering_context_budget = 3,
          confirm_resolve_timeout = 80,
          async_budget = 1,
          max_view_entries = 200,
        },
        preselect = cmp.PreselectMode.None,
        snippet = {
          expand = function(args) vim.snippet.expand(args.body) end,
        },
        completion = { completeopt = "menu,menuone,noinsert,noselect" },
        -- confirmation = {
        --   default_behavior = require("cmp.types").cmp.ConfirmBehavior.Insert,
        --   get_commit_characters = function(commit_characters) return commit_characters end,
        -- },
        entries = {
          name = "custom",
          selection_order = "near_cursor",
          follow_cursor = true,
        },
        window = {
          -- TODO:
          -- https://github.com/hrsh7th/nvim-cmp/wiki/Menu-Appearance#how-to-get-types-on-the-left-and-offset-the-menu
          completion = {
            winhighlight = winhighlight,
            zindex = 1001,
            col_offset = 0,
            border = vim.g.borders.empty,
            -- max_height = math.floor(vim.o.lines * 0.5),
            -- max_width = math.floor(vim.o.columns * 0.4),
            -- height = math.floor(vim.o.lines * 0.5),
            -- width = math.floor(vim.o.columns * 0.4),
            side_padding = 1,
            scrollbar = true,
          },
          documentation = cmp.config.window.bordered({
            border = vim.g.borders.empty,
            -- max_height = math.floor(vim.o.lines * 0.5),
            -- max_width = math.floor(vim.o.columns * 0.4),
            winhighlight = winhighlight,
          }),
        },
        mapping = cmp.mapping.preset.insert(keymaps),

        -- TODO/REF: https://github.com/3rd/config/blob/master/dotfiles/nvim/lua/modules/completion/nvim-cmp.lua#L67C1-L80C4
        formatting = {
          expandable_indicator = true,
          deprecated = true,
          fields = { "abbr", "kind", "menu" },
          -- maxwidth = MAX_MENU_WIDTH,
          minwidth = MIN_MENU_WIDTH,
          ellipsis_char = ELLIPSIS_CHAR,
          -- TODO: format updates, clean up and document things pls!
          -- REF: https://github.com/MariaSolOs/dotfiles/blob/main/.config/nvim/lua/plugins/nvim-cmp.lua#L113-L134
          format = function(entry, vim_item)
            local item_maxwidth = 30
            local ellipsis_char = ELLIPSIS_CHAR

            ---@param item string
            ---@return string limited string
            local function truncate(item)
              if item ~= nil and item:len() > item_maxwidth then
                item = item:sub(0, item_maxwidth) .. ellipsis_char
                return item
              end
              return item
            end

            if entry.source.name == "path" then
              local icon, hl_group = require("nvim-web-devicons").get_icon(entry:get_completion_item().label)
              if icon then
                vim_item.kind = icon
                vim_item.kind_hl_group = hl_group
                return vim_item
              end
            end

            if entry.source.name == "nvim_lsp_signature_help" then
              local parts = vim.split(vim_item.abbr, " ", {})
              local argument = parts[1]
              argument = argument:gsub(":$", "")
              local type = table.concat(parts, " ", 2)
              vim_item.abbr = argument
              if type ~= nil and type ~= "" then
                local icon = icons.vscode[type]
                if icon ~= nil then
                  vim_item.kind = icon
                else
                  vim_item.kind = ""
                end
                vim_item.menu = type
              end
              -- vim_item.kind_hl_group = "Type"
              vim_item.menu_hl_group = "Type"
            end

            local colors_icon = "󱓻"
            local entryItem = entry:get_completion_item()
            local color = entryItem.documentation

            if color and type(color) == "string" and color:match("^#%x%x%x%x%x%x$") then
              local hl = "hex-" .. color:sub(2)

              if #vim.api.nvim_get_hl(0, { name = hl }) == 0 then vim.api.nvim_set_hl(0, hl, { fg = color }) end

              vim_item.kind = " " .. colors_icon
              vim_item.kind_hl_group = hl
              vim_item.menu_hl_group = hl
            else
              vim_item.kind = fmt("%s %s", icons.kind[vim_item.kind], vim_item.kind)
            end
            vim_item.menu = truncate(vim_item.menu)
            vim_item.abbr = truncate(vim_item.abbr)

            if entry.source.name == "nvim_lsp" then
              vim_item.menu = fmt("[%s]", entry.source.source.client.name)
            else
              vim_item.menu = ({
                nvim_lsp = "[lsp]",
                luasnip = "[lsnip]",
                vsnip = "[vsnip]",
                -- minuet = "[󱗻 ai]",
                snippets = "[snips]",
                -- codeium = "[code]",
                nvim_lua = "[nlua]",
                nvim_lsp_signature_help = "[sig]",
                async_path = "[path]",
                git = "[git]",
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

            local highlights_info = require("colorful-menu").cmp_highlights(entry)

            -- if highlight_info==nil, which means missing ts parser, let's fallback to use default `vim_item.abbr`.
            -- What this plugin offers is two fields: `vim_item.abbr_hl_group` and `vim_item.abbr`.
            if highlights_info ~= nil then
              vim_item.abbr_hl_group = highlights_info.highlights
              vim_item.abbr = highlights_info.text
            end

            return vim_item
          end,
        },
        sorting = {
          priority_weight = 2,
          comparators = {
            require("cmp_fuzzy_buffer.compare"),

            cmp.config.compare.offset,
            cmp.config.compare.exact,
            cmp.config.compare.score,
            cmp.config.compare.recently_used,
            require("cmp-under-comparator").under,

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
          {
            name = "snippets",
            group_index = 1,
            max_item_count = 5,
            keyword_length = 1,
            -- Don't show snippet completions in comments or strings.
            entry_filter = function()
              local ctx = require("cmp.config.context")
              local in_string = ctx.in_syntax_group("String") or ctx.in_treesitter_capture("string")
              local in_comment = ctx.in_syntax_group("Comment") or ctx.in_treesitter_capture("comment")

              return not in_string and not in_comment
            end,
          },
          { name = "luasnip", group_index = 1, max_item_count = 5, keyword_length = 1 },
          { name = "vsnip", group_index = 1, max_item_count = 5, keyword_length = 1 },
          -- { name = "nvim_lua" },
          {
            name = "nvim_lsp",
            group_index = 1,
            priority = 100,
            -- max_item_count = 35,
            entry_filter = function(entry)
              if vim.g.completion_exclusions and vim.tbl_contains(vim.g.completion_exclusions, entry.source.source.client.name) then return false end

              return true
            end,
          },
          { name = "async_path", trailing_slash = true },
        }, {
          {
            name = "fuzzy_buffer",
            group_index = 2,
            priority = 1,
            min_match_length = 3,
            max_item_count = 5,
            max_matches = 5,
            get_bufnrs = function()
              local LIMIT = 1024 * 1024 -- 1 Megabyte max
              local bufs = {}

              for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                local line_count = vim.api.nvim_buf_line_count(buf)
                local byte_size = vim.api.nvim_buf_get_offset(buf, line_count)

                if byte_size < LIMIT then bufs[buf] = true end
              end

              return vim.tbl_keys(bufs)
            end,
          },
          { name = "spell" },
        }),
      }
    end,
    config = function(_, opts)
      local cmp = require("cmp")

      cmp.setup(opts)

      local cmdline_keymaps = {
        ["<Down>"] = { c = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }) },
        ["<Up>"] = { c = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }) },
      }

      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(cmdline_keymaps),
        sources = {
          { name = "nvim_lsp_document_symbol" },
          { name = "fuzzy_buffer", min_match_length = 3, max_item_count = 5 },
          { name = "buffer", min_match_length = 2, max_item_count = 5 },
        },
      })

      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(cmdline_keymaps),
        sources = cmp.config.sources({
          { name = "async_path" },
          {
            name = "cmdline",
            keyword_length = 2,
            max_item_count = 5,
            ignore_cmds = {},
            -- ignore_cmds = { "Man", "!" },
            keyword_pattern = [=[[^[:blank:]\!]*]=],
          },
          {
            name = "cmdline_history",
            keyword_length = 2,
            max_item_count = 5,
            ignore_cmds = {},
            -- ignore_cmds = { "Man", "!" },
            keyword_pattern = [=[[^[:blank:]\!]*]=],
          },
        }),
      })

      if pcall(require, "nvim-autopairs") then
        local cmp_autopairs = require("nvim-autopairs.completion.cmp")
        cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
      end

      -- Override the documentation handler to remove the redundant detail section.
      ---@diagnostic disable-next-line: duplicate-set-field
      require("cmp.entry").get_documentation = function(self)
        local item = self.completion_item

        if item.documentation then return vim.lsp.util.convert_input_to_markdown_lines(item.documentation) end

        -- Use the item's detail as a fallback if there's no documentation.
        if item.detail then
          local ft = self.context.filetype
          local dot_index = string.find(ft, "%.")
          if dot_index ~= nil then ft = string.sub(ft, 0, dot_index - 1) end
          return (vim.split(("```%s\n%s```"):format(ft, vim.trim(item.detail)), "\n"))
        end

        return {}
      end

      if pcall(require, "neocodeium") then
        local neocodeium = require("neocodeium")
        local commands = require("neocodeium.commands")
        cmp.event:on("menu_opened", function() neocodeium.clear() end)

        cmp.event:on("menu_closed", function()
          commands.enable()
          neocodeium.cycle_or_complete()
        end)
      end
    end,
  },
}
