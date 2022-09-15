return function()
  local hop = require("hop")
  -- local map = vim.keymap.set
  -- local jump_target = hop.jump_target
  -- local last_chars

  -- @REF: https://github.com/phaazon/hop.nvim/issues/58#issuecomment-1244661113
  -- local function repeatable_hop(chars)
  --   assert(chars ~= nil)
  --   last_chars = chars
  --   hop.hint_with(
  --     jump_target.jump_targets_by_scanning_lines(jump_target.regex_by_case_searching(chars, true, {})),
  --     hop.opts
  --   )
  --   vim.fn["repeat#set"](":lua mega.fn.hop_repeater()\r")
  --   -- vim.cmd([[silent! call repeat#set(":lua mega.fn.hop_repeater()\r", -1)]])
  -- end

  -- mega.fn.hop_repeater = function()
  --   if last_chars == nil then return end
  --   repeatable_hop(last_chars)
  -- end

  -- remove h,j,k,l from hops list of keys
  hop.setup({ keys = "etovxqpdygfbzcisuran" })
  nnoremap(
    "s",
    function() hop.hint_char2({ multi_windows = false, direction = require("hop.hint").HintDirection.AFTER_CURSOR }) end
  )
  nnoremap(
    "S",
    function() hop.hint_char2({ multi_windows = false, direction = require("hop.hint").HintDirection.BEFORE_CURSOR }) end
  )

  -- map(
  --   { "x", "n", "o" },
  --   "F",
  --   function()
  --     hop.hint_char1({
  --       direction = require("hop.hint").HintDirection.BEFORE_CURSOR,
  --       current_line_only = true,
  --       inclusive_jump = false,
  --     })
  --   end
  -- )

  -- map(
  --   { "x", "n", "o" },
  --   "f",
  --   function()
  --     hop.hint_char1({
  --       direction = require("hop.hint").HintDirection.AFTER_CURSOR,
  --       current_line_only = true,
  --       inclusive_jump = false,
  --     })
  --   end
  -- )

  -- map(
  --   { "x", "n" },
  --   "t",
  --   function()
  --     hop.hint_char1({
  --       direction = require("hop.hint").HintDirection.AFTER_CURSOR,
  --       current_line_only = true,
  --       hint_offset = -1,
  --     })
  --   end
  -- )

  -- map(
  --   { "x", "n" },
  --   "T",
  --   function()
  --     hop.hint_char1({
  --       direction = require("hop.hint").HintDirection.BEFORE_CURSOR,
  --       current_line_only = true,
  --       hint_offset = 1,
  --     })
  --   end
  -- )
end
