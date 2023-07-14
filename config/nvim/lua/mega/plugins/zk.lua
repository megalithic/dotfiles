-- REF:
-- Workflow: Using Zk to Manage Meeting Minutes:
-- - https://github.com/mickael-menu/zk-nvim/discussions/65
-- Great keymaps and funcs:
-- - https://github.com/huynle/vim-config/blob/main/after/plugin/zk.lua#L169
-- Obsidian + zk:
-- - https://github.com/ahmedelgabri/dotfiles/blob/main/config/nvim/lua/_/notes.lua
return {
  "vicrdguez/zk-nvim",
  -- "mickael-menu/zk-nvim",
  branch = "fzf-lua",
  cmd = {
    "ZkNotes",
    "ZkLiveGrep",
    "ZkTags",
    "ZkInsertLink",
    "ZkMatch",
    "ZkOrphans",
    "ZkFindNotes",
    "ZkNew",
    "ZkNewFromTitleSelection",
    "ZkInsertLinkAtSelection",
    "ZkNewFromContentSelection",
  },
  keys = {
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

    function insert_line_at_cursor(text, newline)
      local cursor = vim.api.nvim_win_get_cursor(0)
      local row = cursor[1]
      local column = cursor[2]

      if not newline then
        vim.api.nvim_buf_set_text(0, row - 1, column, row - 1, column, { text })
      else
        vim.api.nvim_buf_set_lines(0, row, row, false, { text })
      end
    end

    function insert_tag_at_cursor(text, newline)
      local tag = string.match(text, "([#%a-]+)")
      insert_line_at_cursor(tag, newline)
    end

    if vim.g.picker == "fzf" then
      local fzf_lua = require("fzf-lua")
      -- function ZettelkastenSearch()
      --   require("fzf-lua").fzf_live("textgrep", {
      --     actions = require("fzf-lua").defaults.actions.files,
      --     previewer = "builtin",
      --     exec_empty_query = true,
      --     fzf_opts = {
      --       ["--exact"] = "",
      --       ["--ansi"] = "",
      --       ["--tac"] = "",
      --       ["--no-multi"] = "",
      --       ["--no-info"] = "",
      --       ["--phony"] = "",
      --       ["--bind"] = "change:reload:textgrep \"{q}\"",
      --     },
      --   })
      -- end
      --
      -- function ZettelkastenRelatedTags()
      --   require("fzf-lua").fzf_exec("zk-related-tags \"" .. vim.fn.bufname("%") .. "\"", {
      --     actions = { ["default"] = function(selected, opts) insert_tag_at_cursor(selected[1], true) end },
      --     fzf_opts = { ["--exact"] = "", ["--nth"] = "2" },
      --   })
      -- end
      --
      -- function ZettelkastenTags()
      --   require("fzf-lua").fzf_exec("zkt-raw", {
      --     actions = { ["default"] = function(selected, opts) insert_tag_at_cursor(selected[1], true) end },
      --     fzf_opts = { ["--exact"] = "", ["--nth"] = "2" },
      --   })
      -- end
      --
      -- function CompleteZettelkastenPath()
      --   require("fzf-lua").fzf_exec("rg --files -t md | sed 's/^/[[/g' | sed 's/$/]]/'", {
      --     actions = { ["default"] = function(selected, opts) insert_line_at_cursor(selected[1], false) end },
      --   })
      -- end
      --
      -- function CompleteZettelkastenTag()
      --   require("fzf-lua").fzf_exec("zkt-raw", {
      --     actions = { ["default"] = function(selected, opts) insert_tag_at_cursor(selected[1], false) end },
      --     fzf_opts = {
      --       ["--exact"] = "",
      --       ["--nth"] = "2",
      --       ["--print-query"] = "",
      --       ["--multi"] = "",
      --     },
      --   })
      -- end
      --
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
      mega.nnoremap("<leader>zf", "<cmd>ZkNotes<cr>", desc("zk: find notes"))
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
    elseif vim.g.picker == "telescope" then
      mega.nnoremap(
        "<leader>zf",
        function() require("telescope").extensions.zk.notes(_G.telescope_ivy({ sort = { "modified" } })) end,
        desc("zk: find notes")
      )
      mega.nnoremap(
        "<leader>nf",
        function() require("telescope").extensions.zk.notes(_G.telescope_ivy({ sort = { "modified" } })) end,
        desc("zk: find notes")
      )
      mega.nnoremap(
        "<leader>zw",
        function()
          require("telescope").extensions.zk.notes(_G.telescope_ivy({ sort = { "modified" }, tags = { "tern" } }))
        end,
        desc("zk: find notes")
      )
      mega.nnoremap(
        "<leader>nw",
        function()
          require("telescope").extensions.zk.notes(_G.telescope_ivy({ sort = { "modified" }, tags = { "tern" } }))
        end,
        desc("zk: find notes")
      )
    end

    commands.add("ZkOrphans", make_edit_fn({ orphan = true }, { title = "zk orphans" }))
    commands.add("ZkRecents", make_edit_fn({ createdAfter = "1 week ago" }, { title = "zk recents" }))

    -- mega.nnoremap("<leader>zt", "<cmd>ZkTags<cr>", desc("zk: find tags"))
    mega.nnoremap("<leader>zn", "<Cmd>ZkNew { title = vim.fn.input('title: ') }<CR>", desc("zk: new note"))
    mega.nnoremap("<leader>nn", "<Cmd>ZkNew { title = vim.fn.input('title: ') }<CR>", desc("zk: new note"))
    mega.vnoremap("<leader>zn", function()
      vim.ui.select({ "Title", "Content" }, { prompt = "Set selection as:" }, function(choice)
        if choice == "Title" then
          vim.cmd([['<,'>ZkNewFromTitleSelection]])
        elseif choice == "Content" then
          vim.cmd([['<,'>ZkNewFromContentSelection]])
        end
      end)
    end, desc("zk: new note from selection"))
    mega.vnoremap("<leader>nn", function()
      vim.ui.select({ "Title", "Content" }, { prompt = "Set selection as:" }, function(choice)
        if choice == "Title" then
          vim.cmd([['<,'>ZkNewFromTitleSelection]])
        elseif choice == "Content" then
          vim.cmd([['<,'>ZkNewFromContentSelection]])
        end
      end)
    end, desc("zk: new note from selection"))

    mega.vnoremap("<leader>zg", ":'<,'>ZkMatch<CR>", desc("zk: search notes matching selection"))
    mega.nnoremap("<leader>zr", "<Cmd>ZkRecents<CR>", desc("zk: find recent notes"))
    -- mega.nnoremap(
    --   "<leader>z/",
    --   require("telescope.builtin").live_grep(_G.telescope_ivy({ cwd = vim.g.notes_path })),
    --   { desc = "telescope | Live grep" }
    -- )

    mega.nnoremap("gl", "<Cmd>ZkInsertLink<CR>", desc("zk: insert link"))
    mega.vnoremap("gl", ":'<,'>ZkInsertLinkAtSelection<CR>", desc("zk: insert link (selected)"))
    mega.vnoremap("gL", ":'<,'>ZkInsertLinkAtSelection {match = true}<CR>", desc("zk: insert link (search selected)"))
  end,
}
