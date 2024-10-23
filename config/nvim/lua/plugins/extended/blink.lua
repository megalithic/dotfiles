local SETTINGS = require("mega.settings")
local icons = SETTINGS.icons

local function draw_item(ctx)
  local map = {
    ["blink.cmp.sources.lsp"] = "[]",
    ["blink.cmp.sources.path"] = "[󰉋]",
    ["blink.cmp.sources.snippets"] = "[]",
  }
  return {
    { " " .. ctx.kind_icon, hl_group = "BlinkCmpKind" .. ctx.kind },
    {
      " " .. ctx.item.label,
      fill = true,
      -- hl_group = ctx.deprecated and "BlinkCmpLabelDeprecated" or "BlinkCmpLabel",
    },
    {
      string.format("%6s ", map[ctx.item.source] or "UNKNOWN"),
      hl_group = "BlinkCmpSource",
    },
  }
end

return {
  "saghen/blink.cmp",
  -- "neovim-plugin/blink.cmp",
  dependencies = "rafamadriz/friendly-snippets",
  lazy = false,
  -- event = "InsertEnter *",
  -- version = "v0.3.1", -- REQUIRED release tag to download pre-built binaries

  cond = vim.g.completer == "blink",
  build = "cargo build --release",

  ---@module "blink.cmp"
  ---@type blink.cmp.Config
  opts = {
    sources = {
      providers = {
        { "blink.cmp.sources.lsp", name = "[lsp]" },
        {
          "blink.cmp.sources.snippets",
          name = "[snip]",
          score_offset = -1,
          -- keyword_length = 1, -- not supported yet
        },
        {
          "blink.cmp.sources.path",
          name = "[path]",
          score_offset = 3,
          opts = { get_cwd = vim.uv.cwd },
        },
        {
          "blink.cmp.sources.buffer",
          name = "[buf]",
          keyword_length = 3,
          score = -1,
          fallback_for = { "[path]" }, -- PENDING https://github.com/Saghen/blink.cmp/issues/122
        },
      },
    },
    trigger = {
      completion = {
        -- keyword_range = "full", -- alts: full|prefix
      },
    },

    keymap = {
      accept = { "<C-y>", "<CR>" },
      hide = "<C-e>",
      select_prev = { "<S-Tab>", "<Up>", "<C-p>" },
      select_next = { "<Tab>", "<Down>", "<C-n>" },
      scroll_documentation_down = "<C-j>",
      scroll_documentation_up = "<C-k>",
      snippet_forward = { "<Tab>", "<C-l>" },
      snippet_backward = { "<S-Tab>", "<C-h>" },
    },
    -- keymap = {
    --   show = "<D-c>",
    --   hide = "<S-CR>",
    --   accept = "<CR>",
    --   select_next = { "<Tab>", "<Down>" },
    --   select_prev = { "<S-Tab>", "<Up>" },
    --   scroll_documentation_down = "<PageDown>",
    --   scroll_documentation_up = "<PageUp>",
    -- },
    highlight = {
      use_nvim_cmp_as_default = true,
    },
    nerd_font_variant = "mono",
    windows = {
      documentation = {
        min_width = 15,
        max_width = 50,
        max_height = 15,
        -- border = vim.g.borderStyle,
        auto_show = true,
        auto_show_delay_ms = 200,
      },
      autocomplete = {
        min_width = 30,
        max_height = 10,
        -- border = vim.g.borderStyle,
        selection = "preselect", -- alts: preselect, auto_insert, manual
        cycle = { from_top = false }, -- cycle at bottom, but not at the top
        draw = function(ctx)
          -- https://github.com/Saghen/blink.cmp/blob/819b978328b244fc124cfcd74661b2a7f4259f4f/lua/blink/cmp/windows/autocomplete.lua#L285-L349
          -- differentiate LSP snippets from user snippets and emmet snippets
          -- dbg(ctx.item)
          local icon = icons.kind[ctx.kind] or ctx.kind_icon
          local source = ctx.item.source

          local client = source == "[lsp]" and string.format("[%s]", vim.lsp.get_client_by_id(ctx.item.client_id).name) or source

          if source == "[snip]" or (client == "basics_ls" and ctx.kind == "Snippet") then
            icon = "󰩫"
          elseif source == "[buf]" or (client == "basics_ls" and ctx.kind == "Text") then
            icon = "󰦨"
          elseif client == "emmet_language_server" then
            icon = "󰯸"
          end

          -- FIX highlight for Tokyonight
          local iconHl = "BlinkCmpKind" .. ctx.kind

          return {
            {
              " " .. ctx.item.label .. " ",
              fill = true,
              hl_group = ctx.deprecated and "BlinkCmpLabelDeprecated" or "BlinkCmpLabel",
              max_width = 45,
            },
            {
              icon .. ctx.icon_gap .. ctx.kind .. " ",
              fill = true,
              hl_group = iconHl,
              max_width = 25,
            },
            {
              " " .. client .. " ",
              fill = true,
              hl_group = ctx.deprecated and "BlinkCmpLabelDeprecated" or "BlinkCmpLabel",
              max_width = 15,
            },
            -- { ctx.kind .. " " .. icon .. ctx.icon_gap .. client, hl_group = iconHl },
          }
        end,
        -- draw_item,
      },
    },
    kind_icons = {
      Text = "",
      Method = "󰊕",
      Function = "󰊕",
      Constructor = "",
      Field = "󰇽",
      Variable = "󰂡",
      Class = "⬟",
      Interface = "",
      Module = "",
      Property = "󰜢",
      Unit = "",
      Value = "󰎠",
      Enum = "",
      Keyword = "󰌋",
      Snippet = "󰒕",
      Color = "󰏘",
      Reference = "",
      File = "󰉋",
      Folder = "󰉋",
      EnumMember = "",
      Constant = "󰏿",
      Struct = "",
      Event = "",
      Operator = "󰆕",
      TypeParameter = "󰅲",
    },
  },
  config = function(_, opts)
    require("blink.cmp").setup(opts)
    local cmp = require("blink.cmp")

    -- if pcall(require, "nvim-autopairs") and pcall(require, "cmp") then
    --   local cmp_autopairs = require("nvim-autopairs.completion.cmp")
    --   cmp.on_close(function() cmp_autopairs.on_confirm_done() end)
    -- end

    if pcall(require, "neocodeium") then
      local neocodeium = require("neocodeium.commands")
      local commands = require("neocodeium.commands")
      if cmp.windows and cmp.windows.autocomplete then
        cmp.on_open(function()
          neocodeium.clear() -- Call neocodeium.clear when autocomplete opens
        end)

        cmp.on_close(function()
          commands.enable() -- Enable commands when autocomplete closes
          neocodeium.cycle_or_complete() -- Trigger neocodeium's cycle or complete logic
        end)
      end
    end
  end,
}

