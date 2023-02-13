local function config()
  local fn = vim.fn
  mega.nnoremap("<localleader>oc", "<Cmd>Neorg gtd capture<CR>")
  mega.nnoremap("<localleader>ov", "<Cmd>Neorg gtd views<CR>")

  require("neorg").setup({
    configure_parsers = true,
    load = {
      ["core.defaults"] = {},
      ["core.integrations.telescope"] = {},
      ["core.keybinds"] = {
        config = {
          default_keybinds = true,
          neorg_leader = "<localleader>",
          hook = function(keybinds)
            keybinds.unmap("norg", "n", "<C-s>")
            keybinds.map_event("norg", "n", "<C-x>", "core.integrations.telescope.find_linkable")
          end,
        },
      },
      ["core.norg.completion"] = {
        config = {
          engine = "nvim-cmp",
        },
      },
      ["core.norg.concealer"] = {},
      ["core.norg.dirman"] = {
        config = {
          workspaces = {
            notes = fn.expand("$ICLOUD_DOCUMENTS_DIR/neorg/notes/"),
            tasks = fn.expand("$ICLOUD_DOCUMENTS_DIR/neorg/tasks/"),
            work = fn.expand("$ICLOUD_DOCUMENTS_DIR/neorg/work/"),
            dotfiles = fn.expand("$DOTFILES/neorg/"),
          },
        },
      },
    },
  })
end

return {
  {
    "vhyrro/neorg",
    -- ft = "norg",
    event = "VeryLazy",
    build = ":Neorg sync-parsers",
    config = config,
    dependencies = { "vhyrro/neorg-telescope" },
    cond = false,
  },
}
