-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │                                                                           │
-- │ Setup for Lua-based plugins                                               │
-- │ --> REF: https://github.com/nanotee/nvim-lua-guide                        │
-- │                                                                           │
-- └───────────────────────────────────────────────────────────────────────────┘

-- _G["wr"] = require("wr.global")

-- [ required.. ] --------------------------------------------------------------

require("settings")
require("plugins")
require("autocmds")
require("keymaps")

-- [ plugins.. ] ---------------------------------------------------------------

require("p.nova")
require("p.fzf")
-- require("p.telescope")
-- require("p.colorizer")
-- require("p.golden_ratio")
-- require("p.treesitter")

-- [ lsp.. ] -------------------------------------------------------------------

--require("lc.config")
