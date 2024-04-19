return {
  cond = false,
  "kevinhwang91/nvim-ufo",
  dependencies = {
    "kevinhwang91/promise-async",
  },
  event = { "LazyFile" },
  config = function()
    local ufo = require("ufo")
    ---@diagnostic disable-next-line: missing-fields
    ufo.setup({
      fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
        local newVirtText = {}
        local totalLines = vim.api.nvim_buf_line_count(0) - 1
        local foldedLines = endLnum - lnum
        local suffix = (" ⤶ %d %d%%"):format(foldedLines, foldedLines / totalLines * 100)
        local sufWidth = vim.fn.strdisplaywidth(suffix)
        local targetWidth = width - sufWidth
        local curWidth = 0
        table.insert(virtText, { " …", "Comment" })
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
            -- str width returned from truncate() may less than 2nd argument, need padding
            if curWidth + chunkWidth < targetWidth then
              suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
            end
            break
          end
          curWidth = curWidth + chunkWidth
        end
        local rAlignAppndx = math.max(math.min(vim.opt.textwidth["_value"], width - 1) - curWidth - sufWidth, 0)
        suffix = (" "):rep(rAlignAppndx) .. suffix
        table.insert(newVirtText, { suffix, "MoreMsg" })
        return newVirtText
      end,
      preview = {
        win_config = {
          border = mega.current_border(),
          winhighlight = "Normal:Normal",
          winblend = 0,
        },
      },
      provider_selector = function(_, _, _) return { "treesitter" } end,
    })

    local map = vim.keymap.set
    map("n", "zR", ufo.openAllFolds)
    map("n", "zM", ufo.closeAllFolds)
    map("n", "zk", ufo.goPreviousStartFold)
    map("n", "zn", ufo.goNextClosedFold)
    map("n", "zp", ufo.goPreviousClosedFold)
  end,
}
