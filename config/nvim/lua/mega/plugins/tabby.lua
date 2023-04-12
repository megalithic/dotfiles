-- REF: replace with latest syntax:
--
-- https://github.com/007Psycho007/dotfiles/blob/master/config/nvim/lua/user/tabby.lua
local M = {
  "nanozuki/tabby.nvim",
  event = { "BufReadPost" },
  dependencies = { "rktjmp/lush.nvim" },
  cond = not vim.g.started_by_firenvim,
}

function M.config()
  --
  --
  -- [ V2 ] --------------------------------------------------------------------
  --
  --
  vim.o.showtabline = 2
  function tab_name(tab) return string.gsub(tab, "%[..%]", "") end

  function tab_modified(tab)
    local wins = require("tabby.module.api").get_tab_wins(tab)
    for _, x in pairs(wins) do
      if vim.bo[vim.api.nvim_win_get_buf(x)].modified then return "" end
    end
    return ""
  end

  function lsp_diag(buf)
    local diagnostics = vim.diagnostic.get(buf)
    local count = { 0, 0, 0, 0 }

    for _, diagnostic in ipairs(diagnostics) do
      count[diagnostic.severity] = count[diagnostic.severity] + 1
    end
    if count[1] > 0 then
      return vim.bo[buf].modified and "" or ""
    elseif count[2] > 0 then
      return vim.bo[buf].modified and "" or ""
    end
    return vim.bo[buf].modified and "" or ""
  end

  function GetFileExtension(url) return url:match("^.+(%..+)$"):sub(2) end

  local theme = {
    fill = "TabFill",
    head = "TabLineHead",
    current_tab = "TabLineSel",
    inactive_tab = "TabLineIn",
    tab = "TabLine",
    win = "TabLineHead",
    tail = "TabLineHead",
  }

  if false then
    require("tabby.tabline").set(function(line)
      return {
        {
          { mega.icons.misc.lblock, hl = theme.head },
          line.sep(" ", theme.head, theme.fill),
        },
        line.tabs().foreach(function(tab)
          local hl = tab.is_current() and theme.current_tab or theme.inactive_tab
          return {
            line.sep(" ", hl, theme.fill),
            tab.number(),
            " ",
            tab_name(tab.name()),
            " ",
            tab_modified(tab.id),
            line.sep(" ", hl, theme.fill),
            hl = hl,
            margin = " ",
          }
        end),
        line.spacer(),
        line.wins_in_tab(line.api.get_current_tab()).foreach(
          function(win)
            return {
              line.sep(" ", theme.win, theme.fill),
              win.is_current() and "" or "",
              win.buf_name(),
              line.sep(" ", theme.win, theme.fill),
              hl = theme.win,
              margin = " ",
            }
          end
        ),
        {
          line.sep(" ", theme.tail, theme.fill),
          { mega.icons.misc.rblock, hl = theme.tail },
        },
        hl = theme.fill,
      }
    end)
  end
  --
  --
  -- [ V1 ] --------------------------------------------------------------------
  --
  --
  local config = {
    layout = "active_wins_at_tail",
  }

  local special = {
    ["megaterm"] = "megaterm",
  }

  -- NOTE: these are deprecated..
  local filename = require("tabby.filename")
  local util = require("tabby.util")

  local function get_special_name_for_win(winid, name)
    local bufid = vim.api.nvim_win_get_buf(winid)
    local ft = vim.api.nvim_buf_get_option(bufid, "filetype")

    return special[ft] or name or filename.unique(winid)
  end

  local function get_win_name(winid, name) return get_special_name_for_win(winid, name) end

  local function tab_label(tabid, active)
    local icon = active and "" or ""
    local number = vim.api.nvim_tabpage_get_number(tabid)
    local name = util.get_tab_name(tabid)

    local tab_name = get_special_name_for_win(vim.api.nvim_tabpage_get_win(tabid), name)

    if active then
      return string.format(" %s %d:%s ", icon, number, tab_name)
    else
      return string.format(" %s %d:%s ", icon, number, mega.icons.misc.ellipsis)
    end
  end

  local function win_label(winid, top)
    local icon = top and "" or ""
    return string.format(" %s %s ", icon, get_win_name(winid))
  end

  local tabline = {
    hl = { fg = mega.colors.grey1.hex, bg = mega.colors.bg_dark.hex },
    layout = config.layout,
    head = {
      { mega.icons.misc.lblock, hl = { fg = mega.colors.bg1.hex, bg = mega.colors.bg2.hex } },
      {
        "",
        hl = { fg = mega.colors.grey2.hex, bg = mega.colors.bg2.hex },
      },
    },
    active_tab = {
      label = function(tabid)
        return {
          tab_label(tabid, true),
          hl = { fg = mega.colors.green.hex, bg = mega.colors.bg0.hex, style = "bold" },
        }
      end,
    },
    inactive_tab = {
      label = function(tabid)
        return {
          tab_label(tabid),
          hl = { fg = mega.colors.grey2.hex, bg = mega.colors.bg1.hex },
        }
      end,
    },
    top_win = {
      label = function(winid)
        return {
          win_label(winid, true),
          hl = { fg = mega.colors.green.hex, bg = mega.colors.bg0.hex, style = "italic" },
        }
      end,
    },
    win = {
      label = function(winid)
        return {
          win_label(winid),
          hl = { fg = mega.colors.grey1.hex, bg = mega.colors.bg1.hex },
        }
      end,
    },
    tail = {
      { mega.icons.misc.rblock, hl = { fg = mega.colors.bg1.hex, bg = mega.colors.bg2.hex } },
    },
  }

  if true then require("tabby").setup({ tabline = tabline }) end
end

return M
