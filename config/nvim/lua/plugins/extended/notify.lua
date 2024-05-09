-- REF: https://github.com/rcarriga/nvim-notify/wiki/Usage-Recipes
return {
  {
    "echasnovski/mini.notify",
    event = "VeryLazy",
    cond = false,
    config = function()
      local win_config = function()
        local has_statusline = vim.o.laststatus > 0
        local bottom_space = vim.o.cmdheight + (has_statusline and 1 or 0)
        return { anchor = "SE", col = vim.o.columns, row = vim.o.lines - bottom_space, border = "none" }
      end
      require("mini.notify").setup({ window = { config = win_config } })
    end,
  },
  {
    "rcarriga/nvim-notify",
    event = "VeryLazy",
    cond = vim.g.notifier_enabled and not vim.g.started_by_firenvim,
    config = function()
      local notify = require("notify")
      local base = require("notify.render.base")
      local U = require("mega.utils")
      local SETTINGS = require("mega.settings")
      local icons = SETTINGS.icons

      -- local stages_util = require("notify.stages.util")
      -- local function initial(direction, opacity)
      --   return function(state)
      --     local next_height = state.message.height + 1 -- + 2
      --     local next_row = stages_util.available_slot(state.open_windows, next_height, direction)
      --     if not next_row then return nil end
      --     return {
      --       relative = "editor",
      --       anchor = "NE",
      --       width = state.message.width,
      --       height = state.message.height,
      --       col = vim.opt.columns:get(),
      --       row = next_row,
      --       border = "none",
      --       style = "minimal",
      --       opacity = opacity,
      --     }
      --   end
      -- end
      -- local function stages(type, direction)
      --   type = type or "static"
      --   direction = stages_util[string.lower(direction)] or stages_util.DIRECTION.BOTTOM_UP
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

      local function stages(type)
        type = type or "static"
        local stages_util = require("notify.stages.util")
        local direction = stages_util.DIRECTION.BOTTOM_UP
        -- local direction = stages_util[string.lower(direction)] or stages_util.DIRECTION.BOTTOM_UP

        if type == "static" then
          local function initial(direction, opacity)
            return function(state)
              local next_height = state.message.height + 1 -- + 2
              local next_row = stages_util.available_slot(state.open_windows, next_height, direction)
              if not next_row then return nil end
              return {
                relative = "editor",
                anchor = "NE",
                width = state.message.width,
                height = state.message.height,
                col = vim.opt.columns:get(),
                row = next_row,
                border = "none",
                style = "minimal",
                opacity = opacity,
              }
            end
          end
          return {
            initial(direction, 100),
            function()
              return {
                col = { vim.opt.columns:get() },
                time = true,
              }
            end,
          }
        end

        return {
          function(state)
            local width = state.message.width or 1
            -- local next_height = state.message.height + 1
            local next_height = #state.open_windows == 0 and state.message.height + 1 or 1
            local next_row = stages_util.available_slot(state.open_windows, next_height, direction)
            if not next_row then return nil end
            return {
              relative = "editor",
              anchor = "NE",
              width = width,
              height = state.message.height,
              col = vim.opt.columns:get(),
              row = next_row,
              border = "none",
              style = "minimal",
              opacity = type == "fade" and 0 or 100,
            }
          end,
          function(state)
            return {
              opacity = type == "fade" and { 100 } or { 100 },
              width = { state.message.width, frequency = 2 },
              col = { vim.opt.columns:get() },
            }
          end,
          function()
            return {
              col = { vim.opt.columns:get() },
              time = true,
            }
          end,
          function()
            return {
              width = {
                1,
                frequency = 2.5,
                damping = 0.9,
                complete = function(cur_width) return cur_width < 2 end,
              },
              opacity = type == "fade" and {
                0,
                frequency = 2,
                complete = function(cur_opacity) return cur_opacity <= 4 end,
              } or { 100 },
              col = { vim.opt.columns:get() },
            }
          end,
        }
      end

      notify.setup({
        timeout = 3000,
        top_down = false,
        background_colour = "NotifyBackground",
        max_width = function() return math.floor(vim.o.columns * 0.8) end,
        max_height = function() return math.floor(vim.o.lines * 0.8) end,
        on_open = function(winnr)
          if vim.api.nvim_win_is_valid(winnr) then
            -- vim.api.nvim_win_set_config(winnr, { border = "", focusable = false })
            local buf = vim.api.nvim_win_get_buf(winnr)
            vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
            -- vim.cmd([[setlocal nospell]])
          end
        end,
        -- stages = "slide", -- alts: "static", "slide"
        stages = stages("slide"), -- alts: "static", "slide", "fade"
        -- render = "compact",
        render = function(bufnr, notif, hls, cfg)
          -- local namespace = base.namespace()
          -- vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, notif.message)
          --
          -- vim.api.nvim_buf_set_extmark(bufnr, namespace, 0, 0, {
          --   hl_group = hls.icon,
          --   end_line = #notif.message - 1,
          --   end_col = #notif.message[#notif.message],
          --   priority = 50,
          -- })

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
          if U.starts_with(msg, "[LSP]") then
            local client, found_client = msg:gsub("^%[LSP%]%[(.-)%] .*", "%1")
            if found_client > 0 then
              opts.title = ("LSP %s %s"):format(icons.misc.caret_right, client)
            else
              opts.title = "LSP"
            end
            msg = msg:gsub("^%[.*%] (.*)", "%1")
          elseif msg == "No code actions available" then
            -- https://github.com/neovim/neovim/blob/master/runtime/lua/vim/lsp/buf.lua#LL629C39-L629C39
            opts.title = "LSP"
          end
          -- opts.render = "wrapped-compact"
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
  },
}
