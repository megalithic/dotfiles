return {
  "stevearc/oil.nvim",
  -- event = "VeryLazy",
  lazy = false,
  cmd = { "Oil" },
  config = function()
    local SETTINGS = require("config.options")
    local icons = SETTINGS.icons
    local icon_file = vim.trim(icons.kind.File)
    local icon_dir = vim.trim(icons.kind.Folder)
    local permission_hlgroups = setmetatable({
      ["-"] = "OilPermissionNone",
      ["r"] = "OilPermissionRead",
      ["w"] = "OilPermissionWrite",
      ["x"] = "OilPermissionExecute",
    }, {
      __index = function() return "OilDir" end,
    })

    local type_hlgroups = setmetatable({
      ["-"] = "OilTypeFile",
      ["d"] = "OilTypeDir",
      ["f"] = "OilTypeFifo",
      ["l"] = "OilTypeLink",
      ["s"] = "OilTypeSocket",
    }, {
      __index = function() return "OilTypeFile" end,
    })

    require("oil").setup({
      delete_to_trash = true,
      default_file_explorer = true,
      skip_confirm_for_simple_edits = true,
      -- trash_command = "trash-cli",
      prompt_save_on_select_new_entry = false,
      use_default_keymaps = false,
      is_always_hidden = function(name, _bufnr) return name == ".." end,
      -- columns = {
      --   "icon",
      --   -- "permissions",
      --   -- "size",
      --   -- "mtime",
      -- },

      columns = {
        {
          "type",
          icons = {
            directory = "d",
            fifo = "f",
            file = "-",
            link = "l",
            socket = "s",
          },
          highlight = function(type_str) return type_hlgroups[type_str] end,
        },
        {
          "permissions",
          highlight = function(permission_str)
            local hls = {}
            for i = 1, #permission_str do
              local char = permission_str:sub(i, i)
              table.insert(hls, { permission_hlgroups[char], i - 1, i })
            end
            return hls
          end,
        },
        { "size", highlight = "Special" },
        { "mtime", highlight = "Number" },
        {
          "icon",
          default_file = icon_file,
          directory = icon_dir,
          add_padding = false,
        },
      },
      view_options = {
        show_hidden = true,
      },
      keymaps = {
        ["<C-y>"] = "actions.yank_entry",
        ["g?"] = "actions.show_help",
        ["gs"] = "actions.change_sort",
        ["gx"] = "actions.open_external",
        ["g."] = "actions.toggle_hidden",
        ["gd"] = {
          desc = "Toggle detail view",
          callback = function()
            local oil = require("oil")
            local config = require("oil.config")
            if #config.columns == 1 then
              oil.set_columns({ "icon", "permissions", "size", "mtime" })
            else
              oil.set_columns({ "type", "icon" })
            end
          end,
        },
        ["gr"] = {
          callback = function()
            -- get the current directory
            local prefills = { paths = oil.get_current_dir() }

            local grug_far = require("grug-far")
            -- instance check
            if not grug_far.has_instance("explorer") then
              grug_far.open({
                instanceName = "explorer",
                prefills = prefills,
                staticTitle = "Find and Replace from Explorer",
              })
            else
              grug_far.get_instance("explorer"):open()
              -- updating the prefills without clearing the search and other fields
              grug_far.get_instance("explorer"):update_input_values(prefills, false)
            end
          end,
          desc = "oil: Search in directory",
        },
        ["<CR>"] = "actions.select",
        ["gp"] = function()
          local oil = require("oil")
          local entry = oil.get_cursor_entry()
          if entry["type"] == "file" then
            local dir = oil.get_current_dir()
            local fileName = entry["name"]
            local fullName = dir .. fileName

            require("config.utils").preview_file(fullName)
          else
            return ""
          end
        end,
      },
    })
  end,

  keys = {
    {
      "<leader>ev",
      function()
        -- vim.cmd([[vertical rightbelow split|vertical resize 60]])
        vim.cmd([[vertical rightbelow split]])
        require("oil").open()
      end,
      desc = "[e]xplore cwd -> oil ([v]split)",
    },
    {
      "<leader>ee",
      function() require("oil").open() end,
      desc = "[e]xplore cwd -> oil ([e]dit)",
    },
  },
}
