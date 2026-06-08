local group = vim.api.nvim_create_augroup("mega.autocmds", { clear = true })

vim.api.nvim_create_autocmd("BufWritePre", {
  group = group,
  callback = function(args)
    if vim.bo[args.buf].filetype == "oil" or vim.api.nvim_buf_get_name(args.buf) == "" then return end

    local dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(args.buf), ":p:h")
    if dir == "" or dir:match("^%w%+://") or dir:match("^suda:") then return end

    local stats = vim.uv.fs_stat(dir)
    if stats and stats.type == "directory" then return end

    if vim.v.cmdbang == 0 then
      vim.fn.inputsave()
      local ok, result = pcall(vim.fn.input, string.format('"%s" does not exist. Create? [y/N] ', dir), "")
      vim.fn.inputrestore()
      if not ok or result:lower() ~= "y" then
        print("Canceled")
        return
      end
    end

    vim.fn.mkdir(dir, "p")
  end,
})
