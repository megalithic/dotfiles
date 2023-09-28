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
          -- vim.api.nvim_buf_set_option(vim.api.nvim_win_get_buf(winnr), "filetype", "markdown")
          -- vim.cmd([[setlocal nospell]])
        end
      end,
      stages = "slide", -- or "static"
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

        local messages = { notif.message[1] }
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, messages)

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
      end,
    })

    -- HT: https://github.com/davidosomething/dotfiles/blob/dev/nvim/lua/dko/plugins/notify.lua#L32
    local notify_override = function(msg, level, opts)
      if not opts then opts = {} end
      if not opts.title then
        if mega.starts_with(msg, "[LSP]") then
          local client, found_client = msg:gsub("^%[LSP%]%[(.-)%] .*", "%1")
          if found_client > 0 then
            opts.title = ("LSP > %s"):format(client)
          else
            opts.title = "LSP"
          end
          msg = msg:gsub("^%[.*%] (.*)", "%1")
        elseif msg == "No code actions available" then
          -- https://github.com/neovim/neovim/blob/master/runtime/lua/vim/lsp/buf.lua#LL629C39-L629C39
          opts.title = "LSP"
        end
      end

      notify(msg, level, opts)
    end

    if not pcall(require, "plenary") then
      vim.notify = notify_override
    else
      local log = require("plenary.log").new({
        plugin = "notify",
        level = "debug",
        use_console = false,
        use_quickfix = false,
        use_file = false,
      })

      vim.notify = function(msg, level, opts)
        log.info(msg, level, opts)

        notify_override(msg, level, opts)
      end
    end
  end,
}
