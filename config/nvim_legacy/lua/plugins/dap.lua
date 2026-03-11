local SETTINGS = require("config.options")

return {
  cond = false,
  "mfussenegger/nvim-dap",
  event = { "LazyFile" },
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "theHamsta/nvim-dap-virtual-text",
    {
      "LiadOz/nvim-dap-repl-highlights",
      build = function()
        vim.cmd("TSInstall dap_repl")
      end,
    },
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
    local dap = require("plugins.dap")
    local dapui = require("dapui")
    require("nvim-dap-repl-highlights").setup()
    require("mason-nvim-dap").setup({
      automatic_setup = true,
      handlers = {},
      ensure_installed = {
        "delve",
        "python",
        -- "elixir",
        -- "node2",
        -- "chrome",
        -- "firefox",
        "js",
      },
    })

    require("nvim-dap-virtual-text").setup({ enabled = true, commented = true })

    vim.keymap.set("n", "<localleader>dd", dap.continue, { desc = "Debug: Start/Continue" })
    vim.keymap.set("n", "<localleader>di", dap.step_into, { desc = "Debug: Step Into" })
    vim.keymap.set("n", "<localleader>do", dap.step_over, { desc = "debug: Step Over" })
    vim.keymap.set("n", "<localleader>dt", dap.step_out, { desc = "Debug: Step Out" })
    vim.keymap.set("n", "<localleader>db", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
    vim.keymap.set("n", "<localleader>dB", function()
      dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
    end, { desc = "Debug: Set Breakpoint" })

    vim.keymap.set("n", "<localleader>dc", dap.run_to_cursor, { desc = "Debug: Run to cursor" })
    vim.keymap.set("n", "<localleader>dx", dap.terminate, { desc = "Debug: Terminate" })
    vim.keymap.set("n", "<localleader>dr", dap.repl.toggle, { desc = "Debug: Toggle REPL" })
    vim.keymap.set("n", "<localleader>dt", dapui.toggle, { desc = "Debug: Toggle UI" })

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
      mappings = {
        -- Use a table to apply multiple mappings
        expand = { "<CR>", "<2-LeftMouse>" },
        open = "o",
        remove = "x",
        edit = "e",
        repl = "r",
        toggle = "t",
      },
      -- Expand lines larger than the window
      -- Requires >= 0.7
      expand_lines = true,
      -- Layouts define sections of the screen to place windows.
      -- The position can be "left", "right", "top" or "bottom".
      -- The size specifies the height/width depending on position. It can be an Int
      -- or a Float. Integer specifies height/width directly (i.e. 20 lines/columns) while
      -- Float value specifies percentage (i.e. 0.3 - 30% of available lines/columns)
      -- Elements are the elements shown in the layout (in order).
      -- Layouts are opened in order so that earlier layouts take priority in window sizing.
      layouts = {
        {
          elements = {
            -- Elements can be strings or table with id and size keys.
            { id = "scopes", size = 0.25 },
            "breakpoints",
            "stacks",
            "watches",
          },
          size = 40, -- 40 columns
          position = "left",
        },
        {
          elements = {
            "repl",
            "console",
          },
          size = 0.25, -- 25% of total lines
          position = "bottom",
        },
      },
      floating = {
        max_height = nil, -- These can be integers or a float between 0 and 1.
        max_width = nil, -- Floats will be treated as percentage of your screen.
        border = "single", -- Border style. Can be "single", "double" or "rounded"
        mappings = {
          close = { "q", "<Esc>" },
        },
      },
      windows = { indent = 1 },
      render = {
        max_type_length = nil, -- Can be integer or nil.
      },
    })

    vim.fn.sign_define({
      {
        name = "DapBreakpoint",
        text = Icons.misc.bug,
        texthl = "DapBreakpoint",
        linehl = "",
        numhl = "",
      },
      {
        name = "DapStopped",
        text = Icons.misc.bookmark,
        texthl = "DapStopped",
        linehl = "",
        numhl = "",
      },
    })

    vim.keymap.set("n", "<localleader>d?", function()
      require("dapui").eval(nil, { enter = true })
    end)
    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    vim.keymap.set("n", "<localleader>dl", dapui.toggle, { desc = "Debug: See last session result." })

    dap.adapters.nlua = function(callback, config)
      callback({ type = "server", host = config.host or "127.0.0.1", port = config.port or 8086 })
    end

    -- local elixir_ls_debugger = vim.fn.exepath("elixir-ls-debugger")
    local elixir_ls_debugger =
      vim.fn.expand(string.format("%s/lsp/elixir-ls/%s", vim.env.XDG_DATA_HOME, "debug_adapter.sh"))

    if elixir_ls_debugger ~= "" then
      dap.adapters.mix_task = {
        type = "executable",
        command = elixir_ls_debugger,
        args = {},
      }

      dap.configurations.elixir = {
        {
          type = "mix_task",
          name = "󰙨 mix test",
          task = "test",
          taskArgs = { "--trace" },
          request = "launch",
          startApps = true, -- for Phoenix projects
          projectDir = "${workspaceFolder}",
          requireFiles = {
            "test/**/test_helper.exs",
            "test/**/*_test.exs",
          },
        },
        {
          type = "mix_task",
          name = " phx.server",
          task = "phx.server",
          request = "launch",
          projectDir = "${workspaceFolder}", -- alts: projectDir = ".",
          exitAfterTaskReturns = false,
          debugAutoInterpretAllModules = false,
        },
        {
          type = "mix_task",
          name = " bellhop phx.server",
          task = "iex --sname bellhop-tern --cookie ternit -S mix phx.server",
          request = "launch",
          projectDir = "${workspaceFolder}",
          exitAfterTaskReturns = false,
          debugAutoInterpretAllModules = false,
        },
        {
          type = "mix_task",
          name = " retriever server",
          task = "iex --sname retriever-tern --cookie retriever -S mix",
          request = "launch",
          projectDir = "${workspaceFolder}",
          exitAfterTaskReturns = false,
          debugAutoInterpretAllModules = false,
        },
      }
    end

    -- Python remote debugging for LaunchDeck devspace
    dap.adapters.python = {
      type = "server",
      host = "localhost",
      port = 5678,
    }

    dap.configurations.python = {
      {
        type = "python",
        request = "attach",
        name = "🚀 Attach to LaunchDeck DevSpace API",
        connect = {
          host = "localhost",
          port = 5678,
        },
        pathMappings = {
          {
            localRoot = vim.fn.getcwd() .. "/app",
            remoteRoot = "/app/app",
          },
        },
      },
      {
        type = "python",
        request = "attach",
        name = "🚀 Attach to LaunchDeck DevSpace API (custom path)",
        connect = {
          host = "localhost",
          port = 5678,
        },
        pathMappings = {
          {
            localRoot = function()
              return vim.fn.input("Local root path: ", vim.fn.getcwd(), "file")
            end,
            remoteRoot = "/app/app",
          },
        },
      },
    }

    dap.configurations.lua = {
      {
        type = "nlua",
        request = "attach",
        name = "Attach to running Neovim instance",
      },
    }

    dap.listeners.before.attach.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.launch.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
      dapui.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
      dapui.close()
    end
    dap.listeners.after.event_initialized.dapui_config = function()
      dapui.open()
    end
  end,
}
