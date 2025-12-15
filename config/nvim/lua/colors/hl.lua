local M = {}

vim.api.nvim_create_augroup("mega.hl_overrides", { clear = false })

function M.override(hl)
  local function cb()
    for k, v in pairs(hl) do
      vim.api.nvim_set_hl(0, k, v)
    end
  end
  -- rehighlight after colorscheme loaded
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = "mega.hl_overrides",
    callback = cb,
  })

  cb()
end

function M.opts_with_hl(opts, hl)
  return function()
    M.override(hl)
    return opts
  end
end

return M
