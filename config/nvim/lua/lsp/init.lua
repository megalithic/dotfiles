-- lua/lsp/init.lua
-- Core LSP setup using native vim.lsp.config (nvim 0.11+)
-- Server configs come from lua/langs/*.lua via require("langs")
-- NO nvim-lspconfig dependency

local M = {}
local did_setup = false

local function do_setup()
  local diagnostics = require("lsp.diagnostics")
  local keymaps = require("lsp.keymaps")
  local progress = require("lsp.progress")
  local langs = require("langs")

  -- Setup diagnostics and progress
  diagnostics.setup()
  progress.setup()

  -- Capabilities (blink.cmp integration)
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  local ok_blink, blink = pcall(require, "blink.cmp")
  if ok_blink then capabilities = blink.get_lsp_capabilities(capabilities) end

  -- Set shared capabilities for all servers
  vim.lsp.config("*", {
    log_level = vim.lsp.protocol.MessageType.Warning,
    message_level = vim.lsp.protocol.MessageType.Warning,
    capabilities = capabilities,
  })

  -- Get server configs from langs module (cached after first call)
  local servers, server_keys = langs.servers()

  -- Apply per-server settings via vim.lsp.config
  for server, config in pairs(servers) do
    vim.lsp.config(server, config)
  end

  -- LspAttach autocommand for keymaps
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("mega.lsp.attach", { clear = true }),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client then return end

      -- Shared keymaps (gd, gr, K, etc.)
      keymaps.on_attach(client, args.buf)

      -- Per-server keymaps from lang configs (use cached server_keys)
      local keys = server_keys[client.name]
      if keys then
        for _, key in ipairs(keys) do
          vim.keymap.set(key.mode or "n", key[1], key[2], { buffer = args.buf, desc = key.desc })
        end
      end
    end,
  })

  -- Enable all configured servers
  local server_names = vim.tbl_keys(servers)
  if #server_names > 0 then vim.lsp.enable(server_names) end
end

-- Setup on VeryLazy (after plugins load, before files open)
function M.setup()
  if did_setup then return end
  did_setup = true

  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = do_setup,
  })
end

return M
