-- TODO:
-- https://github.com/jfpedroza/neotest-elixir
-- https://github.com/jfpedroza/neotest-elixir/pull/23
-- --
-- local ok_nt, nt = mega.require("neotest")
-- local function neotest() return nt end
--
local function open() require("neotest").output.open({ enter = true, short = false }) end
local function run_file() require("neotest").run.run(vim.fn.expand("%")) end
local function run_file_sync() require("neotest").run.run({ vim.fn.expand("%"), concurrent = false }) end
local function run_nearest() require("neotest").run.run() end
local function run_last() require("neotest").run.run_last() end
local function next_failed() require("neotest").jump.prev({ status = "failed" }) end
local function prev_failed() require("neotest").jump.next({ status = "failed" }) end
local function toggle_summary() require("neotest").summary.toggle() end
local function cancel() require("neotest").run.stop({ interactive = true }) end

return {
  {
    "vim-test/vim-test",
    cmd = {
      "TestNearest",
      "TestFile",
      "TestLast",
      "TestVisit",
      -- "A",
      -- "AV",
    },
    -- keys = {
    --   { "<localleader>tn", "<cmd>TestNearest<cr>", desc = "run _test under cursor" },
    --   { "<localleader>ta", "<cmd>TestFile<cr>", desc = "run _all tests in file" },
    --   { "<localleader>tf", "<cmd>TestFile<cr>", desc = "run _all tests in file" },
    --   { "<localleader>tl", "<cmd>TestLast<cr>", desc = "run _last test" },
    --   { "<localleader>tt", "<cmd>TestLast<cr>", desc = "run _last test" },
    --   { "<localleader>tv", "<cmd>TestVisit<cr>", desc = "run test file _visit" },
    --   { "<localleader>tp", "<cmd>A<cr>", desc = "open alt (edit)" },
    --   { "<localleader>tP", "<cmd>AV<cr>", desc = "open alt (vsplit)" },
    -- },
    event = { "BufReadPost", "BufNewFile" },
    -- cond = vim.g.tester == "vim-test",
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
    -- event = { "BufReadPost", "BufNewFile" },
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
      { "<localleader>tn", function() require("neotest").run.run() end, desc = "neotest: run nearest" },
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
    -- init = function()
    --   nmap("<localleader>tn", function() require("neotest").run.run() end, { desc = "neotest: run nearest" })
    -- end,
    config = function()
      local nt_ns = vim.api.nvim_create_namespace("neotest")
      vim.diagnostic.config({
        virtual_text = {
          format = function(diagnostic)
            dd(fmt("orig: %s", diagnostic.message))

            return diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
          end,
        },
      }, nt_ns)

      require("neotest").setup({
        log_level = L.DEBUG,
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
          enabled = true,
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

          passed = "", --alts: 
          running = "",
          skipped = "○",
          failed = "",
          unknown = "", -- alts: 
          -- running_animated = vim.tbl_map(
          --   function(s) return s .. " " end,
          --   { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
          -- ),
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
