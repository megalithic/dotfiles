return {
  "nvim-neorg/neorg",
  cond = false,
  ft = "norg",
  cmd = "Neorg",
  keys = {
    { "<leader>ne", ":Neorg export to-file ", desc = "neorg: export file" },
    { "<leader>nt", "<cmd>Neorg tangle current-file<cr>", desc = "neorg: tangle file" },
    { "<leader>np", "<cmd>Neorg presenter<cr>", desc = "neorg: presenter" },
    { "<leader>nw", ":Neorg workspace <TAB>", desc = "neorg: select workspace" },
    { "<leader>nmi", "<cmd>Neorg inject-metadata<cr>", desc = "neorg: inject" },
    { "<leader>nmu", "<cmd>Neorg update-metadata<cr>", desc = "neorg: update" },
    { "<leader>nol", "<cmd>Neorg toc left<cr>", desc = "neorg: open toc (left)" },
    { "<leader>nor", "<cmd>Neorg toc right<cr>", desc = "neorg: open toc (right)" },
    { "<leader>noq", "<cmd>Neorg toc qflist<cr>", desc = "neorg: open toc (quickfix list)" },
    { "<leader>njt", "<cmd>Neorg journal today<cr>", desc = "neorg: journal (today)" },
    { "<leader>njn", "<cmd>Neorg journal tomorrow<cr>", desc = "neorg: journal (tomorrow)" },
    { "<leader>njp", "<cmd>Neorg journal yesterday<cr>", desc = "neorg: journal (yesterday)" },
  },
  build = ":Neorg sync-parsers",
  opts = {
    load = {
      ["core.defaults"] = {},
      ["core.keybinds"] = { -- Configure core.keybinds
        config = {
          default_keybinds = true, -- Generate the default keybinds
          -- neorg_leader = km.localleader("o"), -- This is the default if unspecified
          hook = function(keybinds)
            keybinds.remap_event("norg", "n", "]]", "core.integrations.treesitter.next.heading")
            keybinds.remap_event("norg", "n", "[[", "core.integrations.treesitter.previous.heading")
            -- keybinds.map_event("norg", "n", km.leader("fl"), "core.integrations.telescope.find_linkable")
            -- keybinds.map_event("norg", "i", km.ctrl("l"), "core.integrations.telescope.insert_link")
            -- keybinds.map_event("norg", "n", km.localleader("m"), "core.looking-glass.magnify-code-block")
            -- keybinds.map_event("norg", "i", km.ctrl("m"), "core.looking-glass.magnify-code-block")
          end,
        },
      },
      ["core.completion"] = {
        config = {
          engine = "nvim-cmp",
          name = "[neorg]",
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
          autochdir = false,
          autodetect = true,
          autochdetect = true,
          workspaces = {
            notes = "~/Documents/_org",
            journal = "~/Documents/_org",
            work = "~/Documents/_org/work",
          },
          default_workspace = "home",
          index = "index.norg",
        },
      },
      ["core.journal"] = { config = { workspace = "journal", strategy = "nested" } }, -- Enable the notes
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
