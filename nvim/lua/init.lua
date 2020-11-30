-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │                                                                           │
-- │ Setup for Lua-based config and plugins                                    │
-- │ --> REF: https://github.com/nanotee/nvim-lua-guide                        │
-- │                                                                           │
-- └───────────────────────────────────────────────────────────────────────────┘

-- [ globals.. ] ---------------------------------------------------------------

RELOAD = require("plenary.reload").reload_module

R = function(name)
  RELOAD(name)
  return require(name)
end

P = function(v)
  print(vim.inspect(v))
  return v
end

-- [ main loaders.. ] ----------------------------------------------------------

require("commands")
require("autocmds")
require("keymaps")
require("abbrev")

-- [ plugin loaders.. ] --------------------------------------------------------

require("p.colorizer")
require("p.golden_size")
require("p.telescope")
-- require("p.treesitter")

-- [ lsp loaders.. ] -----------------------------------------------------------

require("lc.config")
