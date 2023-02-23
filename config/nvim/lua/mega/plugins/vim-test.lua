local M = {
  "vim-test/vim-test",
  cmd = {
    "TestNearest",
    "TestFile",
    "TestLast",
    "TestVisit",
    "A",
    "AV",
  },
  event = "VeryLazy",
  dependencies = { "tpope/vim-projectionist" },
}

function M.config()
  local system = vim.fn.system

  local function terminal_notifier(term_cmd, exit)
    if exit == 0 then
      vim.notify("Test(s) passed.", vim.log.levels.INFO)
      system(string.format([[terminal-notifier -title "Neovim" -message "Success!"]], term_cmd))
    else
      vim.notify("Test(s) failed.", vim.log.levels.ERROR)
      system(string.format([[terminal-notifier -title "Neovim" -message "Failure!"]], term_cmd))
    end
  end

  local term_opts = function(cmd, extra_opts)
    return vim.tbl_extend("force", {
      winnr = vim.fn.winnr(),
      cmd = cmd,
      -- pre_cmd = "eval $(desk load)",
      notifier = terminal_notifier,
      temp = true,
      start_insert = false,
      focus_on_open = false,
      move_on_direction_change = false,
    }, extra_opts or {})
  end

  -- REF:
  -- neat ways to detect jest things
  -- https://github.com/weilbith/vim-blueplanet/blob/master/pack/plugins/start/test_/autoload/test/typescript/jest.vim
  -- https://github.com/roginfarrer/dotfiles/blob/main/nvim/.config/nvim/lua/rf/plugins/vim-test.lua#L19

  vim.g["test#strategy"] = "neovim"
  vim.g["test#ruby#use_binstubs"] = 0
  vim.g["test#ruby#bundle_exec"] = 0
  vim.g["test#filename_modifier"] = ":."
  vim.g["test#preserve_screen"] = 1

  vim.g["test#custom_strategies"] = {
    termsplit = function(cmd) mega.term.open(term_opts(cmd)) end,
    termvsplit = function(cmd) mega.term.open(term_opts(cmd, { direction = "vertical" })) end,
    termfloat = function(cmd) mega.term.open(term_opts(cmd, { direction = "float", focus_on_open = true })) end,
  }

  vim.g["test#strategy"] = {
    nearest = "termsplit",
    file = "termfloat",
    suite = "termfloat",
    last = "termsplit",
  }

  mega.nnoremap("<localleader>tn", "<cmd>TestNearest<cr>", "run _test under cursor")
  mega.nnoremap("<localleader>ta", "<cmd>TestFile<cr>", "run _all tests in file")
  mega.nnoremap("<localleader>tf", "<cmd>TestFile<cr>", "run _all tests in file")
  mega.nnoremap("<localleader>tl", "<cmd>TestLast<cr>", "run _last test")
  mega.nnoremap("<localleader>tt", "<cmd>TestLast<cr>", "run _last test")
  mega.nnoremap("<localleader>tv", "<cmd>TestVisit<cr>", "run test file _visit")
  mega.nnoremap("<localleader>tp", "<cmd>A<cr>", "open alt (edit)")
  mega.nnoremap("<localleader>tP", "<cmd>AV<cr>", "open alt (vsplit)")
end

return M
