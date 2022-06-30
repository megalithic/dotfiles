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

  require("mini.jump").setup({
    -- Module mappings. Use `''` (empty string) to disable one.
    mappings = {
      forward = "f",
      backward = "F",
      forward_till = "t",
      backward_till = "T",
      repeat_jump = ";",
    },

    -- Delay values (in ms) for different functionalities. Set any of them to
    -- a very big number (like 10^7) to virtually disable.
    delay = {
      -- Delay between jump and highlighting all possible jumps
      highlight = 250,

      -- Delay between jump and automatic stop if idle (no jump is done)
      idle_stop = 10000000,
    },

    -- Functions to be executed at certain events
    hooks = {
      before_start = nil, -- Before jump start
      after_jump = function()
        mega.blink_cursorline()
      end, -- After jump was actually done
    },
  })

  -- require("mini.jump2d").setup({
  --   enable = false,
  --   -- Function producing jump spots (byte indexed) for a particular line.
  --   -- For more information see |MiniJump2d.start|.
  --   -- If `nil` (default) - use |MiniJump2d.default_spotter|
  --   spotter = nil,

  --   -- Characters used for labels of jump spots (in supplied order)
  --   -- labels = "abcdefghijklmnopqrstuvwxyz",
  --   labels = "etovxqpdygfbzcisuran",

  --   -- Which lines are used for computing spots
  --   allowed_lines = {
  --     blank = true, -- Blank line (not sent to spotter even if `true`)
  --     cursor_before = true, -- Lines before cursor line
  --     cursor_at = true, -- Cursor line
  --     cursor_after = true, -- Lines after cursor line
  --     fold = true, -- Start of fold (not sent to spotter even if `true`)
  --   },

  --   -- Which windows from current tabpage are used for visible lines
  --   allowed_windows = {
  --     current = true,
  --     not_current = false,
  --   },

  --   -- Functions to be executed at certain events
  --   hooks = {
  --     before_start = nil, -- Before jump start
  --     after_jump = function()
  --       mega.blink_cursorline()
  --     end, -- After jump was actually done
  --   },

  --   -- Module mappings. Use `''` (empty string) to disable one.
  --   mappings = {
  --     start_jumping = "<CR>",
  --   },
  -- })

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
