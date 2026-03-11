-- lua/plugins/flash.lua
-- Navigate with search labels, enhanced f/t, and treesitter integration

return {
  "folke/flash.nvim",
  event = "VeryLazy",
  ---@type Flash.Config
  opts = {
    labels = "asdfghjklqwertyuiopzxcvbnm",
    -- Exclude terminal buffers
    exclude = {
      "megaterm",
      "terminal",
      "toggleterm",
      "notify",
      "noice",
      "cmp_menu",
      function(win)
        -- Exclude non-focusable windows and terminal buftype
        local buf = vim.api.nvim_win_get_buf(win)
        return vim.bo[buf].buftype == "terminal"
      end,
    },
    search = {
      multi_window = true,
      forward = true,
      wrap = true,
      mode = "exact",
    },
    jump = {
      jumplist = true,
      pos = "start",
      autojump = false,
    },
    label = {
      uppercase = true,
      after = true,
      before = false,
      style = "overlay",
      reuse = "lowercase",
      distance = true,
      min_pattern_length = 0,
    },
    highlight = {
      backdrop = true,
      matches = true,
      groups = {
        match = "FlashMatch",
        current = "FlashCurrent",
        backdrop = "FlashBackdrop",
        label = "FlashLabel",
      },
    },
    modes = {
      search = {
        enabled = false, -- don't enhance / search by default
      },
      char = {
        enabled = true,
        autohide = false,
        jump_labels = false,
        multi_line = true,
        label = { exclude = "hjkliardc" },
        keys = { "f", "F", "t", "T", ";", "," },
        char_actions = function(motion)
          return {
            [";"] = "next",
            [","] = "prev",
            [motion:lower()] = "next",
            [motion:upper()] = "prev",
          }
        end,
        search = { wrap = false },
        highlight = { backdrop = true },
        jump = { register = false, autojump = false },
      },
      treesitter = {
        labels = "asdfghjklqwertyuiopzxcvbnm",
        jump = { pos = "range", autojump = true },
        search = { incremental = false },
        label = { before = true, after = true, style = "inline" },
        highlight = { backdrop = false, matches = false },
      },
    },
    prompt = {
      enabled = true,
      prefix = { { "⚡", "FlashPromptIcon" } },
    },
  },
  keys = {
    { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    { "S", mode = { "n", "o", "x" }, function() require("flash").treesitter() end, desc = "Flash treesitter" },
    {
      "v",
      mode = { "v" },
      function()
        require("flash").treesitter({
          actions = {
            ["v"] = "next",
            ["V"] = "prev",
          },
        })
      end,
      desc = "Treesitter incremental selection",
    },
    { "r", mode = "o", function() require("flash").remote() end, desc = "Remote flash" },
    { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter search" },
    { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle flash search" },
  },
}
