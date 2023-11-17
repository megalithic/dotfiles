-- REF:
-- Workflow: Using Zk to Manage Meeting Minutes:
-- - https://github.com/mickael-menu/zk-nvim/discussions/65
-- Great keymaps and funcs:
-- - https://github.com/huynle/vim-config/blob/main/after/plugin/zk.lua#L169
-- Obsidian + zk:
-- - https://github.com/ahmedelgabri/dotfiles/blob/main/config/nvim/lua/_/notes.lua
return {
  -- "vicrdguez/zk-nvim",
  "mickael-menu/zk-nvim",
  -- branch = "fzf-lua",
  event = "VeryLazy",
  cmd = {
    "ZkNotes",
    "ZkLiveGrep",
    "ZkTags",
    "ZkInsertLink",
    "ZkMatch",
    "ZkOrphans",
    "ZkFindNotes",
    "ZkLinks",
    "ZkBacklinks",
    "ZkNew",
    "ZkNewFromTitleSelection",
    "ZkInsertLinkAtSelection",
    "ZkNewFromContentSelection",
  },
  keys = {
    "<leader>zd",
    "<leader>zl",
    "<leader>zb",
    "<leader>zn",
    "<leader>zf",
    "<leader>z/",
    "<leader>zw",
    "<leader>zt",
    "<leader>nn",
    "<leader>nf",
    "<leader>n/",
    "<leader>nw",
    "<leader>nt",
  },
  config = function()
    local zk = require("zk")
    zk.setup({
      picker = vim.g.picker,

      lsp = {
        config = {
          cmd = { "zk", "lsp" },
          name = "zk",
        },

        auto_attach = {
          enabled = true,
          filetypes = { "markdown" },
        },
      },
    })

    local zk = require("zk")
    local util = require("zk.util")
    local commands = require("zk.commands")
    local api = require("zk.api")
    local desc = function(desc) return { desc = desc, silent = true } end

    local function make_edit_fn(defaults, picker_options)
      return function(options)
        options = vim.tbl_extend("force", defaults, options or {})
        zk.edit(options, picker_options)
      end
    end

    -- local function make_new_fn(defaults, picker_options)
    --   return function(options)
    --     options = vim.tbl_extend("force", defaults, options or {})
    --     zk.new(options, picker_options)
    --   end
    -- end
    --
    --
    -- function insert_line_at_cursor(text, newline)
    --   local cursor = vim.api.nvim_win_get_cursor(0)
    --   local row = cursor[1]
    --   local column = cursor[2]
    --
    --   if not newline then
    --     vim.api.nvim_buf_set_text(0, row - 1, column, row - 1, column, { text })
    --   else
    --     vim.api.nvim_buf_set_lines(0, row, row, false, { text })
    --   end
    -- end
    --
    -- function insert_tag_at_cursor(text, newline)
    --   local tag = string.match(text, "([#%a-]+)")
    --   insert_line_at_cursor(tag, newline)
    -- end

    if vim.g.picker == "fzf_lua" then
      --------------------------------------------------------------------------
      -- FZF_LUA ---------------------------------------------------------------
      --------------------------------------------------------------------------
      local fzf_lua = require("fzf-lua")
      mega.zk_live_grep = function(opts)
        opts = opts or {}
        opts.prompt = "search notes  "
        opts.file_icons = true
        opts.actions = fzf_lua.defaults.actions.files
        opts.previewer = "builtin"
        opts.fn_transform = function(x) return fzf_lua.make_entry.file(x, opts) end

        return fzf_lua.fzf_live(
          function(q) return "rg --column --color=always -- " .. vim.fn.shellescape(q or "") end,
          opts
        )
      end

      mega.zk_find_notes = function(opts)
        local delimiter = "\x01"
        local notes = {}
        local list_opts = { select = { "title", "path", "absPath" } }

        -- custom "builtin"/treesitter previewer since i need to break apart of the note's absPath/title
        local Preview = require("fzf-lua.previewer.builtin").buffer_or_file:extend()
        function Preview:new(o, options, fzf_win)
          Preview.super.new(self, o, options, fzf_win)
          setmetatable(self, Preview)
          return self
        end
        function Preview:parse_entry(entry_str)
          local path = string.match(entry_str, "([^" .. delimiter .. "]+)")
          return {
            path = path,
            col = 1,
          }
        end

        opts = opts or {}
        opts.prompt = "find notes  "
        opts.file_icons = true
        opts.actions = fzf_lua.defaults.actions.files
        opts.previewer = Preview
        opts.fzf_opts = {
          ["--delimiter"] = delimiter,
          ["--tiebreak"] = "index",
          ["--with-nth"] = 2,
          ["--tabstop"] = 4,
        }

        api.list(vim.env.ZK_NOTEBOOK_DIR, list_opts, function(_, result)
          for _, note in ipairs(result) do
            local title = note.title or note.path
            table.insert(notes, table.concat({ note.absPath, title }, delimiter))
          end

          -- TODO: determine if we need to wrap this in a coroutine at some point
          fzf_lua.fzf_exec(notes, opts)
        end)
      end
      commands.add("ZkLiveGrep", mega.zk_live_grep)
      commands.add("ZkFindNotes", mega.zk_find_notes)
      mega.nnoremap("<leader>zf", "<cmd>ZkFindNotes<cr>", desc("zk: find notes"))
      mega.nnoremap(
        "<leader>z/",
        function() mega.zk_live_grep({ exec_empty_query = false, cwd = vim.env.ZK_NOTEBOOK_DIR }) end,
        desc("zk: live grep")
      )
      mega.nnoremap(
        "<leader>zg",
        function() mega.zk_live_grep({ exec_empty_query = false, cwd = vim.env.ZK_NOTEBOOK_DIR }) end,
        desc("zk: live grep")
      )
    ----------------------------------------------------------------------------
    -- TELESCOPE ---------------------------------------------------------------
    ----------------------------------------------------------------------------
    elseif vim.g.picker == "telescope" then
      local function get_notes(opts)
        opts = opts or {}
        return require("telescope").extensions.zk.notes(_G.picker.telescope.ivy(opts))
      end
      local function get_tags(opts)
        opts = opts or {}
        return require("telescope").extensions.zk.tags(_G.picker.telescope.ivy(opts))
      end

      mega.nnoremap("<leader>zf", function() get_notes({ sort = { "modified" } }) end, desc("zk: find notes"))
      mega.nnoremap(
        "<leader>zw",
        function() get_notes({ sort = { "modified" }, tags = { "tern OR work" } }) end,
        desc("zk: work notes")
      )
      mega.nnoremap(
        "<leader>zd",
        function() get_notes({ sort = { "modified" }, tags = { "daily" } }) end,
        desc("zk: daily notes")
      )
      mega.nnoremap(
        "<leader>zl",
        function()
          get_notes({
            linkedBy = { vim.api.nvim_buf_get_name(0) },
          })
        end,
        desc("zk: links")
      )
      mega.nnoremap(
        "<leader>zb",
        function()
          get_notes({
            linkedTo = { vim.api.nvim_buf_get_name(0) },
          })
        end,
        desc("zk: backlinks")
      )
      mega.nnoremap("<leader>zt", function() get_tags() end, desc("zk: tags"))

      mega.nnoremap(
        "<leader>za",
        function()
          get_notes({
            match = {},
          })
        end,
        -- function() require("telescope.builtin").live_grep(_G.picker.telescope.ivy({ cwd = vim.g.notes_path })) end,
        { desc = "zk: live grep notes" }
      )
    end

    commands.add("ZkOrphans", make_edit_fn({ orphan = true }, { title = "zk: orphans" }))
    commands.add(
      "ZkRecents",
      make_edit_fn({ sort = { "modified" }, createdAfter = "1 week ago" }, { title = "zk: recents" })
    )

    mega.nnoremap("<leader>zn", "<Cmd>ZkNew { title = vim.fn.input('title: ') }<CR>", desc("zk: new note"))
    mega.vnoremap("<leader>zn", function()
      vim.ui.select({ "Title", "Content" }, { prompt = "Set selection as:" }, function(choice)
        if choice == "Title" then
          vim.cmd([['<,'>ZkNewFromTitleSelection]])
        elseif choice == "Content" then
          vim.cmd([['<,'>ZkNewFromContentSelection]])
        end
      end)
    end, desc("zk: new note from selection"))
    mega.nnoremap("<leader>zr", "<Cmd>ZkRecents<CR>", desc("zk: find recent notes"))
    -- mega.vnoremap("<leader>zg", ":'<,'>ZkMatch<CR>", desc("zk: search notes matching selection"))
    -- mega.vnoremap("<leader>za", ":'<,'>ZkMatch<CR>", desc("zk: search notes matching selection"))
    mega.nnoremap(
      "<leader>z/",
      function() require("telescope.builtin").live_grep(_G.picker.telescope.ivy({ cwd = vim.g.notes_path })) end,
      { desc = "zk: live grep notes" }
    )

    mega.nnoremap("gl", "<Cmd>ZkInsertLink<CR>", desc("zk: insert link"))
    mega.vnoremap("gl", ":'<,'>ZkInsertLinkAtSelection<CR>", desc("zk: insert link (selected)"))
    mega.vnoremap("gL", ":'<,'>ZkInsertLinkAtSelection {match = true}<CR>", desc("zk: insert link (search selected)"))
  end,
}
