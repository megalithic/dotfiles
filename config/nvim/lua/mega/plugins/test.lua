-- TODO:
-- https://github.com/jfpedroza/neotest-elixir
-- https://github.com/jfpedroza/neotest-elixir/pull/23

return {
  {
    "megalithic/nvim-test",
    cond = vim.g.tester == "nvim-test",
    dev = true,
    cmd = {
      "TestNearest",
      "TestFile",
      "TestLast",
      "TestVisit",
      "TestSuite",
      "A",
      "AV",
    },
    keys = {
      { "<localleader>tn", "<cmd>TestNearest<cr>", desc = "run (n)earest test" },
      { "<localleader>ta", "<cmd>TestFile<cr>", desc = "run (a)ll tests in file" },
      { "<localleader>tf", "<cmd>TestFile<cr>", desc = "run (a)ll tests in file" },
      { "<localleader>tl", "<cmd>TestLast<cr>", desc = "run (l)ast test" },
      { "<localleader>ts", "<cmd>TestSuite<cr>", desc = "run test (s)uite" },
      -- { "<localleader>tT", "<cmd>TestLast<cr>", desc = "run _last test" },
      { "<localleader>tv", "<cmd>TestVisit<cr>", desc = "open last (v)isited test" },
      { "<localleader>tp", "<cmd>A<cr>", desc = "open alt (edit)" },
      { "<localleader>tP", "<cmd>AV<cr>", desc = "open alt (vsplit)" },
    },
    config = function()
      require("nvim-test").setup({
        run = true, -- run tests (using for debug)
        commands_create = true, -- create commands (TestFile, TestLast, ...)
        filename_modifier = ":.", -- modify filenames before tests run(:h filename-modifiers)
        silent = false, -- less notifications
        term = "terminal", -- a terminal to run ("terminal"|"toggleterm")
        termOpts = {
          direction = "vertical", -- terminal's direction ("horizontal"|"vertical"|"float")
          width = 96, -- terminal's width (for vertical|float)
          height = 24, -- terminal's height (for horizontal|float)
          go_back = false, -- return focus to original window after executing
          stopinsert = "auto", -- exit from insert mode (true|false|"auto")
          keep_one = true, -- keep only one terminal for testing
        },
        runners = { -- setup tests runners
          cs = "nvim-test.runners.dotnet",
          go = "nvim-test.runners.go-test",
          haskell = "nvim-test.runners.hspec",
          javascriptreact = "nvim-test.runners.jest",
          javascript = "nvim-test.runners.jest",
          lua = "nvim-test.runners.busted",
          python = "nvim-test.runners.pytest",
          ruby = "nvim-test.runners.rspec",
          eelixir = "nvim-test.runners.mix",
          elixir = "nvim-test.runners.mix",
          rust = "nvim-test.runners.cargo-test",
          typescript = "nvim-test.runners.jest",
          typescriptreact = "nvim-test.runners.jest",
        },
      })
    end,
  },

  {
    "vim-test/vim-test",
    cond = vim.g.tester == "vim-test",
    cmd = {
      "TestNearest",
      "TestFile",
      "TestLast",
      "TestVisit",
      -- "A",
      -- "AV",
    },
    keys = {
      { "<localleader>tn", "<cmd>TestNearest<cr>", desc = "run (n)earest test" },
      { "<localleader>ta", "<cmd>TestFile<cr>", desc = "run (a)ll tests in file" },
      { "<localleader>tf", "<cmd>TestFile<cr>", desc = "run (a)ll tests in file" },
      { "<localleader>tl", "<cmd>TestLast<cr>", desc = "run (l)ast test" },
      { "<localleader>ts", "<cmd>TestSuite<cr>", desc = "run test (s)uite" },
      -- { "<localleader>tT", "<cmd>TestLast<cr>", desc = "run _last test" },
      { "<localleader>tv", "<cmd>TestVisit<cr>", desc = "run test file (v)isit" },
      { "<localleader>tp", "<cmd>A<cr>", desc = "open alt (edit)" },
      { "<localleader>tP", "<cmd>AV<cr>", desc = "open alt (vsplit)" },
    },
    -- event = { "BufReadPost", "BufNewFile" },
    dependencies = { "tpope/vim-projectionist" },
    init = function()
      local system = vim.fn.system

      local function terminal_notifier(term_cmd, exit)
        if exit == 0 then
          mega.notify("vim-test(s) passed 👍", L.INFO)
          -- system(string.format([[terminal-notifier -title "Neovim [vim-test]" -message "test(s) passed"]], term_cmd))
        else
          mega.notify("vim-test(s) failed 👎", L.ERROR)
          -- system(string.format([[terminal-notifier -title "Neovim [vim-test]" -message "test(s) failed"]], term_cmd))
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
        termvsplit = function(cmd) mega.term(term_opts(cmd, { direction = "vertical" })) end,
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
    cond = true,
    "nvim-neotest/neotest",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "Neotest" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "antoinemadec/FixCursorHold.nvim",
      { "megalithic/neotest-elixir", dev = true },
      { "haydenmeade/neotest-jest" },
      { "rcarriga/neotest-plenary", dependencies = { "nvim-lua/plenary.nvim" } },
    },
    keys = {
      -- { "<localleader>ts", toggle_summary, desc = "neotest: toggle summary" },
      { "<localleader>to", function() require("neotest").output_panel.open() end, desc = "neotest: output" },
      { "<localleader>tt", "<cmd>lua require('neotest').run.run()<cr>", desc = "neotest: run nearest" },
      -- { "<localleader>tl", run_last, desc = "neotest: run last" },
      -- { "<localleader>tf", run_file, desc = "neotest: run file" },
      -- { "<localleader>tF", run_file_sync, desc = "neotest: run file synchronously" },
      -- { "<localleader>tc", cancel, desc = "neotest: cancel" },
      -- { "[e", next_failed, desc = "jump to next failed test" },
      -- { "]e", prev_failed, desc = "jump to previous failed test" },
    },
    config = function()
      local nt_ns = vim.api.nvim_create_namespace("neotest")
      vim.diagnostic.config({
        virtual_text = {
          format = function(diagnostic)
            return diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
          end,
        },
      }, nt_ns)

      require("neotest").setup({
        log_level = L.INFO,
        discovery = { enabled = true },
        diagnostic = { enabled = true },
        output = {
          enabled = true,
          open_on_run = "short",
        },
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
        floating = { border = mega.get_border() },
        icons = {
          expanded = "",
          child_prefix = "",
          child_indent = "",
          final_child_prefix = "",
          non_collapsible = "",
          collapsed = "",

          passed = mega.icons.test.passed,
          running = mega.icons.test.running,
          skipped = mega.icons.test.skipped,
          failed = mega.icons.test.failed,
          unknown = mega.icons.test.unknown,
          running_animated = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
          -- running_animated = vim.tbl_map(
          --   function(s) return s .. " " end,
          --   { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
          -- ),
          -- running_animated = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
        },
        summary = {
          mappings = {
            jumpto = "<CR>",
            expand = { "<Space>", "<2-LeftMouse>" },
          },
        },
        adapters = {
          require("neotest-plenary"),
          require("neotest-elixir")({
            args = { "--trace" },
            iex_shell_direction = "float",
            extra_formatters = { "ExUnit.CLIFormatter", "ExUnitNotifier" },
          }),
          require("neotest-jest")({
            jestCommand = "npm test --",
            jestConfigFile = "jest.config.js",
            -- env = { CI = true },
            cwd = function(path) return require("lspconfig.util").root_pattern("package.json", "jest.config.js")(path) end,
          }),
        },
      })
    end,
  },
}
