return {

  "nvim-neorg/neorg",
  ft = "norg",
  cmd = "Neorg",
  keys = {
    { "<leader>ne", ":Neorg export to-file ", desc = "neorg: Export file" },
    { "<leader>nt", "<cmd>Neorg tangle current-file<cr>", desc = "neorg: Tangle file" },
    { "<leader>np", "<cmd>Neorg presenter<cr>", desc = "neorg: Presenter" },
    { "<leader>nmi", "<cmd>Neorg inject-metadata<cr>", desc = "neorg: Inject" },
    { "<leader>nmu", "<cmd>Neorg update-metadata<cr>", desc = "neorg: Update" },
    { "<leader>nol", "<cmd>Neorg toc left<cr>", desc = "neorg: Open ToC (left)" },
    { "<leader>nor", "<cmd>Neorg toc right<cr>", desc = "neorg: Open ToC (right)" },
    { "<leader>noq", "<cmd>Neorg toc qflist<cr>", desc = "neorg: Open ToC (quickfix list)" },
  },
  build = ":Neorg sync-parsers",
  opts = {
    load = {
      ["core.defaults"] = {},
      ["core.keybinds"] = {},
      ["core.completion"] = {
        config = {
          engine = "nvim-cmp",
        },
      },
      ["core.concealer"] = {
        config = {
          icons = {
            heading = {
              icons = { "◈", "◆", "◇", "❖", "⟡", "⋄" },
            },
          },
          dim_code_blocks = {
            conceal = false, -- do not conceal @code and @end
          },
        },
      },
      ["core.qol.toc"] = {},
      ["core.qol.todo_items"] = {},
      ["core.dirman"] = {
        config = {
          autodetect = true,
          workspaces = {
            notes = "~/Documents/_org",
            journal = "~/Documents/_org/journal",
          },
        },
      },
      ["core.journal"] = {},
      ["core.presenter"] = {
        config = {
          zen_mode = "zen-mode",
        },
      },
      ["core.esupports.hop"] = {},
      ["core.esupports.metagen"] = {
        config = {
          type = "empty",
        },
      },
      ["core.manoeuvre"] = {},
      ["core.export"] = {},
      ["core.export.markdown"] = {
        config = {
          extensions = "all",
        },
      },
      ["core.tangle"] = {},
      ["core.tempus"] = {},
      ["core.clipboard"] = {},
      ["core.clipboard.code-blocks"] = {},
      ["core.ui.calendar"] = {},
    },
  },
}
