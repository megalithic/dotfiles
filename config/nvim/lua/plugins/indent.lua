local SETTINGS = require("config.options")

return {
  { "megalithic/virt-column.nvim", opts = { char = vim.g.virt_column_char }, event = "VimEnter" },
  -- {
  --   -- NOTE: we also have `mini.indentscope` that is handling current scope
  --   "lukas-reineke/indent-blankline.nvim",
  --   event = { "LazyFile" },
  --   cond = false,
  --   main = "ibl",
  --   opts = {
  --     indent = {
  --       char = vim.g.indent_char,
  --       smart_indent_cap = false,
  --     },
  --     scope = {
  --       enabled = false,
  --     },
  --     exclude = { filetypes = { "markdown" } },
  --   },
  -- },
  -- {
  --   "lukas-reineke/indent-blankline.nvim",
  --   event = { "LazyFile" },
  --   main = "ibl",
  --   opts = {
  --     indent = {
  --       char = "┊",
  --       smart_indent_cap = true,
  --     },
  --     scope = {
  --       enabled = false,
  --     },
  --   },
  -- },
}
