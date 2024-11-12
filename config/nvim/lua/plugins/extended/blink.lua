local SETTINGS = require("mega.settings")
local icons = SETTINGS.icons
local U = require("mega.utils")

return {
  "saghen/blink.cmp",
  -- build = "cargo build --release",
  version = "v0.*",
  cond = vim.g.completer == "blink",
  dependencies = {
    "rafamadriz/friendly-snippets",
    "saghen/blink.compat",
    { "chrisgrieser/cmp-nerdfont", lazy = true },
    { "hrsh7th/cmp-emoji", lazy = true },
  },
  event = "VeryLazy",

  opts = {
    keymap = {
      preset = "enter",
      ["<Tab>"] = {
        function(cmp)
          if cmp.is_in_snippet() then
            return cmp.accept()
          else
            return cmp.select_next()
          end
        end,
        "snippet_forward",
        "fallback",
      },
      ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
    },
    accept = {
      auto_brackets = { enabled = true },
    },

    trigger = {
      signature_help = { enabled = true },
    },

    highlight = {
      use_nvim_cmp_as_default = true,
    },

    blocked_filetypes = { "firenvim" },
    nerd_font_variant = "mono",

    sources = {
      -- add lazydev to your completion providers
      completion = {
        enabled_providers = {
          "lsp",
          "path",
          "snippets",
          "buffer",
          "lazydev",
          "nerdfont",
          "emoji",
        },
      },
      providers = {
        -- dont show LuaLS require statements when lazydev has items
        lsp = { fallback_for = { "lazydev" } },
        lazydev = { name = "LazyDev", module = "lazydev.integrations.blink" },
        nerdfont = {
          name = "nerdfont",
          module = "blink.compat.source",
          transform_items = function(ctx, items)
            -- TODO: check https://github.com/Saghen/blink.cmp/pull/253#issuecomment-2454984622
            local kind = require("blink.cmp.types").CompletionItemKind.Text

            for i = 1, #items do
              items[i].kind = kind
            end

            return items
          end,
        },
        emoji = {
          name = "emoji",
          module = "blink.compat.source",
          transform_items = function(ctx, items)
            -- TODO: check https://github.com/Saghen/blink.cmp/pull/253#issuecomment-2454984622
            local kind = require("blink.cmp.types").CompletionItemKind.Text

            for i = 1, #items do
              items[i].kind = kind
            end

            return items
          end,
        },
      },
    },
    windows = {
      documentation = {
        border = SETTINGS.borders.blink_empty,
        auto_show = true,
        min_width = 15,
        max_width = 60,
        max_height = 20,
        auto_show_delay_ms = 250,
      },
      signature_help = {
        border = SETTINGS.borders.blink_empty,
      },
      autocomplete = {
        min_width = 25,
        max_height = 30,
        scrollbar = true,
        border = SETTINGS.borders.blink_empty,
        selection = "manual", -- alts: preselect, manual, auto_insert
        draw = function(ctx)
          local icon = ctx.kind_icon
          local icon_hl = vim.api.nvim_get_hl_by_name("BlinkCmpKind", true) and "BlinkCmpKind" .. ctx.kind or "BlinkCmpKind"

          local source, client = ctx.item.source_id, ctx.item.client_id
          if client and vim.lsp.get_client_by_id(client).name then source = vim.lsp.get_client_by_id(client).name end

          return {
            {
              " " .. ctx.item.label .. " ",
              fill = true,
              hl_group = ctx.deprecated and "BlinkCmpLabelDeprecated" or "BlinkCmpLabel",
              max_width = 35,
            },
            {
              icon .. ctx.icon_gap .. ctx.kind .. " ",
              fill = true,
              hl_group = icon_hl,
              max_width = 25,
            },
            {
              " [" .. string.lower(source) .. "] ",
              fill = true,
              hl_group = ctx.deprecated and "BlinkCmpLabelDeprecated" or "CmpItemMenu",
              max_width = 15,
            },
          }
        end,
      },
    },
    kind_icons = SETTINGS.icons.vscode,
  },
}
