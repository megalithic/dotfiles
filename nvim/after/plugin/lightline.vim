let status_timer = timer_start(1000, 'UpdateStatusBar', { 'repeat': -1 })
let g:lightline = {
      \   'colorscheme': 'nova',
      \   'component': {
      \     'modified': '%#ModifiedColor#%{LightlineModified()}',
      \   },
      \   'component_expand': {
      \     'linter_errors': 'GetErrors',
      \     'linter_warnings': 'GetWarnings',
      \     'linter_infos': 'GetInformations',
      \     'linter_hints': 'GetHints',
      \     'lsp_status': 'LspStatus',
      \   },
      \   'component_type': {
      \     'readonly': 'error',
      \     'modified': 'raw',
      \     'linter_checking': 'left',
      \     'linter_ok': 'left',
      \     'linter_errors': 'error',
      \     'linter_warnings': 'warning',
      \     'linter_infos': 'right',
      \     'linter_hints': 'right',
      \     'lsp_status': 'raw',
      \   },
      \   'component_function': {
      \     'readonly': 'LightlineReadonly',
      \     'filename': 'LightlineFileName',
      \     'filetype': 'LightlineFileType',
      \     'fileformat': 'LightlineFileFormat',
      \     'branch': 'LightlineBranch',
      \     'lineinfo': 'LightlineLineInfo',
      \     'percent': 'LightlinePercent',
      \   },
      \   'component_function_visible_condition': {
      \     'branch': '&buftype!="nofile"',
      \     'filename': '&buftype!="nofile"',
      \     'fileformat': '&buftype!="nofile"',
      \     'fileencoding': '&buftype!="nofile"',
      \     'filetype': '&buftype!="nofile"',
      \     'percent': '&buftype!="nofile"',
      \     'lineinfo': '&buftype!="nofile"',
      \     'time': '&buftype!="nofile"',
      \   },
      \   'active': {
      \     'left': [
      \       ['mode'],
      \       ['branch'],
      \       ['filename'],
      \       ['spell'],
      \       ['paste', 'readonly', 'modified'],
      \     ],
      \     'right': [
      \       ['lineinfo', 'percent'],
      \       ['linter_errors', 'linter_warnings', 'linter_infos', 'linter_hints'],
      \       ['lsp_status'],
      \       ['filetype', 'fileformat'],
      \     ],
      \   },
      \   'inactive': {
      \     'left': [ ['filename'], ['readonly', 'modified'] ],
      \     'right': [ ['lineinfo'], ['fileinfo' ] ],
      \   },
      \   'mode_map': {
      \     'n' : 'N',
      \     'i' : 'I',
      \     'R' : 'R',
      \     'v' : 'V',
      \     'V' : 'V-LINE',
      \     "\<C-v>": 'V-BLOCK',
      \     'c' : 'C',
      \     's' : 'S',
      \     'S' : 'S-LINE',
      \     "\<C-s>": 'S-BLOCK',
      \     't': 'T',
      \   },
      \ }

let g:indicator_errors = "\uf05e "
let g:indicator_warnings = "\uf071 "
let g:indicator_infos = "\uf7fc "
let g:indicator_hints = "\ufbe7 "

let g:lightline#ale#indicator_ok = "\uf42e  "
let g:lightline#ale#indicator_warnings = '  '
let g:lightline#ale#indicator_errors = '  '
let g:lightline#ale#indicator_checking = '  '

let g:coc_status_warning_sign = '  '
let g:coc_status_error_sign = '  '

let g:lsp_warning_sign = '  '
let g:lsp_error_sign = '  '
let g:lsp_hint_sign = '‣ '
let g:lsp_info_sign = '‣ '

let g:scroll_bar_chars = [
  \  '▁', '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'
  \  ]

au User LspDiagnosticsChanged call lightline#update()
" au User ClapOnExit call lightline#update()
au BufEnter call lightline#update()
au BufLeave call lightline#update()
au BufDelete call lightline#update()
au BufWritePost,TextChanged,TextChangedI * call lightline#update()

function! UpdateStatusBar(timer)
  call lightline#update()
endfunction

function! PrintStatusline(v)
  return &buftype ==? 'nofile' ? '' : a:v
endfunction

function! LightlineFileType()
  return winwidth(0) > 70 ? (strlen(&filetype) ? WebDevIconsGetFileTypeSymbol() . ' '. &filetype : 'no ft') : ''
  " return &filetype
