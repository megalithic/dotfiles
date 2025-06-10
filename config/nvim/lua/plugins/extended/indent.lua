local SETTINGS = require("mega.settings")

return {
  { "megalithic/virt-column.nvim", opts = { char = SETTINGS.virt_column_char }, event = "VimEnter" },
  {
    -- NOTE: we also have `mini.indentscope` that is handling current scope
    "lukas-reineke/indent-blankline.nvim",
    event = { "LazyFile" },
    cond = false,
    main = "ibl",
    opts = {
      indent = {
        char = SETTINGS.indent_char,
        smart_indent_cap = false,
      },
      scope = {
        enabled = false,
      },
      exclude = { filetypes = { "markdown" } },
    },
  },
}
