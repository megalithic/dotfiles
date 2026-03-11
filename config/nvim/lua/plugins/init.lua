return {
  {
    "nacro90/numb.nvim",
    event = "CmdlineEnter",
    opts = {},
  },

  --   "mrjones2014/smart-splits.nvim",
  --   lazy = false,
  --   commit = "36bfe63246386fc5ae2679aa9b17a7746b7403d5",
  --   opts = { at_edge = "stop" },
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    opts = { ignored_buftypes = { "nofile" }, cursor_follows_swapped_bufs = true, at_edge = "stop" },
    keys = {
      { "<A-h>", function() require("smart-splits").resize_left() end, mode = { "n", "i", "v" }, desc = "Resize left" },
      {
        "<A-l>",
        function() require("smart-splits").resize_right() end,
        mode = { "n", "i", "v" },
        desc = "Resize right",
      },
      {
        "<C-h>",
        function()
          require("smart-splits").move_cursor_left()
          vim.cmd.normal("zz")
        end,
        mode = { "n", "i", "v" },
        desc = "Move to left split",
      },
      {
        "<C-j>",
        function() require("smart-splits").move_cursor_down() end,
        mode = { "n", "i", "v" },
        desc = "Move to below split",
      },
      {
        "<C-k>",
        function() require("smart-splits").move_cursor_up() end,
        mode = { "n", "i", "v" },
        desc = "Move to above split",
      },
      {
        "<C-l>",
        function()
          require("smart-splits").move_cursor_right()
          vim.cmd.normal("zz")
        end,
        mode = { "n", "i", "v" },
        desc = "Move to right split",
      },
    },
  },
  {
    "max397574/better-escape.nvim",
    event = { "InsertEnter" },
    -- event = { "InsertEnter", require("utils.events").VisualEnter },
    config = function()
      require("better_escape").setup({
        timeout = vim.o.timeoutlen,
        default_mappings = false,
        mappings = {
          i = { k = { j = "<esc>" } },
          c = { k = { j = "<esc>" } },
          -- HACK: move the cursor back before escaping
          v = { k = { j = "j<esc>" } },
        },
      })
    end,
  },
  { "chrisgrieser/nvim-genghis" },
  {
    "fei6409/log-highlight.nvim",
    ft = { "log" },
    opts = {},
  },
  { "megalithic/virt-column.nvim", opts = { char = vim.g.virt_column_char }, event = "VimEnter" },
}
