-- {
--   "folke/edgy.nvim",
--   opts = function(_, opts)
--     for _, pos in ipairs({ "top", "bottom", "left", "right" }) do
--       opts[pos] = opts[pos] or {}
--       table.insert(opts[pos], {
--         ft = "megaterm",
--         size = { height = 0.3, width = 0.3 },
--         title = "%{b:megaterm.id}: %{b:term_title}",
--         filter = function(_buf, win)
--           local edgy_filter = vim.w[win].megaterm_win
--             and vim.w[win].megaterm_win.position == pos
--             and vim.w[win].megaterm_win.relative == "editor"
--             and not vim.w[win].trouble_preview

--           return edgy_filter
--         end,
--       })
--     end
--   end,
-- },

return {
  "folke/edgy.nvim",
  enabled = false,
  opts = {
    animate = { enabled = false },
    exit_when_last = true,
    icons = {
      closed = " " .. Icons.misc.fold_close,
      open = " " .. Icons.misc.fold_open,
    },
    keys = {
      ["q"] = false,
      ["<c-q>"] = false,
      ["Q"] = false,
      ["]w"] = false,
      ["[w"] = false,
      ["]W"] = false,
      ["[W"] = false,
      ["<c-w>>"] = false,
      ["<c-w><lt>"] = false,
      ["<c-w>+"] = false,
      ["<c-w>-"] = false,
      ["<c-w>="] = false,
    },

    right = {
      {
        title = "Outline",
        ft = "aerial",
        open = "AerialToggle",
        size = {
          width = 0.13,
        },
      },
      {
        title = "megaterm",
        ft = "megaterm",
        size = {
          width = 0.3,
        },
      },
      {
        title = "Grug Far",
        ft = "grug-far",
        size = { width = 0.3 },
      },
      {
        title = "Overseer",
        ft = "OverseerList",
      },
    },
    bottom = {
      "Trouble",
      { ft = "qf", title = "QuickFix" },
      {
        title = "megaterm",
        ft = "megaterm",
        size = {
          height = 0.2,
        },
      },
      {
        title = "Overseer Output",
        ft = "OverseerListOutput",
      },
      { title = "Neotest Output", ft = "neotest-output-panel", size = { height = 15 } },
      { title = "Undo Tree Diff", ft = "diff", size = { height = 15 } },
      {
        title = "Kulala",
        ft = "json.kulala_ui",
      },
      {
        title = "Kulala",
        ft = "text.kulala_ui",
      },
    },
    left = {
      { title = "Neotest Summary", ft = "neotest-summary" },
      { title = "Undo Tree", ft = "undotree" },
    },
  },
}
