return function()
  local neotest = require("neotest")

  neotest.setup({
    icons = {
      running = mega.icons.misc.clock,
    },
    adapters = {
      require("neotest-plenary"),
      require("neotest-vim-test")({ ignore_filetypes = { "python", "lua" } }),
    },
    floating = {
      border = mega.get_border(),
    },
  })

  local function open()
    neotest.output.open({ enter = false })
  end

  local function run_file()
    neotest.run.run(vim.fn.expand("%"))
  end

  nnoremap("<localleader>ts", neotest.summary.toggle, "neotest: run suite")
  nnoremap("<localleader>to", open, "neotest: output")
  nnoremap("<localleader>tn", neotest.run.run, "neotest: run")
  nnoremap("<localleader>tf", run_file, "neotest: run file")
end
