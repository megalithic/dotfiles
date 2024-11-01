-- modern vim command line replacement, requires nvim 0.9 or higher
---@type LazySpec
return {
  "folke/noice.nvim",
  enabled = false,
  event = "VeryLazy",
  ---@type NoiceConfig
  opts = {
    lsp = {
      -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
      override = {
        -- ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        -- ["vim.lsp.util.stylize_markdown"] = true,
        -- ["cmp.entry.get_documentation"] = true,
      },
    },
    views = {
      cmdline_popup = {
        position = {
          row = 1,
          col = "50%",
        },
      },
    },
    presets = {
      -- you can enable a preset by setting it to true, or a table that will override the preset config
      -- you can also add custom presets that you can enable/disable with enabled=true
      bottom_search = true, -- use a classic bottom cmdline for search
      long_message_to_split = true, -- long messages will be sent to a split
      lsp_doc_border = true, -- add a border to hover docs and signature help
    },

    routes = {
      -- suppress no information available from LSP on K
      -- when there are multiple LSPs this can be annoying
      {
        filter = {
          event = "notify",
          find = "No information available",
        },
        opts = { skip = true },
      },

      -- show buffer written messages in mini
      {
        filter = {
          event = "msg_show",
          kind = "",
          find = "written",
        },
        view = "mini",
        opts = {},
      },

      -- show alternate file creation prompt in popup (the notify.nvim animation
      -- was messing with it)
      {
        filter = {
          event = "msg_show",
          kind = "",
          find = "Create alternate file?",
        },
        view = "popup",
        opts = {},
      },

      -- hide the annoying code_action notifications from null ls
      {
        filter = {
          event = "lsp",
          kind = "progress",
          cond = function(message)
            local title = vim.tbl_get(message.opts, "progress", "title")
            local client = vim.tbl_get(message.opts, "progress", "client")

            -- skip none-ls noisy messages
            return client == "null-ls" and title == "code_action"
          end,
        },
        opts = { skip = true },
      },
    },
  },
  dependencies = {
    -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
    { "MunifTanjim/nui.nvim", lazy = true },
    "rcarriga/nvim-notify",
  },
}
