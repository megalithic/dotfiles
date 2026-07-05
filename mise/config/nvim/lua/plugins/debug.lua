-- lua/plugins/debug.lua
-- Debug Adapter Protocol (DAP) configuration
-- Keymaps under <localleader>d prefix

return {
  -- Core DAP
  {
    "mfussenegger/nvim-dap",
    lazy = true,
    keys = {
      -- Breakpoints
      { "<localleader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      { "<localleader>dB", function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end, desc = "Conditional breakpoint" },
      { "<localleader>dL", function() require("dap").set_breakpoint(nil, nil, vim.fn.input("Log: ")) end, desc = "Log point" },

      -- Execution
      { "<localleader>dc", function() require("dap").continue() end, desc = "Continue" },
      { "<localleader>dP", function() require("dap").pause() end, desc = "Pause" },
      { "<localleader>di", function() require("dap").step_into() end, desc = "Step into" },
      { "<localleader>ds", function() require("dap").step_over() end, desc = "Step over" },
      { "<localleader>dO", function() require("dap").step_out() end, desc = "Step out" },
      { "<localleader>d<", function() require("dap").step_back() end, desc = "Step back" },
      { "<localleader>dr", function() require("dap").restart() end, desc = "Restart" },
      { "<localleader>dl", function() require("dap").run_last() end, desc = "Run last" },
      { "<localleader>dq", function() require("dap").terminate() end, desc = "Terminate" },

      -- Inspection
      { "<localleader>de", function() require("dap").eval(nil, { enter = true }) end, desc = "Eval expression" },
      { "<localleader>de", function() require("dap").eval(nil, { enter = true }) end, mode = "v", desc = "Eval selection" },
      { "<localleader>dh", function() require("dap.ui.widgets").hover() end, desc = "Hover" },
      { "<localleader>dp", function() require("dap.ui.widgets").preview() end, desc = "Preview" },

      -- UI
      { "<localleader>du", function() require("dapui").toggle() end, desc = "Toggle UI" },
      { "<localleader>dR", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
    },
    dependencies = {
      "nvim-neotest/nvim-nio",
    },
    config = function()
      local dap = require("dap")

      -- Signs
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
      vim.fn.sign_define("DapLogPoint", { text = "◇", texthl = "DiagnosticInfo" })
      vim.fn.sign_define("DapStopped", { text = "→", texthl = "DiagnosticOk", linehl = "CursorLine" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DiagnosticHint" })

      ------------------------------------------------------------------------
      -- Elixir (elixir-ls debug adapter)
      ------------------------------------------------------------------------
      -- elixir-ls includes a debug adapter at debugger.sh
      -- Requires: elixir-ls installed (mason or manual)
      dap.adapters.mix_task = {
        type = "executable",
        command = vim.fn.exepath("elixir-ls-debugger") ~= "" and "elixir-ls-debugger" or vim.fn.expand("~/.local/share/nvim/mason/packages/elixir-ls/debug_adapter.sh"),
        args = {},
      }

      dap.configurations.elixir = {
        {
          type = "mix_task",
          name = "mix test",
          task = "test",
          taskArgs = { "--trace" },
          request = "launch",
          startApps = true,
          projectDir = "${workspaceFolder}",
          requireFiles = {
            "test/**/test_helper.exs",
            "test/**/*_test.exs",
          },
        },
        {
          type = "mix_task",
          name = "phoenix server",
          task = "phx.server",
          request = "launch",
          projectDir = "${workspaceFolder}",
          exitAfterTaskReturns = false,
          debugAutoInterpretAllModules = false,
        },
        {
          type = "mix_task",
          name = "mix (default task)",
          request = "launch",
          projectDir = "${workspaceFolder}",
        },
      }

      ------------------------------------------------------------------------
      -- JavaScript / TypeScript (vscode-js-debug)
      ------------------------------------------------------------------------
      -- Uses js-debug-adapter from mason or vscode-js-debug
      local js_debug_path = vim.fn.expand("~/.local/share/nvim/mason/packages/js-debug-adapter")

      -- Check if installed
      if vim.fn.isdirectory(js_debug_path) == 1 then
        dap.adapters["pwa-node"] = {
          type = "server",
          host = "localhost",
          port = "${port}",
          executable = {
            command = "node",
            args = { js_debug_path .. "/js-debug/src/dapDebugServer.js", "${port}" },
          },
        }

        dap.adapters["pwa-chrome"] = {
          type = "server",
          host = "localhost",
          port = "${port}",
          executable = {
            command = "node",
            args = { js_debug_path .. "/js-debug/src/dapDebugServer.js", "${port}" },
          },
        }

        -- Node.js configurations
        for _, lang in ipairs({ "javascript", "typescript" }) do
          dap.configurations[lang] = {
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
              name = "Attach to process",
              processId = require("dap.utils").pick_process,
              cwd = "${workspaceFolder}",
            },
            {
              type = "pwa-node",
              request = "launch",
              name = "Debug Jest tests",
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

        -- Browser configurations (Chrome/Brave)
        -- Start Brave with: brave --remote-debugging-port=9222
        for _, lang in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
          dap.configurations[lang] = dap.configurations[lang] or {}
          table.insert(dap.configurations[lang], {
            type = "pwa-chrome",
            request = "launch",
            name = "Launch Chrome",
            url = "http://localhost:3000",
            webRoot = "${workspaceFolder}",
          })
          table.insert(dap.configurations[lang], {
            type = "pwa-chrome",
            request = "attach",
            name = "Attach to Chrome/Brave (port 9222)",
            port = 9222,
            webRoot = "${workspaceFolder}",
            -- For Brave Nightly, start with:
            -- /Applications/Brave\ Browser\ Nightly.app/Contents/MacOS/Brave\ Browser\ Nightly --remote-debugging-port=9222
          })
        end
      end

      ------------------------------------------------------------------------
      -- Go (delve)
      ------------------------------------------------------------------------
      dap.adapters.delve = function(callback, config)
        if config.mode == "remote" and config.request == "attach" then
          callback({
            type = "server",
            host = config.host or "127.0.0.1",
            port = config.port or "38697",
          })
        else
          callback({
            type = "server",
            port = "${port}",
            executable = {
              command = "dlv",
              args = { "dap", "-l", "127.0.0.1:${port}", "--log", "--log-output=dap" },
              detached = vim.fn.has("win32") == 0,
            },
          })
        end
      end

      dap.configurations.go = {
        {
          type = "delve",
          name = "Debug file",
          request = "launch",
          program = "${file}",
        },
        {
          type = "delve",
          name = "Debug test",
          request = "launch",
          mode = "test",
          program = "${file}",
        },
        {
          type = "delve",
          name = "Debug test (go.mod)",
          request = "launch",
          mode = "test",
          program = "./${relativeFileDirname}",
        },
        {
          type = "delve",
          name = "Attach to process",
          request = "attach",
          mode = "local",
          processId = require("dap.utils").pick_process,
        },
      }

      ------------------------------------------------------------------------
      -- Lua (one-small-step-for-vimkind for nvim lua debugging)
      ------------------------------------------------------------------------
      dap.adapters.nlua = function(callback, config)
        callback({
          type = "server",
          host = config.host or "127.0.0.1",
          port = config.port or 8086,
        })
      end

      dap.configurations.lua = {
        {
          type = "nlua",
          request = "attach",
          name = "Attach to running Neovim instance",
        },
      }

      ------------------------------------------------------------------------
      -- Auto-open/close UI on session events
      ------------------------------------------------------------------------
      local function open_ui()
        local ok, dapui = pcall(require, "dapui")
        if ok then dapui.open() end
      end

      local function close_ui()
        local ok, dapui = pcall(require, "dapui")
        if ok then dapui.close() end
      end

      dap.listeners.after.event_initialized["dapui_config"] = open_ui
      dap.listeners.before.event_terminated["dapui_config"] = close_ui
      dap.listeners.before.event_exited["dapui_config"] = close_ui
    end,
  },

  -- DAP UI
  {
    "rcarriga/nvim-dap-ui",
    lazy = true,
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    opts = {
      icons = { expanded = "▾", collapsed = "▸", current_frame = "→" },
      layouts = {
        {
          elements = {
            { id = "scopes", size = 0.4 },
            { id = "breakpoints", size = 0.2 },
            { id = "stacks", size = 0.2 },
            { id = "watches", size = 0.2 },
          },
          size = 40,
          position = "left",
        },
        {
          elements = {
            { id = "repl", size = 0.5 },
            { id = "console", size = 0.5 },
          },
          size = 10,
          position = "bottom",
        },
      },
      floating = {
        border = "rounded",
        mappings = { close = { "q", "<Esc>" } },
      },
    },
  },

  -- Virtual text (inline values)
  {
    "theHamsta/nvim-dap-virtual-text",
    lazy = true,
    dependencies = { "mfussenegger/nvim-dap", "nvim-treesitter/nvim-treesitter" },
    opts = {
      enabled = true,
      enabled_commands = true,
      highlight_changed_variables = true,
      highlight_new_as_changed = false,
      show_stop_reason = true,
      commented = false,
      virt_text_pos = "eol",
    },
  },

  -- Lua debugger for Neovim
  {
    "jbyuki/one-small-step-for-vimkind",
    lazy = true,
    dependencies = { "mfussenegger/nvim-dap" },
    keys = {
      { "<localleader>dN", function() require("osv").launch({ port = 8086 }) end, desc = "Launch Neovim Lua debugger" },
    },
  },
}
