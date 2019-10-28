if executable('yarn') && executable('node')
  let g:coc_global_extensions = [
        \ 'coc-bookmark',
        \ 'coc-calc',
        \ 'coc-css',
        \ 'coc-diagnostic',
        \ 'coc-dictionary',
        \ 'coc-eslint',
        \ 'coc-github',
        \ 'coc-gitignore',
        \ 'coc-gocode',
        \ 'coc-highlight',
        \ 'coc-html',
        \ 'coc-json',
        \ 'coc-lists',
        \ 'coc-lua',
        \ 'coc-marketplace',
        \ 'coc-pairs',
        \ 'coc-prettier',
        \ 'coc-python',
        \ 'coc-rls',
        \ 'coc-sh',
        \ 'coc-snippets',
        \ 'coc-solargraph',
        \ 'coc-svg',
        \ 'coc-syntax',
        \ 'coc-tailwindcss',
        \ 'coc-tslint-plugin',
        \ 'coc-tsserver',
        \ 'coc-vimlsp',
        \ 'coc-vimtex',
        \ 'coc-word',
        \ 'coc-yaml',
        \ ]
endif

let g:coc_force_debug = 0
let g:coc_node_path = $HOME . '/.asdf/installs/nodejs/10.15.3/bin/node'

" for showSignatureHelp
" set completeopt=noinsert,menuone "https://github.com/neoclide/coc.nvim/issues/478
set shortmess+=c
set keywordprg=:call\ CocAction('doHover')

inoremap <silent><expr> <TAB>
      \ pumvisible() ? coc#_select_confirm() :
      \ coc#expandableOrJumpable() ? coc#rpc#request('doKeymap', ['snippets-expand-jump','']) :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

let g:coc_snippet_next = '<TAB>'
let g:coc_snippet_prev = '<S-TAB>'

" Use <C-e> for trigger completion.
" inoremap <silent><expr> <C-e> coc#refresh()
" imap <expr> <C-e> pumvisible() ? (<SID>isSnipsExpandable() ? "<C-R>=UltiSnips#ExpandSnippet()<CR>" : "") : "\<ESC>A"
" inoremap <expr> <C-e> pumvisible() ? (<SID>isSnipsExpandable() ? "<C-R>=UltiSnips#ExpandSnippet()<CR>" : "") : "\<ESC>A"

" Instead of coc.nvim specific things, let's just do readline things here in
" insert mode
inoremap <silent> <C-e> <ESC>A
inoremap <silent> <C-a> <ESC>I

" Use <TAB> and <S-TAB> for navigate completion list:
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" Use <CR> for confirm completion.
" Coc only does snippet and additional edit on confirm.
inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

" Use <C-x><C-o> to complete 'word', 'emoji' and 'include' sources
imap <silent> <C-x><C-o> <Plug>(coc-complete-custom)

" Use K for show documentation in preview window
function! s:show_documentation()
  if &filetype ==# 'vim'
    execute 'h '.expand('<cword>')
  else
    call CocActionAsync('doHover')
  endif
endfunction

" ToggleCoc: disable coc.nvim for large file
function! ToggleCoc() abort
  let g:trigger_size = get(g:, 'trigger_size', 0.5 * 1048576)
  let size = getfsize(expand('<afile>'))
  if (size > g:trigger_size) || (size == -2)
    echohl WarningMsg
    echomsg 'Coc.nvim was disabled for this large file'
    echohl None
    exec 'CocDisable'
  else
    exec 'CocEnable'
  endif
endfunction

" ShowDoc: show document
function! ShowDoc() abort
  if (index(['vim','help'], &filetype) >= 0)
      execute 'h '.expand('<cword>')
    else
      call CocAction('jumpDefinition')
    endif
endfunction

nmap <silent> [c <Plug>(coc-diagnostic-prev)
nmap <silent> ]c <Plug>(coc-diagnostic-next)
" nmap <silent> [l <Plug>(coc-diagnostic-prev)
" nmap <silent> ]l <Plug>(coc-diagnostic-next)

" nnoremap <silent> K :call <SID>show_documentation()<CR>
nnoremap <silent> K :<C-u>call ShowDoc()<CR>
nnoremap <silent> <leader>lh :call <SID>show_documentation()<CR>
vnoremap <silent> <leader>lh :call <SID>show_documentation()<CR>

nmap <silent> <leader>lgd <Plug>(coc-definition)
nmap <silent> <leader>lgt <Plug>(coc-type-definition)
nmap <silent> <leader>lgi <Plug>(coc-implementation)

nmap <silent> <leader>lr <Plug>(coc-references)
nmap <silent> <leader>lgr <Plug>(coc-references)

nmap <silent> <leader>ln <Plug>(coc-rename)
nmap <silent> <leader>lR <Plug>(coc-rename)
vmap <silent> <leader>ln <Plug>(coc-rename)

nmap <silent> <leader>la <Plug>(coc-codeaction)
nmap <silent> <leader>lA <Plug>(coc-codeaction-selected)
vmap <silent> <leader>lA <Plug>(coc-codeaction-selected)

nmap <silent> <leader>lo <Plug>(coc-openlink)

" Fix autofix problem of current line
nmap <silent> <leader>lq <Plug>(coc-fix-current)

" Use `:Format` for format current buffer
command! -nargs=0 Format :call CocActionAsync('format')
" Use `:Fold` for fold current buffer
command! -nargs=? Fold :call CocActionAsync('fold', <f-args>)

 " Workspace symbols
nnoremap <silent> <leader>lS  :<C-u>CocList -I symbols<cr>
" Document symbols
nnoremap <silent> <leader>ls :<C-u>CocList outline<cr>
nnoremap <silent> <leader>lD :<C-u>CocList diagnostics<CR>
nnoremap <silent> <leader>lG :<C-u>CocList --normal --auto-preview gstatus<CR>
nnoremap <silent> <leader>lC :<C-u>CocList commands<cr>
nnoremap <silent> <leader>lO :<C-u>CocList outline<cr>
nnoremap <silent> <leader>lE :<C-u>CocList extensions<cr>
nnoremap <silent> <leader>lY :<C-u>CocList -A --normal yank<CR>

" nmap <silent> ,b <Plug>(coc-bookmark-toggle)
" nmap <silent> ,a <Plug>(coc-bookmark-annotate)
" nmap <silent> gh <Plug>(coc-bookmark-prev)
" nmap <silent> gl <Plug>(coc-bookmark-next)

augroup Coc
  au!
  au BufReadPre * call ToggleCoc()
  " au CursorHold * silent call CocActionAsync('highlight')
  au CursorHoldI * silent call CocActionAsync('showSignatureHelp')
  au User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
  au User CocDiagnosticChange call lightline#update_once()
augroup END
