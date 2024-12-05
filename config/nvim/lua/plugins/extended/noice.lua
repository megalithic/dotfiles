--
-- highlighting of filepaths and error codes
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "noice", "snacks_notif" },
  callback = function(ctx)
    vim.defer_fn(function()
      vim.api.nvim_buf_call(ctx.buf, function()
        vim.fn.matchadd("WarningMsg", [[[^/]\+\.lua:\d\+\ze:]])
        vim.fn.matchadd("WarningMsg", [[E\d\+]])
      end)
    end, 1)
  end,
})

--------------------------------------------------------------------------

-- DOCS https://github.com/folke/noice.nvim#-routes
local routes = {
  -- REDIRECT TO POPUP
  {
    filter = {
      min_height = 10,
      cond = function(msg)
        local title = (msg.opts and msg.opts.title) or ""
        return not title:find("tinygit") and not title:find("lazy%.nvim")
      end,
    },
    view = "popup",
  },

  -- output from `:Inspect`, for easier copying
  { filter = { event = "msg_show", find = "Treesitter.*- @" }, view = "popup" },

  -----------------------------------------------------------------------------
  -- REDIRECT TO MINI

  -- write/deletion messages
  { filter = { event = "msg_show", find = "%d+B written$" }, view = "mini" },
  { filter = { event = "msg_show", find = "%d+L, %d+B$" }, view = "mini" },
  { filter = { event = "msg_show", find = "%-%-No lines in buffer%-%-" }, view = "mini" },

  -- search
  { filter = { event = "msg_show", find = "^E486: Pattern not found" }, view = "mini" },

  -- word added to spellfile via `zg`
  { filter = { event = "msg_show", find = "^Word .*%.add$" }, view = "mini" },

  -- gitsigns.nvim
  { filter = { event = "msg_show", find = "Hunk %d+ of %d+" }, view = "mini" },
  { filter = { event = "msg_show", find = "No hunks" }, view = "mini" },

  -- nvim-treesitter
  { filter = { event = "msg_show", find = "^%[nvim%-treesitter%]" }, view = "mini" },
  { filter = { event = "notify", find = "All parsers are up%-to%-date" }, view = "mini" },

  -----------------------------------------------------------------------------
  -- SKIP

  -- FIX LSP bugs?
  { filter = { event = "msg_show", find = "lsp_signature? handler RPC" }, opts = { skip = true } },
	-- stylua: ignore
	{ filter = { event = "msg_show", find = "^%s*at process.processTicksAndRejections" }, opts = {skip = true} },

  -- code actions
  { filter = { event = "notify", find = "No code actions available" }, opts = { skip = true } },

  -- unneeded info on search patterns when pattern not found
  { filter = { event = "msg_show", find = "^[/?]." }, opts = { skip = true } },

  -- useless notification when closing buffers
  { filter = { event = "notify", find = "^Client marksman quit with exit code 1 and signal 0." }, opts = { skip = true } },

  { filter = { event = "msg_show", find = "Pattern not found:" }, opts = { skip = true } },
  { filter = { event = "msg_show", find = "search hit %a+, continuing at %a+" }, opts = { skip = true } },
}

