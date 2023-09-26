vim.cmd([[
  " Autosize quickfix to match its minimum content
  " https://vim.fandom.com/wiki/Automatically_fitting_a_quickfix_window_height
  function! s:adjust_height(minheight, maxheight)
    exe max([min([line("$"), a:maxheight]), a:minheight]) . "wincmd _"
  endfunction

  " force quickfix to open beneath all other splits
  wincmd J

  setlocal nonumber
  setlocal norelativenumber
  setlocal nowrap
  setlocal signcolumn=yes
  setlocal colorcolumn=
  setlocal nobuflisted " quickfix buffers should not pop up when doing :bn or :bp
  call s:adjust_height(3, 10)
  setlocal winfixheight

  " REF: https://github.com/romainl/vim-qf/blob/2e385e6d157314cb7d0385f8da0e1594a06873c5/autoload/qf.vim#L22
]])

nnoremap("<C-n>", [[:cnext<cr>]], { buffer = 0, label = "QF: next" })
nnoremap("<C-p>", [[:cprevious<cr>]], { buffer = 0, label = "QF: previous" })

local ok_bqf, bqf = mega.require("bqf")
if not ok_bqf then return end

local fugitive_pv_timer
local preview_fugitive = function(bufnr, qwinid, bufname)
  local is_loaded = vim.api.nvim_buf_is_loaded(bufnr)
  if fugitive_pv_timer and fugitive_pv_timer:get_due_in() > 0 then
    fugitive_pv_timer:stop()
    fugitive_pv_timer = nil
  end
  fugitive_pv_timer = vim.defer_fn(function()
    if not is_loaded then
      vim.api.nvim_buf_call(bufnr, function() vim.cmd(("do fugitive BufReadCmd %s"):format(bufname)) end)
    end
    require("bqf.preview.handler").open(qwinid, nil, true)
    vim.api.nvim_buf_set_option(require("bqf.preview.session").float_bufnr(), "filetype", "git")
  end, is_loaded and 0 or 60)
  return true
end

bqf.setup({
  auto_enable = true,
  auto_resize_height = true,
  preview = {
    auto_preview = true,
    win_height = 15,
    win_vheight = 15,
    delay_syntax = 80,
    border_chars = { "┃", "┃", "━", "━", "┏", "┓", "┗", "┛", "█" },
    ---@diagnostic disable-next-line: unused-local
    should_preview_cb = function(bufnr, qwinid)
      local bufname = vim.api.nvim_buf_get_name(bufnr)
      local fsize = vim.fn.getfsize(bufname)
      if fsize > 100 * 1024 then
        -- skip file size greater than 100k
        return false
      elseif bufname:match("^fugitive://") then
        return preview_fugitive(bufnr, qwinid, bufname)
      end

      return true
    end,
  },
  filter = {
    fzf = {
      extra_opts = { "--bind", "ctrl-o:toggle-all", "--delimiter", "│" },
    },
  },
})

-- save & quit via "q"
mega.augroup("ReplacerFileType", {
  pattern = "replacer",
  callback = function() mega.nmap("q", vim.cmd.write, { desc = " done replacing", buffer = true, nowait = true }) end,
})

mega.nnoremap("<leader>r", function() require("replacer").run() end, { desc = "qf: replace in qflist", nowait = true })
