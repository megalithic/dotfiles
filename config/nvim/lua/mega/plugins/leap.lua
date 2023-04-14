local api = vim.api
local fn = vim.fn

local function leap_keys()
  require("leap").leap({
    target_windows = vim.tbl_filter(
      function(win) return mega.empty(fn.win_gettype(win)) end,
      api.nvim_tabpage_list_wins(0)
    ),
  })
end

local function leap_config() require("leap").setup({ equivalence_classes = { " \t\r\n", "([{", ")]}", "`\"'" } }) end

return {
  {
    "ggandor/leap.nvim",
    dependencies = { "tpope/vim-repeat" },
    keys = { { "s", leap_keys } },
    config = leap_config,
    enabled = false,
  },
  {
    "ggandor/flit.nvim",
    keys = { "f", "t", "F", "T" },
    dependencies = { "ggandor/leap.nvim" },
    opts = { labeled_modes = "nvo", multiline = false },
    enabled = false,
  },
}
