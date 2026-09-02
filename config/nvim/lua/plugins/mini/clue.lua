-- lua/plugins/mini/clue.lua
-- Key hint popup with helix-style bottom-right layout

return {
  "echasnovski/mini.clue",
  version = false,
  cond = function()
    return vim.g.keyhelper == "mini.clue"
  end,
  event = "VeryLazy",
  config = function()
    local clue = require("mini.clue")

    clue.setup({
      -- Clue window settings
      window = {
        delay = 300, -- ms before showing clues
        config = {
          width = "auto",
          -- Helix-style: bottom-right of screen
          anchor = "SE",
          row = "auto",
          col = "auto",
          border = "rounded",
        },
      },

      -- Triggers for different modes
      triggers = {
        -- Leader triggers
        { mode = "n", keys = "<Leader>" },
        { mode = "x", keys = "<Leader>" },

        -- Localleader triggers
        { mode = "n", keys = "<Localleader>" },
        { mode = "x", keys = "<Localleader>" },

        -- Built-in completion
        { mode = "i", keys = "<C-x>" },

        -- `g` key
        { mode = "n", keys = "g" },
        { mode = "x", keys = "g" },

        -- Marks
        { mode = "n", keys = "'" },
        { mode = "n", keys = "`" },
        { mode = "x", keys = "'" },
        { mode = "x", keys = "`" },

        -- Registers
        { mode = "n", keys = '"' },
        { mode = "x", keys = '"' },
        { mode = "i", keys = "<C-r>" },
        { mode = "c", keys = "<C-r>" },

        -- Window commands
        { mode = "n", keys = "<C-w>" },

        -- `z` key
        { mode = "n", keys = "z" },
        { mode = "x", keys = "z" },

        -- Brackets
        { mode = "n", keys = "[" },
        { mode = "n", keys = "]" },
        { mode = "x", keys = "[" },
        { mode = "x", keys = "]" },
      },

      -- Clue groups with descriptions (matching whichkey.lua)
      clues = {
        -- Leader subgroups (only ones with actual keymaps)
        { mode = "n", keys = "<Leader>f", desc = "+ pick" },
        { mode = "n", keys = "<Leader>g", desc = "+󰊢 git" },
        { mode = "n", keys = "<Leader>l", desc = "+ lsp" },
        { mode = "n", keys = "<Leader>p", desc = "+󰏖 plugins" },
        { mode = "n", keys = "<Leader>u", desc = "+󰔡 ui/toggle" },
        { mode = "n", keys = "<Leader>x", desc = "+ trouble" },

        -- Localleader subgroups
        { mode = "n", keys = "<Localleader>m", desc = "+π send" },
        { mode = "x", keys = "<Localleader>m", desc = "+π send" },
        { mode = "n", keys = "<Localleader>p", desc = "+π pi" },
        { mode = "x", keys = "<Localleader>p", desc = "+π pi" },

        { mode = "n", keys = "<Localleader>t", desc = "+󰙨 test" },

        -- Text objects (mini.ai custom)
        { mode = "o", keys = "if", desc = "function" },
        { mode = "o", keys = "af", desc = "function" },
        { mode = "x", keys = "if", desc = "function" },
        { mode = "x", keys = "af", desc = "function" },
        { mode = "o", keys = "ic", desc = "class" },
        { mode = "o", keys = "ac", desc = "class" },
        { mode = "x", keys = "ic", desc = "class" },
        { mode = "x", keys = "ac", desc = "class" },
        { mode = "o", keys = "io", desc = "block/cond/loop" },
        { mode = "o", keys = "ao", desc = "block/cond/loop" },
        { mode = "x", keys = "io", desc = "block/cond/loop" },
        { mode = "x", keys = "ao", desc = "block/cond/loop" },
        { mode = "o", keys = "ia", desc = "argument" },
        { mode = "o", keys = "aa", desc = "argument" },
        { mode = "x", keys = "ia", desc = "argument" },
        { mode = "x", keys = "aa", desc = "argument" },
        { mode = "o", keys = "it", desc = "tag" },
        { mode = "o", keys = "at", desc = "tag" },
        { mode = "x", keys = "it", desc = "tag" },
        { mode = "x", keys = "at", desc = "tag" },
        { mode = "o", keys = "ig", desc = "entire buffer" },
        { mode = "o", keys = "ag", desc = "entire buffer" },
        { mode = "x", keys = "ig", desc = "entire buffer" },
        { mode = "x", keys = "ag", desc = "entire buffer" },
        { mode = "o", keys = "ie", desc = "subword" },
        { mode = "o", keys = "ae", desc = "subword" },
        { mode = "x", keys = "ie", desc = "subword" },
        { mode = "x", keys = "ae", desc = "subword" },

        -- Enhance built-in clues
        clue.gen_clues.builtin_completion(),
        clue.gen_clues.g(),
        clue.gen_clues.marks(),
        clue.gen_clues.registers(),
        clue.gen_clues.windows(),
        clue.gen_clues.z(),
      },
    })
  end,
}
