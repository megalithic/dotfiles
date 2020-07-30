" ## plasticboy/vim-markdown
let g:markdown_fenced_languages = [
      \ 'javascript', 'js=javascript', 'json=javascript',
      \ 'css', 'scss', 'sass',
      \ 'ruby', 'erb=eruby',
      \ 'python',
      \ 'haml', 'html',
      \ 'bash=sh', 'zsh', 'elm', 'elixir', 'eelixir']
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_conceal = 0
let g:vim_markdown_conceal_code_blocks = 0
let g:vim_markdown_folding_style_pythonic = 0
let g:vim_markdown_override_foldtext = 0
let g:vim_markdown_follow_anchor = 1
let g:vim_markdown_frontmatter = 1
let g:vim_markdown_new_list_item_indent = 2
let g:vim_markdown_no_extensions_in_markdown = 1
let g:vim_markdown_math=1
let g:vim_markdown_strikethrough=1
set conceallevel=2

command! PDF call system("pandoc -o " . fnameescape(expand('%:r')) . ".pdf " . fnameescape(expand('%')))
command! DOCX call system("pandoc -o " . fnameescape(expand('%:r')) . ".docx " . fnameescape(expand('%')))
