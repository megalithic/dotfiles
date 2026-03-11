-- lua/plugins/mini/surround.lua
-- Add/delete/change surrounding pairs
-- Reference: https://github.com/drowning-cat/nvim/blob/main/plugin/30_mini_ai%2Bsurround.lua

return {
  "echasnovski/mini.surround",
  keys = {
    { "S", mode = "x" },
    "ys",
    "ds",
    "cs",
  },
  opts = function()
    local surround = require("mini.surround")

    return {
      mappings = {
        add = "ys",
        delete = "ds",
        replace = "cs",
        find = "",
        find_left = "",
        highlight = "",
        update_n_lines = "",
        suffix_last = "",
        suffix_next = "",
      },
      custom_surroundings = {
        -- Function (treesitter-based)
        F = {
          input = surround.gen_spec.input.treesitter({
            outer = "@function.outer",
            inner = "@function.inner",
          }),
        },
        -- Class (treesitter-based)
        C = {
          input = surround.gen_spec.input.treesitter({
            outer = "@class.outer",
            inner = "@class.inner",
          }),
        },
      },
    }
  end,
  config = function(_, opts)
    require("mini.surround").setup(opts)
    -- Visual mode surround
    vim.keymap.set("x", "S", [[:<C-u>lua MiniSurround.add('visual')<CR>]], { silent = true })
    -- yss for current line
    vim.keymap.set("n", "yss", "ys_", { remap = true })
  end,
}
