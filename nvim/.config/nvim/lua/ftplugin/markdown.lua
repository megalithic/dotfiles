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

  vim.fn.sign_define("markdownH1", {linehl = "markdownH1"})
  vim.fn.sign_define("markdownH2", {linehl = "markdownH2"})
  vim.fn.sign_define("markdownH3", {linehl = "markdownH3"})
  vim.fn.sign_define("markdownH4", {linehl = "markdownH4"})

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
        vim.fn.sign_place(0, markdown_sign_namespace, "markdownH1", bufnr, {lnum = i + offset})
      end
      if level == 2 then
        vim.fn.sign_place(0, markdown_sign_namespace, "markdownH2", bufnr, {lnum = i + offset})
      end
      if level == 3 then
        vim.fn.sign_place(0, markdown_sign_namespace, "markdownH3", bufnr, {lnum = i + offset})
      end
      if level and level == 4 then
        vim.fn.sign_place(0, markdown_sign_namespace, "markdownH4", bufnr, {lnum = i + offset})
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

  -- needs this scheme file to work correctly for md files:
  -- https://github.com/b3nj5m1n/dotfiles/tree/master/files/nvim/after/queries/markdown
--   vim.cmd([[
--     highlight h1 guifg=#50fa7b gui=bold
--     highlight _h1 guifg=#50fa7b gui=nocombine
--     highlight h2 guifg=#ff79c6 gui=bold
--     highlight _h2 guifg=#ff79c6 gui=nocombine
--     highlight h3 guifg=#ffb86c gui=bold
--     highlight _h3 guifg=#ffb86c gui=nocombine
--     highlight h4 guifg=#8be9fd gui=bold
--     highlight _h4 guifg=#8be9fd gui=nocombine
--     highlight h5 guifg=#f1fa8c gui=bold
--     highlight _h5 guifg=#f1fa8c gui=nocombine
--     highlight emphasis gui=italic
--     highlight strong_emphasis gui=bold
--     highlight strikethrough gui=strikethrough
--     highlight info_string guifg=#f1fa8c gui=italic
--
--     highlight markdownH1 guifg=#50fa7b gui=bold
--     highlight markdownH1Delimiter guifg=#50fa7b
--     highlight markdownH2 guifg=#ff79c6 gui=bold
--     highlight markdownH2Delimiter guifg=#ff79c6
--     highlight markdownH3 guifg=#ffb86c gui=bold
--     highlight markdownH3Delimiter guifg=#ffb86c
--     highlight markdownH4 guifg=#8be9fd gui=bold
--     highlight markdownH4Delimiter guifg=#8be9fd
--     highlight markdownH5 guifg=#ff5555 gui=bold
--     highlight markdownH5Delimiter guifg=#ff5555
--   ]])

  vim.cmd([[
  unlet b:current_syntax

  syn include @tex syntax/tex.vim
  syn region mkdMath start="\\\@<!\$" end="\$" skip="\\\$" contains=@tex keepend
  syn region mkdMath start="\\\@<!\$\$" end="\$\$" skip="\\\$" contains=@tex keepend
  syn region mkdStrike matchgroup=htmlStrike start="\%(\~\~\)" end="\%(\~\~\)" concealends

  syn region mkdID matchgroup=mkdDelimiter    start="\["    end="\]" contained oneline conceal
  syn region mkdURL matchgroup=mkdDelimiter   start="("     end=")"  contained oneline conceal
  syn region mkdLink matchgroup=mkdDelimiter  start="\\\@<!!\?\[\ze[^]\n]*\n\?[^]\n]*\][[(]" end="\]" contains=@mkdNonListItem,@Spell nextgroup=mkdURL,mkdID skipwhite concealends

  syn match   mkdInlineURL /https\?:\/\/\(\w\+\(:\w\+\)\?@\)\?\([A-Za-z0-9][-_0-9A-Za-z]*\.\)\{1,}\(\w\{2,}\.\?\)\{1,}\(:[0-9]\{1,5}\)\?[^] \t]*/

  syn region  mkdInlineURL matchgroup=mkdDelimiter start="(\(https\?:\/\/\(\w\+\(:\w\+\)\?@\)\?\([A-Za-z0-9][-_0-9A-Za-z]*\.\)\{1,}\(\w\{2,}\.\?\)\{1,}\(:[0-9]\{1,5}\)\?[^] \t]*)\)\@=" end=")"

  syn region mkdInlineURL matchgroup=mkdDelimiter start="\\\@<!<\ze[a-z][a-z0-9,.-]\{1,22}:\/\/[^> ]*>" end=">"

  syn region mkdLinkDef matchgroup=mkdDelimiter   start="^ \{,3}\zs\[\^\@!" end="]:" oneline nextgroup=mkdLinkDefTarget skipwhite
  syn region mkdLinkDefTarget start="<\?\zs\S" excludenl end="\ze[>[:space:]\n]"   contained nextgroup=mkdLinkTitle,mkdLinkDef skipwhite skipnl oneline
  syn region mkdLinkTitle matchgroup=mkdDelimiter start=+"+     end=+"+  contained
  syn region mkdLinkTitle matchgroup=mkdDelimiter start=+'+     end=+'+  contained
  syn region mkdLinkTitle matchgroup=mkdDelimiter start=+(+     end=+)+  contained
  syn region mkdBlockquote   start=/^\s*>/                   end=/$/ contains=mkdLink,mkdInlineURL,@Spell

  syn cluster mkdNonListItem contains=mkdInlineURL,mkdLink,mkdLinkDef,mkdLineBreak,mkdBlockquote,mkdMath,mkdStrike


  hi  mkdLink          guifg=#83A598 guibg=NONE guisp=#83A598 gui=underline blend=NONE
  hi def link mkdURL           markdownUrl
  hi def link mkdInlineURL     mkdLink
  hi def link mkdID            Identifier
  hi def link mkdLinkDef       mkdID
  hi def link mkdLinkDefTarget mkdURL
  hi def link mkdLinkTitle     GruvboxGreen
  hi def link mkdBlockquote    Comment
  hi mkdStrike term=strikethrough cterm=strikethrough gui=strikethrough

  let b:current_syntax = 'markdown'
  ]])


--   vim.cmd([[
--   function! MarkdownHeaders()
--       let l:filename = expand("%")
--       let l:lines = getbufline('%', 0, '$')
--       let l:lines = map(l:lines, {index, value -> {"lnum": index + 1, "text": value, "filename": l:filename}})
--
--       call filter(l:lines, {_, value -> value.text =~# '^#\+ .*$'})
--
--       call setqflist(l:lines)
--
--       copen
--   endfunction
--   ]])

  vim.cmd([[
  syntax region mkdURL matchgroup=mkdEscape start="(" end=")" contained oneline
  syntax region mkdCode matchgroup=mkdEscape start="`" end="`" oneline concealends contained
  syntax region mkdID matchgroup=mkdEscape start="\[" end="\]" oneline concealends contains=mkdCode
  syntax region mkdURI matchgroup=mkdEscape  start="\\\@<!!\?\[\ze[^]\n]*\n\?[^]\n]*\][[(]" end="\]" contains=mkdID,mkdURL,mkdCode nextgroup=mkdURL,mkdID skipwhite
  syntax match mkdUnderline /─*$/
  syntax match mkdLeftAngle /&lt;/ conceal cchar=<
  syntax match mkdRightAngle /&gt;/ conceal cchar=>

  hi def link mkdLine special
  hi def link mkdID markdownLinkText
  hi def link mkdURI markdownLinkText
  hi def link mkdURL markdownURL
  hi def link mkdCode markdownCode
  ]])
end
