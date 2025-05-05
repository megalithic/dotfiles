return {
  {
    "folke/snacks.nvim",
    cmd = { "Snacks" },
    opts = {
      picker = {
        sources = {
          smart = {
            multi = { { source = "recent", paths = { ["~/.config"] = false } } },
            --multi = { { source = "recent", paths = { ["~/.config"] = false } } },
          },
        },
      },
    },
  },
}
