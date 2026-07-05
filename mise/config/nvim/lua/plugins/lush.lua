return {
  {
    "rktjmp/lush.nvim",
    branch = "main",
    lazy = false,
    config = function()
      require("themes")
      mega.t[vim.g.theme].apply()
    end,
  },
}
