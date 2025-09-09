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
  "zk-org/zk-nvim",
  cond = vim.g.note_taker == "zk",
  event = "VeryLazy",
  config = function()
    local ok, zk = pcall(require, "zk")
    if not ok then return end

    local function on_attach(client, bufnr)
      if client.name == "zk" and require("zk.util").notebook_root(vim.fn.expand("%:p")) ~= nil then
        vim.diagnostic.config({ signs = false, underline = false })

        local command = vim.api.nvim_create_user_command
        local zk_command = require("zk.commands")

        local function zkc(cmd, opts)
          local zk_cmd = zk_command.get(cmd)
          if zk_cmd then
            zk_cmd(opts)
          else
            if type(opts) == "function" then zk_command.add(cmd, opts) end
          end
        end

        -- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
        -- HELPERS
        -- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
        local function pick(opts)
          local default_style = mega.picker.ivy
          if default_style ~= nil then
            return default_style(opts)
          else
            return opts
          end
        end

        local desc = function(desc) return { desc = desc, silent = true, buffer = bufnr } end

        local function make_edit_fn(defaults, picker_options)
          return function(options)
            options = vim.tbl_extend("force", defaults, options or {})
            zk.edit(options, pick(picker_options))
          end
        end

        local function make_new_fn(defaults, picker_options)
          return function(options)
            options = vim.tbl_extend("force", defaults, options or {})
            zk.new(options, pick(picker_options))
          end
        end

        local function get_notes(...)
          if vim.g.picker == "fzf_lua" then return zk_command.get("ZkNotes")(...) end
          return require("telescope").extensions.zk.notes(pick(...))
        end

        local function get_tags(...)
          if vim.g.picker == "fzf_lua" then return zk_command.get("ZkTags")(...) end
          return require("telescope").extensions.zk.tags(pick(...))
        end

        -- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
        -- COMMANDS
        -- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
        command("ZkToday", function(_) zkc("ZkNew", { dir = "log/daily" }) end, { desc = "zk: opens or creates zk note for today" })
        command("ZkLog", function(_) get_notes({ hrefs = { "log" }, sort = { "created" } }) end, { desc = "zk: list all the zk log notes" })
        command("ZkMultiTags", function(opts)
          get_tags(opts, pick({ title = "zk multi tags" }), function(tags)
            tags = vim.tbl_map(function(v) return v.name end, tags)
            get_notes({ tags = tags }, pick({ title = "zk notes for tag(s) " .. vim.inspect(tags), multi_select = true }), function(notes)
              local cmd = "args"
              for _, note in ipairs(notes) do
                cmd = cmd .. " " .. note.absPath
              end
              vim.cmd(cmd)
            end)
          end)
        end, { nargs = "?", force = true, complete = "lua" })

        zkc("ZkMyBacklinks", function(options)
          options = vim.tbl_extend("force", { linkTo = { vim.api.nvim_buf_get_name(0) } }, options or {})
          local picker_options = pick({
            title = "zk backlinks",
            fzf_options = { "--select-1" },
          })

          local parent_filename = vim.api.nvim_buf_get_name(0):match(".*/(.*).md$")

          require("zk").pick_notes(options, picker_options, function(notes)
            for _, note in ipairs(notes) do
              vim.cmd("e " .. note.absPath)
              vim.cmd("/(" .. parent_filename .. ")")
            end
          end)
        end)

        zkc("ZkOrphans", make_edit_fn({ orphan = true }, { title = "zk: orphans" }))
        zkc("ZkRecents", make_edit_fn({ sort = { "modified" }, createdAfter = "1 week ago" }, { title = "zk: recents" }))
        -- zkc(
        --   "ZkInsertLink",
        --   make_edit_fn(
        --     { matchSelected = true, select = {
        --       "title",
        --       "absPath",
        --       "path",
        --       "metadata",
        --     } },
        --     mega.picker.ivy
        --   )
        -- )

        -- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
        -- KEYMAPS
        -- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
        -- FIXME:
        -- Needs working mappings..
        --
        -- REFS:
        -- https://github.com/kirasok/nvchad/blob/main/mappings/zk-nvim.lua
        -- https://github.com/vicrdguez/dotfiles/blob/main/dot_config/nvim/lua/plugins/notes.lua#L27
        vim.keymap.set("n", "gd", require("telescope.builtin").lsp_definitions, { desc = "[g]oto [d]efinition (follow link)", noremap = false })
        vim.keymap.set("n", "gr", "<cmd>ZkBacklinks<CR>", { desc = "[g]oto [r]eferences (backlinks)", noremap = false })
        vim.keymap.set("n", "gt", "<cmd>ZkTags<CR>", { desc = "[g]oto [t]ags (references)", noremap = false })
        vim.keymap.set("i", "[[", "<cmd>ZkInsertLink<CR>", { desc = "[[link references]]" })
      end
    end

    zk.setup({
      picker = vim.g.picker,
      lsp = {
        config = {
          cmd = { "zk", "lsp" },
          name = "zk",
          on_attach = on_attach,
        },
        auto_attach = {
          enabled = true,
          filetypes = { "markdown" },
        },
      },
    })

    -- mega.lsp.on_attach(on_attach)
  end,
}
