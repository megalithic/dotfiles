return function()
  local dap_ok, dap = pcall(require, "dap")
  if not dap_ok then return end

  -- extra dap plugins/extensions/adapters
  mega.conf("dap-ruby", {})
  mega.conf("nvim-dap-virtual-text", {
    commented = true,
  })

  local fn = vim.fn

  local function repl_toggle() require("dap").repl.toggle(nil, "botright split") end
  local function continue() require("dap").continue() end
  local function step_out() require("dap").step_out() end
  local function step_into() require("dap").step_into() end
  local function step_over() require("dap").step_over() end
  local function run_last() require("dap").run_last() end
  local function toggle_breakpoint() require("dap").toggle_breakpoint() end
  local function set_breakpoint() require("dap").set_breakpoint(fn.input("Breakpoint condition: ")) end

  nnoremap("<localleader>db", toggle_breakpoint, "dap: toggle breakpoint")
  nnoremap("<localleader>dB", set_breakpoint, "dap: set breakpoint")
  nnoremap("<localleader>dc", continue, "dap: continue or start debugging")
  nnoremap("<localleader>de", step_out, "dap: step out")
  nnoremap("<localleader>di", step_into, "dap: step into")
  nnoremap("<localleader>do", step_over, "dap: step over")
  nnoremap("<localleader>dl", run_last, "dap REPL: run last")
  nnoremap("<localleader>dt", repl_toggle, "dap REPL: toggle")

  local icons = mega.icons

  fn.sign_define({
    {
      name = "DapBreakpoint",
      text = icons.misc.bug,
      texthl = "DapBreakpoint",
      linehl = "",
      numhl = "",
    },
    {
      name = "DapStopped",
      text = icons.misc.bookmark,
      texthl = "DapStopped",
      linehl = "",
      numhl = "",
    },
  })

  -- [ adapters ] --------------------------------------------------------------

  dap.adapters.nlua = function(cb, config) cb({ type = "server", host = config.host, port = config.port }) end

  dap.adapters.mix_task = function(cb, config)
    if config.preLaunchTask then vim.fn.system(config.preLaunchTask) end
    cb({
      type = "executable",
      command = require("mega.utils").lsp.elixirls_cmd({ debugger = true }),
      args = {},
    })
  end

  -- dap.adapters.chrome = {
  --   type = "executable",
  --   command = "node",
  --   args = { vim.fn.stdpath("data") .. "/mason/packages/chrome-debug-adapter/out/src/chromeDebug.js" },
  -- }

  dap.adapters.node2 = function(cb, config)
    if config.preLaunchTask then vim.fn.system(config.preLaunchTask) end
    cb({
      type = "executable",
      command = "node",
      args = {
        -- os.getenv("HOME") .. "/build/vscode-node-debug2/out/src/nodeDebug.js",
        vim.fn.stdpath("data") .. "/mason/packages/node-debug2-adapter/out/src/nodeDebug.js",
      },
    })
  end

  dap.adapters.expo = function(cb, config)
    if config.preLaunchTask then vim.fn.system(config.preLaunchTask) end
    cb({
      name = "Debug in Exponent",
      request = "launch",
      type = "reactnative",
      cwd = "${workspaceFolder}",
      platform = "exponent",
      expoHostType = "local",
    })
  end

  -- -- WIP does not execute
  -- dap.adapters.deno = function(cb)
  --   local adapter = {
  --     type = "executable",
  --     command = "deno",
  --   }
  --   cb(adapter)
  -- end

  -- dap.adapters.firefox = {
  --   type = "executable",
  --   command = "node",
  --   args = {
  --     os.getenv("HOME") .. "/build/vscode-firefox-debug/dist/adapter.bundle.js",
  --   },
  -- }

  -- dap.adapters.yarn = {
  --   type = "executable",
  --   command = "yarn",
  --   args = {
  --     "node",
  --     os.getenv("HOME") .. "/build/vscode-node-debug2/out/src/nodeDebug.js",
  --   },
  -- }

  -- dap.adapters.yarn_firefox = {
  --   type = "executable",
  --   command = "yarn",
  --   args = {
  --     "node",
  --     os.getenv("HOME") .. "/build/vscode-firefox-debug/dist/adapter.bundle.js",
  --   },
  -- }

  -- [ configs ] ---------------------------------------------------------------

  dap.configurations.lua = {
    {
      type = "nlua",
      request = "attach",
      name = "Attach to running Neovim instance",
      host = function()
        local value = fn.input("Host [default: 127.0.0.1]: ")
        return value ~= "" and value or "127.0.0.1"
      end,
      port = function()
        local val = tonumber(fn.input("Port: "))
        assert(val, "Please provide a port number")
        return val
      end,
    },
  }

  dap.configurations.elixir = {
    {
      type = "mix_task",
      name = "mix test",
      task = "test",
      taskArgs = { "--trace" },
      request = "launch",
      startApps = true, -- for Phoenix projects
      projectDir = "${workspaceFolder}",
      requireFiles = {
        "test/**/test_helper.exs",
        "test/**/*_test.exs",
        "apps/**/test/**/test_helper.exs",
        "apps/**/test/**/*_test.exs",
      },
    },
    {
      type = "mix_task",
      name = "phx.server",
      request = "launch",
      task = "phx.server",
      projectDir = ".",
    },
  }
end
