-- REF: https://github.com/rcarriga/nvim-notify/wiki/Usage-Recipes
return {
  "rcarriga/nvim-notify",
  event = "VeryLazy",
  cond = vim.g.notifier_enabled and not vim.g.started_by_firenvim,
  config = function()
    local notify = require("notify")
    local base = require("notify.render.base")

    notify.setup({
      timeout = 3000,
      top_down = false,
      background_colour = "NotifyFloat",
      max_width = function() return math.floor(vim.o.columns * 0.8) end,
      max_height = function() return math.floor(vim.o.lines * 0.8) end,
      on_open = function(winnr)
        if vim.api.nvim_win_is_valid(winnr) then
          vim.api.nvim_win_set_config(winnr, { border = "", focusable = false })
          vim.api.nvim_buf_set_option(vim.api.nvim_win_get_buf(winnr), "filetype", "markdown")
        end
      end,
      stages = "slide",
      -- render = "compact",
      render = function(bufnr, notif, hls, cfg)
        local ns = base.namespace()
        local icon = notif.icon or "" -- » notif.icon
        local title = notif.title[1]

        local prefix
        if type(title) == "string" and #title > 0 then
          prefix = string.format("%s %s", icon, title)
        else
          prefix = string.format("%s", icon)
        end

        -- notif.message[1] = string.format("%s %s ", prefix, notif.message[1])

        local messages = { notif.message[1] }
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, messages)

        -- local icon_length = vim.str_utfindex(icon)
        -- local prefix_length = vim.str_utfindex(prefix)
        --
        -- vim.api.nvim_buf_set_extmark(bufnr, ns, 0, 0, {
        --   hl_group = hls.icon,
        --   end_col = icon_length + 1,
        --   priority = 50,
        -- })
        -- vim.api.nvim_buf_set_extmark(bufnr, ns, 0, icon_length + 1, {
        --   hl_group = hls.title,
        --   end_col = prefix_length + 2,
        --   priority = 50,
        -- })
        -- vim.api.nvim_buf_set_extmark(bufnr, ns, 0, prefix_length + 2, {
        --   hl_group = hls.body,
        --   end_line = #messages,
        --   priority = 50,
        -- })
        -- vim.api.nvim_buf_set_lines(bufnr, 0, 1, false, { "" })
        vim.api.nvim_buf_set_extmark(bufnr, ns, 0, 0, {
          virt_text = {
            { " " },
            { prefix, hls.title },
            { " ⋮ " },
            { messages[1], hls.body },
            { " " },
          },
          virt_text_win_col = 0,
          priority = 10,
        })
        -- local max_message_width =
        --   math.max(math.max(unpack(vim.tbl_map(function(line) return vim.fn.strchars(line) end, notif.message))))
        -- local title = notif.title[1]
        -- local title_accum = vim.str_utfindex(title)
        --
        -- local title_buffer =
        --   string.rep(" ", (math.max(max_message_width, title_accum, config.minimum_width()) - title_accum) / 2)
        -- vim.api.nvim_buf_set_lines(bufnr, 0, 1, false, { "", "" })
        -- vim.api.nvim_buf_set_extmark(bufnr, namespace, 0, 0, {
        --   virt_text = {
        --     { title_buffer .. title .. title_buffer, highlights.title },
        --   },
        --   virt_text_win_col = 0,
        --   priority = 10,
        -- })
        -- vim.api.nvim_buf_set_extmark(bufnr, namespace, 1, 0, {
        --   virt_text = {
        --     {
        --       string.rep("━", math.max(max_message_width, title_accum, config.minimum_width())),
        --       highlights.border,
        --     },
        --   },
        --   virt_text_win_col = 0,
        --   priority = 10,
        -- })
        -- vim.api.nvim_buf_set_lines(bufnr, 2, -1, false, notif.message)
        --
        -- vim.api.nvim_buf_set_extmark(bufnr, namespace, 2, 0, {
        --   hl_group = highlights.body,
        --   end_line = 1 + #notif.message,
        --   end_col = #notif.message[#notif.message],
        --   priority = 50,
        -- })
      end,
    })

    vim.notify = notify
  end,
}
