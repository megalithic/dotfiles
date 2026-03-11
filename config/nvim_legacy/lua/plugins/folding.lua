if true then
  return {}
end

return {
  -- { -- QoL features for folding
  --   "chrisgrieser/nvim-origami",
  --   event = "VeryLazy",
  --   opts = true,
  -- },
  { -- use LSP as folding provider
    "kevinhwang91/nvim-ufo",
    -- cond = vim.o.foldlevel > 0 and vim.o.foldmethod ~= "manual",
    enabled = false,
    dependencies = "kevinhwang91/promise-async",
    event = "UIEnter", -- needed for folds to load in time and comments being closed
    keys = {
      { "z?", vim.cmd.UfoInspect, desc = "󱃄 :UfoInspect" },
      {
        "zm",
        function()
          require("ufo").closeAllFolds()
        end,
        desc = "󱃄 Close All Folds",
      },
      {
        "zr",
        function()
          require("ufo").openFoldsExceptKinds({ "comment", "imports" })
        end,
        desc = "󱃄 Open Regular Folds",
      },
      {
        "z1",
        function()
          require("ufo").closeFoldsWith(1)
        end,
        desc = "󱃄 Close L1 Folds",
      },
      {
        "z2",
        function()
          require("ufo").closeFoldsWith(2)
        end,
        desc = "󱃄 Close L2 Folds",
      },
      {
        "z3",
        function()
          require("ufo").closeFoldsWith(3)
        end,
        desc = "󱃄 Close L3 Folds",
      },
    },
    init = function()
      -- INFO fold commands usually change the foldlevel, which fixes folds, e.g.
      -- auto-closing them after leaving insert mode, however ufo does not seem to
      -- have equivalents for zr and zm because there is no saved fold level.
      -- Consequently, the vim-internal fold levels need to be disabled by setting
      -- them to 99.
      vim.opt.foldlevel = 99
      vim.opt.foldlevelstart = 99
    end,
    opts = {
      -- when opening the buffer, close these fold kinds
      close_fold_kinds_for_ft = {
        default = { "imports", "comment" },
        json = { "array" },
        -- use `:UfoInspect` to get see available fold kinds
      },
      open_fold_hl_timeout = 800,
      provider_selector = function(_, ft, buftype)
        -- PERF disable folds on `log`, and only use `indent` for `bib` files
        if vim.tbl_contains({ "log", "ghostty", "conf", "tmux" }, ft) then
          return ""
        end
        -- ufo accepts only two kinds as priority, see https://github.com/kevinhwang91/nvim-ufo/issues/256
        if ft == "" or buftype ~= "" or vim.startswith(ft, "git") or ft == "applescript" then
          return "indent"
        end
        return { "lsp", "treesitter" }
      end,
      -- show folds with number of folded lines instead of just the icon
      fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
        local hlgroup = "NonText"
        local icon = ""
        local newVirtText = {}
        local suffix = ("  %s %d"):format(icon, endLnum - lnum)
        local sufWidth = vim.fn.strdisplaywidth(suffix)
        local targetWidth = width - sufWidth
        local curWidth = 0
        for _, chunk in ipairs(virtText) do
          local chunkText = chunk[1]
          local chunkWidth = vim.fn.strdisplaywidth(chunkText)
          if targetWidth > curWidth + chunkWidth then
            table.insert(newVirtText, chunk)
          else
            chunkText = truncate(chunkText, targetWidth - curWidth)
            local hlGroup = chunk[2]
            table.insert(newVirtText, { chunkText, hlGroup })
            chunkWidth = vim.fn.strdisplaywidth(chunkText)
            if curWidth + chunkWidth < targetWidth then
              suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
            end
            break
          end
          curWidth = curWidth + chunkWidth
        end
        table.insert(newVirtText, { suffix, hlgroup })
        return newVirtText
      end,
    },
  },
}
