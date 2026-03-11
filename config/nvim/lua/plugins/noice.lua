return {
  "folke/noice.nvim",
  -- enabled = false,
  dependencies = {
    "MunifTanjim/nui.nvim",
    "folke/snacks.nvim", -- Use snacks.notifier instead of nvim-notify
  },
  event = "VeryLazy",
  opts = {
    -- Disable messages UI (let snacks.notifier handle notifications)
    messages = { enabled = true, view = "mini" },
    presets = {
      bottom_search = true, -- use a classic bottom cmdline for search
      command_palette = false, -- position the cmdline and popupmenu together
      long_message_to_split = true, -- long messages will be sent to a split
      inc_rename = false, -- enables an input dialog for inc-rename.nvim
      lsp_doc_border = false, -- add a border to hover docs and signature help
    },

    -- Keep cmdline and popupmenu (the good parts)
    cmdline = {
      enabled = true,
      format = {
        -- cmdline = { icon = " " },
        -- search_down = { icon = "  " },
        -- search_up = { icon = "  " },
        cmdline = { pattern = "^:", icon = "❯", lang = "vim" },
        search_down = { view = "cmdline", icon = "  " },
        search_up = { view = "cmdline", icon = "  " },
        filter = { icon = " ", lang = "fish" },
        lua = { icon = " " },
        help = { icon = " 󰋖" },
      },
      view = "cmdline",
      -- opts = {
      --   position = {
      --     row = "90%", -- near bottom (like normal cmdline)
      --     col = "50%",
      --   },
      --   size = { width = "20%", height = 1 },
      --   border = {
      --     padding = { 1, 1 },
      --   },
      -- },
    },
    popupmenu = { enabled = true },

    -- cmdline_popup = {
    --   position = {
    --     row = 5,
    --     col = "50%",
    --   },
    --   size = {
    --     width = 60,
    --     height = "auto",
    --   },
    -- },

    views = {
      cmdline = {
        -- position = {
        --   row = "90%", -- near bottom (like normal cmdline)
        --   col = "50%",
        -- },
        -- size = { width = "20%", height = 1 },
        border = {
          padding = { 1, 1 },
        },

        -- position = {
        --   -- row = vim.o.lines,
        --   row = "98%", -- near bottom (like normal cmdline)
        --   col = "50%",
        -- },
        -- size = {
        --   -- Match smart_layout: 50% width (centered)
        --   width = "50%",
        --   height = 1,
        -- },
      },
      search = {
        -- size = {
        --   -- Match smart_layout: 50% width (centered)
        --   width = "50%",
        --   height = 1,
        -- },
        -- position = {
        --   -- row = vim.o.lines,
        --   row = "98%", -- near bottom (like normal cmdline)
        --   col = "50%",
        -- },
        border = {
          padding = { 1, 1 },
        },
      },
      confirm = {
        backend = "popup",
        relative = "editor",
        align = "center",
        position = {
          row = "40%",
          col = "50%",
        },
        size = "auto",
        border = {
          style = "rounded",
          padding = { 0, 2 },
        },
      },
    },

    -- LSP improvements
    lsp = {
      signature = { enabled = true },
      hover = { enabled = true },
      documentation = {
        opts = {
          win_options = {
            concealcursor = "n",
            conceallevel = 3,
          },
        },
      },
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
        ["cmp.entry.get_documentation"] = true,
      },
      -- Route LSP progress to snacks (if you want)
      progress = { enabled = false },
    },

    -- Route remaining messages through snacks
    routes = {
      -- Send notifications to snacks
      {
        filter = { event = "notify" },
        view = "notify",
      },
      {
        filter = {
          event = "msg_show",
          kind = "search_count",
        },
        opts = { skip = true },
      },
      {
        filter = {
          event = "msg_show",
          kind = "",
          find = "written",
        },
        opts = { skip = true },
      },
      {
        filter = { find = "Scanning" },
        opts = { skip = true },
      },
      -- Skip noisy messages
      {
        filter = {
          any = {
            { find = '"[^"]+"%s+%d+L,%s+%d+B%s+written' },
            { find = "No active Snippet" },
            { find = "No signature help available" },
            { find = "^<$" },
            { kind = "wmsg" },
            { find = "E486: Pattern not found" },
          },
        },
        opts = { skip = true },
      },
    },
  },
}
