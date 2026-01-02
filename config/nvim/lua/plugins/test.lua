-- TODO:
-- https://github.com/jfpedroza/neotest-elixir
-- https://github.com/jfpedroza/neotest-elixir/pull/23

local SETTINGS = require("config.options")
local icons = Icons
local keys = {}
local fmt = string.format
if vim.g.tester == "neotest" then
  keys = {
    {
      "<localleader>tn",
      function() require("neotest").run.run({}) end,
      mode = "n",
    },
    {
      "<localleader>tt",
      function() require("neotest").run.run({ vim.api.nvim_buf_get_name(0) }) end,
      mode = "n",
    },
    {
      "<localleader>ta",
      function()
        for _, adapter_id in ipairs(require("neotest").run.adapters()) do
          require("neotest").run.run({ suite = true, adapter = adapter_id })
        end
      end,
      mode = "n",
    },
    {
      "<localleader>tl",
      function() require("neotest").run.run_last() end,
      mode = "n",
    },
    {
      "<localleader>td",
      function() require("neotest").run.run({ strategy = "dap" }) end,
      mode = "n",
    },
    {
      "<localleader>to",
      function() require("neotest").output.open() end,
      mode = "n",
    },
    { "<localleader>tp", "<cmd>A<cr>", desc = "open alt (edit)" },
    { "<localleader>tP", "<cmd>AV<cr>", desc = "open alt (vsplit)" },
  }
elseif vim.g.tester == "vim-test" then
  keys = {
    { "<localleader>tn", "<cmd>TestNearest<cr>", desc = "run [n]earest test" },
    { "<localleader>ta", "<cmd>TestFile<cr>", desc = "run [a]ll tests in file" },
    { "<localleader>tf", "<cmd>TestFile<cr>", desc = "run [a]ll tests in [f]ile" },
    { "<localleader>tl", "<cmd>TestLast<cr>", desc = "run [l]ast test" },
    { "<localleader>ts", "<cmd>TestSuite<cr>", desc = "run test [s]uite" },
    -- { "<localleader>tT", "<cmd>TestLast<cr>", desc = "run _last test" },
    { "<localleader>tv", "<cmd>TestVisit<cr>", desc = "[v]isit last test" },
    { "<localleader>tp", "<cmd>A<cr>", desc = "open alt (edit)" },
    -- { "<localleader><localleader>", "<cmd>A<cr>", desc = "open alt (edit)" },
    { "<localleader>tP", "<cmd>AV<cr>", desc = "open alt (vsplit)" },
  }
end

