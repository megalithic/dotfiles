-- TODO:
-- https://github.com/jfpedroza/neotest-elixir
-- https://github.com/jfpedroza/neotest-elixir/pull/23
--
local function neotest() return require("neotest") end
local function open() neotest().output.open({ enter = true, short = false }) end
local function run_file() neotest().run.run(vim.fn.expand("%")) end
local function run_file_sync() neotest().run.run({ vim.fn.expand("%"), concurrent = false }) end
local function nearest() neotest().run.run() end
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
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "tpope/vim-projectionist" },
    init = function()
      local system = vim.fn.system

      local function terminal_notifier(term_cmd, exit)
        if exit == 0 then
          mega.notify("test(s) passed 👍", vim.log.levels.INFO)
          system(string.format([[terminal-notifier -title "Neovim [vim-test]" -message "test(s) passed"]], term_cmd))
        else
          mega.notify("test(s) failed 👎", vim.log.levels.ERROR)
          system(string.format([[terminal-notifier -title "Neovim [vim-test]" -message "test(s) failed"]], term_cmd))
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

      mega.nnoremap("<localleader>tn", "<cmd>TestNearest<cr>", "run _test under cursor")
      mega.nnoremap("<localleader>ta", "<cmd>TestFile<cr>", "run _all tests in file")
      mega.nnoremap("<localleader>tf", "<cmd>TestFile<cr>", "run _all tests in file")
      mega.nnoremap("<localleader>tl", "<cmd>TestLast<cr>", "run _last test")
      mega.nnoremap("<localleader>tt", "<cmd>TestLast<cr>", "run _last test")
      mega.nnoremap("<localleader>tv", "<cmd>TestVisit<cr>", "run test file _visit")
      mega.nnoremap("<localleader>tp", "<cmd>A<cr>", "open alt (edit)")
      mega.nnoremap("<localleader>tP", "<cmd>AV<cr>", "open alt (vsplit)")
    end,
  },
  {
    "nvim-neotest/neotest",
    keys = {
      { "<localleader>ts", toggle_summary, desc = "neotest: toggle summary" },
      { "<localleader>to", open, desc = "neotest: output" },
      { "<localleader>tn", nearest, desc = "neotest: run" },
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
      local namespace = vim.api.nvim_create_namespace("neotest")
      vim.diagnostic.config({
        virtual_text = {
          format = function(diagnostic)
            return diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
          end,
        },
      }, namespace)

      require("neotest").setup({
        log_level = L.INFO, -- default is L.WARN
        discovery = { enabled = true },
        diagnostic = { enabled = true },
        output_panel = { enabled = true },
        quickfix = { enabled = true },
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
    dependencies = {
      { "scottming/neotest-elixir", branch = "only-support-iex" }, -- https://github.com/jfpedroza/neotest-elixir
      { "haydenmeade/neotest-jest" },
      { "rcarriga/neotest-plenary", dependencies = { "nvim-lua/plenary.nvim" } },
    },
  },
}
