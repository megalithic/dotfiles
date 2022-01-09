-- REFs:
-- * https://jdhao.github.io/2019/01/15/markdown_edit_preview_nvim/
-- * https://github.com/dkarter/bullets.vim
-- * https://github.com/mnarrell/dotfiles/blob/main/nvim/lua/ftplugin/markdown.lua
-- * https://vim.works/2019/03/16/using-markdown-in-vim/

-- " source: https://gist.github.com/huytd/668fc018b019fbc49fa1c09101363397
-- " based on: https://www.reddit.com/r/vim/comments/h8pgor/til_conceal_in_vim/
-- " youtube video: https://youtu.be/UuHJloiDErM?t=793
-- Custom conceal (does not work with existing syntax highlight plugin)

vim.cmd([[autocmd FileType markdown nnoremap gO <cmd>Toc<cr>]])

vim.o.equalprg = [[prettier --stdin-filepath '%:p']]
vim.o.makeprg = [[open %]]
vim.o.textwidth = 0
vim.o.wrapmargin = 0
vim.o.wrap = true
vim.cmd([[setlocal spell linebreak textwidth=0 wrap conceallevel=2]])

vim.cmd([[setlocal autoindent tabstop=2 shiftwidth=2 formatoptions-=t comments=fb:>,fb:*,fb:+,fb:-]])

-- continuous meeting note datetime entry
vim.cmd([[iabbrev <expr> mdate "### ".strftime("%Y-%m-%d %H:%M:%S")]])

vim.cmd([[
  setlocal nowrap
  setlocal spell
  setlocal nolist
  setlocal colorcolumn=
  setlocal foldexpr=markdown#FoldExpression(v:lnum)
  setlocal foldmethod=expr
  setlocal formatoptions+=t
  setlocal nolist
  ]])
vim.opt_local.spell = true
vim.opt_local.list = false

-- mega.augroup(
--   "mega.filetypes",
--   {
--     {
--       events = {"BufRead", "BufNewFile"},
--       targets = {"*.md"},
--       command = "setlocal spell linebreak"
--     }
--   })

-- ## plasticboy/vim-markdown
vim.g.markdown_fenced_languages = {
  "diff",
  "javascript",
  "js=javascript",
  "json=javascript",
  "typescript",
  "css",
  "scss",
  "sass",
  "ruby",
  "erb=eruby",
  "python",
  "haml",
  "html",
  "bash=sh",
  "zsh=sh",
  "shell=sh",
  "console=sh",
  "sh",
  "elm",
  -- "elixir",
  -- "eelixir",
  "lua",
  "vim",
  "viml",
}

vim.g.markdown_enable_conceal = 1
vim.g.vim_markdown_folding_level = 10
vim.g.vim_markdown_folding_disabled = 1
vim.g.vim_markdown_conceal = 0
vim.g.vim_markdown_conceal_code_blocks = 0
vim.g.vim_markdown_folding_style_pythonic = 1
vim.g.vim_markdown_override_foldtext = 0
vim.g.vim_markdown_follow_anchor = 1
vim.g.vim_markdown_frontmatter = 1 -- for YAML format
vim.g.vim_markdown_toml_frontmatter = 1 -- for TOML format
vim.g.vim_markdown_json_frontmatter = 1 -- for JSON format
vim.g.vim_markdown_new_list_item_indent = 2
vim.g.vim_markdown_auto_insert_bullets = 0
vim.g.vim_markdown_no_extensions_in_markdown = 1
vim.g.vim_markdown_math = 1
vim.g.vim_markdown_strikethrough = 1

local mappings = {
  ["<leader>"] = {
    m = {
      name = "markdown",
      p = { "<cmd>MarkdownPreviewToggle<cr>", "preview" },
      s = { "<cmd>MarkdownPreviewStop<cr>", "preview stop" },
    },
  },
}

vim.cmd("packadd which-key.nvim")
local wk = require("which-key")
wk.register(mappings)
