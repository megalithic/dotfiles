return function()
  require("mini.indentscope").setup({
    symbol = "▏", -- │ ▏
    draw = {
      delay = 50,
    },

    -- draw = {
    --   delay = 50,
    --   animation = require("mini.indentscope").gen_animation("none"),
    -- },
    -- options = {
    --   indent_at_cursor = false,
    -- },
    -- symbol = "▏",
  })

  -- require("mini.surround").setup({
  --   -- Number of lines within which surrounding is searched
  --   n_lines = 50,

  --   -- Duration (in ms) of highlight when calling `MiniSurround.highlight()`
  --   highlight_duration = 500,

  --   -- Module mappings. Use `''` (empty string) to disable one.
  --   mappings = {
  --     add = "sa", -- Add surrounding
  --     delete = "sd", -- Delete surrounding
  --     find = "sf", -- Find surrounding (to the right)
  --     find_left = "sF", -- Find surrounding (to the left)
  --     highlight = "sh", -- Highlight surrounding
  --     replace = "sr", -- Replace surrounding
  --     update_n_lines = "sn", -- Update `n_lines`
  --   },
  -- })
end
