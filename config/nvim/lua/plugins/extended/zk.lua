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
    local on_attach = function(_client, bufnr)
      local command = vim.api.nvim_create_user_command
      zk.command = require("zk.commands")

      -- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      -- HELPERS
      -- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      local picker_style = mega.picker.ivy
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
      command("ZkToday", function(_) zk.command.get("ZkNew")({ dir = "log/daily" }) end, { desc = "zk: opens or creates zk note for today" })
      command("ZkLog", function(_) get_notes({ hrefs = { "log" }, sort = { "created" } }) end, { desc = "zk: list all the zk log notes" })
      zk.command.add("ZkMultiTags", function(opts)
        get_tags(opts, { title = "zk tags" }, function(tags)
          tags = vim.tbl_map(function(v) return v.name end, tags)
          get_notes({ tags = tags }, { title = "Zk Notes for tag(s) " .. vim.inspect(tags), multi_select = true }, function(notes)
            local cmd = "args"
            for _, note in ipairs(notes) do
              cmd = cmd .. " " .. note.absPath
            end
            vim.cmd(cmd)
          end)
        end)
      end, { nargs = "?", force = true, complete = "lua" })

      zk.command.add("ZkOrphans", make_edit_fn({ orphan = true }, { title = "zk: orphans" }))
      zk.command.add("ZkRecents", make_edit_fn({ sort = { "modified" }, createdAfter = "1 week ago" }, { title = "zk: recents" }))
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
