local cmd = vim.cmd
local map = mega.map
do --- Auto-completion
  require("compe").setup {
      --min_length = 3;
      preselect = "disable";
      source = {
          path = true,
          tags = true,
          omni = {filetypes = {"tex"}},
          spell = {filetypes = {"markdown", "tex"}},
          buffer = true,
          nvim_lsp = true,
      };
  }

  --- Complete with tab
  map("<Tab>",   "pumvisible() ? '<C-n>' : '<Tab>'", "i", true)
  map("<S-Tab>", "pumvisible() ? '<C-p>' : '<S-Tab>'", "i", true)
end


do ---- LSP
  local conf = require("lspconfig")
  local function on_attach(client, bufnr)
      --- GOTO Mappings
      bufmap("gd", "lua vim.lsp.buf.definition()")
      bufmap("gr", "lua vim.lsp.buf.references()")
      bufmap("gs", "lua vim.lsp.buf.document_symbol()")

      --- Diagnostics navegation mappings
      bufmap("dn", "lua vim.lsp.diagnostic.goto_prev()")
      bufmap("dN", "lua vim.lsp.diagnostic.goto_next()")

      bufmap("<leader>lrn", "lua vim.lsp.buf.rename()")
      bufmap("<leader>lca", "lua vim.lsp.buf.code_action()")
      bufmap("<leader>le",  "lua vim.lsp.diagnostic.show_line_diagnostics()")
      bufmap("<C-k>",     "lua vim.lsp.buf.signature_help()")
      bufmap("<leader>lf",  "lua vim.lsp.buf.formatting()")

      --- auto-commands
      au "BufWritePre *.rs,*.c lua vim.lsp.buf.formatting_sync()"
      au "CursorHold *.rs,*.c lua vim.lsp.diagnostic.show_line_diagnostics()"

      opt.omnifunc = "v:lua.vim.lsp.omnifunc"
  end

  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = {
      'documentation',
      'detail',
      'additionalTextEdits',
    }
  }

  --- Disable virtual text
  lsp.handlers["textDocument.publishDiagnostics"] = lsp.with(
      lsp.diagnostic.on_publish_diagnostics,
      {
          virtual_text = false,
          signs = true,
          update_in_insert = false,
      }
  )

  for _, lsp in ipairs {"clangd", "rust_analyzer"} do
      conf[lsp].setup {
          on_attach = on_attach,
          flags = {debounce_text_changes = 150}
      }
  end
end
