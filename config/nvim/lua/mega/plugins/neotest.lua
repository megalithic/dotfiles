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
    "nvim-neotest/neotest",
    keys = {
      { "<localleader>ts", toggle_summary, desc = "neotest: toggle summary" },
      { "<localleader>to", open, desc = "neotest: output" },
      { "<localleader>tn", nearest, desc = "neotest: run" },
      { "<localleader>tf", run_file, desc = "neotest: run file" },
      { "<localleader>tF", run_file_sync, desc = "neotest: run file synchronously" },
      { "<localleader>tc", cancel, desc = "neotest: cancel" },
      { "[n", next_failed, desc = "jump to next failed test" },
      { "]n", prev_failed, desc = "jump to previous failed test" },
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
        discovery = { enabled = true },
        diagnostic = { enabled = true },
        floating = { border = mega.get_border() },
        adapters = {
          require("neotest-plenary"),
          require("neotest-elixir"),
          require("neotest-jest")({
            jestCommand = "npm test --",
            jestConfigFile = "jest.config.js",
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
