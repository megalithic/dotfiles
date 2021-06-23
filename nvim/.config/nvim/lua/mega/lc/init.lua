mega.inspect("activating lsp_config.lua..")

-- NOTE:
-- - Handy commands for LSP things:
-- - https://github.com/akinsho/dotfiles/blob/main/.config/nvim/lua/as/plugins/lspconfig.lua#L154-L184

-- [ requires ] ----------------------------------------------------------------

local everforest = require("mega.colors.everforest")

local has_lsp, _ = pcall(require, "lspconfig")
if not has_lsp then
  print("[WARN] lspconfig not found/installed/loaded..")

  return
end

-- [ custom on_attach ] --------------------------------------------------------

local on_attach = function(client, bufnr)
  mega.inspect("client.cmd", client.name)
  mega.inspect("client.resolved_capabilities", client.resolved_capabilities)
  -- mega.dump(client.resolved_capabilities)

  if client.config.flags then
    client.config.flags.allow_incremental_sync = true
  end

  vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

  if client.resolved_capabilities.completion then
    local completion_loaded, completion = pcall(require, "mega.lc.completion")
    if completion_loaded then
      completion.activate()
    end
  end

  -- [ mappings ] --------------------------------------------------------------

  if client.resolved_capabilities.document_formatting then
    mega.augroup(
      "lc.format_on_save",
      function()
        vim.api.nvim_command [[autocmd! * <buffer>]]
        -- vim.api.nvim_command [[autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting(nil, 1000)]]
        vim.api.nvim_command [[autocmd BufWritePost <buffer> lua vim.lsp.buf.formatting(nil, 1000)]]
        vim.cmd [[command! Format lua vim.lsp.buf.formatting()]]
      end
    )
  end

  if client.resolved_capabilities.hover then
    mega.map("n", "K", "<cmd>lua require('lspsaga.hover').render_hover_doc()<CR>")
  -- scroll down hover doc
  -- mega.map("n", "<C-f>", "<cmd>lua require('lspsaga.hover').smart_scroll_hover(1)<CR>")
  -- -- scroll up hover doc
  -- mega.map("n", "<C-d>", "<cmd>lua require('lspsaga.hover').smart_scroll_hover(-1)<CR>")
  end

  if client.resolved_capabilities.goto_definition then
    mega.map("n", "<C-]>", "<cmd>lua vim.lsp.buf.definition()<CR>")
    mega.map("n", "<leader>ld", [[<cmd>lua require('telescope.builtin').lsp_definitions()<cr>]])
    -- mega.map("n", "<leader>lgd", [[<cmd>lua require'lspsaga.provider'.preview_definition()<CR>]])
    -- mega.map("n", "<leader>ld", [[<cmd>lua require'lspsaga.provider'.lsp_finder()<CR>]])
    mega.map("n", "<leader>lf", [[<cmd>lua require'lspsaga.provider'.lsp_finder()<CR>]])
  end

  if client.resolved_capabilities.find_references then
    mega.map("n", "<leader>lr", [[<cmd>lua require('telescope.builtin').lsp_references()<cr>]])
    mega.map("n", "<leader>lf", [[<cmd>lua require'lspsaga.provider'.lsp_finder()<CR>]])
  end

  if client.resolved_capabilities.rename then
    mega.map("n", "<leader>ln", "<cmd>lua require('lspsaga.rename').rename()<CR>")
  end

  if client.resolved_capabilities.code_action then
    mega.map("n", "<leader>la", "<cmd>lua require('lspsaga.codeaction').code_action()<CR>")
    mega.map("x", "<leader>la", "<cmd>'<,'>lua require('lspsaga.codeaction').range_code_action()<CR>")
  end

  mega.map("n", "<leader>lgi", "<cmd>lua vim.lsp.buf.implementation()<CR>")
  mega.map("n", "<leader>lgt", "<cmd>lua vim.lsp.buf.type_definition()<CR>")
  mega.map("n", "<leader>ls", "<cmd>lua vim.lsp.buf.document_symbol()<CR>")
  mega.map("n", "<leader>lS", "<cmd>lua vim.lsp.buf.workspace_symbol()<CR>")
  mega.map("n", "<leader>dE", "<cmd>lua vim.lsp.buf.declaration()<CR>")

  -- jump diagnostic
  mega.map("n", "[d", "<cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_prev()<CR>")
  -- mega.map("n", ",d", "<cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_prev()<CR>")
  mega.map("n", "]d", "<cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_next()<CR>")
  -- mega.map("n", ";d", "<cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_next()<CR>")

  -- mega.map("n", "<leader>ll", "<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>")
  -- mega.map("n", "<CR>", "<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>")
  -- # lsp-trouble
  mega.map("n", "<leader>ll", "<cmd>LspTroubleToggle<cr>")

  mega.augroup(
    "lc.cursor_commands",
    function()
      vim.api.nvim_command [[autocmd CursorHold * lua require('lspsaga.diagnostic').show_line_diagnostics()]]

      if client.resolved_capabilities.signature_help then
        vim.api.nvim_command [[autocmd CursorHoldI * lua require('lspsaga.signaturehelp').signature_help()]]
        mega.map("i", "<c-k>", "<cmd>lua require('lspsaga.signaturehelp').signature_help()<CR>")
      end
    end
  )

  vim.cmd([[command! LspLog lua vim.cmd('e'..vim.lsp.get_log_path())]])
end

-- [ diagnostics config ] ------------------------------------------------------

do
  local sign_error = everforest.icons.sign_error
  local sign_warning = everforest.icons.sign_warning
  local sign_information = everforest.icons.sign_information
  local sign_hint = everforest.icons.sign_hint

  vim.fn.sign_define("LspDiagnosticsSignError", {text = sign_error, numhl = "LspDiagnosticsDefaultError"})
  vim.fn.sign_define("LspDiagnosticsSignWarning", {text = sign_warning, numhl = "LspDiagnosticsDefaultWarning"})
  vim.fn.sign_define(
    "LspDiagnosticsSignInformation",
    {text = sign_information, numhl = "LspDiagnosticsDefaultInformation"}
  )
  vim.fn.sign_define("LspDiagnosticsSignHint", {text = sign_hint, numhl = "LspDiagnosticsDefaultHint"})
end

-- [ server config ] -----------------------------------------------------------

local lsp_servers_loaded, lsp_servers = pcall(require, "mega.lc.servers")
if lsp_servers_loaded then
  lsp_servers.activate(on_attach)
else
  mega.inspect("", lsp_servers, 4)
end
