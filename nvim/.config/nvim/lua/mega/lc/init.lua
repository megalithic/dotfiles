mega.inspect("activating lsp_config.lua..")

-- [ requires ] ----------------------------------------------------------------

local nova = require("mega.colors.nova")

local has_lsp, _ = pcall(require, "lspconfig")
if not has_lsp then
  print("[WARN] lspconfig not found/installed/loaded..")

  return
end

-- [ custom on_attach ] --------------------------------------------------------
local on_attach = function(client, bufnr)
  mega.inspect("client.cmd", client.name)
  mega.inspect("client.resolved_capabilities", client.resolved_capabilities)

  vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

  require("lspsaga").init_lsp_saga {
    use_saga_diagnostic_sign = false,
    border_style = 2,
    finder_action_keys = {
      open = "<CR>",
      vsplit = "v",
      split = "s",
      quit = {"q", [[\<ESC>]]}
    }
  }

  if client.resolved_capabilities.completion then
    local completion_loaded, completion = pcall(require, "mega.lc.completion")
    if completion_loaded then
      completion.activate()
    end
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
    mega.map("n", "K", "<cmd>lua require('lspsaga.hover').render_hover_doc()<CR>")
    -- scroll down hover doc
    mega.map("n", "<C-n>", "<cmd>lua require('lspsaga.hover').smart_scroll_hover(1)<CR>")
    -- scroll up hover doc
    mega.map("n", "<C-p>", "<cmd>lua require('lspsaga.hover').smart_scroll_hover(-1)<CR>")
    mega.map("i", "<c-k>", "<cmd>lua require('lspsaga.signaturehelp').signature_help()<CR>")
  end

  if client.resolved_capabilities.goto_definition then
    mega.map("n", "<C-]>", "<cmd>lua vim.lsp.buf.definition()<CR>")
    mega.map("n", "<Leader>lgD", "<cmd>lua vim.lsp.buf.definition()<CR>")
    mega.map("n", "<leader>lgd", "<cmd>lua require'lspsaga.provider'.preview_definition()<CR>")
  end

  if client.resolved_capabilities.find_references then
    mega.map("n", "<Leader>lr", "<cmd>lua vim.lsp.buf.references()<CR>")
    mega.map("n", "<Leader>lgr", "<cmd>lua vim.lsp.buf.references()<CR>")
    mega.map("n", "<leader>lgf", [[<cmd>lua require'lspsaga.provider'.lsp_finder()<CR>]])
    mega.map("n", "<leader>lf", [[<cmd>lua require'lspsaga.provider'.lsp_finder()<CR>]])
  -- mega.bmap("n", "<Leader>lgr", '<cmd>lua require("telescope.builtin").lsp_references()<CR>')
  end

  if client.resolved_capabilities.rename then
    mega.map("n", "<Leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>")
    mega.map("n", "<Leader>ln", "<cmd>lua vim.lsp.buf.rename()<CR>")
    mega.map("n", "<leader>rn", "<cmd>lua require('lspsaga.rename').rename()<CR>")
  end

  if client.resolved_capabilities.code_action then
    mega.map("n", "<leader>lca", "<cmd>lua require('lspsaga.codeaction').code_action()<CR>")
  -- mega.map("x", "<leader>a", "<cmd>'<,'>lua require('lspsaga.codeaction').range_code_action()<CR>")
  end

  mega.map("n", "<Leader>lgi", "<cmd>lua vim.lsp.buf.implementation()<CR>")
  mega.map("n", "<Leader>lgt", "<cmd>lua vim.lsp.buf.type_definition()<CR>")
  mega.map("n", "<Leader>lgs", "<cmd>lua vim.lsp.buf.document_symbol()<CR>")
  mega.map("n", "<Leader>lgS", "<cmd>lua vim.lsp.buf.workspace_symbol()<CR>")
  mega.map("n", "<Leader>dE", "<cmd>lua vim.lsp.buf.declaration()<CR>")

  -- jump diagnostic
  mega.map("n", "[d", "<cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_prev()<CR>")
  mega.map("n", "]d", "<cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_next()<CR>")
  mega.map("n", "<Leader>ll", "<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>")
  mega.map("n", "<CR>", "<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>")

  mega.augroup(
    "lc.cursor_commands",
    function()
      vim.api.nvim_command [[autocmd CursorHold * lua require('lspsaga.diagnostic').show_line_diagnostics()]]
      if client.resolved_capabilities.signature_help then
        vim.api.nvim_command [[autocmd CursorHoldI * lua require('lspsaga.signaturehelp').signature_help()]]
      end
    end
  )
end

-- [ nvim-lsp/diagnostics ] -------------------------------------------------------

-- vim.fn.sign_define("LspDiagnosticsSignError", {text = "", numhl = "LspDiagnosticsDefaultError"})
-- vim.fn.sign_define("LspDiagnosticsSignWarning", {text = "", numhl = "LspDiagnosticsDefaultWarning"})
-- vim.fn.sign_define("LspDiagnosticsSignInformation", {text = "", numhl = "LspDiagnosticsDefaultInformation"})
-- vim.fn.sign_define("LspDiagnosticsSignHint", {text = "", numhl = "LspDiagnosticsDefaultHint"})

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
