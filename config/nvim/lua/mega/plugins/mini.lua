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
end