return {
  {
    "vim-test/vim-test",
    cond = vim.g.tester == "vim-test",
    cmd = {
      "TestNearest",
      "TestFile",
      "TestLast",
      "TestVisit",
      "TestSuite",
      "A",
      "AV",
    },
    keys = keys,
    dependencies = { "tpope/vim-projectionist" },
    init = function()
      if Megaterm ~= nil then
        local function notifier(term_cmd, exit_code)
          if exit_code == 0 then
            Echom(fmt("👍 [PASS] vim-test: %s", term_cmd), "GitSignsAdd")
          -- vim.fn.system(string.format([[terminal-notifier -title "nvim [test]" -message "👍 test(s) passed"]], term_cmd))
          else
            Echom(fmt("👎 [FAIL] vim-test: %s", term_cmd), "GitSignsDelete")
            -- vim.fn.system(string.format([[terminal-notifier -title "nvim [test]" -message "👎 test(s) failed"]], term_cmd))
          end
        end

        local term_opts = function(cmd, extra_opts)
          local opts = vim.tbl_deep_extend("force", {
            cmd = cmd,
            temp = true,
            limit = 1,
            on_exit_notifier = vim.schedule_wrap(notifier),
            start_insert = true,
            auto_insert = false,
            auto_close = false,
            on_exit = function(job_id, exit_code, event, term)
              if exit_code == 0 then term:close() end
            end,
            focus = false,
            win_config = { width = 100, height = 80 },
          }, extra_opts or {})

          return opts
        end

        -- REF:
        -- neat ways to detect jest things
        -- https://github.com/weilbith/vim-blueplanet/blob/master/pack/plugins/start/test_/autoload/test/typescript/jest.vim
        -- https://github.com/roginfarrer/dotfiles/blob/main/nvim/.config/nvim/lua/rf/plugins/vim-test.lua#L19

        vim.g["test#strategy"] = "neovim"
        vim.g["test#filename_modifier"] = ":."
        vim.g["test#preserve_screen"] = 1
        vim.g["test#javascript#runner"] = "jest"
        vim.g["test#custom_strategies"] = {
          termsplit = function(cmd) Megaterm(term_opts(cmd, { position = "bottom", win_config = { height = 100 } })) end,
          termvsplit = function(cmd)
            if vim.opt.lines:get() * 4 < vim.opt.columns:get() then
              -- Snacks.terminal(cmd, { win = { position = "right", width = 50 }, interactive = false, auto_insert = true, auto_close = false })
              Megaterm(term_opts(cmd, { position = "right" }))
            else
              -- Snacks.terminal(cmd, { win = { position = "bottom", height = 100 }, interactive = true })
              Megaterm(term_opts(cmd, { position = "bottom" }))
            end
          end,
          termfloat = function(cmd) Megaterm(term_opts(cmd, { position = "float" })) end,
          termtab = function(cmd) Megaterm(term_opts(cmd, { position = "tab" })) end,
        }
      else
        local function terminal_notifier(term_cmd, exit)
          if exit == 0 then
            Echom(fmt("👍 [PASS] vim-test: %s", term_cmd), "GitSignsAdd")
            -- vim.fn.system(string.format([[terminal-notifier -title "nvim [test]" -message "👍 test(s) passed"]], term_cmd))
          else
            Echom(fmt("👎 [FAIL] vim-test: %s", term_cmd), "GitSignsDelete")
            -- vim.fn.system(string.format([[terminal-notifier -title "nvim [test]" -message "👎 test(s) failed"]], term_cmd))
          end
        end

        local term_opts = function(cmd, extra_opts)
          return vim.tbl_extend("force", {
            winnr = vim.fn.winnr(),
            cmd = cmd,
            notifier = vim.schedule_wrap(terminal_notifier),
            temp = true,
            open_startinsert = true,
            focus_startinsert = false,
            focus_on_open = false,
            move_on_direction_change = false,
          }, extra_opts or {})
        end

        -- REF:
        -- neat ways to detect jest things
        -- https://github.com/weilbith/vim-blueplanet/blob/master/pack/plugins/start/test_/autoload/test/typescript/jest.vim
        -- https://github.com/roginfarrer/dotfiles/blob/main/nvim/.config/nvim/lua/rf/plugins/vim-test.lua#L19

        vim.g["test#strategy"] = "neovim"
        vim.g["test#filename_modifier"] = ":."
        vim.g["test#preserve_screen"] = 1
        vim.g["test#javascript#runner"] = "jest"
        vim.g["test#custom_strategies"] = {
          termsplit = function(cmd) mega.term(term_opts(cmd)) end,
          termvsplit = function(cmd)
            if vim.opt.lines:get() * 4 < vim.opt.columns:get() then
              mega.term(term_opts(cmd, { position = "right", size = 100 }))
            else
              mega.term(term_opts(cmd, { position = "bottom", size = 100 }))
            end
          end,
          termfloat = function(cmd) mega.term(term_opts(cmd, { position = "float", focus_on_open = true })) end,
          termtab = function(cmd) mega.term(term_opts(cmd, { position = "tab", focus_on_open = true })) end,
        }
      end

      vim.g["test#strategy"] = {
        nearest = "termvsplit",
        file = "termvsplit",
        suite = "termfloat",
        last = "termvsplit",
      }
    end,
  },
}
