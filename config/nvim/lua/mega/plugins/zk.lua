return function(config)
  local zk = require("zk")
  local util = require("zk.util")
  local commands = require("zk.commands")

  zk.setup({
    picker = "telescope",
    lsp = {
      -- config = vim.tbl_extend("force", mega.lsp.get_server_config("zk"), config or {}),
      autostart = true,
    },
  })

  local function make_edit_fn(defaults, picker_options)
    return function(options)
      options = vim.tbl_extend("force", defaults, options or {})
      zk.edit(options, picker_options)
    end
  end

  local function make_new_fn(defaults)
    return function(options)
      options = vim.tbl_extend("force", defaults, options or {})
      zk.new(options)
    end
  end

  -- REF:
  -- https://github.com/elihunter173/dotfiles/blob/main/.config/nvim/init.lua#L429
  -- https://github.com/kabouzeid/dotfiles/blob/main/config/nvim/lua/lsp-settings.lua#L192

  commands.add("ZkOrphans", make_edit_fn({ orphan = true }, { title = "Zk Orphans" }))
  commands.add("ZkRecents", make_edit_fn({ createdAfter = "1 weeks ago" }, { title = "Zk Recents" }))
  commands.add("ZkLiveGrep", function(options)
    options = options or {}
    local notebook_path = options.notebook_path or util.resolve_notebook_path(0)
    local notebook_root = util.notebook_root(notebook_path)
    if notebook_root then
      require("telescope.builtin").live_grep({ cwd = notebook_root, prompt_title = "Zk Live Grep" })
    else
      vim.notify("No notebook found", vim.log.levels.ERROR)
    end
  end)
  commands.add("ZkNewDaily", make_new_fn({ dir = "journal/daily" }))
  commands.add("ZkDaily", make_edit_fn({ hrefs = { "journal/daily" }, sort = { "created" } }, { title = "Zk Daily" }))
  -- commands.add("ZkNewHealth", make_new_fn({ dir = "journal/health" }))
  -- commands.add(
  --   "ZkHealth",
  --   make_edit_fn({ hrefs = { "journal/health" }, sort = { "created" } }, { title = "Zk Health" })
  -- )

  nnoremap("<leader>zn", "<cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>", "zk: new note")
  xnoremap("<leader>zn", ":'<,'>ZkNewFromTitleSelection<CR>", "zk: new note from title")
  xnoremap("<leader>zN", ":'<,'>ZkNewFromContentSelection<CR>", "zk: new note from content")
  nnoremap("<leader>fz", "<cmd>ZkNotes { sort = { 'modified' } }<CR>", "zk: find notes")
  nnoremap("<leader>zf", "<cmd>ZkNotes { sort = { 'modified' } }<CR>", "zk: find notes")
  nnoremap("<leader>za", "<cmd>ZkLiveGrep<CR>", "zk: live grep notes")
  nnoremap(
    "<leader>zs",
    "<cmd>ZkNotes { sort = { 'modified' }, match = vim.fn.input('Search: ') }<CR>",
    "zk: search notes"
  )
  nnoremap("<leader>zb", "<cmd>ZkBacklinks<CR>", "zk: back links")
  nnoremap("<leader>zl", "<cmd>ZkLinks<CR>", "zk: links")
  nnoremap("<leader>zt", "<cmd>ZkTags<CR>", "zk: tags")
  nnoremap("<leader>zo", "<cmd>ZkOrphans<CR>", "zk: orphans")
  nnoremap("<leader>zr", "<cmd>ZkRecents<CR>", "zk: recents")
  xnoremap("<leader>zm", ":'<,'>ZkMatch<CR>", "zk: match on")

  require("telescope").load_extension("zk")
end
