-- TODO:
-- https://github.com/jfpedroza/neotest-elixir
-- https://github.com/jfpedroza/neotest-elixir/pull/23
--
local function neotest() return require("neotest") end
local function open() neotest().output.open({ enter = true, short = false }) end
local function run_file() neotest().run.run(vim.fn.expand("%")) end
local function run_file_sync() neotest().run.run({ vim.fn.expand("%"), concurrent = false }) end
local function run_nearest() neotest().run.run() end
local function run_last() neotest().run.run_last() end
local function next_failed() neotest().jump.prev({ status = "failed" }) end
local function prev_failed() neotest().jump.next({ status = "failed" }) end
local function toggle_summary() neotest().summary.toggle() end
local function cancel() neotest().run.stop({ interactive = true }) end

return {
  {
    "vim-test/vim-test",
    cmd = {
      "TestNearest",
      "TestFile",
      "TestLast",
      "TestVisit",
      "A",
      "AV",
    },
    keys = {
      { "<localleader>tn", "<cmd>TestNearest<cr>", desc = "run _test under cursor" },
      { "<localleader>ta", "<cmd>TestFile<cr>", desc = "run _all tests in file" },
      { "<localleader>tf", "<cmd>TestFile<cr>", desc = "run _all tests in file" },
      { "<localleader>tl", "<cmd>TestLast<cr>", desc = "run _last test" },
      { "<localleader>tt", "<cmd>TestLast<cr>", desc = "run _last test" },
      { "<localleader>tv", "<cmd>TestVisit<cr>", desc = "run test file _visit" },
      { "<localleader>tp", "<cmd>A<cr>", desc = "open alt (edit)" },
      { "<localleader>tP", "<cmd>AV<cr>", desc = "open alt (vsplit)" },
    },
    -- event = { "BufReadPost", "BufNewFile" },
    enabled = vim.g.tester == "vim-test",
    dependencies = { "tpope/vim-projectionist" },
    init = function()
      local system = vim.fn.system

      local function terminal_notifier(term_cmd, exit)
        if exit == 0 then
          mega.notify("test(s) passed 👍", L.INFO)
          -- system(string.format([[terminal-notifier -title "Neovim [vim-test]" -message "test(s) passed"]], term_cmd))
        else
          mega.notify("test(s) failed 👎", L.ERROR)
          -- system(string.format([[terminal-notifier -title "Neovim [vim-test]" -message "test(s) failed"]], term_cmd))
        end
      end

      local term_opts = function(cmd, extra_opts)
        return vim.tbl_extend("force", {
          winnr = vim.fn.winnr(),
          cmd = cmd,
          notifier = terminal_notifier,
          temp = true,
          start_insert = false,
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
        termsplit = function(cmd) mega.term.open(term_opts(cmd)) end,
        termvsplit = function(cmd) mega.term.open(term_opts(cmd, { direction = "vertical" })) end,
        termfloat = function(cmd) mega.term.open(term_opts(cmd, { direction = "float", focus_on_open = true })) end,
        termtab = function(cmd) mega.term.open(term_opts(cmd, { direction = "tab", focus_on_open = true })) end,
      }

      vim.g["test#strategy"] = {
        nearest = "termsplit",
        file = "termtab",
        suite = "termfloat",
        last = "termsplit",
      }
    end,
  },
  {
    "nvim-neotest/neotest",
    -- event = { "LspAttach" },
    enabled = vim.g.tester == "neotest",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "antoinemadec/FixCursorHold.nvim",
      { "scottming/neotest-elixir", branch = "only-support-iex" }, -- https://github.com/jfpedroza/neotest-elixir
      { "haydenmeade/neotest-jest" },
      { "rcarriga/neotest-plenary", dependencies = { "nvim-lua/plenary.nvim" } },
    },
    keys = {
      { "<localleader>ts", toggle_summary, desc = "neotest: toggle summary" },
      { "<localleader>to", function() require("neotest").output_panel.open() end, desc = "neotest: output" },
      { "<localleader>tn", run_nearest, desc = "neotest: run nearest" },
      { "<localleader>tl", run_last, desc = "neotest: run last" },
      { "<localleader>tf", run_file, desc = "neotest: run file" },
      { "<localleader>tF", run_file_sync, desc = "neotest: run file synchronously" },
      { "<localleader>tc", cancel, desc = "neotest: cancel" },
      { "[e", next_failed, desc = "jump to next failed test" },
      { "]e", prev_failed, desc = "jump to previous failed test" },
      -- nnoremap("<leader>nt", function()
      --   neotest.run.run()
      -- end)
      --
      -- nnoremap("<leader>nf", function()
      --   neotest.run.run(vim.fn.expand("%"))
      -- end)
      --
      -- nnoremap("<leader>nd", function()
      --   neotest.run.run({ strategy = "dap" })
      -- end)
      --
      -- nnoremap("<leader>ns", function()
      --   neotest.summary.toggle()
      -- end)
    },
    config = function()
      -- local env = nil
      --
      -- local function run(arg)
      --   local default_env = env or {}
      --   local args
      --
      --   if type(arg) == "table" then
      --     local local_env = arg.env or {}
      --     arg.env = vim.tbl_extend("force", default_env, local_env)
      --     args = arg
      --   else
      --     args = { arg, env = default_env }
      --   end
      --
      --   print("Neotest run called with arg", args[1])
      --   require("neotest").run.run(args)
      -- end
      -- --
      -- -- local function run_file(args)
      -- --   args = args or {}
      -- --   args[1] = vim.fn.expand("%")
      -- --   run(args)
      -- -- end
      -- --
      -- local function run_suite(args)
      --   args = args or {}
      --   args[1] = vim.fn.getcwd()
      --   run(args)
      -- end
      --
      -- vim.api.nvim_create_user_command("Neotest", run_suite, {})
      -- vim.api.nvim_create_user_command("NeotestFile", run_file, {})
      -- vim.api.nvim_create_user_command("NeotestNearest", nearest, {})
      -- vim.api.nvim_create_user_command("NeotestLast", neotest.run.run_last, {})
      -- vim.api.nvim_create_user_command("NeotestAttach", neotest.run.attach, {})
      -- vim.api.nvim_create_user_command("NeotestSummary", neotest.summary.toggle, {})
      -- vim.api.nvim_create_user_command("NeotestOutput", neotest.output.open, {})

      local namespace = vim.api.nvim_create_namespace("neotest")
      vim.diagnostic.config({
        virtual_text = {
          format = function(diagnostic)
            dd(fmt("orig: %s", diagnostic.message))
            dd(fmt("gsub: %s", diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")))

            return diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
          end,
        },
      }, namespace)

      require("neotest").setup({
        log_level = L.DEBUG,
        discovery = { enabled = true },
        diagnostic = { enabled = true },
        output = {
          enabled = false,
          open_on_run = "short",
        },
        output_panel = {
          enabled = true,
          open = "botright split | resize 25",
        },
        quickfix = { enabled = false, open = true },
        floating = { border = mega.get_border() },
        icons = {
          expanded = "",
          child_prefix = "",
          child_indent = "",
          final_child_prefix = "",
          non_collapsible = "",
          collapsed = "",

          passed = "",
          running = "",
          failed = "",
          unknown = "",
          running_animated = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
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
