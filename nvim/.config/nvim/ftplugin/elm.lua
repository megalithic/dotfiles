-- noremap <script> <buffer> <silent> [[
--             \ :call <SID>NextSection(1, 0, 0)<cr>
-- noremap <script> <buffer> <silent> ]]
--             \ :call <SID>NextSection(1, 1, 0)<cr>
-- noremap <script> <buffer> <silent> []
--             \ :call <SID>NextSection(2, 0, 0)<cr>
-- noremap <script> <buffer> <silent> ][
--             \ :call <SID>NextSection(2, 1, 0)<cr>

-- vnoremap <script> <buffer> <silent> [[
--             \ :<c-u>call <SID>NextSection(1, 0, 1)<cr>
-- vnoremap <script> <buffer> <silent> ]]
--             \ :<c-u>call <SID>NextSection(1, 1, 1)<cr>
-- vnoremap <script> <buffer> <silent> []
--             \ :<c-u>call <SID>NextSection(2, 0, 1)<cr>
-- vnoremap <script> <buffer> <silent> ][
--             \ :<c-u>call <SID>NextSection(2, 1, 1)<cr>

vim.api.nvim_exec(
  [[
autocmd FileType elm nnoremap <leader>ep o\|> <ESC>a
autocmd FileType elm iabbrev ep    \|>


    " thieved from @theotherben on elm-lang slack
function! s:NextSection (type, backwards, visual)
    if a:visual
        normal! gv
    endif

    if a:backwards
        let l:dir = '?'
    else
        let l:dir = '/'
    endif

    if a:type == 1
        let l:pattern = '\v(\n\n\n^\zs\S)|(%^)'
        "let l:pattern = '\v\n\n\zs\S.*((:)|(\=$))'
        let l:flags = ''
    elseif a:type == 2
        let l:pattern = '\v\S\n\n+^\S'
        let l:flags = ''
    endif

    execute 'silent normal! ' . l:dir . l:pattern . l:dir . l:flags "\r"
endfunction
]],

  true
)
