-- REF:
-- https://www.instapaper.com/text?u=https%3A%2F%2Fvonheikemen.github.io%2Fdevlog%2Ftools%2Fusing-vim-abbreviations%2F
if not mega then return end
if not vim.g.enabled_plugin["abbreviations"] then return end

mega.iabbrev = function(lhs, rhs, ft)
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

mega.cabbrev = function(lhs, rhs) vim.cmd.cabbrev(string.format([[%s %s]], lhs, rhs)) end
mega.nabbrev = function(lhs, rhs) vim.cmd.abbrev(string.format([[%s %s]], lhs, rhs)) end
mega.noabbrev = function(lhs, rhs) vim.cmd.noabbrev(string.format([[%s %s]], lhs, rhs)) end

-- [ insert ] ------------------------------------------------------------------

local gitcommit_pattern = { "gitcommit", "NeogitCommitMessage", "COMMIT_EDITMSG", "NEOGIT_COMMIT_EDITMSG" }
mega.iabbrev("cabag", "Co-authored-by: Aaron Gunderson <aaron@ternit.com>", gitcommit_pattern)
mega.iabbrev("cabdt", "Co-authored-by: Dan Thiffault <dan@ternit.com>", gitcommit_pattern)
mega.iabbrev("cabjm", "Co-authored-by: Jia Mu <jia@ternit.com>", gitcommit_pattern)
mega.iabbrev("cabam", "Co-authored-by: Ali Marsh<ali@ternit.com>", gitcommit_pattern)
mega.iabbrev("cbag", "Co-authored-by: Aaron Gunderson <aaron@ternit.com>", gitcommit_pattern)
mega.iabbrev("cbdt", "Co-authored-by: Dan Thiffault <dan@ternit.com>", gitcommit_pattern)
mega.iabbrev("cbjm", "Co-authored-by: Jia Mu <jia@ternit.com>", gitcommit_pattern)
mega.iabbrev("cbam", "Co-authored-by: Ali Marsh<ali@ternit.com>", gitcommit_pattern)

mega.iabbrev("dashbarod", "dashboard")
mega.iabbrev("dashbaord", "dashboard")
mega.iabbrev("dashbroad", "dashboard")
mega.iabbrev("fulment", "fulfillment")
mega.iabbrev("fullment", "fulfillment")
mega.iabbrev("fullfillment", "fulfillment")
mega.iabbrev("fulfilment", "fulfillment")
mega.iabbrev("filment", "fulfillment")

-- command -----------------------------------------------------------------

mega.cabbrev("options", "vert options")
