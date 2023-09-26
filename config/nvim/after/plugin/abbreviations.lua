-- REF:
-- https://www.instapaper.com/text?u=https%3A%2F%2Fvonheikemen.github.io%2Fdevlog%2Ftools%2Fusing-vim-abbreviations%2F

local M = {}

M.iabbrev = function(lhs, rhs, ft)
  ft = ft or nil

  if ft then
    mega.augroup("iabbreviations_" .. table.concat(ft, "_"), {
      {
        event = { "FileType" },
        desc = "Insert abbreviation for " .. vim.inspect(ft),
        pattern = ft,
        command = function() vim.cmd.iabbrev(string.format([[%s %s]], lhs, rhs)) end,
      },
    })
  else
    vim.cmd.iabbrev(string.format([[%s %s]], lhs, rhs))
  end
end

-- [ insert ] ------------------------------------------------------------------

local gitcommit_pattern = { "gitcommit", "NeogitCommitMessage" }
M.iabbrev("cabag", "Co-authored-by: Aaron Gunderson <aaron@ternit.com>", gitcommit_pattern)
M.iabbrev("cabdt", "Co-authored-by: Dan Thiffault <dan@ternit.com>", gitcommit_pattern)
M.iabbrev("cabjm", "Co-authored-by: Jia Mu <jia@ternit.com>", gitcommit_pattern)
M.iabbrev("cabam", "Co-authored-by: Ali Marsh<ali@ternit.com>", gitcommit_pattern)

-- [ command ] -----------------------------------------------------------------

vim.cmd.cabbrev("options", "vert options")

return M