-- return {
--   {
--     -- fixes ffi error:
--     -- https://github.com/Saghen/blink.cmp/issues/90#issuecomment-2407226850
--     "neovim-plugin/blink.cmp",
--     dependencies = "rafamadriz/friendly-snippets",

--     -- "saghen/blink.cmp",
--     cond = vim.g.completer == "blink",
--     lazy = false, -- lazy loading handled internally
--     -- optional: provides snippets for the snippet source
--     dependencies = "rafamadriz/friendly-snippets",

--     -- use a release tag to download pre-built binaries
--     -- version = "v0.*",
--     -- version = "v0.2.1", -- REQUIRED release tag to download pre-built binaries
--     -- OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
--     build = "cargo build --release",
--     -- On musl libc based systems you need to add this flag
--     -- build = 'RUSTFLAGS="-C target-feature=-crt-static" cargo build --release',

--     opts = {
--       highlight = {
--         -- sets the fallback highlight groups to nvim-cmp's highlight groups
--         -- useful for when your theme doesn't support blink.cmp
--         -- will be removed in a future release, assuming themes add support
--         use_nvim_cmp_as_default = true,
--       },
--       keymap = {
--         accept = "<CR>",
--         hide = "<C-e>",
--         select_prev = { "<S-Tab>", "<Up>", "<C-p>" },
--         select_next = { "<Tab>", "<Down>", "<C-n>" },
--         scroll_documentation_down = "<C-j>",
--         scroll_documentation_up = "<C-k>",
--         snippet_forward = { "<Tab>", "<C-l>" },
--         snippet_backward = { "<S-Tab>", "<C-h>" },
--       },
--       -- set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
--       -- adjusts spacing to ensure icons are aligned
--       nerd_font_variant = "normal",

--       -- experimental auto-brackets support
--       accept = { auto_brackets = { enabled = true } },

--       -- experimental signature help support
--       trigger = {
--         completion = {
--           show_on_insert_on_trigger_character = false,
--         },
--         signature_help = { enabled = true },
--       },
--       windows = {
--         autocomplete = {
--           preselect = false,
--           selection = "manual",
--         },
--         documentation = {
--           opts = {
--             accept = {
--               create_undo_point = true,
--               auto_brackets = {
--                 enabled = false,
--                 default_brackets = { "(", ")" },
--                 override_brackets_for_filetypes = {},
--                 force_allow_filetypes = {},
--                 blocked_filetypes = {},
--                 kind_resolution = {
--                   enabled = true,
--                   blocked_filetypes = { "typescriptreact", "javascriptreact", "vue" },
--                 },
--                 semantic_token_resolution = {
--                   enabled = true,
--                   blocked_filetypes = {},
--                   timeout_ms = 400,
--                 },
--               },
--             },

--             trigger = {
--               completion = {
--                 keyword_regex = "[%w_\\-]",
--                 blocked_trigger_characters = { " ", "\n", "\t" },
--                 show_on_insert_on_trigger_character = true,
--                 show_on_insert_blocked_trigger_characters = { "'", "\"" },
--               },

--               signature_help = {
--                 enabled = false,
--                 blocked_trigger_characters = {},
--                 blocked_retrigger_characters = {},
--                 show_on_insert_on_trigger_character = true,
--               },
--             },

--             highlight = {
--               use_nvim_cmp_as_default = true,
--               accept = { auto_brackets = { enabled = true } },
--               trigger = { signature_help = { enabled = true } },
--             },
--             nerd_font_variant = "normal", -- mono|normal

--             sources = {
--               providers = {
--                 -- all of these properties work on every source
--                 {
--                   "blink.cmp.sources.lsp",
--                   name = "lsp",
--                   keyword_length = 0,
--                   score_offset = 5,
--                   trigger_characters = { "f", "o", "o" },
--                 },
--                 -- the following two sources have additional options
--                 {
--                   "blink.cmp.sources.path",
--                   name = "path",
--                   score_offset = 3,
--                   opts = {
--                     trailing_slash = false,
--                     label_trailing_slash = true,
--                     get_cwd = function(context) return vim.fn.expand(("#%d:p:h"):format(context.bufnr)) end,
--                     show_hidden_files_by_default = true,
--                   },
--                 },
--                 {
--                   "blink.cmp.sources.snippets",
--                   name = "snip",
--                   score_offset = -3,
--                   -- similar to https://github.com/garymjr/nvim-snippets
--                   opts = {
--                     -- friendly_snippets = true,
--                     friendly_snippets = false,
--                     search_paths = { vim.fn.stdpath("config") .. "/snippets_vscode" },
--                     global_snippets = { "all" },
--                     extended_filetypes = {},
--                     ignored_filetypes = {},
--                   },
--                 },
--                 {
--                   "blink.cmp.sources.buffer",
--                   name = "buf",
--                   fallback_for = { "lsp" },
--                 },
--               },
--             },

--             fuzzy = {
--               use_frecency = true,
--               use_proximity = true,
--               max_items = 200,
--               sorts = { "label", "kind", "score" },
--               prebuiltBinaries = {
--                 download = false,
--                 forceVersion = nil,
--               },
--             },

--             keymap = {
--               show = "<C-space>",
--               hide = "<C-e>",
--               accept = "<CR>",
--               select_next = { "<Down>", "<C-n>", "<Tab>" },
--               select_prev = { "<Up>", "<C-p>", "<S-Tab>" },
--               -- show_documentation = "",
--               -- hide_documentation = "",
--               scroll_documentation_up = "<C-d>",
--               scroll_documentation_down = "<C-u>",
--               -- snippet_forward = "",
--               -- snippet_backward = "",
--             },
--             windows = {
--               autocomplete = {
--                 min_width = 15,
--                 max_height = 10,
--                 border = "",
--                 -- winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None",
--                 scrolloff = 0,
--                 direction_priority = { "s", "n" },
--                 selection = "auto_insert",
--                 -- selection = "manual",
--                 -- 'function(blink.cmp.CompletionRenderContext): blink.cmp.Component[]' for custom rendering
--                 draw = "simple", -- simple | reversed | minimal | function
--                 cycle = {
--                   from_bottom = true,
--                   from_top = true,
--                 },
--               },
--               documentation = {
--                 min_width = 15,
--                 max_width = 60,
--                 max_height = 20,
--                 border = "rounded",
--                 -- winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,CursorLine:BlinkCmpDocCursorLine,Search:None",
--                 direction_priority = {
--                   autocomplete_north = { "e", "w", "n", "s" },
--                   autocomplete_south = { "e", "w", "s", "n" },
--                 },
--                 auto_show = true,
--                 auto_show_delay_ms = 500,
--                 update_delay_ms = 50,
--               },
--               signature_help = {
--                 min_width = 1,
--                 max_width = 100,
--                 max_height = 10,
--                 border = "rounded",
--                 -- winhighlight = "Normal:BlinkCmpSignatureHelp,FloatBorder:BlinkCmpSignatureHelpBorder",
--               },
--             },

--             kind_icons = {
--               -- base
--               Class = "󰠱",
--               Color = "󰏘",
--               Constant = "",
--               Constructor = "",
--               Enum = "",
--               EnumMember = "",
--               Event = "",
--               Field = "󰅩",
--               File = "󰈙",
--               Folder = "󰉋",
--               Function = "󰊕",
--               Interface = "",
--               Keyword = "󰌋",
--               Method = "󰆧",
--               Module = "",
--               Operator = "󰆕",
--               Property = "󰜢",
--               Reference = "󰈇",
--               Snippet = "",
--               Struct = "󰙅",
--               Text = "󰉿",
--               TypeParameter = "󰊄",
--               Unit = "",
--               Value = "󰎠",
--               Variable = "󰆧",
--               -- tree-sitter
--               String = "󰉿",
--             },
--           },
--         },
--       },
--       sources = {
--         providers = {
--           {
--             { "blink.cmp.sources.lsp" },
--             { "blink.cmp.sources.path" },
--             {
--               "blink.cmp.sources.snippets",
--               keyword_length = 1,
--               score_offset = -3,
--               opts = {
--                 extended_filetypes = {
--                   javascriptreact = { "javascript" },
--                   eelixir = { "elixir" },
--                   typescript = { "javascript" },
--                   typescriptreact = {
--                     "javascript",
--                     "javascriptreact",
--                     "typescript",
--                   },
--                 },
--                 friendly_snippets = false,
--               },
--             },
--           },
--           {
--             { "blink.cmp.sources.buffer", keyword_length = 2 },
--           },
--         },
--       },
--     },
--   },
-- }
