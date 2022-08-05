return function()
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
end
