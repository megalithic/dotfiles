" " firenvim
" " let fc['.*'] = { 'cmdline' : 'firenvim' }
" au BufEnter www.firecode.*.txt set filetype=cpp
" au BufEnter github.com_*.txt set filetype=markdown
" if exists('g:started_by_firenvim') && g:started_by_firenvim
"   " general options
"   setl laststatus=0
"   setl showtabline=0
"   colorscheme nova
" endif
" function! s:IsFirenvimActive(event) abort
"   if !exists('*nvim_get_chan_info')
"     return 0
"   endif
"   let l:ui = nvim_get_chan_info(a:event.chan)
"   return has_key(l:ui, 'client') && has_key(l:ui.client, "name") &&
"         \ l:ui.client.name is# "Firenvim"
" endfunction

" function! OnUIEnter(event) abort
"   if s:IsFirenvimActive(a:event)
"     set laststatus=0
"   endif
" endfunction
" autocmd UIEnter * call OnUIEnter(deepcopy(v:event))
" nnoremap <Esc><Esc> :call firenvim#focus_page()<CR>
" nnoremap <C-z> :call firenvim#hide_frame()<CR>
