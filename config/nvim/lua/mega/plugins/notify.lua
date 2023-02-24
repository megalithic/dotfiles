local M = {
  "rcarriga/nvim-notify",
  -- event = "VeryLazy",
  lazy = false,
  cond = vim.g.notifier_enabled and not vim.g.started_by_firenvim,
}

function M.config()
  local nnotify = require("notify")
  -- local stages_util = require("notify.stages.util")
  --
  -- local function initial(direction, opacity)
  --   return function(state)
  --     local next_height = state.message.height -- + 2
  --     local next_row = stages_util.available_slot(state.open_windows, next_height, direction)
  --     if not next_row then return nil end
  --     return {
  --       relative = "editor",
  --       anchor = "NE",
  --       width = state.message.width,
  --       height = state.message.height,
  --       col = vim.opt.columns:get(),
  --       row = next_row - 1,
  --       border = "",
  --       style = "minimal",
  --       opacity = opacity,
  --     }
  --   end
  -- end
  --
  -- local function stages(type, direction)
  --   type = type or "static"
  --   direction = stages_util[string.lower(direction)] or stages_util.DIRECTION.BOTTOM_UP
  --
  --   if type == "static" then
  --     return {
  --       initial(direction, 100),
  --       function()
  --         return {
  --           col = { vim.opt.columns:get() },
  --           time = true,
  --         }
  --       end,
  --     }
  --   elseif type == "fade_in_slide_out" then
  --     return {
  --       initial(direction, 0),
  --       function(state, win)
  --         return {
  --           opacity = { 100 },
  --           col = { vim.opt.columns:get() },
  --           row = {
  --             stages_util.slot_after_previous(win, state.open_windows, direction),
  --             frequency = 3,
  --             complete = function() return true end,
  --           },
  --         }
  --       end,
  --       function(state, win)
  --         return {
  --           col = { vim.opt.columns:get() },
  --           time = true,
  --           row = {
  --             stages_util.slot_after_previous(win, state.open_windows, direction),
  --             frequency = 3,
  --             complete = function() return true end,
  --           },
  --         }
  --       end,
  --       function(state, win)
  --         return {
  --           width = {
  --             1,
  --             frequency = 2.5,
  --             damping = 0.9,
  --             complete = function(cur_width) return cur_width < 3 end,
  --           },
  --           opacity = {
  --             0,
  --             frequency = 2,
  --             complete = function(cur_opacity) return cur_opacity <= 4 end,
  --           },
  --           col = { vim.opt.columns:get() },
  --           row = {
  --             stages_util.slot_after_previous(win, state.open_windows, direction),
  --             frequency = 3,
  --             complete = function() return true end,
  --           },
  --         }
  --       end,
  --     }
  --   end
  -- end
  --
  -- local base_stages = require("notify.stages.fade_in_slide_out")("bottom_up")
  nnotify.setup({
    timeout = 3000,
    top_down = false,
    background_colour = "NotifyFloat",
    -- max_width = function() return math.floor(vim.o.columns * 0.8) end,
    -- max_height = function() return math.floor(vim.o.lines * 0.8) end,
    -- on_open = function(winnr)
    --   if vim.api.nvim_win_is_valid(winnr) then
    --     vim.api.nvim_win_set_config(winnr, { border = "", focusable = false })
    --     vim.api.nvim_buf_set_option(vim.api.nvim_win_get_buf(winnr), "filetype", "markdown")
    --   end
    -- end,
    -- -- render = "minimal",
    -- -- stages = {
    -- --   function(...)
    -- --     local opts = base_stages[1](...)
    -- --     if opts then opts.border = "none" end
    -- --     return opts
    -- --   end,
    -- --   unpack(base_stages, 2),
    -- -- },
    -- stages = stages("static", "bottom_up"),
    -- render = function(bufnr, notif, hls, _cfg)
    --   local ns = require("notify.render.base").namespace()
    --   local title = (notif.title and mega.tlen(notif.title) > 0 and notif.title[1] ~= "") and notif.title[1] or "nvim"
    --   local message = notif.message[1] and notif.message[1] or ""
    --   dd(fmt("notify: %s", vim.inspect(notif)))
    --
    --   vim.api.nvim_buf_set_lines(bufnr, 0, 1, false, { "" })
    --   vim.api.nvim_buf_set_extmark(bufnr, ns, 0, 0, {
    --     virt_text = {
    --       { " " },
    --       { title, hls.title },
    --       { " ⋮ " },
    --       { message, hls.body },
    --     },
    --     virt_text_win_col = 0,
    --     priority = 10,
    --   })
    -- end,
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

return M
