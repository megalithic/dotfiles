local fn = vim.fn
mega.debug = { layout = { ft = { dart = 2 } } }
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
        function() require("dapui").close(mega.debug.layout.ft[vim.bo.ft]) end,
        desc = "dap ui: close",
      },
      {
        "<localleader>dut",
        function() require("dapui").toggle(mega.debug.layout.ft[vim.bo.ft]) end,
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
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open(mega.debug.layout.ft[vim.bo.ft]) end
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
    dependencies = { "mfussenegger/nvim-dap" },
    opts = {
      adapters = { "chrome", "pwa-node", "pwa-chrome", "node-terminal", "pwa-extensionHost" },
      node_path = "node",
      debugger_cmd = { "js-debug-adapter" },
    },
    config = function(_, opts)
      require("dap-vscode-js").setup(opts)
      for _, language in ipairs({ "typescript", "typescriptreact", "javascript" }) do
        require("dap").configurations[language] = {
          {
            type = "chrome",
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
        }
      end
    end,
  },
}
