return function()
  local config = {
    layout = "active_wins_at_tail",
  }

  -- NOTE: these are deprecated..
  local filename = require("tabby.filename")
  local util = require("tabby.util")

  local function get_win_name(winid)
    local bufid = vim.api.nvim_win_get_buf(winid)
    local ft = vim.api.nvim_buf_get_option(bufid, "filetype")

    if ft == "megaterm" then
      return "megaterm"
    else
      return filename.unique(winid)
    end
  end

  local function tab_label(tabid, active)
    local icon = active and "" or ""
    local number = vim.api.nvim_tabpage_get_number(tabid)

    if active then
      return string.format(" %s %d ", icon, number)
    else
      local name = util.get_tab_name(tabid)
      return string.format(" %s %d: %s ", icon, number, name)
    end
  end

  local function win_label(winid, top)
    local icon = top and "" or ""
    return string.format(" %s %s ", icon, get_win_name(winid))
  end

  local tabline = {
    hl = { fg = mega.colors.grey1.hex, bg = mega.colors.bg1.hex },
    layout = config.layout,
    head = {
      { mega.icons.misc.lblock, hl = { fg = mega.colors.bg1.hex, bg = mega.colors.bg2.hex } },
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

  require("tabby").setup({
    tabline = tabline,
  })
end
