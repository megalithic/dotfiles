return function()
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

    -- if active then
    --   return string.format(" %s %d: %s ", icon, number)
    -- else
    --   return string.format(" %s %d: %s ", icon, number, name)
    -- end

    return string.format(" %s %d: %s ", icon, number, tab_name)
  end

  local function win_label(winid, top)
    local icon = top and "" or ""
    return string.format(" %s %s ", icon, get_win_name(winid))
  end

  local function workspace_name()
    -- local ws_ok, ws = pcall(function() return require("workspaces").name() end)
    -- if ws_ok and ws then return ws end

    return vim.g.workspace or ""
  end

  local tabline = {
    hl = { fg = mega.colors.grey1.hex, bg = mega.colors.bg1.hex },
    layout = config.layout,
    head = {
      { mega.icons.misc.lblock, hl = { fg = mega.colors.bg1.hex, bg = mega.colors.bg2.hex } },
      {
        workspace_name(),
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

  require("tabby").setup({
    tabline = tabline,
  })
end
