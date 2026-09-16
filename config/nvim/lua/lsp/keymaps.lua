-- lua/lsp/keymaps.lua
-- Shared LSP keymaps applied on LspAttach

local M = {}

--- Check LSP capabilities for current buffer
function M.check_capabilities()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    vim.notify("No LSP attached", vim.log.levels.WARN)
    return
  end

  local caps = {
    { "definition", "definitionProvider" },
    { "declaration", "declarationProvider" },
    { "implementation", "implementationProvider" },
    { "typeDefinition", "typeDefinitionProvider" },
    { "references", "referencesProvider" },
    { "codeAction", "codeActionProvider" },
    { "rename", "renameProvider" },
    { "hover", "hoverProvider" },
    { "signatureHelp", "signatureHelpProvider" },
    { "completion", "completionProvider" },
    { "formatting", "documentFormattingProvider" },
    { "inlayHint", "inlayHintProvider" },
  }

  local lines = {}
  for _, client in ipairs(clients) do
    table.insert(lines, string.format("**%s**", client.name))
    for _, cap in ipairs(caps) do
      local has = client.server_capabilities[cap[2]]
      local icon = has and "✓" or "✗"
      table.insert(lines, string.format("  %s %s", icon, cap[1]))
    end
    table.insert(lines, "")
  end

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "LSP Capabilities" })
end

vim.api.nvim_create_user_command("LspCapabilities", M.check_capabilities, { desc = "Show LSP capabilities" })

local function get_snacks()
  local ok, snacks = pcall(require, "snacks")
  return ok and snacks or nil
end

local function get_conform()
  local ok, conform = pcall(require, "conform")
  return ok and conform or nil
end

function M.on_attach(client, bufnr)
  local methods = vim.lsp.protocol.Methods
  local diag = require("lsp.diagnostics")
  local snacks = get_snacks()

  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = "LSP: " .. desc })
  end

  -- Navigation
  if client:supports_method(methods.textDocument_definition) then
    map("n", "gd", function()
      if snacks then
        snacks.picker.lsp_definitions({ auto_confirm = true })
      else
        vim.lsp.buf.definition()
      end
    end, "Goto definition")

    map("n", "gD", function()
      vim.cmd("vsplit")
      vim.lsp.buf.definition()
    end, "Goto definition (vsplit)")
  end

  if client:supports_method(methods.textDocument_declaration) then
    map("n", "gI", function()
      if snacks and snacks.picker.lsp_declarations then
        snacks.picker.lsp_declarations()
      else
        vim.lsp.buf.declaration()
      end
    end, "Goto declaration")
  end

  if client:supports_method(methods.textDocument_references) then
    map("n", "gr", function()
      if snacks then
        snacks.picker.lsp_references({ include_declaration = false })
      else
        vim.lsp.buf.references()
      end
    end, "References")
  end

  if client:supports_method(methods.textDocument_implementation) then
    map("n", "gi", function()
      if snacks then
        snacks.picker.lsp_implementations()
      else
        vim.lsp.buf.implementation()
      end
    end, "Implementation")
  end

  if client:supports_method(methods.textDocument_typeDefinition) then
    map("n", "gy", function()
      if snacks then
        snacks.picker.lsp_type_definitions()
      else
        vim.lsp.buf.type_definition()
      end
    end, "Type definition")
  end

  -- Hover & signature
  map("n", "K", vim.lsp.buf.hover, "Hover")

  if client:supports_method(methods.textDocument_signatureHelp) then
    map("n", "gK", vim.lsp.buf.signature_help, "Signature help")
    map("i", "<C-k>", vim.lsp.buf.signature_help, "Signature help")
  end

  -- Actions
  if client:supports_method(methods.textDocument_rename) then
    map("n", "<leader>ln", vim.lsp.buf.rename, "Rename")
  end

  if client:supports_method(methods.textDocument_codeAction) then
    map({ "n", "v" }, "ga", vim.lsp.buf.code_action, "Code action")
    map({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, "Code action")
  end

  -- Diagnostics (with highlight flash + cursorline blink)
  map("n", "]d", diag.goto_next, "Next diagnostic")
  map("n", "[d", diag.goto_prev, "Prev diagnostic")
  map("n", "]e", function()
    diag.goto_next({ severity = vim.diagnostic.severity.ERROR })
  end, "Next error")
  map("n", "[e", function()
    diag.goto_prev({ severity = vim.diagnostic.severity.ERROR })
  end, "Prev error")
  map("n", "<leader>ld", diag.show_popup, "Line diagnostics")

  -- Inlay hints
  if client:supports_method(methods.textDocument_inlayHint) then
    map("n", "<leader>lh", function()
      local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
      vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
    end, "Toggle inlay hints")
  end

  -- Format (prefer conform, fallback to LSP)
  map("n", "<leader>lf", function()
    local conform = get_conform()
    if conform then
      conform.format({ async = true, lsp_fallback = true })
    else
      vim.lsp.buf.format({ async = true })
    end
  end, "Format")
end

return M
