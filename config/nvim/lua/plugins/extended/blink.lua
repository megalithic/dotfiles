local SETTINGS = require("mega.settings")
local icons = SETTINGS.icons
local U = require("mega.utils")

-- DOCS https://github.com/saghen/blink.cmp#configuration
--------------------------------------------------------------------------------
---@diagnostic disable: missing-fields -- pending https://github.com/Saghen/blink.cmp/issues/427
--------------------------------------------------------------------------------

return {
  {
    "saghen/blink.cmp",
    -- lazy = false,
    event = { "InsertEnter *", "CmdlineEnter *" },
    enabled = true,
    version = "*",
    -- build = "cargo build --release",
    cond = vim.g.completer == "blink",
    dependencies = {
      "rafamadriz/friendly-snippets",
      { "saghen/blink.compat", version = "*", opts = { impersonate_nvim_cmp = true } },
      { "chrisgrieser/cmp-nerdfont", lazy = true },
      { "hrsh7th/cmp-emoji", lazy = true },
    },
    opts = {
      -- enabled = function()
      --   -- prevent useless suggestions when typing `--` in lua, but keep the
      --   -- `---@param;@return` suggestion
      --   if vim.bo.ft == "lua" then
      --     local col = vim.api.nvim_win_get_cursor(0)[2]
      --     local charsBefore = vim.api.nvim_get_current_line():sub(col - 2, col)
      --     local commentButNotLuadocs = charsBefore:find("^%-%-?$") or charsBefore:find("%s%-%-?")
      --     if commentButNotLuadocs then return false end
      --   end

      --   if vim.bo.buftype == "prompt" then return false end
      --   local ignoredFts = { "DressingInput", "snacks_input", "rip-substitute", "gitcommit" }
      --   return not vim.tbl_contains(ignoredFts, vim.bo.filetype)
      -- end,
      sources = {
        default = { "lsp", "path", "snippets", "buffer", "lazydev" },
        -- default = function(ctx)
        --   -- local node = vim.treesitter.get_node()
        --   -- if vim.bo.filetype == "lua" then
        --   --   return { "lsp", "path" }
        --   -- elseif node and vim.tbl_contains({ "comment", "line_comment", "block_comment" }, node:type()) then
        --   --   return { "buffer" }
        --   -- else
        --   return { "lsp", "path", "snippets", "buffer", "codecompanion", "lazydev", "copilot" }
        --   -- end
        -- end,
        -- compat = { "supermaven" },
        -- min_keyword_length = function()
        --   --   return vim.bo.filetype == 'markdown' and 2 or 0
        --   return 2
        -- end,
        -- cmdline = function()
        --   local type = vim.fn.getcmdtype()
        --   -- Search forward and backward
        --   if type == "/" or type == "?" then return { "buffer" } end
        --   -- Commands
        --   if type == ":" then return { "cmdline" } end
        --   return {}
        -- end,
        providers = {
          lsp = {
            name = "[lsp]",
          },
          snippets = {
            name = "[snips]",
            -- don't show when triggered manually (= length 0), useful
            -- when manually showing completions to see available JSON keys
            min_keyword_length = 2,
            score_offset = -1,
          },
          path = { name = "[path]", opts = { get_cwd = vim.uv.cwd } },
          -- copilot = {
          --   name = "[copilot]",
          --   module = "blink-cmp-copilot",
          --   score_offset = 100,
          --   async = true,
          -- },
          lazydev = {
            name = "[lazy]",
            module = "lazydev.integrations.blink",
            score_offset = 100, -- show at a higher priority than lsp
          },
          markdown = { name = "[md]", module = "render-markdown.integ.blink" },
          -- supermaven = { name = "[super]", kind = "Supermaven", module = "supermaven.cmp", score_offset = 100, async = true },
          -- codecompanion = {
          --   name = "codecompanion",
          --   module = "codecompanion.providers.completion.blink",
          --   enabled = true,
          -- },
          buffer = {
            name = "[buf]",
            -- disable being fallback for LSP, but limit its display via
            -- the other settings
            -- fallbacks = {},
            max_items = 4,
            min_keyword_length = 4,
            score_offset = -3,

            -- show completions from all buffers used within the last x minutes
            opts = {
              get_bufnrs = function()
                local mins = 15
                local allOpenBuffers = vim.fn.getbufinfo({ buflisted = 1, bufloaded = 1 })
                local recentBufs = vim
                  .iter(allOpenBuffers)
                  :filter(function(buf)
                    local recentlyUsed = os.time() - buf.lastused < (60 * mins)
                    local nonSpecial = vim.bo[buf.bufnr].buftype == ""
                    return recentlyUsed and nonSpecial
                  end)
                  :map(function(buf) return buf.bufnr end)
                  :totable()
                return recentBufs
              end,
            },
          },
        },
      },
      keymap = {
        ["<C-c>"] = { "cancel" },
        ["<C-y>"] = { "select_and_accept", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
        ["<Tab>"] = { "select_next", "fallback" },
        ["<S-Tab>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<Up>"] = { "select_prev", "fallback" },
        ["<PageDown>"] = { "scroll_documentation_down" },
        ["<PageUp>"] = { "scroll_documentation_up" },
      },
      signature = { enabled = true },
      completion = {
        -- ghost_text = {
        --   enabled = true,
        -- },
        -- enabled_providers = function(_)
        --   -- if vim.bo.filetype == "codecompanion" then return { "codecompanion" } end

        --   return { "lsp", "path", "snippets", "buffer", "markdown", "supermaven", "codecompanion" }
        -- end,
        list = {
          cycle = { from_top = false }, -- cycle at bottom, but not at the top
          selection = "manual", -- alts: auto_insert, preselect
        },
        accept = {
          auto_brackets = {
            -- Whether to auto-insert brackets for functions
            enabled = true,
            -- Default brackets to use for unknown languages
            default_brackets = { "(", ")" },
            -- Overrides the default blocked filetypes
            override_brackets_for_filetypes = { "rust", "elixir", "heex", "lua" },
            -- Synchronously use the kind of the item to determine if brackets should be added
            kind_resolution = {
              enabled = true,
              blocked_filetypes = { "typescriptreact", "javascriptreact", "vue" },
            },
            -- Asynchronously use semantic token to determine if brackets should be added
            semantic_token_resolution = {
              enabled = true,
              blocked_filetypes = {},
              -- How long to wait for semantic tokens to return before assuming no brackets should be added
              timeout_ms = 400,
            },
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 250,
          window = {
            border = SETTINGS.borders.blink_empty,
            max_width = 50,
            max_height = 15,
          },
        },
        menu = {
          border = SETTINGS.borders.blink_empty,
          draw = {
            treesitter = { "lsp" },
            columns = {
              { "label", "label_description", gap = 1 },
              { "kind_icon", "kind", gap = 1 },
              { "source_name" },
            },
            components = {
              label = { width = { max = 30, fill = true } }, -- more space for doc-win
              label_description = { width = { max = 20 } },
              kind_icon = {
                text = function(ctx)
                  -- detect emmet-ls
                  local source, client = ctx.item.source_id, ctx.item.client_id
                  local lspName = client and vim.lsp.get_client_by_id(client).name
                  if lspName == "emmet_language_server" then source = "emmet" end

                  -- use source-specific icons, and `kind_icon` only for items from LSPs
                  local sourceIcons = { snippets = "󰩫", buffer = "󰦨", emmet = "", path = "" }
                  return sourceIcons[source] or ctx.kind_icon
                end,
              },
              source_name = {
                width = { max = 30, fill = true },
                text = function(ctx)
                  if ctx.item.source_id == "lsp" then
                    local client = vim.lsp.get_client_by_id(ctx.item.client_id)
                    if client ~= nil then return string.format("[%s]", client.name) end
                    return ctx.source_name
                  end

                  return ctx.source_name
                end,
                highlight = "BlinkCmpSource",
              },
            },
          },
        },
      },
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = "mono",
        kind_icons = {
          -- different icons of the corresponding source
          Text = "󰦨", -- `buffer`
          Snippet = "󰞘", -- `snippets`
          File = "", -- `path`
          Folder = "󰉋",
          Method = "󰊕",
          Function = "󰡱",
          Constructor = "",
          Field = "󰇽",
          Variable = "󰀫",
          Class = "󰜁",
          Interface = "",
          Module = "",
          Property = "󰜢",
          Unit = "",
          Value = "󰎠",
          Enum = "",
          Keyword = "󰌋",
          Color = "󰏘",
          Reference = "",
          EnumMember = "",
          Constant = "󰏿",
          Struct = "󰙅",
          Event = "",
          Operator = "󰆕",
          TypeParameter = "󰅲",
        },
      },
    },
  },
}

-- return {
--   "saghen/blink.cmp",
--   -- build = "cargo build --release",
--   version = "v0.*",
--   cond = vim.g.completer == "blink",
--   dependencies = {
--     "rafamadriz/friendly-snippets",
--     { "saghen/blink.compat", version = "*", opts = { impersonate_nvim_cmp = true } },
--     { "chrisgrieser/cmp-nerdfont", lazy = true },
--     { "hrsh7th/cmp-emoji", lazy = true },
--   },
--   event = "VeryLazy",

--   opts = {
--     keymap = {
--       preset = "enter",
--       ["<Tab>"] = {
--         function(cmp)
--           if cmp.is_in_snippet() then
--             return cmp.accept()
--           else
--             return cmp.select_next()
--           end
--         end,
--         "snippet_forward",
--         "fallback",
--       },
--       ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
--     },
--     accept = {
--       auto_brackets = { enabled = true },
--     },

--     trigger = {
--       signature_help = { enabled = false },
--     },

--     highlight = {
--       use_nvim_cmp_as_default = true,
--     },

--     blocked_filetypes = { "firenvim" },
--     nerd_font_variant = "mono",

--     sources = {
--       -- add lazydev to your completion providers
--       completion = {
--         enabled_providers = {
--           "lsp",
--           "path",
--           "snippets",
--           "buffer",
--           "lazydev",
--           "nerdfont",
--           "emoji",
--         },
--       },
--       providers = {
--         snippets = {
--           -- don't show when triggered manually (= zero length), useful for JSON keys
--           min_keyword_length = 1,
--           score_offset = -1,
--         },
--         buffer = {
--           -- disable being fallback for LSP, but limit its display via
--           -- the other settings
--           fallback_for = {},
--           max_items = 4,
--           min_keyword_length = 4,
--           score_offset = -3,
--         },
--         -- dont show LuaLS require statements when lazydev has items
--         lsp = { fallback_for = { "lazydev" } },
--         lazydev = { name = "LazyDev", module = "lazydev.integrations.blink" },
--         nerdfont = {
--           name = "nerdfont",
--           module = "blink.compat.source",
--           transform_items = function(ctx, items)
--             -- TODO: check https://github.com/Saghen/blink.cmp/pull/253#issuecomment-2454984622
--             local kind = require("blink.cmp.types").CompletionItemKind.Text

--             for i = 1, #items do
--               items[i].kind = kind
--             end

--             return items
--           end,
--         },
--         emoji = {
--           name = "emoji",
--           module = "blink.compat.source",
--           transform_items = function(ctx, items)
--             -- TODO: check https://github.com/Saghen/blink.cmp/pull/253#issuecomment-2454984622
--             local kind = require("blink.cmp.types").CompletionItemKind.Text

--             for i = 1, #items do
--               items[i].kind = kind
--             end

--             return items
--           end,
--         },
--       },
--     },
--     windows = {
--       documentation = {
--         border = SETTINGS.borders.blink_empty,
--         auto_show = true,
--         min_width = 15,
--         max_width = 60,
--         max_height = 20,
--         auto_show_delay_ms = 250,
--       },
--       signature_help = {
--         border = SETTINGS.borders.blink_empty,
--       },
--       autocomplete = {
--         min_width = 25,
--         max_height = 30,
--         scrollbar = true,
--         border = SETTINGS.borders.blink_empty,
--         selection = "manual", -- alts: preselect, manual, auto_insert
--         draw = function(ctx)
--           local icon = ctx.kind_icon
--           local icon_hl = vim.api.nvim_get_hl_by_name("BlinkCmpKind", true) and "BlinkCmpKind" .. ctx.kind or "BlinkCmpKind"

--           local source, client = ctx.item.source_id, ctx.item.client_id
--           if client and vim.lsp.get_client_by_id(client).name then source = vim.lsp.get_client_by_id(client).name end

--           return {
--             {
--               " " .. ctx.item.label .. " ",
--               fill = true,
--               hl_group = ctx.deprecated and "BlinkCmpLabelDeprecated" or "BlinkCmpLabel",
--               max_width = 35,
--             },
--             {
--               icon .. ctx.icon_gap .. ctx.kind .. " ",
--               fill = true,
--               hl_group = icon_hl,
--               max_width = 25,
--             },
--             {
--               " [" .. string.lower(source) .. "] ",
--               fill = true,
--               hl_group = ctx.deprecated and "BlinkCmpLabelDeprecated" or "CmpItemMenu",
--               max_width = 15,
--             },
--           }
--         end,
--       },
--     },
--     kind_icons = SETTINGS.icons.vscode,
--   },
-- }
