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
  local function active_sessions()
    local api = vim.api
    local function new_buf()
      local buf = api.nvim_create_buf(false, true)
      api.nvim_buf_set_option(buf, "modifiable", false)
      api.nvim_buf_set_option(buf, "buftype", "nofile")
      api.nvim_buf_set_option(buf, "modifiable", false)
      api.nvim_buf_set_keymap(
        buf,
        "n",
        "<CR>",
        "<Cmd>lua require('dap.ui').trigger_actions({ mode = 'first' })<CR>",
        {}
      )
      api.nvim_buf_set_keymap(buf, "n", "a", "<Cmd>lua require('dap.ui').trigger_actions()<CR>", {})
      api.nvim_buf_set_keymap(buf, "n", "o", "<Cmd>lua require('dap.ui').trigger_actions()<CR>", {})
      api.nvim_buf_set_keymap(buf, "n", "<2-LeftMouse>", "<Cmd>lua require('dap.ui').trigger_actions()<CR>", {})
      return buf
    end
    local widgets = require("dap.ui.widgets")

    local new_cursor_anchored_float_win = function(buf)
      vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
      vim.api.nvim_buf_set_option(buf, "filetype", "dap-float")
      local opts = vim.lsp.util.make_floating_popup_options(50, 30, { border = false })
      local win = vim.api.nvim_open_win(buf, true, opts)
      vim.api.nvim_win_set_option(win, "scrolloff", 0)
      return win
    end

    local widget = widgets
      .builder(widgets.expression)
      .new_buf(new_buf)
      .new_win(widgets.with_resize(new_cursor_anchored_float_win))
      .build()

    widget.open()
    -- widgets.hover("<cexpr>", { border = false })
  end

  nnoremap("<localleader>db", toggle_breakpoint, "dap: toggle breakpoint")
  nnoremap("<localleader>dB", set_breakpoint, "dap: set breakpoint")
  nnoremap("<localleader>dc", continue, "dap: continue or start debugging")
  nnoremap("<localleader>de", step_out, "dap: step out")
  nnoremap("<localleader>di", step_into, "dap: step into")
  nnoremap("<localleader>do", step_over, "dap: step over")
  nnoremap("<localleader>dl", run_last, "dap REPL: run last")
  nnoremap("<localleader>dt", repl_toggle, "dap REPL: toggle")
  nnoremap("<localleader>K", active_sessions, "dap: show active sessions")

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

  require("dap-vscode-js").setup({
    log_file_level = vim.log.levels.TRACE,
    adapters = {
      "pwa-node",
      "pwa-chrome",
      "pwa-msedge",
      "node-terminal",
      "pwa-extensionHost",
    }, -- which adapters to register in nvim-dap
  })

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
  dap.adapters.reactnative = function(cb, config)
    if config.preLaunchTask then vim.fn.system(config.preLaunchTask) end

    cb({
      type = "executable",
      command = "node",
      args = {
        vim.fn.stdpath("data") .. "/mason/packages/node-debug2-adapter/out/src/nodeDebug.js",
      },
    })
  end

  -- dap.adapters.firefox = {
  --   type = "executable",
  --   command = "node",
  --   args = {
  --     -- vim.fn.stdpath("data") .. "/mason/packages/node-debug2-adapter/out/src/nodeDebug.js",
  --     os.getenv("HOME") .. "/build/vscode-firefox-debug/dist/adapter.bundle.js",
  --   },
  -- }

  -- dap.adapters.yarn = {
  --   type = "executable",
  --   command = "yarn",
  --   args = {
  --     "node",
  --     -- vim.fn.stdpath("data") .. "/mason/packages/node-debug2-adapter/out/src/nodeDebug.js",
  --     os.getenv("HOME") .. "/build/vscode-node-debug2/out/src/nodeDebug.js",
  --   },
  -- }

  -- dap.adapters.yarn_firefox = {
  --   type = "executable",
  --   command = "yarn",
  --   args = {
  --     "node",
  --     -- vim.fn.stdpath("data") .. "/mason/packages/node-debug2-adapter/out/src/nodeDebug.js",
  --     os.getenv("HOME") .. "/build/vscode-firefox-debug/dist/adapter.bundle.js",
  --   },
  -- }

  -- [ launchers ] ---------------------------------------------------------------

  -- local firefox = {
  --   name = "Debug with Firefox",
  --   type = "firefox",
  --   request = "launch",
  --   reAttach = true,
  --   sourceMaps = true,
  --   url = "http://localhost:6969",
  --   webRoot = "${workspaceFolder}",
  --   firefoxExecutable = "/usr/bin/firefox",
  -- }

  -- local node = {
  --   name = "Launch node",
  --   type = "node2",
  --   request = "launch",
  --   program = "${file}",
  --   cwd = vim.fn.getcwd(),
  --   sourceMaps = true,
  --   protocol = "inspector",
  --   console = "integratedTerminal",
  -- }

  -- local node_attach = {
  --   -- For this to work you need to make sure the node process is started with the `--inspect` flag.
  --   name = "Attach to node process",
  --   type = "node2",
  --   request = "attach",
  --   processId = require("dap.utils").pick_process,
  -- }

  -- local react_native = {
  --   name = "Debug in Exponent",
  --   request = "launch",
  --   type = "reactnative",
  --   cwd = "${workspaceFolder}",
  --   platform = "exponent",
  --   expoHostType = "local",
  --   processId = require("dap.utils").pick_process,
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

  for _, language in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact" }) do
    dap.configurations[language] = {
      {
        type = "pwa-node",
        request = "launch",
        name = "Launch file",
        program = "${file}",
        cwd = "${workspaceFolder}",
      },
      {
        type = "pwa-node",
        request = "attach",
        name = "Attach",
        processId = require("dap.utils").pick_process,
        cwd = "${workspaceFolder}",
      },
      {
        type = "pwa-node",
        request = "launch",
        name = "Debug Jest Tests",
        -- trace = true, -- include debugger info
        runtimeExecutable = "node",
        runtimeArgs = {
          "./node_modules/jest/bin/jest.js",
          "--runInBand",
        },
        rootPath = "${workspaceFolder}",
        cwd = "${workspaceFolder}",
        console = "integratedTerminal",
        internalConsoleOptions = "neverOpen",
      },
    }
  end

  -- dap.configurations.javascript = { firefox, node, node_attach, react_native }
  -- dap.configurations.javascriptreact = {
  --   firefox,
  --   node,

  --   node_attach,
  --   react_native,
  -- }

  -- dap.configurations.typescript = { firefox, node, node_attach, react_native }
  -- dap.configurations.typescriptreact = {
  --   firefox,
  --   node,
  --   node_attach,
  --   react_native,
  -- }

  -- NOTE: see rcarriga/cmp-dap instead
  -- mega.augroup("DapAutocmds", {
  --   {
  --     event = { "FileType", "CmdlineChanged" },
  --     pattern = { "dap-repl" },
  --     callback = function() require("dap.ext.autocompl").attach() end,
  --   },
  -- })
end
