-- [ debugging ] ---------------------------------------------------------------

-- Can set this lower if needed (used in tandem with utils.inspect) ->
-- require('vim.lsp.log').set_level("trace")
-- require('vim.lsp.log').set_level("debug")

local utils = require("utils")
utils.inspect("loading lsp_config.lua")

-- To execute in :cmd ->
-- :lua <the_command>

-- LSP log location ->
-- `tail -n150 -f $HOME/.local/share/nvim/lsp.log`

-- [ requires ] ----------------------------------------------------------------

local has_lsp, _ = pcall(require, "nvim_lsp")
if not has_lsp then
    print("[WARN] nvim_lsp not found/installed/loaded..")

    return
end

-- local has_extensions = pcall(require, 'lsp_extensions') -- theirs
-- local has_completion, completion = pcall(require, "completion") -- theirs

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
    utils.inspect("client.resolved_capabilities", client.resolved_capabilities)

    vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

    if not vim.tbl_isempty(vim.lsp.buf_get_clients(0)) then
        utils.inspect("get_all_diagnostics", get_all_diagnostics())
    end

    if client.resolved_capabilities.completion then
        local completion_loaded, completion = pcall(require, "lc.completion")
        if completion_loaded then
            completion.activate()
        end
    end

    -- [ mappings ] --------------------------------------------------------------

    if client.resolved_capabilities.document_formatting then
        vim.api.nvim_command [[augroup lc.format]]
        vim.api.nvim_command [[autocmd! * <buffer>]]
        vim.api.nvim_command [[autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting(nil, 1000)]]
        vim.api.nvim_command [[augroup END]]
    end

    if client.resolved_capabilities.hover then
        utils.bmap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>")
    end

    if client.resolved_capabilities.goto_definition then
        utils.bmap("n", "<C-]>", "<cmd>lua vim.lsp.buf.definition()<CR>")
        utils.bmap("n", "<Leader>lgd", "<cmd>lua vim.lsp.buf.definition()<CR>")
    end

    if client.resolved_capabilities.find_references then
        utils.bmap("n", "<Leader>lr", "<cmd>lua vim.lsp.buf.references()<CR>")
        utils.bmap("n", "<Leader>lgr", '<cmd>lua require("telescope.builtin").lsp_references()<CR>')
    end

    if client.resolved_capabilities.rename then
        -- map("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>")
        utils.bmap("n", "<Leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>")
        utils.bmap("n", "<Leader>ln", "<cmd>lua vim.lsp.buf.rename()<CR>")
    end

    utils.bmap("n", "<Leader>lgi", "<cmd>lua vim.lsp.buf.implementation()<CR>")
    utils.bmap("n", "<Leader>lgt", "<cmd>lua vim.lsp.buf.type_definition()<CR>")
    utils.bmap("n", "<Leader>lgs", "<cmd>lua vim.lsp.buf.document_symbol()<CR>")
    utils.bmap("n", "<Leader>lgS", "<cmd>lua vim.lsp.buf.workspace_symbol()<CR>")
    utils.bmap("n", "<Leader>dE", "<cmd>lua vim.lsp.buf.declaration()<CR>")
    utils.bmap("n", "<Leader>la", "<cmd>lua vim.lsp.buf.code_action()<CR>")

    utils.bmap("n", "[d", "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>")
    utils.bmap("n", "]d", "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>")
    utils.bmap("n", "<Leader>ll", "<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>")
    utils.bmap("n", "<CR>", "<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>")

    utils.augroup(
        "lc.diagnostics",
        function()
            vim.api.nvim_command(
                "autocmd CursorHold <buffer> lua vim.lsp.diagnostic.show_line_diagnostics()"
            )
        end
    )
end

-- [ nvim-lsp/diagnostics ] -------------------------------------------------------

local sign_error = vim.api.nvim_get_var("sign_error")
local sign_warning = vim.api.nvim_get_var("sign_warning")
local sign_information = vim.api.nvim_get_var("sign_information")
local sign_hint = vim.api.nvim_get_var("sign_hint")

vim.fn.sign_define("LspDiagnosticsSignError", {text = sign_error, numhl = "LspDiagnosticsDefaultError"})
vim.fn.sign_define("LspDiagnosticsSignWarning", {text = sign_warning, numhl = "LspDiagnosticsDefaultWarning"})
vim.fn.sign_define(
    "LspDiagnosticsSignInformation",
    {text = sign_information, numhl = "LspDiagnosticsDefaultInformation"}
)
vim.fn.sign_define("LspDiagnosticsSignHint", {text = sign_hint, numhl = "LspDiagnosticsDefaultHint"})

-- [ lsp server config ] -------------------------------------------------------

local lsp_servers_loaded, lsp_servers = pcall(require, "lc.servers")
if lsp_servers_loaded then
    lsp_servers.activate(on_attach)
else
    utils.inspect("", lsp_servers, 4)
end
