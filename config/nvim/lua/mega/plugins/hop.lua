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

  -- --REF: https://github.com/phaazon/hop.nvim/issues/58#issuecomment-1339989116
  -- -- https://gist.github.com/kylechui/a5c1258cd2d86755f97b10fc921315c3
  -- -- https://www.vikasraj.dev/blog/vim-dot-repeat
  -- local hop = require("hop")
  -- local builtin_targets = require("hop.jump_target")

  -- _G._repeated_hop_state = {
  --   last_chars = nil,
  --   count = 0,
  -- }

  -- _G._repeatable_hop = function ()
  --   for i=1,_G._repeated_hop_state.count  do
  --     hop.hint_with(builtin_targets.jump_targets_by_scanning_lines(builtin_targets.regex_by_case_searching(
  --       _G._repeated_hop_state.last_chars, true, {})),
  --     hop.opts)
  --   end
  -- end

  -- hop.setup({})
  -- vim.api.nvim_set_keymap("n", [[f]],
  -- function()

  --   local char
  --   while true do
  --     vim.api.nvim_echo({ { "hop 1 char:", "Search" } }, false, {})
  --     local code = vim.fn.getchar()
  --     -- fixme: custom char range by needs
  --     if code >= 61 and code <= 0x7a then
  --       -- [a-z]
  --       char = string.char(code)
  --       break
  --     elseif code == 0x20 or code == 0x1b then
  --       -- press space, esc to cancel
  --       char = nil
  --       break
  --     end
  --   end
  --   if not char then return end

  --   -- setup the state to pickup in _G._repeatable_hop
  --   _G._repeated_hop_state = {
  --     last_chars = char,
  --     count = (vim.v.count or 0) + 1
  --   }

  --   vim.go.operatorfunc = "v:lua._repeatable_hop"
  --   -- return this↓ to run that↑
  --   return "g@l" -- see expr=true
  -- end , { noremap = true,
  -- -- ↓ see "g@l"
  -- expr = true})
end
