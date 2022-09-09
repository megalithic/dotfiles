return function()
  local api = vim.api
  local gs = require("golden_size")

  -- local function ignore_by(type, types)
  --   local t = api.nvim_buf_get_option(api.nvim_get_current_buf(), type)
  --   for _, type in pairs(types) do
  --     if type == t then
  --       return 1
  --     end
  --   end
  -- end

  local function ignore_by_buftype(types)
    local bt = api.nvim_buf_get_option(api.nvim_get_current_buf(), "buftype")
    for _, type in pairs(types) do
      if type == bt then return 1 end
    end
  end

  local function ignore_by_filetype(types)
    local ft = api.nvim_buf_get_option(api.nvim_get_current_buf(), "filetype")
    for _, type in pairs(types) do
      if type == ft then return 1 end
    end
  end

  gs.set_ignore_callbacks({
    {
      ignore_by_filetype,
      {
        "help",
        "terminal",
        "megaterm",
        "dirbuf",
        "Trouble",
        "qf",
        "neo-tree",
      },
    },
    {
      ignore_by_buftype,
      {
        "help",
        "acwrite",
        "Undotree",
        "quickfix",
        "nerdtree",
        "current",
        "Vista",
        "Trouble",
        "LuaTree",
        "NvimTree",
        "terminal",
        "dirbuf",
        "tsplayground",
        "neo-tree",
      },
    },
    { gs.ignore_float_windows }, -- default one, ignore float windows
    { gs.ignore_by_window_flag }, -- default one, ignore windows with w:ignore_gold_size=1
  })
end
