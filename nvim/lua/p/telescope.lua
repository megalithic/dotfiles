-- https://github.com/nvim-telescope/telescope.nvim/blob/master/README.md#customization

local telescope = require "telescope"
local themes = require "telescope.themes"
local actions = require "telescope.actions"
local sorters = require "telescope.sorters"

local telescope_config = {
  prompt_prefix = " >",
  winblend = 0,
  preview_cutoff = 120,
  scroll_strategy = "cycle",
  layout_strategy = "horizontal",
  layout_defaults = {
    horizontal = {
      width_padding = 0.1,
      height_padding = 0.1,
      preview_width = 0.6
    },
    vertical = {
      width_padding = 0.05,
      height_padding = 1,
      preview_height = 0.5
    }
  },
  sorting_strategy = "descending",
  prompt_position = "bottom",
  color_devicons = true,
  mappings = {
    i = {
      ["<c-x>"] = false,
      ["<c-s>"] = actions.goto_file_selection_split
    }
  },
  borderchars = {
    {"─", "│", "─", "│", "╭", "╮", "╯", "╰"},
    preview = {"─", "│", "─", "│", "╭", "╮", "╯", "╰"}
  }
  -- file_sorter = sorters.get_fzy_sorter
}

telescope.setup({defaults = telescope_config})
-- telescope.setup {
--   defaults = {
--     prompt_prefix = " >",
--     winblend = 0,
--     preview_cutoff = 120,
--     scroll_strategy = "cycle",
--     layout_strategy = "horizontal",
--     layout_defaults = {
--       horizontal = {
--         width_padding = 0.1,
--         height_padding = 0.1,
--         preview_width = 0.6
--       },
--       vertical = {
--         width_padding = 0.05,
--         height_padding = 1,
--         preview_height = 0.5
--       }
--     },
--     sorting_strategy = "descending",
--     prompt_position = "bottom",
--     color_devicons = true,
--     mappings = {
--       i = {
--         ["<c-x>"] = false,
--         ["<c-s>"] = actions.goto_file_selection_split
--       }
--     },
--     borderchars = {
--       {"─", "│", "─", "│", "╭", "╮", "╯", "╰"},
--       preview = {"─", "│", "─", "│", "╭", "╮", "╯", "╰"}
--     },
--     file_sorter = sorters.get_fzy_sorter
--   }
-- }
