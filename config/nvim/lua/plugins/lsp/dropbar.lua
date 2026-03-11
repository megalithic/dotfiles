return {
  -- cond = not require("modes").minimal_mode,
  "Bekaboo/dropbar.nvim",
  lazy = false,
  cond = false,
  init = function()
    -- local color_utils = require("utils.colors")
    -- color_utils.register_color_update(function()
    --   local fg = vim.api.nvim_get_hl(0, { name = "Normal" }).fg
    --   local winbar_fg = color_utils.blend_bg(fg, 0.9)
    --   local winbarnc_fg = color_utils.blend_bg(fg, 0.7)
    --   vim.api.nvim_set_hl(0, "WinBar", { fg = winbar_fg, bold = true })
    --   vim.api.nvim_set_hl(0, "WinBarNC", { fg = winbarnc_fg })
    -- end)
  end,
  opts = {
    sources = {
      path = {
        modified = function(sym)
          if sym then
            return sym:merge({
              icon = "● ",
              name_hl = "DiffAdded",
              icon_hl = "DiffAdded",
            })
          end
        end,
      },
    },
    bar = {
      enable = function(buf, win, _)
        if
          not vim.api.nvim_buf_is_valid(buf)
          or not vim.api.nvim_win_is_valid(win)
          or vim.fn.win_gettype(win) ~= ""
          or vim.wo[win].winbar ~= ""
          or vim.bo[buf].ft == "help"
          -- sindrets/diffview.nvim
          or vim.bo[buf].ft == "DiffviewFiles"
          -- folke/snacks.nvim
          or vim.bo[buf].ft == "bigfile"
          or vim.bo[buf].ft == "snacks_picker_preview"
          -- folke/noice.nvim
          or vim.bo[buf].ft == "noice"
          -- NickvanDyke/opencode.nvim
          or vim.bo[buf].ft == "opencode_terminal"
          or vim.bo[buf].ft == "megaterm"
          or vim.bo[buf].ft == "pi"
        then
          return false
        end
        return true
      end,
    },
  },
}
