-- Runtime startup after vim.pack registration.

require("langs").setup()
require("lsp").setup()
require("ui.pack_interface")
