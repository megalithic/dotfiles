-- REF:
-- Workflow: Using Zk to Manage Meeting Minutes:
-- - https://github.com/mickael-menu/zk-nvim/discussions/65
-- Great keymaps and funcs:
-- - https://github.com/huynle/vim-config/blob/main/after/plugin/zk.lua#L169
-- Obsidian + zk:
-- - https://github.com/ahmedelgabri/dotfiles/blob/main/config/nvim/lua/_/notes.lua
--
-- - https://github.com/jfpedroza/dotfiles/blob/master/nvim/lua/jp/zk.lua
-- - https://github.com/MaienM/dotfiles/blob/3f11f8f45b3a2d4c69e4bc6bbc318223c55d3e8c/vim/rc/plugins/lsp/zk.lua#L4
-- - https://github.com/tlein/dotfiles/blob/f01c6332db182ca2fe6fa962971847e585dab34e/nvim/lua/tjl/extensions/my_zk.lua#L4

return {
  "mickael-menu/zk-nvim",
  event = "VeryLazy",
  config = function()
    local zk = require("zk")
    local util = require("zk.util")
    local api = require("zk.api")
    local on_attach = function(client, bufnr)
      zk.command = require("zk.commands")

      -- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      -- HELPERS
      -- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      local picker_style = _G.picker[vim.g.picker]["ivy"]
      local desc = function(desc) return { desc = desc, silent = true, buffer = bufnr } end
      local function make_edit_fn(defaults, picker_options)
        return function(options)
          options = vim.tbl_extend("force", defaults, options or {})
          zk.edit(options, picker_style(picker_options))
        end
      end
      -- local function make_new_fn(defaults, picker_options)
      --   return function(options)
      --     options = vim.tbl_extend("force", defaults, options or {})
      --     zk.new(options, picker_style(picker_options))
      --   end
      -- end
      local function get_notes(...)
        if vim.g.picker == "fzf_lua" then return zk.command.get("ZkNotes")(...) end
        return require("telescope").extensions.zk.notes(picker_style(...))
      end
      local function get_tags(...)
        if vim.g.picker == "fzf_lua" then return zk.command.get("ZkTags")(...) end
        return require("telescope").extensions.zk.tags(picker_style(...))
      end

      -- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      -- COMMANDS
      -- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      mega.command(
        "ZkToday",
        function(_) zk.command.get("ZkNew")({ dir = "log/daily" }) end,
        { desc = "zk: opens or creates zk note for today" }
      )
      mega.command(
        "ZkLog",
        function(_) get_notes({ hrefs = { "log" }, sort = { "created" } }) end,
        { desc = "zk: list all the zk log notes" }
      )
      zk.command.add("ZkMultiTags", function(opts)
        get_tags(opts, { title = "zk tags" }, function(tags)
          tags = vim.tbl_map(function(v) return v.name end, tags)
          get_notes(
            { tags = tags },
            { title = "Zk Notes for tag(s) " .. vim.inspect(tags), multi_select = true },
            function(notes)
              local cmd = "args"
              for _, note in ipairs(notes) do
                cmd = cmd .. " " .. note.absPath
              end
              vim.cmd(cmd)
            end
          )
        end)
      end, { nargs = "?", force = true, complete = "lua" })

      zk.command.add("ZkOrphans", make_edit_fn({ orphan = true }, { title = "zk: orphans" }))
      zk.command.add(
        "ZkRecents",
        make_edit_fn({ sort = { "modified" }, createdAfter = "1 week ago" }, { title = "zk: recents" })
      )

      -- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      -- MAPPINGS
      -- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      mega.nnoremap("<leader>nf", function() get_notes({ sort = { "modified" } }) end, desc("zk: find notes"))
      mega.nnoremap(
        "<leader>nw",
        function() get_notes({ sort = { "modified" }, tags = { "tern OR work" } }, { title = "work notes" }) end,
        desc("zk: work notes")
      )
      mega.nnoremap(
        "<leader>nd",
        function() get_notes({ sort = { "modified" }, tags = { "daily" } }, { title = "daily notes" }) end,
        desc("zk: daily notes")
      )
      mega.nnoremap(
        "<leader>nl",
        function()
          get_notes({
            linkedBy = { vim.api.nvim_buf_get_name(0) },
          })
        end,
        desc("zk: links")
      )
      mega.nnoremap(
        "<leader>nb",
        function()
          get_notes({
            linkedTo = { vim.api.nvim_buf_get_name(0) },
          })
        end,
        desc("zk: backlinks")
      )
      mega.nnoremap("<leader>nt", function() get_tags() end, desc("zk: tags"))
      mega.nnoremap("gt", function() get_tags() end, desc("zk: tags"))
      -- FIXME: not quite working
      mega.nnoremap(
        "<leader>na",
        function()
          get_notes({
            match = {},
          }, { title = "live grep notes" })
        end,
        { desc = "zk: live grep notes" }
      )

      mega.xnoremap("gm", "<esc><cmd>'<,'>ZkMatch<cr>", desc("zk: find notes in selection"))
      mega.nnoremap("gm", "<esc><cmd>ZkMatch<cr>", desc("zk: find notes under cursor"))
      mega.nnoremap("<leader>nr", "<Cmd>ZkRecents<CR>", desc("zk: find recent notes"))
      mega.vnoremap("<leader>gr", "<cmd>ZkMatch<CR>", desc("zk: search notes matching under cursor"))
      mega.vnoremap("<leader>gr", ":'<,'>ZkMatch<CR>", desc("zk: search notes matching selection"))
      mega.map({ "v", "x" }, "<leader>gr", ":'<,'>ZkMatch<CR>", desc("zk: search notes matching selection"))
      mega.nnoremap("gi", "<Cmd>ZkInsertLink<CR>", desc("zk: insert link"))
      mega.vnoremap("gi", ":'<,'>ZkInsertLinkAtSelection<CR>", desc("zk: insert link (selected)"))
      mega.vnoremap("gI", ":'<,'>ZkInsertLinkAtSelection {match = true}<CR>", desc("zk: insert link (search selected)"))
      mega.nnoremap("<leader>nn", "<Cmd>ZkNew { title = vim.fn.input('title: ') }<CR>", desc("zk: new note"))

      mega.map(
        { "v", "x" },
        "<leader>nn",
        ":'<,'>ZkNewFromContentSelection { title = vim.fn.input('Title: ') }<CR>",
        desc("zk: new note from selection")
      )
      mega.map(
        { "v", "x" },
        "<leader>nN",
        ":'<,'>ZkNewFromTitleSelection<CR>",
        desc("zk: new note title from selection")
      )
    end

    zk.setup({
      picker = vim.g.picker,
      lsp = {
        config = {
          cmd = { "zk", "lsp" },
          name = "zk",
          -- on_attach = on_attach,
        },
        auto_attach = {
          enabled = true,
          filetypes = { "markdown" },
        },
      },
    })

    on_attach(nil, 0)
  end,
}
