return {
  activate = function()
    mega.inspect("activating lsp_config.lua..")

    -- [ requires ] ----------------------------------------------------------------

    local nova = require("mega.colors.nova")

    local has_lsp, _ = pcall(require, "lspconfig")
    if not has_lsp then
      print("[WARN] lspconfig not found/installed/loaded..")

      return
    end

    local function get_all_diagnostics()
      local result = {}
      local levels = {
        errors = "Error",
        warnings = "Warning",
        info = "Information",
        hints = "Hint"
      }

      for k, level in pairs(levels) do
        result[k] = vim.lsp.diagnostic.get_count(level)
      end

      return result
    end

    -- [ custom on_attach ] --------------------------------------------------------
    local on_attach = function(client, bufnr)
      -- print("on_attaching for client -> " .. vim.inspect(client))

      mega.inspect("client.resolved_capabilities", client.resolved_capabilities)

      vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

      if not vim.tbl_isempty(vim.lsp.buf_get_clients(0)) then
        mega.inspect("get_all_diagnostics", get_all_diagnostics())
      end

      if client.resolved_capabilities.completion then
        local completion_loaded, completion = pcall(require, "mega.lc.completion")
        if completion_loaded then
          completion.activate()
        end
      end

      if client.resolved_capabilities.document_highlight then
      -- require "illuminate".on_attach(client)
      end

      -- [ mappings ] --------------------------------------------------------------

      if client.resolved_capabilities.document_formatting then
        mega.augroup(
          "lc.format",
          function()
            vim.api.nvim_command [[autocmd! * <buffer>]]
            vim.api.nvim_command [[autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting(nil, 1000)]]
            -- vim.api.nvim_command [[autocmd BufWritePost plugins.lua PackerCompile]]
          end
        )
      end

      if client.resolved_capabilities.hover then
        mega.bmap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>")
      end

      if client.resolved_capabilities.goto_definition then
        mega.bmap("n", "<C-]>", "<cmd>lua vim.lsp.buf.definition()<CR>")
        mega.bmap("n", "<Leader>lgd", "<cmd>lua vim.lsp.buf.definition()<CR>")
      end

      if client.resolved_capabilities.find_references then
        mega.bmap("n", "<Leader>lr", "<cmd>lua vim.lsp.buf.references()<CR>")
        mega.bmap("n", "<Leader>lgr", "<cmd>lua vim.lsp.buf.references()<CR>")
      -- mega.bmap("n", "<Leader>lgr", '<cmd>lua require("telescope.builtin").lsp_references()<CR>')
      end

      if client.resolved_capabilities.rename then
        mega.bmap("n", "<Leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>")
        mega.bmap("n", "<Leader>ln", "<cmd>lua vim.lsp.buf.rename()<CR>")
      end

      mega.bmap("n", "<Leader>lgi", "<cmd>lua vim.lsp.buf.implementation()<CR>")
      mega.bmap("n", "<Leader>lgt", "<cmd>lua vim.lsp.buf.type_definition()<CR>")
      mega.bmap("n", "<Leader>lgs", "<cmd>lua vim.lsp.buf.document_symbol()<CR>")
      mega.bmap("n", "<Leader>lgS", "<cmd>lua vim.lsp.buf.workspace_symbol()<CR>")
      mega.bmap("n", "<Leader>dE", "<cmd>lua vim.lsp.buf.declaration()<CR>")
      mega.bmap("n", "<Leader>la", "<cmd>lua vim.lsp.buf.code_action()<CR>")

      mega.bmap("n", "[d", "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>")
      mega.bmap("n", "]d", "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>")
      mega.bmap("n", "<Leader>ll", "<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>")
      mega.bmap("n", "<CR>", "<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>")

      mega.augroup(
        "lc.diagnostics",
        function()
          vim.api.nvim_command [[autocmd CursorHold <buffer> lua vim.lsp.diagnostic.show_line_diagnostics()]]
          -- vim.api.nvim_command [[autocmd InsertLeave * lua vim.lsp.diagnostic.set_loclist({open_loclist = false})]]
        end
      )
    end

    -- [ nvim-lsp/diagnostics ] -------------------------------------------------------

    local sign_error = nova.icons.sign_error
    local sign_warning = nova.icons.sign_warning
    local sign_information = nova.icons.sign_information
    local sign_hint = nova.icons.sign_hint

    vim.fn.sign_define("LspDiagnosticsSignError", {text = sign_error, numhl = "LspDiagnosticsDefaultError"})
    vim.fn.sign_define("LspDiagnosticsSignWarning", {text = sign_warning, numhl = "LspDiagnosticsDefaultWarning"})
    vim.fn.sign_define(
      "LspDiagnosticsSignInformation",
      {text = sign_information, numhl = "LspDiagnosticsDefaultInformation"}
    )
    vim.fn.sign_define("LspDiagnosticsSignHint", {text = sign_hint, numhl = "LspDiagnosticsDefaultHint"})

    -- [ lsp server config ] -------------------------------------------------------

    local lsp_servers_loaded, lsp_servers = pcall(require, "mega.lc.servers")
    if lsp_servers_loaded then
      lsp_servers.activate(on_attach)
    else
      mega.inspect("", lsp_servers, 4)
    end
  end
}
