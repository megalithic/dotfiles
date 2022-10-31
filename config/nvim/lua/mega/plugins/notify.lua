return function()
  local nnotify = require("notify")
  nnotify.setup({
    timeout = 3000,
    stages = "fade_in_slide_out",
    top_down = false,
    style = "minimal",
    background_colour = "NotifyFloat",
    max_width = function() return math.floor(vim.o.columns * 0.8) end,
    max_height = function() return math.floor(vim.o.lines * 0.8) end,
    on_open = function(winnr)
      if vim.api.nvim_win_is_valid(winnr) then
        vim.api.nvim_win_set_config(winnr, { border = mega.get_border("NotifyFloat") })
        -- vim.api.nvim_buf_set_option(vim.api.nvim_win_get_buf(winnr), "filetype", "markdown")
      end
    end,
    render = function(bufnr, notif, hls)
      local ns = require("notify.render.base").namespace()
      vim.api.nvim_buf_set_lines(bufnr, 0, 1, false, { "" })
      vim.api.nvim_buf_set_extmark(bufnr, ns, 0, 0, {
        virt_text = {
          { notif.title[1], hls.title },
          { " ⋮ " },
          { notif.message[1], hls.body },
        },
        virt_text_win_col = 0,
        priority = 10,
      })
    end,
  })

  _G.mega.augroup("CloseNotify", {
    {
      event = { "VimLeavePre", "LspDetach" },
      command = function()
        local ok, n = mega.require("notify")
        if ok then n.dismiss() end
      end,
    },
  })

  vim.notify = nnotify
end
