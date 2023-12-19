-- @REF:
-- https://github.com/jayp0521/dotfiles/blob/main/shell/.config/nvim/lua/user/plugins/dap.lua
if true then return {} end
return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
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
      {
        "mxsdev/nvim-dap-vscode-js",
        ft = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
        dependencies = { "mfussenegger/nvim-dap" },
        opts = {
          -- debugger_path = require("mason-registry").get_package("js-debug-adapter"):get_install_path(),
          debugger_path = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter",
          debugger_cmd = { "js-debug-adapter" },
          node_path = "node",
          adapters = { "chrome", "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" },
        },
        -- config = function(_, opts)
        --   require("dap-vscode-js").setup(opts)
        --   for _, language in ipairs({ "typescript", "typescriptreact", "javascript" }) do
        --     require("dap").configurations[language] = {
        --       {
        --         type = "chrome",
        --         request = "launch",
        --         name = "Launch Chrome against localhost",
        --         url = "http://localhost:3000",
        --         webRoot = "${workspaceFolder}",
        --       },
        --       {
        --         type = "pwa-node",
        --         request = "attach",
        --         name = "Attach",
        --         processId = require("dap.utils").pick_process,
        --         cwd = "${workspaceFolder}",
        --       },
        --     }
        --   end
        -- end,
      },
      {
        "microsoft/vscode-js-debug",
        build = "npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out",
      },
    },
    keys = {
      "<localleader>db",
      "<localleader>dB",
      "<localleader>dc",
      "<localleader>de",
      "<localleader>di",
      "<localleader>do",
      "<localleader>dO",
      "<localleader>dl",
      "<localleader>dt",
      "<localleader>K",
      "<localleader>dt",
      "<localleader>dC",
    },
    config = function()
      local dap_ok, dap = pcall(require, "dap")
      if not dap_ok then return end
      -- P("loaded dap")

      -- extra dap plugins/extensions/adapters
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
      -- nnoremap("<localleader>de", step_out, "dap: step out")
      nnoremap("<localleader>di", step_into, "dap: step into")
      nnoremap("<localleader>do", step_out, "dap: step out")
      nnoremap("<localleader>dO", step_over, "dap: step over")
      nnoremap("<localleader>dl", run_last, "dap REPL: run last")
      nnoremap("<localleader>dt", repl_toggle, "dap REPL: toggle")
      nnoremap("<localleader>K", active_sessions, "dap: show active sessions")
      nnoremap("<localleader>dt", "<CMD>lua require('dap').terminate()<CR>", "dap: terminate")
      nnoremap("<localleader>dC", "<CMD>lua require('dapui').close()<CR>", "dap: close")

      -- keymap("n", "<Leader>db", "<CMD>lua require('dap').toggle_breakpoint()<CR>", opts)
      -- keymap("n", "<Leader>dc", "<CMD>lua require('dap').continue()<CR>", opts)
      -- keymap("n", "<Leader>dd", "<CMD>lua require('dap').continue()<CR>", opts)
      -- keymap("n", "<Leader>dh", "<CMD>lua require('dapui').eval()<CR>", opts)
      -- keymap("n", "<Leader>di", "<CMD>lua require('dap').step_into()<CR>", opts)
      -- keymap("n", "<Leader>do", "<CMD>lua require('dap').step_out()<CR>", opts)
      -- keymap("n", "<Leader>dO", "<CMD>lua require('dap').step_over()<CR>", opts)
      -- keymap("n", "<Leader>dt", "<CMD>lua require('dap').terminate()<CR>", opts)
      -- keymap("n", "<Leader>dC", "<CMD>lua require('dapui').close()<CR>", opts)
      --
      -- keymap("n", "<Leader>dw", "<CMD>lua require('dapui').float_element('watches', { enter = true })<CR>", opts)
      -- keymap("n", "<Leader>ds", "<CMD>lua require('dapui').float_element('scopes', { enter = true })<CR>", opts)
      -- keymap("n", "<Leader>dr", "<CMD>lua require('dapui').float_element('repl', { enter = true })<CR>", opts)

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

      -- dap.adapters.nlua = function(cb, config)
      --   cb({ type = "server", host = config.host or "127.0.0.1", port = config.port or 8088 })
      -- end
      --
      -- dap.adapters.mix_task = function(cb, config)
      --   if config.preLaunchTask then vim.fn.system(config.preLaunchTask) end
      --   cb({
      --     type = "executable",
      --     command = require("mega.utils").lsp.elixirls_cmd({ debugger = true }),
      --     args = {},
      --   })
      -- end
      --
      -- dap.adapters.node2 = function(cb, config)
      --   if config.preLaunchTask then vim.fn.system(config.preLaunchTask) end
      --   cb({
      --     type = "executable",
      --     command = "node",
      --     args = {
      --       -- os.getenv("HOME") .. "/build/vscode-node-debug2/out/src/nodeDebug.js",
      --       vim.fn.stdpath("data") .. "/mason/packages/node-debug2-adapter/out/src/nodeDebug.js",
      --     },
      --   })
      -- end
      -- dap.adapters.reactnative = function(cb, config)
      --   if config.preLaunchTask then vim.fn.system(config.preLaunchTask) end
      --
      --   cb({
      --     type = "executable",
      --     command = "node",
      --     args = {
      --       vim.fn.stdpath("data") .. "/mason/packages/node-debug2-adapter/out/src/nodeDebug.js",
      --     },
      --   })
      -- end

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

      -- dap.configurations.elixir = {
      --   {
      --     type = "mix_task",
      --     name = "mix test",
      --     task = "test",
      --     taskArgs = { "--trace" },
      --     request = "launch",
      --     startApps = true, -- for Phoenix projects
      --     projectDir = "${workspaceFolder}",
      --     requireFiles = {
      --       "test/**/test_helper.exs",
      --       "test/**/*_test.exs",
      --       "apps/**/test/**/test_helper.exs",
      --       "apps/**/test/**/*_test.exs",
      --     },
      --   },
      --   {
      --     type = "mix_task",
      --     name = "phx.server",
      --     request = "launch",
      --     task = "phx.server",
      --     projectDir = ".",
      --   },
      -- }

      -- for _, language in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact" }) do
      --   dap.configurations[language] = {
      --     {
      --       type = "pwa-node",
      --       request = "launch",
      --       name = "Launch file",
      --       program = "${file}",
      --       cwd = "${workspaceFolder}",
      --     },
      --     {
      --       type = "pwa-node",
      --       request = "attach",
      --       name = "Attach",
      --       processId = require("dap.utils").pick_process,
      --       cwd = "${workspaceFolder}",
      --     },
      --     {
      --       type = "pwa-node",
      --       request = "launch",
      --       name = "Debug Jest Tests",
      --       -- trace = true, -- include debugger info
      --       runtimeExecutable = "node",
      --       runtimeArgs = {
      --         "./node_modules/jest/bin/jest.js",
      --         "--runInBand",
      --       },
      --       rootPath = "${workspaceFolder}",
      --       cwd = "${workspaceFolder}",
      --       console = "integratedTerminal",
      --       internalConsoleOptions = "neverOpen",
      --     },
      --   }
      -- end

      -- ╭──────────────────────────────────────────────────────────╮
      -- │ Adapters                                                 │
      -- ╰──────────────────────────────────────────────────────────╯

      -- NODE
      dap.adapters.node2 = {
        type = "executable",
        command = "node",
        args = { vim.fn.stdpath("data") .. "/mason/packages/node-debug2-adapter/out/src/nodeDebug.js" },
      }

      -- Chrome
      dap.adapters.chrome = {
        type = "executable",
        command = "node",
        args = { vim.fn.stdpath("data") .. "/mason/packages/chrome-debug-adapter/out/src/chromeDebug.js" },
      }

      -- VSCODE JS
      vim.notify("configuring vscode-js plugin..", L.INFO)
      local js_debug_path = require("mason-registry").get_package("js-debug-adapter"):get_install_path()
      require("dap-vscode-js").setup({
        debugger_path = js_debug_path,
        debugger_cmd = { "js-debug-adapter" },
        adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" },
      })

      -- ╭──────────────────────────────────────────────────────────╮
      -- │ Configurations                                           │
      -- ╰──────────────────────────────────────────────────────────╯
      dap.configurations.javascript = {
        {
          name = "Node.js",
          type = "node2",
          request = "launch",
          program = "${file}",
          cwd = vim.fn.getcwd(),
          sourceMaps = true,
          protocol = "inspector",
          console = "integratedTerminal",
        },
      }

      dap.configurations.javascript = {
        {
          name = "Chrome (9222)",
          type = "chrome",
          request = "attach",
          program = "${file}",
          cwd = vim.fn.getcwd(),
          sourceMaps = true,
          protocol = "inspector",
          port = 9222,
          webRoot = "${workspaceFolder}",
        },
      }

      dap.configurations.javascriptreact = {
        {
          name = "Chrome (9222)",
          type = "chrome",
          request = "attach",
          program = "${file}",
          cwd = vim.fn.getcwd(),
          sourceMaps = true,
          protocol = "inspector",
          port = 9222,
          webRoot = "${workspaceFolder}",
        },
      }

      dap.configurations.typescriptreact = {
        {
          name = "Chrome (9222)",
          type = "chrome",
          request = "attach",
          program = "${file}",
          cwd = vim.fn.getcwd(),
          sourceMaps = true,
          protocol = "inspector",
          port = 9222,
          webRoot = "${workspaceFolder}",
        },
        {
          name = "React Native (8081) (Node2)",
          type = "node2",
          request = "attach",
          program = "${file}",
          cwd = vim.fn.getcwd(),
          sourceMaps = true,
          protocol = "inspector",
          console = "integratedTerminal",
          port = 8081,
        },
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
        },
      }
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
    },
    config = function()
      local dapui_ok, dapui = pcall(require, "dapui")
      if not dapui_ok then return end

      dapui.setup()

      nnoremap("<localleader>duc", function() dapui.close() end, "dap-ui: close")
      nnoremap("<localleader>dut", function() dapui.toggle() end, "dap-ui: toggle")

      local dap_ok, dap = pcall(require, "dap")
      if dap_ok and dap then
        dap.listeners.after.event_initialized["dapui_config"] = function()
          dapui.open()
          vim.api.nvim_exec_autocmds("User", { pattern = "DapStarted" })
        end
        dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
        dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
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
    build = function()
      if not require("nvim-treesitter.parsers").has_parser("dap_repl") then vim.cmd(":TSInstall dap_repl") end
    end,
  },
}
