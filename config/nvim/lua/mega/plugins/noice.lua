local border = mega.get_border()

local fn = vim.fn
local border, L = mega.get_border(), vim.log.levels

-- REF:
-- https://github.com/willothy/nvim-config/blob/main/lua/plugins/noice.lua
-- https://github.com/Oliver-Leete/Configs/blob/master/nvim/lua/user/noice.lua
-- https://github.com/zolrath/dotfiles/blob/main/dot_config/nvim/lua/plugins/noice.lua
return {
  "folke/noice.nvim",
  event = "VeryLazy",
  cond = vim.o.cmdheight == 0,
  version = "*",
  dependencies = { "MunifTanjim/nui.nvim" },
  init = function()
    map({ "n", "i", "s" }, "<c-f>", function()
      if not require("noice.lsp").scroll(4) then return "<c-f>" end
    end, { silent = true, expr = true })

    map({ "n", "i", "s" }, "<c-b>", function()
      if not require("noice.lsp").scroll(-4) then return "<c-b>" end
    end, { silent = true, expr = true })

    -- cmap("<S-Enter>", function() require("noice").redirect(fn.getcmdline()) end, { desc = "redirect Cmdline" })
    -- cmap("<S-CR>", function() require("noice").redirect(fn.getcmdline()) end, { desc = "redirect Cmdline" })
    nmap("<leader>snl", function() require("noice").cmd("last") end, { desc = "noice: last message" })
    nmap("<leader>snh", function() require("noice").cmd("history") end, { desc = "noice: history" })
    nmap("<leader>sna", function() require("noice").cmd("all") end, { desc = "noice: all" })
    nmap("<leader>snd", function() require("noice").cmd("dismiss") end, { desc = "noice: dismiss" })
  end,
  config = function(_, _opts)
    local spinners = require("noice.util.spinners")
    spinners.spinners["mega"] = {
      frames = {
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
      },
      interval = 80,
    }

    require("noice").setup({
      format = {
        spinner = {
          name = "mega",
          hl = "Constant",
        },
      },
      cmdline = {
        view = "cmdline",
        format = {
          IncRename = { title = " Rename " },
          substitute = { pattern = "^:%%?s/", icon = " ", ft = "regex", title = "" },
          input = { icon = " ", lang = "text", view = "cmdline_popup", title = "" },
        },
      },
      popupmenu = {
        backend = "nui",
      },
      lsp = {
        progress = {
          enabled = false,
          format = {
            { "{data.progress.percentage} ", hl_group = "Comment" },
            { "{spinner} ", hl_group = "NoiceLspProgressSpinner" },
            { "{data.progress.title} ", hl_group = "Comment" },
          },
          format_done = {},
        },
        documentation = {
          opts = {
            border = { style = border },
            position = { row = 2 },
          },
        },
        signature = {
          enabled = true,
          opts = {
            position = { row = 2 },
          },
        },
        hover = { enabled = true },
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
      },
      views = {
        vsplit = { size = { width = "auto" } },
        split = { win_options = { winhighlight = { Normal = "Normal" } } },
        popup = {
          border = { style = border, padding = { 0, 1 } },
        },
        cmdline_popup = {
          position = { row = 5, col = "50%" },
          size = { width = "auto", height = "auto" },
          border = { style = border, padding = { 0, 1 } },
        },
        confirm = {
          border = { style = border, padding = { 0, 1 }, text = { top = "" } },
        },
        popupmenu = {
          relative = "editor",
          position = { row = 9, col = "50%" },
          size = { width = 60, height = 10 },
          border = { style = border, padding = { 0, 1 } },
          win_options = { winhighlight = { Normal = "NotifyFloat", FloatBorder = "FloatBorder" } },
        },
      },
      redirect = { view = "popup", filter = { event = "msg_show" } },
      -- routes = {
      --   {
      --     opts = { skip = true },
      --     filter = {
      --       any = {
      --         { event = "msg_show", find = "written" },
      --         { event = "msg_show", find = "%d+ lines, %d+ bytes" },
      --         { event = "msg_show", find = "line %d+ of %d+" },
      --         { event = "msg_show", kind = "search_count" },
      --         { event = "msg_show", find = "%d+L, %d+B" },
      --         { event = "msg_show", find = "^Hunk %d+ of %d" },
      --         { event = "msg_show", find = "%d+ change" },
      --         { event = "msg_show", find = "%d+ line" },
      --         { event = "msg_show", find = "%d+ more line" },
      --         -- TODO: investigate the source of this LSP message and disable it happens in typescript files
      --         { event = "notify", find = "No information available" },
      --       },
      --     },
      --   },
      --   {
      --     view = "vsplit",
      --     filter = { event = "msg_show", min_height = 20 },
      --   },
      --   {
      --     view = "notify",
      --     filter = {
      --       any = {
      --         { event = "msg_show", min_height = 10 },
      --         { event = "msg_show", find = "Treesitter" },
      --       },
      --     },
      --     opts = { timeout = 10000 },
      --   },
      --   {
      --     view = "notify",
      --     filter = { event = "notify", find = "Type%-checking" },
      --     opts = { replace = true, merge = true, title = "TSC" },
      --     stop = true,
      --   },
      --   {
      --     view = "mini",
      --     filter = {
      --       any = {
      --         { event = "msg_show", find = "^E486:" },
      --         { event = "notify", max_height = 1 },
      --         { event = "notify", find = "lazy" },
      --         { event = "notify", find = "test" },
      --       },
      --     }, -- minimise pattern not found messages
      --   },
      --   {
      --     view = "notify",
      --     filter = {
      --       any = {
      --         { warning = true },
      --         { event = "msg_show", find = "^Warn" },
      --         { event = "msg_show", find = "^W%d+:" },
      --         { event = "msg_show", find = "^No hunks$" },
      --       },
      --     },
      --     opts = { title = "Warning", level = L.WARN, merge = false, replace = false },
      --   },
      --   {
      --     view = "notify",
      --     opts = { title = "Error", level = L.ERROR, merge = true, replace = false },
      --     filter = {
      --       any = {
      --         { error = true },
      --         { event = "msg_show", find = "^Error" },
      --         { event = "msg_show", find = "^E%d+:" },
      --       },
      --     },
      --   },
      --   {
      --     view = "notify",
      --     opts = { title = "" },
      --     filter = { kind = { "emsg", "echo", "echomsg" } },
      --   },
      --   {
      --     filter = {
      --       event = "msg_show",
      --       find = "%d+L, %d+B",
      --     },
      --     view = "mini",
      --   },
      --   {
      --     filter = { event = "msg_show", min_height = 10 },
      --     view = "split",
      --     opts = { enter = true },
      --   },
      --   {
      --     filter = { event = "msg_show", kind = "search_count" },
      --     opts = { skip = true },
      --   },
      --   {
      --     filter = {
      --       event = "msg_show",
      --       find = "; before #",
      --     },
      --     opts = { skip = true },
      --   },
      --   {
      --     filter = {
      --       event = "msg_show",
      --       find = "; after #",
      --     },
      --     opts = { skip = true },
      --   },
      --   {
      --     filter = {
      --       event = "msg_show",
      --       find = " lines, ",
      --     },
      --     opts = { skip = true },
      --   },
      --   {
      --     filter = {
      --       event = "msg_show",
      --       find = "go up one level",
      --     },
      --     opts = { skip = true },
      --   },
      --   {
      --     filter = {
      --       event = "msg_show",
      --       find = "yanked",
      --     },
      --     opts = { skip = true },
      --   },
      --   {
      --     filter = { find = "No active Snippet" },
      --     opts = { skip = true },
      --   },
      --   {
      --     filter = { find = "waiting for cargo metadata" },
      --     opts = { skip = true },
      --   },
      --   -- Show "recording" messages
      --   {
      --     view = "notify",
      --     filter = { event = "msg_showmode" },
      --   },
      --   -- Hide "written" messages
      --   {
      --     filter = {
      --       event = "msg_show",
      --       kind = "",
      --       find = "written",
      --     },
      --     opts = { skip = true },
      --   },
      --   -- Hide "No information available" messages
      --   {
      --     view = "notify",
      --     filter = {
      --       find = "No information available",
      --     },
      --     opts = { skip = true },
      --   },
      -- },
      commands = {
        history = { view = "vsplit" },
      },

      messages = {
        -- NOTE: If you enable messages, then the cmdline is enabled automatically.
        -- This is a current Neovim limitation.
        enabled = true, -- enables the Noice messages UI
        view = "notify", -- default view for messages
        view_error = "notify", -- view for errors
        view_warn = "notify", -- view for warnings
        view_history = "messages", -- view for :messages
        view_search = "virtualtext", -- view for search count messages. Set to `false` to disable
      },
      presets = {
        lsp_doc_border = true,
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = true,
      },
      -- format = {
      --   spinner = {
      --     name = "mine",
      --     hl = "Constant",
      --   },
      -- },
      -- lsp = {
      --   progress = {
      --     enabled = false,
      --     format = {
      --       { "{data.progress.percentage} ", hl_group = "Comment" },
      --       { "{spinner} ", hl_group = "NoiceLspProgressSpinner" },
      --       { "{data.progress.title} ", hl_group = "Comment" },
      --     },
      --     format_done = {},
      --   },
      --   hover = { enabled = true },
      --   signature = { enabled = false, auto_open = { enabled = false } },
      --   override = {
      --     ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      --     ["vim.lsp.util.stylize_markdown"] = true,
      --     ["cmp.entry.get_documentation"] = true,
      --   },
      -- },
      -- cmdline = {
      --   format = {
      --     filter = { pattern = "^:%s*!", icon = " ", ft = "sh" },
      --     IncRename = {
      --       pattern = "^:%s*IncRename%s+",
      --       icon = " ",
      --       conceal = true,
      --       opts = {
      --         -- relative = "cursor",
      --         -- size = { min_width = 20 },
      --         -- position = { row = -3, col = 0 },
      --         buf_options = { filetype = "text" },
      --       },
      --     },
      --   },
      -- },
      -- views = {
      --   cmdline_popup = {
      --     win_options = {
      --       winblend = 5,
      --       winhighlight = {
      --         Normal = "NormalFloat",
      --         FloatBorder = "NoiceCmdlinePopupBorder",
      --         IncSearch = "",
      --         Search = "",
      --       },
      --       cursorline = false,
      --     },
      --   },
      -- },
      -- popupmenu = {
      --   enabled = true,
      -- },
      -- routes = {
      --   {
      --     filter = {
      --       event = "msg_show",
      --       find = "%d+L, %d+B",
      --     },
      --     view = "mini",
      --   },
      --   {
      --     filter = { event = "msg_show", min_height = 10 },
      --     view = "split",
      --     opts = { enter = true },
      --   },
      --   {
      --     filter = { event = "msg_show", kind = "search_count" },
      --     opts = { skip = true },
      --   },
      --   {
      --     filter = {
      --       event = "msg_show",
      --       find = "; before #",
      --     },
      --     opts = { skip = true },
      --   },
      --   {
      --     filter = {
      --       event = "msg_show",
      --       find = "; after #",
      --     },
      --     opts = { skip = true },
      --   },
      --   {
      --     filter = {
      --       event = "msg_show",
      --       find = " lines, ",
      --     },
      --     opts = { skip = true },
      --   },
      --   {
      --     filter = {
      --       event = "msg_show",
      --       find = "go up one level",
      --     },
      --     opts = { skip = true },
      --   },
      --   {
      --     filter = {
      --       event = "msg_show",
      --       find = "yanked",
      --     },
      --     opts = { skip = true },
      --   },
      --   {
      --     filter = { find = "No active Snippet" },
      --     opts = { skip = true },
      --   },
      --   {
      --     filter = { find = "waiting for cargo metadata" },
      --     opts = { skip = true },
      --   },
      --   -- Show "recording" messages
      --   {
      --     view = "notify",
      --     filter = { event = "msg_showmode" },
      --   },
      --   -- Hide "written" messages
      --   {
      --     filter = {
      --       event = "msg_show",
      --       kind = "",
      --       find = "written",
      --     },
      --     opts = { skip = true },
      --   },
      --   -- Hide "No information available" messages
      --   {
      --     view = "notify",
      --     filter = {
      --       find = "No information available",
      --     },
      --     opts = { skip = true },
      --   },
      -- },
    })

    -- highlight.plugin('noice', {
    --   { NoiceMini = { inherit = 'MsgArea', bg = { from = 'Normal' } } },
    --   { NoicePopupBaseGroup = { inherit = 'NormalFloat', fg = { from = 'DiagnosticSignInfo' } } },
    --   { NoicePopupWarnBaseGroup = { inherit = 'NormalFloat', fg = { from = 'Float' } } },
    --   { NoicePopupInfoBaseGroup = { inherit = 'NormalFloat', fg = { from = 'Conditional' } } },
    --   { NoiceCmdlinePopup = { bg = { from = 'NormalFloat' } } },
    --   { NoiceCmdlinePopupBorder = { link = 'FloatBorder' } },
    --   { NoiceCmdlinePopupBorderCmdline = { link = 'NoicePopupBaseGroup' } },
    --   { NoiceCmdlinePopupBorderSearch = { link = 'NoicePopupWarnBaseGroup' } },
    --   { NoiceCmdlinePopupBorderFilter = { link = 'NoicePopupWarnBaseGroup' } },
    --   { NoiceCmdlinePopupBorderHelp = { link = 'NoicePopupInfoBaseGroup' } },
    --   { NoiceCmdlinePopupBorderSubstitute = { link = 'NoicePopupWarnBaseGroup' } },
    --   { NoiceCmdlinePopupBorderIncRename = { link = 'NoicePopupWarnBaseGroup' } },
    --   { NoiceCmdlinePopupBorderInput = { link = 'NoicePopupBaseGroup' } },
    --   { NoiceCmdlinePopupBorderLua = { link = 'NoicePopupBaseGroup' } },
    --   { NoiceCmdlineIconCmdline = { link = 'NoicePopupBaseGroup' } },
    --   { NoiceCmdlineIconSearch = { link = 'NoicePopupWarnBaseGroup' } },
    --   { NoiceCmdlineIconFilter = { link = 'NoicePopupWarnBaseGroup' } },
    --   { NoiceCmdlineIconHelp = { link = 'NoicePopupInfoBaseGroup' } },
    --   { NoiceCmdlineIconIncRename = { link = 'NoicePopupWarnBaseGroup' } },
    --   { NoiceCmdlineIconSubstitute = { link = 'NoicePopupWarnBaseGroup' } },
    --   { NoiceCmdlineIconInput = { link = 'NoicePopupBaseGroup' } },
    --   { NoiceCmdlineIconLua = { link = 'NoicePopupBaseGroup' } },
    --   { NoiceConfirm = { bg = { from = 'NormalFloat' } } },
    --   { NoiceConfirmBorder = { link = 'NoicePopupBaseGroup' } },
    -- })
  end,
}

