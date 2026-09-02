-- Snacks picker layouts: static presets + dynamic layout functions

local presets = {
  small_no_preview = {
    cycle = true,
    layout = {
      box = "horizontal",
      width = 0.65,
      height = 0.6,
      border = "none",
      {
        box = "vertical",
        border = "rounded",
        title = "{title} {live} {flags}",
        { win = "input", height = 1, border = "bottom" },
        { win = "list", border = "none" },
      },
    },
  },

  wide_with_preview = {
    preset = "small_no_preview",
    layout = {
      width = 0.95,
      [2] = { win = "preview", title = "{preview}", border = "rounded", width = 0.5 },
    },
  },

  big_preview = {
    preset = "wide_with_preview",
    layout = { height = 0.8, [2] = { width = 0.6 } },
  },

  sidebar = {
    preview = "main",
    cycle = true,
    layout = {
      box = "vertical",
      position = "left",
      width = 0.3,
      min_width = 25,
      { win = "input", height = 1, border = "bottom" },
      { win = "list" },
      { win = "preview" },
    },
  },

  sidebar_no_input = {
    preview = "main",
    cycle = true,
    layout = {
      box = "vertical",
      position = "left",
      width = 0.3,
      min_width = 25,
      { win = "list" },
      { win = "preview" },
    },
  },

  sidebar_right = {
    preview = "main",
    cycle = true,
    layout = {
      box = "vertical",
      position = "right",
      width = 0.3,
      min_width = 25,
      { win = "input", height = 1, border = "bottom" },
      { win = "list" },
      { win = "preview" },
    },
  },

  ivy = {
    cycle = true,
    layout = {
      box = "vertical",
      position = "bottom",
      height = 0.4,
      border = "top",
      { box = "horizontal", { win = "input", height = 1, border = "bottom" } },
      {
        box = "horizontal",
        { win = "list", border = "none" },
        { win = "preview", title = "{preview}", width = 0.5, border = "left" },
      },
    },
  },

  flow = {
    cycle = true,
    layout = {
      box = "vertical",
      anchor = "SE",
      width = 0.5,
      height = 0.4,
      border = "rounded",
      row = -2,
      col = -2,
      { win = "input", height = 1, border = "bottom" },
      { win = "list", border = "none" },
    },
  },
}

local shared_buffer_opts = {
  preview = "main",
  layout = {
    box = "vertical",
    border = "solid",
    title = "{title} {live} {flags}",
    min_width = 50,
    min_height = 10,
    backdrop = false,
    { win = "preview", title = "{preview}", width = 0.6, border = "top" },
    { win = "input", height = 1, border = "single" },
    { win = "list", border = "none" },
  },
}

local function buffer_layout()
  local win = vim.api.nvim_get_current_win()
  local win_pos = vim.api.nvim_win_get_position(win)
  local win_width = vim.api.nvim_win_get_width(win)
  local win_height = vim.api.nvim_win_get_height(win)

  local picker_height = math.floor(0.25 * win_height)
  return vim.tbl_deep_extend("force", shared_buffer_opts, {
    layout = {
      col = win_pos[2],
      width = win_width - 2,
      row = win_pos[1] + win_height - picker_height - 1,
      height = picker_height,
    },
  })
end

local function smart_layout()
  local win = vim.api.nvim_get_current_win()
  local win_pos = vim.api.nvim_win_get_position(win)
  local win_width = vim.api.nvim_win_get_width(win)
  local win_height = vim.api.nvim_win_get_height(win)

  local picker_height = math.floor(0.25 * win_height)
  local row = win_pos[1] + win_height - picker_height - 1

  if win_width >= 165 then
    return vim.tbl_deep_extend("force", shared_buffer_opts, {
      layout = { width = 0.5, row = row, height = picker_height },
    })
  end
  return buffer_layout()
end

local function centered(opts)
  opts = opts or {}
  return {
    layout = {
      box = "horizontal",
      width = opts.width or 0.8,
      height = opts.height or 0.7,
      border = "rounded",
      { box = "vertical", border = "none", { win = "input", height = 1, border = "bottom" }, { win = "list", border = "none" } },
      { win = "preview", title = "{preview}", width = opts.preview_width or 0.5, border = "left" },
    },
  }
end

return {
  "folke/snacks.nvim",
  presets = presets,
  shared_buffer_opts = shared_buffer_opts,
  buffer_layout = buffer_layout,
  smart_layout = smart_layout,
  centered = centered,
}
