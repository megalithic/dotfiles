-- REF:
-- https://www.instapaper.com/text?u=https%3A%2F%2Fvonheikemen.github.io%2Fdevlog%2Ftools%2Fusing-vim-abbreviations%2F
if not mega then return end
if not vim.g.enabled_plugin["abbreviations"] then return end

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
mega.iabbrev("fulfillment_instruciton", "fulfillment_instruction")
mega.iabbrev("filment", "fulfillment")
mega.iabbrev("repload", "preload")
mega.iabbrev("reploads", "preloads")

-- command -----------------------------------------------------------------

mega.cabbrev("options", "vert options")
