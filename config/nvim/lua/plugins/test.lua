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
  {
    "nvim-neotest/neotest",
    cmd = { "Neotest", "NeotestFile", "NeotestNearest", "NeotestLast", "NeotestAttach", "NeotestSummary", "A", "AV" },
    dependencies = {
      { "pablobfonseca/nvim-nio", branch = "fix-deprecations" },
      { "nvim-neotest/neotest-plenary", dependencies = { "nvim-lua/plenary.nvim" } },
      "tpope/vim-projectionist",
      "antoinemadec/FixCursorHold.nvim",
      "jfpedroza/neotest-elixir",
      "nvim-neotest/neotest-python",
      "nvim-neotest/neotest-jest",
      {
        "stevearc/overseer.nvim",
        cmd = {
          "OverseerToggle",
          "OverseerOpen",
          "OverseerRun",
          "OverseerBuild",
          "OverseerClose",
          "OverseerLoadBundle",
          "OverseerSaveBundle",
          "OverseerDeleteBundle",
          "OverseerRunCmd",
          "OverseerQuickAction",
          "OverseerTaskAction",
        },
        keys = {
          -- { "<leader>ttR", "<cmd>OverseerRunCmd<cr>", desc = "Run Command" },
          -- { "<leader>tta", "<cmd>OverseerTaskAction<cr>", desc = "Task Action" },
          -- { "<leader>ttb", "<cmd>OverseerBuild<cr>", desc = "Build" },
          -- { "<leader>ttc", "<cmd>OverseerClose<cr>", desc = "Close" },
          -- { "<leader>ttd", "<cmd>OverseerDeleteBundle<cr>", desc = "Delete Bundle" },
          -- { "<leader>ttl", "<cmd>OverseerLoadBundle<cr>", desc = "Load Bundle" },
          -- { "<leader>tto", "<cmd>OverseerOpen<cr>", desc = "Open" },
          -- { "<leader>ttq", "<cmd>OverseerQuickAction<cr>", desc = "Quick Action" },
          -- { "<leader>ttr", "<cmd>OverseerRun<cr>", desc = "Run" },
          -- { "<leader>tts", "<cmd>OverseerSaveBundle<cr>", desc = "Save Bundle" },
          -- { "<leader>ttt", "<cmd>OverseerToggle<cr>", desc = "Toggle" },
        },
        opts = {},
      },
    },
    keys = keys,
    config = function()
      local neotest = require("neotest")
      local neotest_ns = vim.api.nvim_create_namespace("neotest")
      local nt = {}

      nt.env = nil

      function nt.run(arg)
        local default_env = nt.env or {}
        local args

        if type(arg) == "table" then
          local env = arg.env or {}
          arg.env = vim.tbl_extend("force", default_env, env)
          args = arg
        else
          args = { arg, env = default_env }
        end

        print("Neotest run called with arg", args[1])
        require("neotest").run.run(args)
      end

      function nt.run_file(args)
        args = args or {}
        args[1] = vim.fn.expand("%")
        nt.run(args)
      end

      function nt.run_suite(args)
        args = args or {}
        args[1] = vim.fn.getcwd()
        nt.run(args)
      end

      function nt.read_env(...) nt.env = vim.fn.DotenvRead(...) end

      vim.diagnostic.config({
        virtual_text = {
          format = function(diagnostic)
            local message = diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
            return message
          end,
        },
      }, neotest_ns)

      require("neotest.logging"):set_level("trace")

      require("neotest").setup({
        log_level = L.INFO,
        discovery = { enabled = false },
        diagnostic = { enabled = true },
        consumers = {
          overseer = require("neotest.consumers.overseer"),
        },
        output = { open_on_run = true },
        -- output = {
        --   enabled = true,
        --   open_on_run = false,
        -- },
        overseer = {
          enabled = true,
          force_default = true,
        },
        status = {
          enabled = true,
        },
        -- output_panel = {
        --   enabled = true,
        --   open = "botright split | resize 25",
        -- },
        -- quickfix = {
        --   enabled = false,
        --   open = function() vim.cmd("Trouble quickfix") end,
        -- },
        -- floating = { border = vim.g.current_border },
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

      vim.api.nvim_create_user_command("Neotest", nt.run_suite, {})
      vim.api.nvim_create_user_command("NeotestFile", nt.run_file, {})
      vim.api.nvim_create_user_command("NeotestNearest", nt.run, {})
      vim.api.nvim_create_user_command("NeotestLast", neotest.run.run_last, {})
      vim.api.nvim_create_user_command("NeotestAttach", neotest.run.attach, {})
      vim.api.nvim_create_user_command("NeotestSummary", neotest.summary.toggle, {})
      vim.api.nvim_create_user_command("NeotestOutput", neotest.output.open, {})

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
  {
    "quolpr/quicktest.nvim",
    cond = vim.g.tester == "quicktest",
    config = function()
      local qt = require("quicktest")

      qt.setup({
        -- Choose your adapter, here all supported adapters are listed
        adapters = {
          require("quicktest.adapters.golang")({
            additional_args = function(bufnr) return { "-race", "-count=1" } end,
            -- bin = function(bufnr) return 'go' end
            -- cwd = function(bufnr) return 'your-cwd' end
          }),
          require("quicktest.adapters.vitest")({
            -- bin = function(bufnr) return 'vitest' end
            -- cwd = function(bufnr) return bufnr end
            -- config_path = function(bufnr) return 'vitest.config.js' end
          }),
          require("quicktest.adapters.elixir"),
          require("quicktest.adapters.criterion"),
          require("quicktest.adapters.dart"),
        },
        -- split or popup mode, when argument not specified
        default_win_mode = "split",
        -- Baleia make coloured output. Requires baleia package
        use_baleia = true,
      })
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "m00qek/baleia.nvim",
    },
    keys = {
      {
        "<localleader>tl",
        function()
          local qt = require("quicktest")
          -- current_win_mode return currently opened panel, split or popup
          qt.run_line()
          -- You can force open split or popup like this:
          -- qt.run_line('split')
          -- qt.run_line('popup')
        end,
        desc = "[T]est Run [L]line",
      },
      {
        "<localleader>tf",
        function()
          local qt = require("quicktest")

          qt.run_file()
        end,
        desc = "[T]est Run [F]ile",
      },
      {
        "<localleader>td",
        function()
          local qt = require("quicktest")

          qt.run_dir()
        end,
        desc = "[T]est Run [D]ir",
      },
      {
        "<localleader>ta",
        function()
          local qt = require("quicktest")

          qt.run_all()
        end,
        desc = "[T]est Run [A]ll",
      },
      {
        "<localleader>tp",
        function()
          local qt = require("quicktest")

          qt.run_previous()
        end,
        desc = "[T]est Run [P]revious",
      },
      {
        "<localleader>tt",
        function()
          local qt = require("quicktest")

          qt.toggle_win("split")
        end,
        desc = "[T]est [T]oggle Window",
      },
      {
        "<localleader>tc",
        function()
          local qt = require("quicktest")

          qt.cancel_current_run()
        end,
        desc = "[T]est [C]ancel Current Run",
      },
    },
  },
}
