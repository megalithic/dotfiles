-- TODO:
-- https://github.com/jfpedroza/neotest-elixir
-- https://github.com/jfpedroza/neotest-elixir/pull/23

local SETTINGS = require("mega.settings")
local icons = SETTINGS.icons
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
      "<localleader>tp",
      function() require("neotest").summary.toggle() end,
      mode = "n",
    },
    {
      "<localleader>to",
      function() require("neotest").output.open({ short = true }) end,
      mode = "n",
    },
  }
elseif vim.g.tester == "vim-test" then
  keys = {
    { "<localleader>tn", "<cmd>TestNearest<cr>", desc = "run (n)earest test" },
    { "<localleader>ta", "<cmd>TestFile<cr>", desc = "run (a)ll tests in file" },
    { "<localleader>tf", "<cmd>TestFile<cr>", desc = "run (a)ll tests in file" },
    { "<localleader>tl", "<cmd>TestLast<cr>", desc = "run (l)ast test" },
    { "<localleader>ts", "<cmd>TestSuite<cr>", desc = "run test (s)uite" },
    -- { "<localleader>tT", "<cmd>TestLast<cr>", desc = "run _last test" },
    { "<localleader>tv", "<cmd>TestVisit<cr>", desc = "(v)isit last test" },
    -- { "<localleader>tp", "<cmd>A<cr>", desc = "open alt (edit)" },
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
    -- event = { "BufReadPost", "BufNewFile" },
    dependencies = { "tpope/vim-projectionist" },
    init = function()
      local function terminal_notifier(term_cmd, exit)
        -- local system = vim.fn.system
        if exit == 0 then
          mega.notify(fmt("👍 [PASS] vim-test: %s", term_cmd), L.INFO)
          -- system(string.format([[terminal-notifier -title "nvim [test]" -message "👍 test(s) passed"]], term_cmd))
        else
          mega.notify(fmt("👎 [FAIL] vim-test: %s", term_cmd), L.ERROR)
          -- system(string.format([[terminal-notifier -title "nvim [test]" -message "👎 test(s) failed"]], term_cmd))
        end
      end

      local term_opts = function(cmd, extra_opts)
        return vim.tbl_extend("force", {
          winnr = vim.fn.winnr(),
          cmd = cmd,
          notifier = terminal_notifier,
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
      vim.g["test#ruby#use_binstubs"] = 0
      vim.g["test#ruby#bundle_exec"] = 0
      vim.g["test#filename_modifier"] = ":."
      vim.g["test#preserve_screen"] = 1

      vim.g["test#custom_strategies"] = {
        termsplit = function(cmd) mega.term(term_opts(cmd)) end,
        termvsplit = function(cmd)
          if vim.opt.lines:get() * 4 < vim.opt.columns:get() then
            mega.term(term_opts(cmd, { direction = "vertical", size = 100 }))
          else
            mega.term(term_opts(cmd))
          end
        end,
        termfloat = function(cmd) mega.term(term_opts(cmd, { direction = "float", focus_on_open = true })) end,
        termtab = function(cmd) mega.term(term_opts(cmd, { direction = "tab", focus_on_open = true })) end,
      }

      vim.g["test#strategy"] = {
        nearest = "termvsplit",
        file = "termtab",
        suite = "termfloat",
        last = "termvsplit",
      }
    end,
  },
  {
    "nvim-neotest/neotest",
    -- event = { "BufReadPost **.js,**.jsx,**.ts,**.tsx", "BufNewFile **.js,**.jsx,**.ts,**.tsx" },
    cmd = { "Neotest" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "antoinemadec/FixCursorHold.nvim",
      "megalithic/neotest-elixir",
      "nvim-neotest/neotest-python",
      "nvim-neotest/neotest-plenary",
      "nvim-neotest/neotest-jest",
      "nvim-neotest/neotest-go",
      "nvim-neotest/nvim-nio",
      "stevearc/overseer.nvim",
      "nvim-lua/plenary.nvim",
      { "rcarriga/neotest-plenary", dependencies = { "nvim-lua/plenary.nvim" } },
    },
    keys = keys,
    config = function()
      local neotest = require("neotest")
      local nt_ns = vim.api.nvim_create_namespace("neotest")
      vim.diagnostic.config({
        virtual_text = {
          format = function(diagnostic)
            local message = diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
            return message
          end,
        },
      }, nt_ns)
      require("neotest.logging"):set_level("trace")

      require("neotest").setup({
        log_level = L.INFO,
        discovery = { enabled = false },
        diagnostic = { enabled = true },
        consumers = {
          overseer = require("neotest.consumers.overseer"),
        },
        output = {
          enabled = true,
          open_on_run = false,
        },
        -- overseer = {
        --   enabled = true,
        --   force_default = true,
        -- },
        status = {
          enabled = true,
        },
        output_panel = {
          enabled = true,
          open = "botright split | resize 25",
        },
        quickfix = {
          enabled = false,
          open = function() vim.cmd("Trouble quickfix") end,
        },
        floating = { border = SETTINGS.current_border },
        icons = {
          expanded = "",
          child_prefix = "",
          child_indent = "",
          final_child_prefix = "",
          non_collapsible = "",
          collapsed = "",

          passed = icons.test.passed,
          running = icons.test.running,
          skipped = icons.test.skipped,
          failed = icons.test.failed,
          unknown = icons.test.unknown,
          running_animated = vim.tbl_map(function(s) return s .. " " end, { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }),
          -- running_animated = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
          -- running_animated = vim.tbl_map(
          --   function(s) return s .. " " end,
          --   { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
          -- ),
          -- running_animated = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
        },
        summary = {
          mappings = {
            jumpto = "<cr>",
            -- jumpto = "gf",
            expand = "<tab>",
            -- expand = { "<Space>", "<2-LeftMouse>" },
            -- expand = "l",
            attach = "a",
            expand_all = "L",
            output = "o",
            run = "<C-r>",
            short = "p",
            stop = "u",
          },
        },
        adapters = {
          require("neotest-plenary"),
          require("neotest-elixir")({
            args = { "--trace" },
            strategy = "iex",
            iex_shell_direction = "vertical",
            extra_formatters = { "ExUnit.CLIFormatter", "ExUnitNotifier" },
          }),
          require("neotest-jest")({
            -- jestCommand = "npm test --",
            -- jestConfigFile = "jest.config.js",
            cwd = require("neotest-jest").root,
            -- cwd = function(path) return require("lspconfig.util").root_pattern("package.json", "jest.config.js")(path) end,
          }),
        },
      })
      --
      -- vim.keymap.set("n", "<leader>tn", function() neotest.run.run({}) end)
      -- vim.keymap.set("n", "<leader>tt", function() neotest.run.run({ vim.api.nvim_buf_get_name(0) }) end)
      -- vim.keymap.set("n", "<leader>ta", function()
      --   for _, adapter_id in ipairs(neotest.run.adapters()) do
      --     neotest.run.run({ suite = true, adapter = adapter_id })
      --   end
      -- end)
      -- vim.keymap.set("n", "<leader>tl", function() neotest.run.run_last() end)
      -- vim.keymap.set("n", "<leader>td", function() neotest.run.run({ strategy = "dap" }) end)
      -- vim.keymap.set("n", "<leader>tp", function() neotest.summary.toggle() end)
      -- vim.keymap.set("n", "<leader>to", function() neotest.output.open({ short = true }) end)
    end,
  },
}