endfunction

function! LightlineFileFormat()
  " return winwidth(0) > 70 ? (WebDevIconsGetFileFormatSymbol() . ' ' . &fileformat) : ''
  return &fileformat
endfunction

function! LightlineBranch()
  if exists('*fugitive#head')
    let l:branch = fugitive#head()
    return PrintStatusline(branch !=# '' ? ' ' . l:branch : '')
  endif
  return ''
endfunction

function! LightlineLineInfo()
  return PrintStatusline(printf("\ue0a1 %d/%d %d:%d", line('.'), line('$'), col('.'), col('$')))
endfunction

function! LightlinePercent()
  return PrintStatusline("\uf0c9 " . line('.') * 100 / line('$') . '%')
endfunction

function! LightlineReadonly()
  " return PrintStatusline(&ro ? "\ue0a2" : '')
  return PrintStatusline(&readonly && &filetype !=# 'help' ? '' : '')
endfunction

function! LightlineModified()
  return PrintStatusline(!&modifiable ? '-' : &modified ?
        \ '' : '')
        " \ "\uf085" : '')
        " \ "\uf085" : '')
        " ''
endfunction

function! LightlineFileName()
  " Get the full path of the current file.
  let filepath =  expand('%:p')

  " If the filename is empty, then display nothing as appropriate.
  if empty(filepath)
    return '[No Name]'
  endif

  " Find the correct expansion depending on whether Vim has autochdir.
  let mod = (exists('+autochdir') && &autochdir) ? ':~' : ':~:.'

  " Apply the above expansion to the expanded file path and split by the separator.
  let shortened_filepath = fnamemodify(filepath, mod)
  if len(shortened_filepath) < 45
    return shortened_filepath
  endif

  " Ensure that we have the correct slash for the OS.
  let dirsep = has('win32') && ! &shellslash ? '\\' : '/'

  " Check if the filepath was shortened above.
  let was_shortened = filepath != shortened_filepath

  " Split the filepath.
  let filepath_parts = split(shortened_filepath, dirsep)

  " Take the first character from each part of the path (except the tidle and filename).
  let initial_position = was_shortened ? 0 : 1
  let excluded_parts = filepath_parts[initial_position:-2]
  let shortened_paths = map(excluded_parts, 'v:val[0]')

  " Recombine the shortened paths with the tilde and filename.
  let combined_parts = shortened_paths + [filepath_parts[-1]]
  let combined_parts = (was_shortened ? [] : [filepath_parts[0]]) + combined_parts

  " Recombine into a single string.
  let finalpath = join(combined_parts, dirsep)
  return PrintStatusline(finalpath)
  " return finalpath
endfunction

function! Scrollbar() abort
  " Zero index line number so 1/3 = 0, 2/3 = 0.5, and 3/3 = 1
  let l:current_line = line('.') - 1
  let l:total_lines = line('$') - 1

  if l:current_line == 0
    let l:index = 0
  elseif l:current_line == l:total_lines
    let l:index = -1
  else
    let l:line_no_fraction = floor(l:current_line) / floor(l:total_lines)
    let l:index = float2nr(l:line_no_fraction * len(g:scroll_bar_chars))
  endif

  return g:scroll_bar_chars[l:index]
endfunction

function! GetErrors() abort
	let l:all_errors = luaeval("vim.lsp.util.buf_diagnostics_count(\"Error\")")
	return l:all_errors == 0 ? '' : printf(g:indicator_errors . '%d', all_errors)
endfunction

function! GetWarnings() abort
	let l:all_warns = luaeval("vim.lsp.util.buf_diagnostics_count(\"Warning\")")
	return l:all_warns == 0 ? '' : printf(g:indicator_warnings . '%d', all_warns)
endfunction

function! GetInformations() abort
	let l:all_infos = luaeval("vim.lsp.util.buf_diagnostics_count(\"Information\")")
	return l:all_infos == 0 ? '' : printf(g:indicator_infos . '%d', all_infos)
endfunction

function! GetHints() abort
	let l:all_hints = luaeval("vim.lsp.util.buf_diagnostics_count(\"Hint\")")
	return l:all_hints == 0 ? '' : printf(g:indicator_hints . '%d', all_hints)
endfunction

function! LspStatus() abort
  if luaeval('#vim.lsp.buf_get_clients() > 0')
    return ''
    return luaeval("require('lsp-status').status()")
  endif

  return ''
endfunction
