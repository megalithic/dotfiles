return {
  {
    "nvim-mini/mini.jump",
    event = "VeryLazy",
    opts = {},
  },
  {
    "nvim-mini/mini.jump2d",
    event = "VeryLazy",
    opts = {
      view = {
        dim = true,
        n_steps_ahead = 2,
      },
      mappings = {
        start_jumping = "",
      },
    },
    config = function(_, opts)
      require("mini.jump2d").setup(opts)

      vim.keymap.set(
        "n",
        "gw",
        "<cmd>:lua MiniJump2d.start(MiniJump2d.builtin_opts.word_start)<cr>",
        { desc = "jump to word" }
      )
    end,
  },
}
