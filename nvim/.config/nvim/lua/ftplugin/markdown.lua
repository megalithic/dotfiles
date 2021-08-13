-- REFs:
-- * https://jdhao.github.io/2019/01/15/markdown_edit_preview_nvim/
-- * https://github.com/dkarter/bullets.vim
-- * https://github.com/mnarrell/dotfiles/blob/main/nvim/lua/ftplugin/markdown.lua
-- * https://vim.works/2019/03/16/using-markdown-in-vim/
return function(_) -- bufnr
  -- " source: https://gist.github.com/huytd/668fc018b019fbc49fa1c09101363397
  -- " based on: https://www.reddit.com/r/vim/comments/h8pgor/til_conceal_in_vim/
  -- " youtube video: https://youtu.be/UuHJloiDErM?t=793
  -- Custom conceal (does not work with existing syntax highlight plugin)
  vim.cmd([[syntax match todoCheckbox "\v.*\[\ \]"hs=e-2 conceal cchar=]])
  vim.cmd([[syntax match todoCheckbox "\v.*\[x\]"hs=e-2 conceal cchar=]])
  mega.highlight("Conceal", {guibg="NONE"})
  -- https://vi.stackexchange.com/a/4003/16249
  vim.cmd([[syntax match NoSpellAcronym '\<\(\u\|\d\)\{3,}s\?\>' contains=@NoSpell]])

  vim.cmd([[autocmd FileType markdown nnoremap gO <cmd>Toc<cr>]])

  vim.o.equalprg = [[prettier --stdin-filepath '%:p']]
  vim.o.makeprg = [[open %]]
  vim.o.textwidth = 0
  vim.o.wrapmargin = 0
  vim.o.list = false
  vim.o.wrap = true
  vim.cmd([[setlocal spell linebreak textwidth=0 wrap conceallevel=2]])

  vim.cmd([[setlocal autoindent tabstop=2 shiftwidth=2 formatoptions-=t comments=fb:>,fb:*,fb:+,fb:-]])

  -- continuous meeting note datetime entry
  vim.cmd([[iabbrev <expr> mdate "### ".strftime("%Y-%m-%d %H:%M:%S")]])

  -- mega.augroup_cmds(
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
    "elixir",
    "eelixir",
    "lua",
    "vim",
    "viml"
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

  -- ## markdown/mkdx
  -- vim.g["mkdx#settings"] = {
  --   highlight = {enable = 1},
  --   enter = {shift = 1},
  --   links = {external = {enable = 1}},
  --   toc = {text = "Table of Contents", update_on_write = 1},
  --   fold = {enable = 1}
  -- }
  -- vim.api.nvim_exec(
  --   [[
  --   nmap <leader>ml <Plug>(mkdx-toggle-list-n)
  --   xmap <leader>ml <Plug>(mkdx-toggle-list-v)
  --   nmap <leader>mc <Plug>(mkdx-toggle-checkbox-n)
  --   xmap <leader>mc <Plug>(mkdx-toggle-checkbox-v)
  --   ]],
  --   true
  -- )

  vim.fn.sign_define("firstHeadline", {linehl = "markdownFirstHeadline"})
  vim.fn.sign_define("secondHeadline", {linehl = "markdownSecondHeadline"})
  vim.fn.sign_define("thirdHeadline", {linehl = "markdownHeadline"})

  local markdown_dash_namespace = vim.api.nvim_create_namespace("markdown_dash")

  _G.MarkdownHeadlines = function()
    if vim.bo.filetype ~= "markdown" and vim.bo.filetype ~= "vimwiki" then
      return
    end

    local markdown_sign_namespace = "markdown_sign_namespace"
    local bufnr = vim.api.nvim_get_current_buf()
    vim.fn.sign_unplace(markdown_sign_namespace, {buffer = vim.fn.bufname(bufnr)})
    vim.api.nvim_buf_clear_namespace(0, markdown_dash_namespace, 1, -1)
    local offset = math.max(vim.fn.line("w0") - 1, 0)
    local range = math.min(vim.fn.line("w$"), vim.api.nvim_buf_line_count(bufnr))
    local lines = vim.api.nvim_buf_get_lines(bufnr, offset, range, false)
    local marker = "#"

    for i = 1, #lines do
      local _, level = lines[i]:find("^" .. marker .. "+")
      if level == 1 then
        vim.fn.sign_place(0, markdown_sign_namespace, "firstHeadline", bufnr, {lnum = i + offset})
      end
      if level == 2 then
        vim.fn.sign_place(0, markdown_sign_namespace, "secondHeadline", bufnr, {lnum = i + offset})
      end
      if level and level == 3 then
        vim.fn.sign_place(0, markdown_sign_namespace, "thirdHeadline", bufnr, {lnum = i + offset})
      end

      local _, dashes = lines[i]:find("^---+$")
      if dashes then
        vim.api.nvim_buf_set_virtual_text(
          bufnr,
          markdown_dash_namespace,
          i - 1 + offset,
          {{("-"):rep(500), "markdownBold"}},
          vim.empty_dict()
        )
      end

      ::continue::
    end
  end
  MarkdownHeadlines()

  vim.cmd [[autocmd FileChangedShellPost,Syntax,TextChanged,InsertLeave,WinScrolled * lua MarkdownHeadlines()]]
end
