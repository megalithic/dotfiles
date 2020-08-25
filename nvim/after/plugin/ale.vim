let g:ale_linters = {
      \  '*': ['remove_trailing_lines', 'trim_whitespace'],
      \  'css':        ['csslint', 'prettier'],
      \  'javascript': ['standard', 'prettier_eslint'],
      \  'javascript.jsx': ['prettier_eslint'],
      \  'json':       ['jsonlint', 'prettier'],
      \  'html':       ['beautify', 'prettier'],
      \  'markdown':   ['mdl'],
      \  'ruby':       ['standardrb'],
      \  'scss':       ['sasslint', 'prettier'],
      \  'yaml':       ['yamllint'],
      \  'elm': [],
      \  'elixir': ['mix_format'],
      \  'eelixir': ['mix_format'],
      \}
let g:ale_linters = {}

let g:ale_fixers = {
      \  '*': ['remove_trailing_lines', 'trim_whitespace'],
      \  'javascript': ['prettier_eslint', 'prettier-standard'],
      \  'javascript.jsx': ['prettier_eslint', 'prettier-standard'],
      \  'css':  ['prettier'],
      \  'json': ['prettier'],
      \  'ruby': ['standardrb'],
      \  'scss': ['prettier'],
      \  'yml':  ['prettier'],
      \  'html': ['prettier', 'tidy'],
      \ }
" \   'elixir': ['mix_format'],
" \   'eelixir': ['mix_format'],
" \  'elm': [],

let g:ale_enabled                  = 1
let g:ale_completion_enabled       = 0
let g:ale_fix_on_save              = 1
let g:ale_lint_on_enter            = 1
let g:ale_lint_on_filetype_changed = 0
let g:ale_lint_on_insert_leave     = 0
let g:ale_lint_on_save             = 1
let g:ale_lint_on_text_changed     = 'never'
let g:ale_linters_explicit         = 1
let g:ale_open_list                = 0
let g:ale_sign_error               = '❯❯'
let g:ale_sign_info                = '❯❯'
let g:ale_sign_warning             = '❯❯'
let g:ale_sign_priority            = 50

" Use ~/dotfiles/vim/after/plugin/unimpaired.vim square brackets 'w'
" mappings to navigate the location list
nmap <silent> [W :lfirst<CR>zz
nmap <silent> ]W :llast<CR>zz
" nmap <Space>f    <Plug>(ale_fix)
" nmap <Space>l    <Plug>(ale_enable_buffer)
" nmap <Space><BS> <Plug>(ale_disable_buffer)
