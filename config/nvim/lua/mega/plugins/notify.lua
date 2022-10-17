return function()
  local nnotify = require("notify")
  nnotify.setup({
    timeout = 3000,
    stages = "fade_in_slide_out",
    top_down = false,
    background_colour = "NotifyFloat",
    max_width = function() return math.floor(vim.o.columns * 0.8) end,
    max_height = function() return math.floor(vim.o.lines * 0.8) end,
    on_open = function(win)
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_set_config(win, { border = mega.get_border("NotifyFloat") })
      end
    end,
    render = function(...)
      local notif = select(2, ...)
      local style = notif.title[1] == "" and "minimal" or "default"
      require("notify.render")[style](...)
    end,
  })

  -- vim.notify = nnotify
end
