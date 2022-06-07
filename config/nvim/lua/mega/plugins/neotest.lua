return function(plug)
  if plug == nil then
    return
  end

  plug.setup({
    adapters = {
      require("neotest-plenary"),
      require("neotest-vim-test")({ ignore_filetypes = { "python", "lua" } }),
    },
    floating = {
      border = mega.get_border(),
    },
  })

  local function open()
    plug.output.open({ enter = false })
  end

  local function run_file()
    plug.run.run(vim.fn.expand("%"))
  end

  P("loading neotest bindings")
  nnoremap("<localleader>ts", plug.summary.toggle, "neotest: run suite")
  nnoremap("<localleader>to", open, "neotest: output")
  nnoremap("<localleader>tn", plug.run.run, "neotest: run")
  nnoremap("<localleader>tf", run_file, "neotest: run file")
end
