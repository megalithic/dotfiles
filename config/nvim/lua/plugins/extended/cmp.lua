local SETTINGS = require("mega.settings")
local icons = SETTINGS.icons
local fmt = string.format

return {
  {
    -- "yioneko/nvim-cmp",
    -- branch = "perf",
    "iguanacucumber/magazine.nvim",
    name = "nvim-cmp",
    event = { "InsertEnter *", "CmdlineEnter *" },
    -- event = "InsertEnter",
    -- lazy = false,
    priority = 100,
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
              {
                "rafamadriz/friendly-snippets",
                config = function() require("luasnip.loaders.from_vscode").lazy_load() end,
              },
            },
          },
        },
      },
      {
        "petertriho/cmp-git",
        -- dependencies = { "yioneko/nvim-cmp" },
        config = function() require("cmp_git").setup() end,
        init = function() table.insert(require("cmp").get_config().sources, { name = "git" }) end,
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
    config = function()
      local cmp = require("cmp")
      local MIN_MENU_WIDTH = 25
      local MAX_MENU_WIDTH = math.min(30, math.floor(vim.o.columns * 0.5))
      local ELLIPSIS_CHAR = icons.misc.ellipsis

      local function get_ws(max, len) return (" "):rep(max - len) end

      -- local neocodeium = require("neocodeium")
      -- local commands = require("neocodeium.commands")
      -- cmp.event:on("menu_opened", function()
      --   neocodeium.clear()
      --   commands.disable()
      -- end)
      -- cmp.event:on("menu_closed", function() commands.enable() end)

      local has_words_before = function()
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end
      local tab = function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif vim.snippet.active({ direction = 1 }) then
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
        elseif vim.snippet.active({ direction = -1 }) then
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
        -- entries = { name = "custom", selection_order = "near_cursor" },
        confirmation = {
          default_behavior = require("cmp.types").cmp.ConfirmBehavior.Insert,
          get_commit_characters = function(commit_characters) return commit_characters end,
        },
        entries = {
          name = "custom",
          selection_order = "near_cursor",
          follow_cursor = true,
        },
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
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-y>"] = cmp.mapping.confirm({ select = true }),

          ["<C-e>"] = cmp.mapping.abort(),
          -- ["<CR>"] = cmp.mapping.confirm({
          --   behavior = cmp.ConfirmBehavior.Insert,
          --   select = false,
          -- }),
          ["<CR>"] = function(fallback)
            if cmp.visible() then
              cmp.mapping.confirm({ select = false, behavior = cmp.ConfirmBehavior.Replace })(fallback)
            else
              fallback()
            end
          end,
          ["<Tab>"] = {
            i = tab,
            s = tab,
            c = function()
              -- if vim.fn.getcmdline():sub(1, 1) == "!" then
              --   vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-z>", true, false, true), "n", false)
              --   return
              -- end
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

        -- TODO/REF: https://github.com/3rd/config/blob/master/dotfiles/nvim/lua/modules/completion/nvim-cmp.lua#L67C1-L80C4
        formatting = {
          expandable_indicator = true,
          fields = { "abbr", "kind", "menu" },
          -- maxwidth = MAX_MENU_WIDTH,
          -- minwidth = MIN_MENU_WIDTH,
          ellipsis_char = ELLIPSIS_CHAR,
          -- TODO: format updates, clean up and document things pls!
          -- REF: https://github.com/MariaSolOs/dotfiles/blob/main/.config/nvim/lua/plugins/nvim-cmp.lua#L113-L134
          format = function(entry, vim_item)
            -- if entry.source.name == "async_path" then
            --   local icon, hl_group = require("nvim-web-devicons").get_icon(entry:get_completion_item().label)
            --   if icon then
            --     item.kind = icon
            --     item.kind_hl_group = hl_group
            --   end
            -- end

            if entry.source.name == "nvim_lsp_signature_help" then
              local parts = vim.split(vim_item.abbr, " ", {})
              local argument = parts[1]
              argument = argument:gsub(":$", "")
              local type = table.concat(parts, " ", 2)
              vim_item.abbr = argument
              if type ~= nil and type ~= "" then vim_item.kind = type end
              vim_item.kind_hl_group = "Type"
            end

            if vim_item.kind == "Color" and entry.completion_item.documentation and type(entry.completion_item.documentation) == "string" then
              local _, _, r, g, b = string.find(entry.completion_item.documentation, "^rgb%((%d+), (%d+), (%d+)")
              if r then
                local color = string.format("%02x", r) .. string.format("%02x", g) .. string.format("%02x", b)
                local hl_group = "Tw_" .. color
                if vim.fn.hlID(hl_group) < 1 then vim.api.nvim_set_hl(0, hl_group, { fg = "#" .. color }) end
                vim_item.kind = ""
                vim_item.kind_hl_group = hl_group
              end
            else
              vim_item.kind = fmt("%s %s", icons.kind[vim_item.kind], vim_item.kind)
            end

            -- REF: https://github.com/3rd/config/blob/master/home/dotfiles/nvim/lua/modules/completion/nvim-cmp.lua
            vim_item.dup = ({
              fuzzy_buffer = 0,
              buffer = 0,
              path = 0,
              async_path = 0,
              nvim_lsp = 0,
              luasnip = 0,
              vsnip = 0,
              snippets = 0,
            })[entry.source.name] or 0

            -- REF: https://github.com/zolrath/dotfiles/blob/main/dot_config/nvim/lua/plugins/cmp.lua#L45
            -- local max_length = 20
            local max_length = math.floor(vim.o.columns * 0.5)
            vim_item.abbr = #vim_item.abbr >= max_length and string.sub(vim_item.abbr, 1, max_length) .. ELLIPSIS_CHAR or vim_item.abbr
            -- maximum width
            -- src: https://github.com/hrsh7th/nvim-cmp/discussions/609#discussioncomment-3395522

            local content = vim_item.abbr
            if #content > MAX_MENU_WIDTH then
              vim_item.abbr = vim.fn.strcharpart(content, 0, MAX_MENU_WIDTH) .. ELLIPSIS_CHAR
            else
              vim_item.abbr = content .. get_ws(MAX_MENU_WIDTH, #content)
            end

            vim_item.abbr = string.gsub(vim_item.abbr, "^%s+", "")

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
          { name = "snippets", group_index = 1, max_item_count = 5, keyword_length = 1 },
          { name = "luasnip", group_index = 1, max_item_count = 5, keyword_length = 1 },
          { name = "vsnip", group_index = 1, max_item_count = 5, keyword_length = 1 },
          { name = "nvim_lua" },
          {
            name = "nvim_lsp",
            group_index = 1,
            priority = 100,
            -- max_item_count = 35,
            entry_filter = function(entry)
              if vim.tbl_contains(SETTINGS.completion_exclusions, entry.source.source.client.name) then return false end

              return true
            end,
          },
          { name = "async_path", option = { trailing_slash = true } },
        }, {
          {
            name = "fuzzy_buffer",
            group_index = 2,
            priority = 1,
            option = {
              group_index = 2,
              priority = 1,
              min_match_length = 3,
              max_matches = 5,
              options = {
                option = {
                  -- https://github.com/hrsh7th/cmp-buffer#get_bufnrs-type-fun-number=
                  -- https://github.com/hrsh7th/cmp-buffer#performance-on-large-text-files=
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
                -- get_bufnrs = function() return vim.tbl_map(vim.api.nvim_win_get_buf, vim.api.nvim_list_wins()) end,
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
        mapping = cmp.mapping.preset.cmdline({
          ["<Down>"] = { c = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }) },
          ["<Up>"] = { c = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }) },
        }),
        sources = cmp.config.sources({
          { name = "async_path" },
          -- { name = "path" },
          {
            name = "cmdline",
            keyword_length = 2,
            option = {
              ignore_cmds = {},
              -- ignore_cmds = { "Man", "!" },
            },
            keyword_pattern = [=[[^[:blank:]\!]*]=],
          },
          -- { name = "cmdline_history", priority = 10, max_item_count = 3 },
        }),
      })

      -- Set configuration for specific filetype.
      ---@diagnostic disable-next-line missing-fields
      cmp.setup.filetype({ "gitcommit", "NeogitCommitMessage" }, {
        sources = cmp.config.sources({
          { name = "git" },
        }, {
          { name = "buffer" },
        }),
      })

      cmp.setup.filetype({ "sql" }, {
        sources = {
          { name = "vim-dadbod-completion" },
          { name = "buffer" },
        },
      })

      cmp.setup.filetype("markdown", {
        sources = {
          {
            name = "nvim_lsp",
            option = {
              markdown_oxide = {
                keyword_pattern = [[\(\k\| \|\/\|#\|\^\)\+]],
              },
            },
          },
          { name = "snippets" },
          { name = "git" },
          { name = "path" },
        },
      })

      if pcall(require, "nvim-autopairs") then
        local cmp_autopairs = require("nvim-autopairs.completion.cmp")
        cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
      end
    end,
  },
}
