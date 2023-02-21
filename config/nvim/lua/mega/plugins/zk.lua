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

    local zk = require("zk")
    local util = require("zk.util")
    local commands = require("zk.commands")
    local api = require("zk.api")
    local fzf_lua = require("fzf-lua")

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

    commands.add("ZkOrphans", make_edit_fn({ orphan = true }, { title = "zk orphans" }))
    commands.add("ZkRecents", make_edit_fn({ createdAfter = "1 week ago" }, { title = "zk recents" }))

    mega.zk_live_grep = function(opts)
      opts = opts or {}
      opts.prompt = "search notes "
      opts.file_icons = true
      opts.actions = fzf_lua.defaults.actions.files
      opts.previewer = "builtin"
      opts.fn_transform = function(x) return fzf_lua.make_entry.file(x, opts) end

      return fzf_lua.fzf_live(
        function(q) return "rg --column --color=always -- " .. vim.fn.shellescape(q or "") end,
        opts
      )
    end
    commands.add("ZkLiveGrep", mega.zk_live_grep)

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
      opts.prompt = "find notes "
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
    commands.add("ZkFindNotes", mega.zk_find_notes)
    mega.nnoremap("<leader>zf", mega.zk_find_notes, desc("zk: find notes"))

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
    mega.vnoremap("<leader>zg", ":'<,'>ZkMatch<CR>", desc("zk: search notes matching selection"))
    mega.nnoremap("<leader>zr", "<Cmd>ZkRecents<CR>", desc("zk: find recent notes"))

    mega.nnoremap("gl", "<Cmd>ZkInsertLink<CR>", desc("zk: insert link"))
    mega.vnoremap("gl", ":'<,'>ZkInsertLinkAtSelection<CR>", desc("zk: insert link (selected)"))
    mega.vnoremap("gL", ":'<,'>ZkInsertLinkAtSelection {match = true}<CR>", desc("zk: insert link (search selected)"))
  end,
}
