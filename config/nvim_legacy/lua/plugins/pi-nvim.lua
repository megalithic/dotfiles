return {
  "pablopunk/pi.nvim",
  opts = { provider = "anthropic", model = "claude-opus-4-5" },
  config = function(_, opts)
    require("pi").setup(opts)

    -- Ask pi with the current buffer as context
    vim.keymap.set("n", "<localleader>pi", ":PiAsk<CR>", { desc = "Ask pi" })

    -- Ask pi with visual selection as context
    vim.keymap.set("v", "<localleader>pi", ":PiAskSelection<CR>", { desc = "Ask pi (selection)" })
  end,
}
