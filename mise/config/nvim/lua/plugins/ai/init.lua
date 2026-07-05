-- HT: @jesseleite
-- TODO: Temporary workaround for `exit_visual` not working
-- https://github.com/polacekpavel/prompt-yank.nvim/issues/10
local exit_visual_mode = function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
end

return {
  {
    "polacekpavel/prompt-yank.nvim",
    lazy = false,
    opts = {
      keymaps = false,
      exit_visual = true, -- TODO: Custom keymaps don't respect this config?
    },
    keys = {
      {
        "<localleader>yp",
        function()
          require("prompt-yank").yank_selection({ from_visual = true })
          exit_visual_mode()
        end,
        mode = "v",
        desc = "Yank selection for LLM",
      },
      {
        "<localleader>Yp",
        function()
          require("prompt-yank").yank_diagnostics({ from_visual = true })
          exit_visual_mode()
        end,
        mode = "v",
        desc = "Yank selection with diagnostics for LLM",
      },
    },
  },
}