-- modern vim command line replacement, requires nvim 0.9 or higher
---@type LazySpec
-- return {
--   "folke/noice.nvim",
--   cond = vim.o.cmdheight == 0,
--   event = "UIEnter",
--   ---@type NoiceConfig
--   -- opts = {
--   --   lsp = {
--   --     -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
--   --     override = {
--   --       -- ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
--   --       -- ["vim.lsp.util.stylize_markdown"] = true,
--   --       -- ["cmp.entry.get_documentation"] = true,
--   --     },
--   --   },
--   --   views = {
--   --     cmdline_popup = {
--   --       position = {
--   --         row = 1,
--   --         col = "50%",
--   --       },
--   --     },
--   --   },
--   --   presets = {
--   --     -- you can enable a preset by setting it to true, or a table that will override the preset config
--   --     -- you can also add custom presets that you can enable/disable with enabled=true
--   --     bottom_search = true, -- use a classic bottom cmdline for search
--   --     long_message_to_split = true, -- long messages will be sent to a split
--   --     lsp_doc_border = true, -- add a border to hover docs and signature help
--   --   },

--   --   routes = {
--   --     -- suppress no information available from LSP on K
--   --     -- when there are multiple LSPs this can be annoying
--   --     {
--   --       filter = {
--   --         event = "notify",
--   --         find = "No information available",
--   --       },
--   --       opts = { skip = true },
--   --     },

--   --     -- show buffer written messages in mini
--   --     {
--   --       filter = {
--   --         event = "msg_show",
--   --         kind = "",
--   --         find = "written",
--   --       },
--   --       view = "mini",
--   --       opts = {},
--   --     },

--   --     -- show alternate file creation prompt in popup (the notify.nvim animation
--   --     -- was messing with it)
--   --     {
--   --       filter = {
--   --         event = "msg_show",
--   --         kind = "",
--   --         find = "Create alternate file?",
--   --       },
--   --       view = "popup",
--   --       opts = {},
--   --     },

--   --     -- hide the annoying code_action notifications from null ls
--   --     {
--   --       filter = {
--   --         event = "lsp",
--   --         kind = "progress",
--   --         cond = function(message)
--   --           local title = vim.tbl_get(message.opts, "progress", "title")
--   --           local client = vim.tbl_get(message.opts, "progress", "client")

--   --           -- skip none-ls noisy messages
--   --           return client == "null-ls" and title == "code_action"
--   --         end,
--   --       },
--   --       opts = { skip = true },
--   --     },
--   --   },
--   -- },
--   opts = {
--     routes = routes,
--     messages = { view_search = false },
--     cmdline = {
--       view = "cmdline", -- view for rendering the cmdline. Change to `cmdline_popup` or `cmdline` to get a classic cmdline at the bottom
--       format = {
--         search_down = { icon = "  ", view = "cmdline" },
--         eval = { -- formatting for`:Eval`(my custom `:lua=` replacement)
--           pattern = "^:Eval%s+",
--           lang = "lua",
--           icon = "󰓗",
--           icon_hl_group = "@constant",
--         },
--       },
--     },
--     -- DOCS https://github.com/folke/noice.nvim/blob/main/lua/noice/config/views.lua
--     views = {
--       cmdline_popup = {
--         -- border = { style = vim.g.borderStyle },
--       },
--       cmdline_popupmenu = { -- the completions window
--         size = { max_height = 12 },
--         -- border = { padding = { 0, 1 } }, -- setting border style messes up automatic positioning
--         -- win_options = {
--         --   winhighlight = { Normal = "NormalFloat", FloatBorder = "NoicePopupmenuBorder" },
--         -- },
--         border = {
--           style = "none",
--           padding = { 2, 3 },
--         },
--         filter_options = {},
--         win_options = {
--           winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder",
--         },
--       },
--       cmdline = {
--         win_options = { winhighlight = { Normal = "NormalFloat" } },
--       },
--       mini = {
--         timeout = 3000,
--         zindex = 45, -- lower than nvim-notify (50), higher than satellite-scrollbar (40)
--         format = { "{title} ", "{message}" }, -- leave out "{level}"
--       },
--       popup = {
--         -- border = { style = vim.g.borderStyle },
--         size = { width = 90, height = 25 },
--         win_options = { scrolloff = 8, wrap = true, concealcursor = "ncv" },
--         close = { keys = { "q", "<D-w>", "<D-9>", "<D-0>" } },
--         format = { "{message}" },
--       },
--       split = {
--         enter = true,
--         size = "65%",
--         win_options = { scrolloff = 6 },
--         close = { keys = { "q", "<D-w>", "<D-9>", "<D-0>" } },
--       },
--     },
--     commands = {
--       history = {
--         filter_opts = { reverse = true }, -- show newest entries first
--         opts = { format = { "{title} ", "{message}" } }, -- https://github.com/folke/noice.nvim#-formatting
--         filter = { ["not"] = { find = "^/" } }, -- skip search messages
--       },
--       last = {
--         opts = { format = { "{title} ", "{message}" } },
--         filter = { ["not"] = { find = "^/" } }, -- skip search messages
--       },
--     },
--     notify = {
--       merge = true,
--     },

--     -- DISABLE features, since conflicts with existing plugins I prefer to use
--     lsp = {
--       progress = { enabled = false }, -- using my own statusline component instead
--       signature = { enabled = false }, -- using `lsp_signature.nvim` instead

--       -- ENABLE features
--       override = {
--         ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
--         ["vim.lsp.util.stylize_markdown"] = true,
--       },
--     },
--   },
--   dependencies = {
--     -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
--     { "MunifTanjim/nui.nvim", lazy = true },
--     { "rcarriga/nvim-notify" },
--   },
-- }

-- modern vim command line replacement, requires nvim 0.9 or higher
---@type LazySpec
return {
  "folke/noice.nvim",
  enabled = true,
  cond = vim.o.cmdheight == 0,
  event = "VeryLazy",
  ---@type NoiceConfig
  opts = {
    messages = { view_search = false },
    cmdline = {
      view = "cmdline", -- view for rendering the cmdline. Change to `cmdline_popup` or `cmdline` to get a classic cmdline at the bottom
      format = {
        search_down = { icon = "  ", view = "cmdline" },
        eval = { -- formatting for`:Eval`(my custom `:lua=` replacement)
          pattern = "^:Eval%s+",
          lang = "lua",
          icon = "󰓗",
          icon_hl_group = "@constant",
        },
      },
    },

    lsp = {
      -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
        ["cmp.entry.get_documentation"] = true,
      },

      signature = { enabled = false }, -- using `lsp_signature.nvim` instead
      progress = { enabled = false }, -- using my own statusline component instead
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

      {
        filter = {
          event = "msg_show",
          kind = "",
          find = "^E486: Pattern not found",
        },
        view = "mini",
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
    { "rcarriga/nvim-notify" },
  },
}
