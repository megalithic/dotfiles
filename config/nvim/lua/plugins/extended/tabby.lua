-- REF: replace with latest syntax:
--
-- https://github.com/007Psycho007/dotfiles/blob/master/config/nvim/lua/user/tabby.lua
return {
  "nanozuki/tabby.nvim",
  event = { "BufReadPost" },
  dependencies = { "rktjmp/lush.nvim" },
  cond = not vim.g.started_by_firenvim and not vim.env.TMUX_POPUP,
  config = function()
    local SETTINGS = require("mega.settings")
    local icons = SETTINGS.icons
    local fmt = string.format

    vim.o.showtabline = 2
    -- function tab_modified(tab)
    --   local wins = require("tabby.module.api").get_tab_wins(tab)
    --   for _, x in pairs(wins) do
    --     if vim.bo[vim.api.nvim_win_get_buf(x)].modified then return "" end
    --   end
    --   return ""
    -- end

    -- function lsp_diag(buf)
    --   local diagnostics = vim.diagnostic.get(buf)
    --   local count = { 0, 0, 0, 0 }
    --
    --   for _, diagnostic in ipairs(diagnostics) do
    --     count[diagnostic.severity] = count[diagnostic.severity] + 1
    --   end
    --   if count[1] > 0 then
    --     return vim.bo[buf].modified and "" or ""
    --   elseif count[2] > 0 then
    --     return vim.bo[buf].modified and "" or ""
    --   end
    --   return vim.bo[buf].modified and "" or ""
    -- end

    -- function GetFileExtension(url) return url:match("^.+(%..+)$"):sub(2) end

    local theme = {
      fill = "TabFill",
      head = "TabLineHead",
      current_tab = "TabLineTabActive",
      current_win = "TabLineWinActive",
      inactive_tab = "TabLineInactive",
      inactive_win = "TabLineInactive",
      tab = "TabLine",
      win = "TabLineHead",
      tail = "TabLineHead",
    }

    local function tab_name(number, name, active)
      local icon = active and "" or ""

      return fmt(" %s:%s %s ", number, string.gsub(name, "%[..%]", ""), icon)
      -- return fmt(" %s %s ", number, icon)
    end

    local function win_name(name, active)
      local icon = active and "" or ""

      return fmt(" %s %s ", icon, name)
    end

    require("tabby.tabline").set(function(line)
      return {
        {
          { icons.misc.lblock, hl = theme.head },
        },
        line.tabs().foreach(function(tab)
          local hl = tab.is_current() and theme.current_tab or theme.inactive_tab
          return {
            -- line.sep(" ", hl, theme.fill),
            tab_name(tab.number(), tab.name(), tab.is_current()),
            hl = hl,
            margin = " ",
          }
        end),
        line.spacer(),
        line.wins_in_tab(line.api.get_current_tab()).foreach(function(win)
          local hl = win.is_current() and theme.current_win or theme.inactive_win
          return {
            -- line.sep(" ", hl, theme.fill),
            win_name(win.buf_name(), win.is_current()),
            hl = hl,
            margin = " ",
          }
        end),
        {
          { icons.misc.rblock, hl = theme.tail },
        },
        hl = theme.fill,
      }
    end)
  end,
}
