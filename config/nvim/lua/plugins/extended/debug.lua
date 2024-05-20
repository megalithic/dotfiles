local SETTINGS = require("mega.settings")

return {
  "mfussenegger/nvim-dap",
  event = { "LazyFile" },
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "theHamsta/nvim-dap-virtual-text",
    -- {
    --   "jbyuki/one-small-step-for-vimkind",
    --   keys = {
    --     { "<localleader>dL", function() require("osv").launch({ port = 8086 }) end, desc = "Adapter Lua Server" },
    --     { "<localleader>dl", function() require("osv").run_this() end, desc = "Adapter Lua" },
    --   },
    --   opts = {},
    -- },

    { "pablobfonseca/nvim-nio", branch = "fix-deprecations" },
    "williamboman/mason.nvim",
    "jay-babu/mason-nvim-dap.nvim",
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")

    require("mason-nvim-dap").setup({
      automatic_setup = true,
      handlers = {},
      ensure_installed = {
        "delve",
        "python",
        "elixir",
        -- "node2",
        -- "chrome",
        -- "firefox",
        "js",
      },
    })

    vim.keymap.set("n", "<localleader>dd", dap.continue, { desc = "Debug: Start/Continue" })
    vim.keymap.set("n", "<localleader>dsi", dap.step_into, { desc = "Debug: Step Into" })
    vim.keymap.set("n", "<localleader>dso", dap.step_over, { desc = "Debug: Step Over" })
    vim.keymap.set("n", "<localleader>dst", dap.step_out, { desc = "Debug: Step Out" })
    vim.keymap.set("n", "<localleader>db", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
    vim.keymap.set("n", "<localleader>dB", function() dap.set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, { desc = "Debug: Set Breakpoint" })

    vim.keymap.set("n", "<localleader>dc", dap.run_to_cursor)
    vim.keymap.set("n", "<localleader>dx", dap.terminate)
    vim.keymap.set("n", "<localleader>dt", dapui.toggle)

    dapui.setup({
      icons = { expanded = "▾", collapsed = "▸", current_frame = "*" },
      controls = {
        icons = {
          pause = "⏸",
          play = "▶",
          step_into = "⏎",
          step_over = "⏭",
          step_out = "⏮",
          step_back = "b",
          run_last = "▶▶",
          terminate = "⏹",
          disconnect = "⏏",
        },
      },
    })

    vim.fn.sign_define({
      {
        name = "DapBreakpoint",
        text = SETTINGS.icons.misc.bug,
        texthl = "DapBreakpoint",
        linehl = "",
        numhl = "",
      },
      {
        name = "DapStopped",
        text = SETTINGS.icons.misc.bookmark,
        texthl = "DapStopped",
        linehl = "",
        numhl = "",
      },
    })

    vim.keymap.set("n", "<localleader>d?", function() require("dapui").eval(nil, { enter = true }) end)
    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    vim.keymap.set("n", "<localleader>dl", dapui.toggle, { desc = "Debug: See last session result." })

    dap.adapters.nlua = function(callback, config) callback({ type = "server", host = config.host or "127.0.0.1", port = config.port or 8086 }) end

    local elixir_ls_debugger = vim.fn.exepath("elixir-ls-debugger")
    -- elixir_ls_debugger = string.format("%s/lsp/elixir-ls/%s", vim.env.XDG_DATA_HOME, "debug_adapter.sh")
    if elixir_ls_debugger ~= "" then
      dap.adapters.mix_task = {
        type = "executable",
        command = elixir_ls_debugger,
        args = {},
      }

      dap.configurations.elixir = {
        {
          type = "mix_task",
          name = "phx.server",
          task = "phx.server",
          request = "launch",
          projectDir = "${workspaceFolder}",
          exitAfterTaskReturns = false,
          debugAutoInterpretAllModules = false,
        },
        {
          type = "mix_task",
          name = "mix test",
          request = "launch",
          task = "test",
          taskArgs = { "--trace" },
          startApps = true,
          projectDir = "${workspaceFolder}",
          requireFiles = { "test/**/test_helper.exs", "test/**/*_test.exs" },
        },
        {
          type = "mix_task",
          name = "bellhop phx.server",
          task = "iex --sname bellhop-tern --cookie ternit -S mix phx.server",
          request = "launch",
          projectDir = "${workspaceFolder}",
          exitAfterTaskReturns = false,
          debugAutoInterpretAllModules = false,
        },
        {
          type = "mix_task",
          name = "retriever server",
          task = "iex --sname retriever-tern --cookie retriever -S mix",
          request = "launch",
          projectDir = "${workspaceFolder}",
          exitAfterTaskReturns = false,
          debugAutoInterpretAllModules = false,
        },
      }
    end

    dap.configurations.lua = {
      {
        type = "nlua",
        request = "attach",
        name = "Attach to running Neovim instance",
      },
    }

    dap.listeners.before.attach.dapui_config = function() dapui.open() end
    dap.listeners.before.launch.dapui_config = function() dapui.open() end
    dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
    dap.listeners.before.event_exited.dapui_config = function() dapui.close() end
    dap.listeners.after.event_initialized.dapui_config = function() dapui.open() end
  end,
}
