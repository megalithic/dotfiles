return {
  "mickael-menu/zk-nvim",
  dependencies = {
    { "ibhagwan/fzf-lua" },
    {
      "junegunn/fzf.vim",
      dependencies = {
        { "junegunn/fzf" },
      },
    },
    { "vijaymarupudi/nvim-fzf" },
  },
  event = "VeryLazy",
  enabled = true,
  config = function()
    local zk = require("zk")
    zk.setup({
      -- can be "telescope", "fzf" or "select" (`vim.ui.select`)
      -- it's recommended to use "telescope" or "fzf"
      picker = "fzf",

      lsp = {
        -- `config` is passed to `vim.lsp.start_client(config)`
        config = {
          cmd = { "zk", "lsp" },
          name = "zk",
          -- on_attach = require("mega.lsp").on_attach,
          -- etc, see `:h vim.lsp.start_client()`
        },

        -- automatically attach buffers in a zk notebook that match the given filetypes
        auto_attach = {
          enabled = true,
          filetypes = { "markdown" },
        },
      },
    })

    local util = require("zk.util")
    local commands = require("zk.commands")
    local api = require("zk.api")

    --Get dirname of file
    ---@param file string
    ---@return string The full dirname for the file
    local function dirname(file) return file:gsub("(.*)(/.*)$", "%1") end

    --Get basename of file
    ---@param file string
    ---@return string The full basename for the file
    local function basename(file) return file:gsub("(.*/)(.*)$", "%2") end

    local function make_edit_fn(defaults, picker_options)
      return function(options)
        options = vim.tbl_extend("force", defaults, options or {})
        zk.edit(options, picker_options)
      end
    end

    local function make_new_fn(defaults, picker_options)
      return function(options)
        options = vim.tbl_extend("force", defaults, options or {})
        zk.new(options, picker_options)
      end
    end

    local desc = function(desc) return { desc = desc, silent = true } end

    commands.add("ZkOrphans", make_edit_fn({ orphan = true }, { title = "zk orphans" }))
    commands.add("ZkRecents", make_edit_fn({ createdAfter = "1 week ago" }, { title = "zk recents" }))
    commands.add("ZkLiveGrep", function(options)
      -- options = options or {}
      -- local notebook_path = options.notebook_path or util.resolve_notebook_path(0)
      -- local notebook_root = util.notebook_root(notebook_path) or vim.env.ZK_NOTEBOOK_DIR
      -- if notebook_root then
      --   require("telescope.builtin").live_grep(
      --     _G.telescope_ivy({ cwd = notebook_root, search_dirs = { notebook_root }, prompt_title = "zk live grep" })
      --   )
      -- else
      --   vim.notify("No notebook found", vim.log.levels.ERROR)
      -- end
      require("telescope.builtin").live_grep(_G.telescope_ivy({
        cwd = vim.env.ZK_NOTEBOOK_DIR,
        -- search_dirs = { vim.env.ZK_NOTEBOOK_DIR },
        prompt_title = "zk live grep",
      }))
    end)
    --
    --
    -- -- Create a new note after asking for its title.
    mega.nnoremap("<leader>zn", "<Cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>", desc("zk: new note"))
    mega.nnoremap("<leader>zf", "<Cmd>ZkNotes { sort = { 'modified' } }<CR>", desc("zk: find notes"))
    -- mega.nnoremap(
    --   "<leader>zf",
    --   function() require("telescope").extensions.zk.notes(_G.telescope_ivy({ sort = { "modified" } })) end
    -- )
    mega.nnoremap("<leader>z/", "<cmd>ZkLiveGrep<CR>", desc("zk: live grep"))
    -- mega.nnoremap(
    --   "<leader>zg",
    --   "<Cmd>ZkNotes { sort = { 'modified' }, match = vim.fn.input('Search: ') }<CR>",
    --   desc("zk: search notes")
    -- )
    mega.vnoremap("<leader>zg", ":'<,'>ZkMatch<CR>", desc("zk: search notes matching selection"))
    mega.nnoremap("<leader>zr", "<Cmd>ZkRecents<CR>", desc("zk: find recent notes"))

    local function yankName(options, picker_options)
      zk.pick_notes(options, picker_options, function(notes)
        local pos = vim.api.nvim_win_get_cursor(0)[2]
        local line = vim.api.nvim_get_current_line()

        if picker_options.multi_select == false then notes = { notes } end
        for _, note in ipairs(notes) do
          local trimmed_path = note.path:match("[0-9]*.md")
          local nline = line:sub(0, pos) .. "[" .. note.title .. "]" .. "(" .. trimmed_path .. ")" .. line:sub(pos + 1)
          vim.api.nvim_set_current_line(nline)
        end
      end)
    end

    -- commands.add("ZkInsertLink", function(options) yankName(options, { title = "ZkInsertLink" }) end)
    mega.nnoremap("gl", "<Cmd>ZkInsertLink<CR>", desc("zk: insert link"))
    mega.vnoremap("gl", ":'<,'>ZkInsertLinkAtSelection<CR>", desc("zk: insert link (selected)"))
    mega.vnoremap("gL", ":'<,'>ZkInsertLinkAtSelection {match = true}<CR>", desc("zk: insert link (search selected)"))

    -- { "<Leader>zi", "<cmd>ZkInsertLink<CR>", desc = "[l]inking: [i]nsert link at cursor" },
    -- {
    --   "<Leader>zi",
    --   ":'<,'>ZkInsertLinkAtSelection<CR>",
    --   desc = "[l]inking: [i]nsert link around selected text",
    --   mode = "v",
    -- },
    -- {
    --   "<Leader>zI",
    --   ":'<,'>ZkInsertLinkAtSelection {match = true}<CR>",
    --   desc = "[l]inking: insert link, [s]earching for selected text",
    --   mode = "v",
    -- },

    --
    -- -- Journaling stuff
    -- commands.add("ZkDailyEntry", function(opts)
    --   local today = os.date("%Y%m%d")
    --   local today_human = os.date("%Y-%m-%d")
    --   local entry_path = "journal/" .. today .. ".md"
    --
    --   api.list(nil, { select = { "path" }, hrefs = { entry_path } }, function(err, res)
    --     assert(res ~= nil, tostring(err))
    --
    --     if mega.tlen(res) == 0 then
    --       api.new(nil, {
    --         title = today_human,
    --         dir = "journal",
    --         date = "today",
    --         template = "journal.md",
    --       }, function(err, res)
    --         assert(res ~= nil, tostring(err))
    --
    --         local dir = dirname(res.path)
    --         local new_path = dir .. "/" .. basename(entry_path)
    --         os.rename(res.path, new_path)
    --
    --         vim.cmd("e " .. new_path)
    --       end)
    --     else
    --       vim.cmd("e " .. res[1]["path"])
    --     end
    --   end)
    -- end)

    require("telescope").load_extension("zk")
  end,
  -- keys = {
  --   { "<Leader>zn", "<cmd>ZkNew {dir = \"notes\"}<CR>", desc = "[n]ew [n]ote" },
  --   { "<Leader>zj", "<cmd>ZkDailyEntry<CR>", desc = "[n]ew [j]ournal entry" },
  --   { "<Leader>zm", "<cmd>ZkNew {dir = \"notes\", template = \"meeting.md\"}<CR>", desc = "[n]ew [m]eeting note" },
  --   {
  --     "<Leader>zn",
  --     ":'<,'>ZkNewFromTitleSelection {dir = 'notes'}<CR>",
  --     desc = "[n]ew [n]ote; title from selected text",
  --     mode = "v",
  --   },
  --   {
  --     "<Leader>zN",
  --     ":'<,'>ZkNewFromTitleSelection {dir = 'notes', edit = false}<CR>",
  --     desc = "New [n]ote [i]nsert link; title from selected text",
  --     mode = "v",
  --   },
  --   { "<Leader>zf", "<cmd>ZkNotes<CR>", desc = "[f]ind [n]ote" },
  --   { "<Leader>zf", ":'<,'>ZkMatch<CR>", desc = "[f]ind [n]ote based on selected text", mode = "v" },
  --   { "<Leader>zt", "<cmd>ZkTags<CR>", desc = "[f]ind [t]ag" },
  --   { "<Leader>zb", "<cmd>ZkBacklinks<CR>", desc = "[l]inking: show [b]acklinks" },
  --   { "<Leader>zl", "<cmd>ZkLinks<CR>", desc = "[l]inking: show [l]inks to file" },
  --   { "<Leader>zi", "<cmd>ZkInsertLink<CR>", desc = "[l]inking: [i]nsert link at cursor" },
  --   {
  --     "<Leader>zi",
  --     ":'<,'>ZkInsertLinkAtSelection<CR>",
  --     desc = "[l]inking: [i]nsert link around selected text",
  --     mode = "v",
  --   },
  --   {
  --     "<Leader>zI",
  --     ":'<,'>ZkInsertLinkAtSelection {match = true}<CR>",
  --     desc = "[l]inking: insert link, [s]earching for selected text",
  --     mode = "v",
  --   },
  -- },
}
-- local M = { "mickael-menu/zk-nvim", dependencies = "telescope.nvim" }
-- function M.config()
--   local zk = require("zk")
--
--   local util = require("zk.util")
--   local commands = require("zk.commands")
--
--   zk.setup({
--     picker = "telescope",
--     lsp = {
--       -- config = vim.tbl_extend("force", mega.lsp.get_server_config("zk"), config or {}),
--       autostart = true,
--     },
--   })
--
--   local function make_edit_fn(defaults, picker_options)
--     return function(options)
--       options = vim.tbl_extend("force", defaults, options or {})
--       zk.edit(options, picker_options)
--     end
--   end
--
--   local function make_new_fn(defaults)
--     return function(options)
--       options = vim.tbl_extend("force", defaults, options or {})
--       zk.new(options)
--     end
--   end
--
--   -- REF:
--   -- https://github.com/elihunter173/dotfiles/blob/main/.config/nvim/init.lua#L429
--   -- https://github.com/kabouzeid/dotfiles/blob/main/config/nvim/lua/lsp-settings.lua#L192
--
--   commands.add("ZkOrphans", make_edit_fn({ orphan = true }, { title = "Zk Orphans" }))
--   commands.add("ZkRecents", make_edit_fn({ createdAfter = "1 weeks ago" }, { title = "Zk Recents" }))
--   commands.add("ZkLiveGrep", function(options)
--     options = options or {}
--     local notebook_path = options.notebook_path or util.resolve_notebook_path(0)
--     local notebook_root = util.notebook_root(notebook_path)
--     if notebook_root then
--       require("telescope.builtin").live_grep({ cwd = notebook_root, prompt_title = "Zk Live Grep" })
--     else
--       vim.notify("No notebook found", vim.log.levels.ERROR)
--     end
--   end)
--   commands.add("ZkNewDaily", make_new_fn({ dir = "journal/daily" }))
--   commands.add("ZkDaily", make_edit_fn({ hrefs = { "journal/daily" }, sort = { "created" } }, { title = "Zk Daily" }))
--   -- commands.add("ZkNewHealth", make_new_fn({ dir = "journal/health" }))
--   -- commands.add(
--   --   "ZkHealth",
--   --   make_edit_fn({ hrefs = { "journal/health" }, sort = { "created" } }, { title = "Zk Health" })
--   -- )
--
--   nnoremap("<leader>zn", "<cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>", "zk: new note")
--   xnoremap("<leader>zn", ":'<,'>ZkNewFromTitleSelection<CR>", "zk: new note from title")
--   xnoremap("<leader>zN", ":'<,'>ZkNewFromContentSelection<CR>", "zk: new note from content")
--   nnoremap("<leader>zf", "<cmd>ZkNotes { sort = { 'modified' } }<CR>", "zk: find notes")
--   nnoremap("<leader>za", "<cmd>ZkLiveGrep<CR>", "zk: live grep notes")
--   nnoremap(
--     "<leader>zs",
--     "<cmd>ZkNotes { sort = { 'modified' }, match = vim.fn.input('Search: ') }<CR>",
--     "zk: search notes"
--   )
--   nnoremap("<leader>zb", "<cmd>ZkBacklinks<CR>", "zk: back links")
--   nnoremap("<leader>zl", "<cmd>ZkLinks<CR>", "zk: links")
--   nnoremap("<leader>zt", "<cmd>ZkTags<CR>", "zk: tags")
--   nnoremap("<leader>zo", "<cmd>ZkOrphans<CR>", "zk: orphans")
--   nnoremap("<leader>zr", "<cmd>ZkRecents<CR>", "zk: recents")
--   xnoremap("<leader>zm", ":'<,'>ZkMatch<CR>", "zk: match on")
--
--   require("telescope").load_extension("zk")
-- end
--
-- return M
