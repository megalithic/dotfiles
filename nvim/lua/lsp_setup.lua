local lsp_setup = {}

local nvim_lsp = require 'nvim_lsp'
-- local lsp_callbacks = require 'lsp_callbacks'

function lsp_setup.setup()
    nvim_lsp.clangd.setup {}
    nvim_lsp.gopls.setup {}
    nvim_lsp.hie.setup {}
    nvim_lsp.pyls.setup {}
    nvim_lsp.rls.setup {}
    nvim_lsp.texlab.setup {}
end

return lsp_setup
