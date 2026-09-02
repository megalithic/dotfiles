-- lua/plugins/mini/surround.lua
-- Add/delete/change surrounding pairs
-- Reference: https://github.com/drowning-cat/nvim/blob/main/plugin/30_mini_ai%2Bsurround.lua

return {
  "nvim-mini/mini.surround",
  keys = {
    { "S", mode = { "x" } },
    "ys",
    "ds",
    "cs",
  },
  config = function()
    require("mini.surround").setup({
      mappings = {
        add = "ys",
        delete = "ds",
        replace = "cs",
        find = "",
        find_left = "",
        highlight = "",
        update_n_lines = 500,
      },
      custom_surroundings = {
        tag_name_only = {
          input = { "<(%w-)%f[^<%w][^<>]->.-</%1>", "^<()%w+().*</()%w+()>$" },
          output = function()
            local tag_name = require("mini.surround").user_input("Tag name (excluding attributes)")
            if tag_name == nil then return nil end
            return { left = tag_name, right = tag_name }
          end,
        },
      },
    })

    vim.keymap.set("x", "S", [[:<C-u>lua MiniSurround.add('visual')<CR>]])
    vim.keymap.set("n", "yss", "ys_", { noremap = false })
  end,
}
