-- Activate built-in nvim.difftool (Neovim 0.12+) and configure jj-aware qflist UI.
-- Adapted from: https://github.com/iofq/nvim.nix/blob/master/nvim/after/plugin/autocmd.lua
-- All git-coupled logic (staging, git diff --quiet, etc.) removed — jj has no staging.

-- nvim.difftool provides :DiffTool {left} {right} + qflist integration.
-- Loaded here (after/plugin) so it's available once plugins have initialized.
vim.cmd.packadd("nvim.difftool")

vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  group = vim.api.nvim_create_augroup("difftool", { clear = true }),
  callback = function(event)
    local function refresh()
      local qf = vim.fn.getqflist({ all = true }).items

      local entry = qf[1]
      if not entry or not entry.user_data or not entry.user_data.diff then
        return
      end

      local ns = vim.api.nvim_create_namespace("nvim.difftool.hl")
      vim.api.nvim_buf_clear_namespace(event.buf, ns, 0, -1)
      for i, item in ipairs(qf) do
        -- All entries highlighted as 'Added' (no staging concept in jj).
        -- TODO: integrate jj squash -i for staging-like workflow.
        vim.hl.range(event.buf, ns, "Added", { i - 1, 0 }, { i - 1, -1 })
      end
    end

    vim.schedule(refresh)
  end,
})
