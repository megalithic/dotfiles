return function(plug)
  if plug == nil then
    return
  end

  local fn = vim.fn

  local function repl_toggle()
    require("dap").repl.toggle(nil, "botright split")
  end
  local function continue()
    require("dap").continue()
  end
  local function step_out()
    require("dap").step_out()
  end
  local function step_into()
    require("dap").step_into()
  end
  local function step_over()
    require("dap").step_over()
  end
  local function run_last()
    require("dap").run_last()
  end
  local function toggle_breakpoint()
    require("dap").toggle_breakpoint()
  end
  local function set_breakpoint()
    require("dap").set_breakpoint(fn.input("Breakpoint condition: "))
  end

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

  plug.configurations.lua = {
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

  plug.adapters.nlua = function(callback, config)
    callback({ type = "server", host = config.host, port = config.port })
  end

  local cmd = string.format("%s/lsp/elixir-ls/%s", vim.env.XDG_DATA_HOME, "debugger.sh")

  if mega.lsp.elixirls_cmd ~= nil then
    cmd = require("mega.utils").lsp.elixirls_cmd({ is_debug = true })
  end

  plug.adapters.mix_task = {
    type = "executable",
    command = cmd,
    args = {},
  }

  plug.configurations.elixir = {
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

  -- DAP VIRTUAL TEXT ----------------------------------------------------------

  mega.conf("nvim-dap-virtual-text", { config = { all_frames = true } })

  -- DAP UI --------------------------------------------------------------------

  mega.conf("dapi", {})
  nnoremap("<localleader>duc", function()
    require("dapui").close()
  end, "dap-ui: close")
  nnoremap("<localleader>dut", function()
    require("dapui").toggle()
  end, "dap-ui: toggle")

  -- NOTE: this opens dap UI automatically when dap starts
  -- dap.listeners.after.event_initialized['dapui_config'] = function()
  --   dapui.open()
  -- end
  plug.listeners.before.event_terminated["dapui_config"] = function()
    require("dapui").close()
  end
  plug.listeners.before.event_exited["dapui_config"] = function()
    require("dapui").close()
  end

  -- DON'T automatically stop at exceptions
  -- dap.defaults.fallback.exception_breakpoints = {}
  -- NOTE: the window options can be set directly in this function
end
