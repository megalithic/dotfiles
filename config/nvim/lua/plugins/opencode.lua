return {
  {
    "NickvanDyke/opencode.nvim",
    dependencies = {
      "folke/snacks.nvim",
    },

    config = function()
      vim.g.opencode_opts = {
        -- Your configuration, if any — see `lua/opencode/config.lua`
      }

      vim.opt.autoread = true

      nmap("<leader>cc", function()
        local term_opts = function(cmd, extra_opts)
          return vim.tbl_extend("force", {
            winnr = vim.fn.winnr(),
            cmd = cmd,
            -- notifier = vim.schedule_wrap(terminal_notifier),
            temp = true,
            open_startinsert = true,
            focus_startinsert = true,
            focus_on_open = true,
            move_on_direction_change = false,
          }, extra_opts or {})
        end

        mega.term(term_opts("opencode", { position = "right", size = 100 }))
        -- require('snacks.terminal').toggle('opencode', { win = { position = 'right' } })
      end, { desc = "Toggle opencode" })
    end,

    -- Required for `opts.auto_reload`
    ---@type opencode.Config
    opts = {
      auto_reload = true, -- Automatically reload buffers edited by opencode
      context = { -- Context to inject in prompts
        ["@file"] = function()
          return require("opencode.context").file()
        end,
        ["@files"] = function()
          return require("opencode.context").files()
        end,
        ["@cursor"] = function()
          return require("opencode.context").cursor_position()
        end,
        ["@selection"] = function()
          return require("opencode.context").visual_selection()
        end,
        ["@diagnostics"] = function()
          return require("opencode.context").diagnostics()
        end,
        ["@quickfix"] = function()
          return require("opencode.context").quickfix()
        end,
        ["@diff"] = function()
          return require("opencode.context").git_diff()
        end,
      },
    },
    -- stylua: ignore
    keys = {
      {
        '<leader>cc',
        function()
        local term_opts = function(cmd, extra_opts)
          return vim.tbl_extend("force", {
            winnr = vim.fn.winnr(),
            cmd = cmd,
            -- notifier = vim.schedule_wrap(terminal_notifier),
            temp = true,
            open_startinsert = true,
            focus_startinsert = true,
            focus_on_open = true,
            move_on_direction_change = false,
          }, extra_opts or {})
        end


              mega.term(term_opts("opencode", { position = "right", size = 100 }))
          -- require('snacks.terminal').toggle('opencode', { win = { position = 'right' } })
        end,
        desc = "Toggle opencode",
      },
      { '<leader>ca', function() require('opencode').ask() end, desc = 'Ask opencode', mode = { 'n', 'v' }, },
      { '<leader>cA', function() require('opencode').ask('@file ') end, desc = 'Ask opencode about current file', mode = { 'n', 'v' }, },
      { '<leader>ce', function() require('opencode').prompt('Explain @cursor and its context') end, desc = 'Explain code near cursor' },
      { '<leader>cr', function() require('opencode').prompt('Review @file for correctness and readability') end, desc = 'Review file', },
      { '<leader>cf', function() require('opencode').prompt('Fix these @diagnostics') end, desc = 'Fix errors', },
      { '<leader>co', function() require('opencode').prompt('Optimize @selection for performance and readability') end, desc = 'Optimize selection', mode = 'v', },
      { '<leader>cd', function() require('opencode').prompt('Add documentation comments for @selection') end, desc = 'Document selection', mode = 'v', },
      { '<leader>ct', function() require('opencode').prompt('Add tests for @selection') end, desc = 'Test selection', mode = 'v', },
    },
  },
}
