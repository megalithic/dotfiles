local telescope = require "telescope"
local themes = require "telescope.themes"

-- Telescope defaults
local telescope_config = {
  selection_strategy = "reset",
  shorten_path = true,
  layout_strategy = "flex",
  prompt_position = "top",
  sorting_strategy = "ascending",
  winblend = 3,
  prompt_prefix = "※",
  width = 0.8, 
  height = 0.7,
  results_width = 80
}

telescope.setup({ defaults = telescope_config })

function FindFiles()
  require('plenary.reload').reload_module('telescope')
  local theme = themes.get_dropdown{ winblend = 10, results_height = 10 }
  require"telescope.builtin".find_files(theme)
end
