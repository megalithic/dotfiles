local fn = vim.fn

return {
  {
    "mfussenegger/nvim-dap",
    keys = {
      {
        "<localleader>dL",
        function() require("dap").set_breakpoint(nil, nil, fn.input("Log point message: ")) end,
        desc = "dap: log breakpoint",
      },
      {
        "<localleader>db",
        function() require("dap").toggle_breakpoint() end,
        desc = "dap: toggle breakpoint",
      },
      {
        "<localleader>dB",
        function() require("dap").set_breakpoint(fn.input("Breakpoint condition: ")) end,
        desc = "dap: set conditional breakpoint",
      },
      {
        "<localleader>dc",
        function() require("dap").continue() end,
        desc = "dap: continue or start debugging",
      },
      {
        "<localleader>duc",
        function() require("dapui").close() end,
        desc = "dap ui: close",
      },
      {
        "<localleader>dut",
        function() require("dapui").toggle() end,
        desc = "dap ui: toggle",
      },
      { "<localleader>de", function() require("dap").step_out() end, desc = "dap: step out" },
      { "<localleader>di", function() require("dap").step_into() end, desc = "dap: step into" },
      { "<localleader>do", function() require("dap").step_over() end, desc = "dap: step over" },
      { "<localleader>dl", function() require("dap").run_last() end, desc = "dap REPL: run last" },
    },
    config = function()
      local dap = require("dap") -- NOTE: Must be loaded before the signs can be tweaked
      local dapui = require("dapui")

      -- highlight.plugin("dap", {
      --   { DapBreakpoint = { fg = mega.ui.palette.light_red } },
      --   { DapStopped = { fg = mega.ui.palette.green } },
      -- })

      fn.sign_define({
        {
          name = "DapBreakpoint",
          texthl = "DapBreakpoint",
          text = mega.icons.misc.bug,
          linehl = "",
          numhl = "",
        },
        {
          name = "DapStopped",
          texthl = "DapStopped",
          text = mega.icons.misc.bookmark,
          linehl = "",
          numhl = "",
        },
      })

      -- DON'T automatically stop at exceptions
      -- dap.defaults.fallback.exception_breakpoints = {}

      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
    end,
    dependencies = {
      {
        {
          "jbyuki/one-small-step-for-vimkind",
          ft = { "lua" },
        },
        {
          "rcarriga/nvim-dap-ui",
          opts = {
            windows = { indent = 2 },
            floating = { border = mega.get_border() },
            layouts = {
              {
                elements = {
                  { id = "scopes", size = 0.25 },
                  { id = "breakpoints", size = 0.25 },
                  { id = "stacks", size = 0.25 },
                  { id = "watches", size = 0.25 },
                },
                position = "left",
                size = 20,
              },
              { elements = { { id = "repl", size = 0.9 } }, position = "bottom", size = 10 },
            },
          },
        },
        { "theHamsta/nvim-dap-virtual-text", opts = { all_frames = true } },
      },
    },
  },
  {
    "mxsdev/nvim-dap-vscode-js",
    ft = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    dependencies = { "mfussenegger/nvim-dap", "sultanahamer/nvim-dap-reactnative" },
    opts = {
      debugger_path = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter",
      -- debugger_cmd = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js",
      debugger_cmd = { "js-debug-adapter" },
      node_path = "node",
      adapters = { "chrome", "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" },
    },
    config = function(_, opts)
      require("dap-vscode-js").setup(opts)

      local dap = require("dap")
      -- -- ╭──────────────────────────────────────────────────────────╮
      -- -- │ Adapters                                                 │
      -- -- ╰──────────────────────────────────────────────────────────╯
      --
      -- -- NODE
      -- dap.adapters.node2 = {
      --   type = "executable",
      --   command = "node",
      --   args = { vim.fn.stdpath("data") .. "/mason/packages/node-debug2-adapter/out/src/nodeDebug.js" },
      -- }
      --
      -- -- Chrome
      -- dap.adapters.chrome = {
      --   type = "executable",
      --   command = "node",
      --   args = { vim.fn.stdpath("data") .. "/mason/packages/chrome-debug-adapter/out/src/chromeDebug.js" },
      -- }
      --
      -- -- ╭──────────────────────────────────────────────────────────╮
      -- -- │ Configurations                                           │
      -- -- ╰──────────────────────────────────────────────────────────╯
      -- dap.configurations.javascript = {
      --   {
      --     name = "Node.js",
      --     type = "node2",
      --     request = "launch",
      --     program = "${file}",
      --     cwd = vim.fn.getcwd(),
      --     sourceMaps = true,
      --     protocol = "inspector",
      --     console = "integratedTerminal",
      --   },
      -- }
      --
      -- dap.configurations.javascript = {
      --   {
      --     name = "Chrome (9222)",
      --     type = "chrome",
      --     request = "attach",
      --     program = "${file}",
      --     cwd = vim.fn.getcwd(),
      --     sourceMaps = true,
      --     protocol = "inspector",
      --     port = 9222,
      --     webRoot = "${workspaceFolder}",
      --   },
      -- }
      --
      -- dap.configurations.javascriptreact = {
      --   {
      --     name = "Chrome (9222)",
      --     type = "chrome",
      --     request = "attach",
      --     program = "${file}",
      --     cwd = vim.fn.getcwd(),
      --     sourceMaps = true,
      --     protocol = "inspector",
      --     port = 9222,
      --     webRoot = "${workspaceFolder}",
      --   },
      -- }
      --
      -- dap.configurations.typescriptreact = {
      --   {
      --     name = "Chrome (9222)",
      --     type = "chrome",
      --     request = "attach",
      --     program = "${file}",
      --     cwd = vim.fn.getcwd(),
      --     sourceMaps = true,
      --     protocol = "inspector",
      --     port = 9222,
      --     webRoot = "${workspaceFolder}",
      --   },
      --   {
      --     name = "React Native (8081) (Node2)",
      --     type = "node2",
      --     request = "attach",
      --     program = "${file}",
      --     cwd = vim.fn.getcwd(),
      --     sourceMaps = true,
      --     protocol = "inspector",
      --     console = "integratedTerminal",
      --     processId = require("dap.utils").pick_process,
      --     port = 8081,
      --   },
      --   {
      --     name = "Attach React Native (8081)",
      --     type = "pwa-node",
      --     request = "attach",
      --     processId = require("dap.utils").pick_process,
      --     cwd = vim.fn.getcwd(),
      --     rootPath = "${workspaceFolder}",
      --     skipFiles = { "<node_internals>/**", "node_modules/**" },
      --     sourceMaps = true,
      --     protocol = "inspector",
      --     console = "integratedTerminal",
      --   },
      -- }

      -- TODO: https://github.com/sultanahamer/nvim-dap-reactnative

      dap.adapters.node2 = {
        type = "executable",
        command = "node",
        args = { vim.fn.stdpath("data") .. "/mason/packages/node-debug2-adapter/out/src/nodeDebug.js" },
      }

      for _, language in ipairs({ "typescript", "typescriptreact", "javascript", "javascriptreact" }) do
        require("dap").configurations[language] = {
          {
            type = "pwa-chrome",
            request = "launch",
            name = "Launch Chrome against localhost",
            url = "http://localhost:3000",
            webRoot = "${workspaceFolder}",
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
          },
          -- {
          --   name = "React Native (8081) (Node2)",
          --   type = "node2",
          --   request = "attach",
          --   program = "${file}",
          --   cwd = vim.fn.getcwd(),
          --   sourceMaps = true,
          --   protocol = "inspector",
          --   console = "integratedTerminal",
          --   port = 8081,
          -- },
          {
            name = "Attach React Native (8081)",
            type = "pwa-node",
            request = "attach",
            processId = require("dap.utils").pick_process,
            cwd = vim.fn.getcwd(),
            rootPath = "${workspaceFolder}",
            skipFiles = { "<node_internals>/**", "node_modules/**" },
            sourceMaps = true,
            protocol = "inspector",
            console = "integratedTerminal",
            port = 8081,
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
            sourceMaps = true,
          },
          {
            name = "Attach React Native (35000)",
            type = "pwa-node",
            request = "attach",
            program = "${file}",
            cwd = vim.fn.getcwd(),
            sourceMaps = true,
            protocol = "inspector",
            console = "integratedTerminal",
            port = 35000,
          },
        }
      end
    end,
  },
  {
    "LiadOz/nvim-dap-repl-highlights",
    config = true,
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-treesitter/nvim-treesitter",
    },
  },
}