-- return {
--   "folke/noice.nvim",
--   event = "VeryLazy",
--   cond = not vim.g.notifier_enabled,
--   version = "*",
--   dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" },
--   opts = {
--     lsp = {
--       override = {
--         ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
--         ["vim.lsp.util.stylize_markdown"] = true,
--         -- ["cmp.entry.get_documentation"] = true,
--       },
--     },
--     cmdline = {
--       view = "cmdline",
--       format = {
--         -- IncRename = { title = "Rename" },
--         substitute = { pattern = "^:%%?s/", icon = " ", ft = "regex", title = "" },
--       },
--     },
--     views = {
--       vsplit = { size = { width = "auto" } },
--       split = { win_options = { winhighlight = { Normal = "Normal" } } },
--       popup = {
--         border = { style = border, padding = { 0, 1 } },
--       },
--       cmdline_popup = {
--         position = { row = 5, col = "50%" },
--         size = { width = "auto", height = "auto" },
--         border = { style = border, padding = { 0, 1 } },
--       },
--       confirm = {
--         border = { style = border, padding = { 0, 1 }, text = { top = "" } },
--       },
--       popupmenu = {
--         relative = "editor",
--         position = { row = 9, col = "50%" },
--         size = { width = 60, height = 10 },
--         border = { style = border, padding = { 0, 1 } },
--         win_options = { winhighlight = { Normal = "NormalFloat", FloatBorder = "FloatBorder" } },
--       },
--     },
--     messages = {
--       -- NOTE: If you enable messages, then the cmdline is enabled automatically.
--       -- This is a current Neovim limitation.
--       enabled = true, -- enables the Noice messages UI
--       view = "notify", -- default view for messages
--       view_error = "notify", -- view for errors
--       view_warn = "notify", -- view for warnings
--       view_history = "messages", -- view for :messages
--       view_search = "virtualtext", -- view for search count messages. Set to `false` to disable
--     },
--     presets = {
--       bottom_search = true,
--       command_palette = true,
--       long_message_to_split = true,
--     },
--   },
--   -- stylua: ignore
--   keys = {
--     { "<S-Enter>", function() require("noice").redirect(vim.fn.getcmdline()) end, mode = "c", desc = "Redirect Cmdline" },
--     { "<leader>snl", function() require("noice").cmd("last") end, desc = "Noice Last Message" },
--     { "<leader>snh", function() require("noice").cmd("history") end, desc = "Noice History" },
--     { "<leader>sna", function() require("noice").cmd("all") end, desc = "Noice All" },
--     { "<c-f>", function() if not require("noice.lsp").scroll(4) then return "<c-f>" end end, silent = true, expr = true, desc = "Scroll forward", mode = {"i", "n", "s"} },
--     { "<c-b>", function() if not require("noice.lsp").scroll(-4) then return "<c-b>" end end, silent = true, expr = true, desc = "Scroll backward", mode = {"i", "n", "s"}},
--   },
--
--   -- opts = {
--   --   cmdline = {
--   --     format = {
--   --       -- IncRename = { title = "Rename" },
--   --       substitute = { pattern = "^:%%?s/", icon = " ", ft = "regex", title = "" },
--   --     },
--   --   },
--   --   lsp = {
--   --     documentation = {
--   --       opts = {
--   --         border = { style = border },
--   --         position = { row = 2 },
--   --       },
--   --     },
--   --     signature = {
--   --       enabled = true,
--   --       opts = {
--   --         position = { row = 2 },
--   --       },
--   --     },
--   --     hover = { enabled = true },
--   --     override = {
--   --       ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
--   --       ["vim.lsp.util.stylize_markdown"] = true,
--   --       ["cmp.entry.get_documentation"] = true,
--   --     },
--   --   },
--   --   views = {
--   --     vsplit = { size = { width = "auto" } },
--   --     split = { win_options = { winhighlight = { Normal = "Normal" } } },
--   --     popup = {
--   --       border = { style = border, padding = { 0, 1 } },
--   --     },
--   --     cmdline_popup = {
--   --       position = { row = 5, col = "50%" },
--   --       size = { width = "auto", height = "auto" },
--   --       border = { style = border, padding = { 0, 1 } },
--   --     },
--   --     confirm = {
--   --       border = { style = border, padding = { 0, 1 }, text = { top = "" } },
--   --     },
--   --     popupmenu = {
--   --       relative = "editor",
--   --       position = { row = 9, col = "50%" },
--   --       size = { width = 60, height = 10 },
--   --       border = { style = border, padding = { 0, 1 } },
--   --       win_options = { winhighlight = { Normal = "NormalFloat", FloatBorder = "FloatBorder" } },
--   --     },
--   --   },
--   --   redirect = { view = "popup", filter = { event = "msg_show" } },
--   --   routes = {
--   --     {
--   --       opts = { skip = true },
--   --       filter = {
--   --         any = {
--   --           { event = "msg_show", find = "written" },
--   --           { event = "msg_show", find = "%d+ lines, %d+ bytes" },
--   --           { event = "msg_show", kind = "search_count" },
--   --           { event = "msg_show", find = "%d+L, %d+B" },
--   --           { event = "msg_show", find = "^Hunk %d+ of %d" },
--   --           -- TODO: investigate the source of this LSP message and disable it happens in typescript files
--   --           { event = "notify", find = "No information available" },
--   --         },
--   --       },
--   --     },
--   --     {
--   --       view = "vsplit",
--   --       filter = { event = "msg_show", min_height = 20 },
--   --     },
--   --     {
--   --       view = "notify",
--   --       filter = {
--   --         any = {
--   --           { event = "msg_show", min_height = 10 },
--   --           { event = "msg_show", find = "Treesitter" },
--   --         },
--   --       },
--   --       opts = { timeout = 10000 },
--   --     },
--   --     {
--   --       view = "mini",
--   --       filter = { any = { { event = "msg_show", find = "^E486:" } } }, -- minimise pattern not found messages
--   --     },
--   --     {
--   --       view = "notify",
--   --       filter = {
--   --         any = {
--   --           { warning = true },
--   --           { event = "msg_show", find = "^Warn" },
--   --           { event = "msg_show", find = "^W%d+:" },
--   --           { event = "msg_show", find = "^No hunks$" },
--   --         },
--   --       },
--   --       opts = { title = "Warning", level = L.WARN, merge = false, replace = false },
--   --     },
--   --     {
--   --       view = "notify",
--   --       opts = { title = "Error", level = L.ERROR, merge = true, replace = false },
--   --       filter = {
--   --         any = {
--   --           { error = true },
--   --           { event = "msg_show", find = "^Error" },
--   --           { event = "msg_show", find = "^E%d+:" },
--   --         },
--   --       },
--   --     },
--   --     {
--   --       view = "notify",
--   --       opts = { title = "" },
--   --       filter = { kind = { "emsg", "echo", "echomsg" } },
--   --     },
--   --   },
--   --   commands = {
--   --     history = { view = "vsplit" },
--   --   },
--   --   presets = {
--   --     -- inc_rename = true,
--   --     long_message_to_split = true,
--   --     lsp_doc_border = true,
--   --     bottom_search = true, -- use a classic bottom cmdline for search
--   --     command_palette = true, -- position the cmdline and popupmenu together
--   --   },
--   -- },
--   -- config = function(_, opts)
--   --   require("noice").setup(opts)
--   --
--   --   -- highlight.plugin("noice", {
--   --   --   { NoiceMini = { inherit = "MsgArea", bg = { from = "Normal" } } },
--   --   --   { NoicePopupBaseGroup = { inherit = "NormalFloat", fg = { from = "DiagnosticSignInfo" } } },
--   --   --   { NoicePopupWarnBaseGroup = { inherit = "NormalFloat", fg = { from = "Float" } } },
--   --   --   { NoicePopupInfoBaseGroup = { inherit = "NormalFloat", fg = { from = "Conditional" } } },
--   --   --   { NoiceCmdlinePopup = { bg = { from = "NormalFloat" } } },
--   --   --   { NoiceCmdlinePopupBorder = { link = "FloatBorder" } },
--   --   --   { NoiceCmdlinePopupBorderCmdline = { link = "NoicePopupBaseGroup" } },
--   --   --   { NoiceCmdlinePopupBorderSearch = { link = "NoicePopupWarnBaseGroup" } },
--   --   --   { NoiceCmdlinePopupBorderFilter = { link = "NoicePopupWarnBaseGroup" } },
--   --   --   { NoiceCmdlinePopupBorderHelp = { link = "NoicePopupInfoBaseGroup" } },
--   --   --   { NoiceCmdlinePopupBorderSubstitute = { link = "NoicePopupWarnBaseGroup" } },
--   --   --   { NoiceCmdlinePopupBorderIncRename = { link = "NoicePopupWarnBaseGroup" } },
--   --   --   { NoiceCmdlinePopupBorderInput = { link = "NoicePopupBaseGroup" } },
--   --   --   { NoiceCmdlinePopupBorderLua = { link = "NoicePopupBaseGroup" } },
--   --   --   { NoiceCmdlineIconCmdline = { link = "NoicePopupBaseGroup" } },
--   --   --   { NoiceCmdlineIconSearch = { link = "NoicePopupWarnBaseGroup" } },
--   --   --   { NoiceCmdlineIconFilter = { link = "NoicePopupWarnBaseGroup" } },
--   --   --   { NoiceCmdlineIconHelp = { link = "NoicePopupInfoBaseGroup" } },
--   --   --   { NoiceCmdlineIconIncRename = { link = "NoicePopupWarnBaseGroup" } },
--   --   --   { NoiceCmdlineIconSubstitute = { link = "NoicePopupWarnBaseGroup" } },
--   --   --   { NoiceCmdlineIconInput = { link = "NoicePopupBaseGroup" } },
--   --   --   { NoiceCmdlineIconLua = { link = "NoicePopupBaseGroup" } },
--   --   --   { NoiceConfirm = { bg = { from = "NormalFloat" } } },
--   --   --   { NoiceConfirmBorder = { link = "NoicePopupBaseGroup" } },
--   --   -- })
--   --
--   --   vim.keymap.set({ "n", "i", "s" }, "<c-f>", function()
--   --     if not require("noice.lsp").scroll(4) then return "<c-f>" end
--   --   end, { silent = true, expr = true })
--   --
--   --   vim.keymap.set({ "n", "i", "s" }, "<c-b>", function()
--   --     if not require("noice.lsp").scroll(-4) then return "<c-b>" end
--   --   end, { silent = true, expr = true })
--   --
--   --   vim.keymap.set("c", "<M-CR>", function() require("noice").redirect(vim.fn.getcmdline()) end, {
--   --     desc = "redirect Cmdline",
--   --   })
--   -- end,
-- }
