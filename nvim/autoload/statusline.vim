let g:indicator_checking = "\uf110"
let g:indicator_errors = "\uf05e "
let g:indicator_warnings = "\uf071 "
let g:indicator_infos = "\uf7fc "
let g:indicator_hints = "\ufbe7 "
let g:indicator_ok = "\uf00c"
let g:modified_symbol = ''
let g:vcs_symbol = ''
let g:readonly_symbol = ''

let g:spinner_frames = ['⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷']

let s:ale_frame_idx = 0


" -- Statusline functions --

function! statusline#icon() abort
  " return luaeval("require('utils').icons.lookup_filetype(_A)", &filetype)

  return winwidth(0) > 70 ? (strlen(&filetype) ? WebDevIconsGetFileTypeSymbol() : '') : ''
endfunction

function! statusline#filetype() abort
  " return &filetype !=# '' ? &filetype : 'no filetype'
  return winwidth(0) > 70 ? (strlen(&filetype) ? &filetype : 'no ft') : ''
endfunction

function! statusline#ale_warnings() abort
  let l:counts = ale#statusline#Count(bufnr(''))
  let l:all_errors = l:counts.error + l:counts.style_error
  let l:all_non_errors = l:counts.total - l:all_errors
  return l:all_non_errors == 0 ? '' : printf(g:indicator_warnings . ' %d', all_non_errors)
endfunction

function! statusline#ale_errors() abort
  let l:counts = ale#statusline#Count(bufnr(''))
  let l:all_errors = l:counts.error + l:counts.style_error
  return l:all_errors == 0 ? '' : printf(g:indicator_errors . ' %d', all_errors)
endfunction

function! statusline#ale_ok() abort
  let l:counts = ale#statusline#Count(bufnr(''))
  return l:counts.total == 0 ? g:indicator_ok : ''
endfunction

function! statusline#ale_checking() abort
  let result = ''
  if ale#engine#IsCheckingBuffer(bufnr(''))
    let result = g:spinner_frames[s:ale_frame_idx % len(g:spinner_frames)]
    let s:ale_frame_idx = s:ale_frame_idx + 1
  else
    let s:ale_frame_idx = 0
  endif
  return result
endfunction

function! statusline#ale_enabled() abort
  return (get(g:, 'ale_enabled', 0) == 1 && getbufvar(bufnr(''), 'ale_linted', 0) > 0) || getbufvar(bufnr(''), 'ale_linted', 0) > 0
endfunction

function! statusline#ale() abort
  if !statusline#ale_enabled()
    return ''
  endif

  let l:icon = ' 🍺 '
  let l:checking = statusline#ale_checking()

  if l:checking !=# ''
    return l:icon . l:checking . ' '
  endif

  let l:ok = statusline#ale_ok()
  if l:ok !=# ''
    return l:icon . l:ok . ' '
  endif

  let l:warnings = statusline#ale_warnings()
  let l:errors = statusline#ale_errors()
  return l:icon . l:warnings . (l:warnings ==# '' ? '' : (l:errors ==# '' ? '' : ' ')) . l:errors . ' '
endfunction

function! statusline#gutentags_enabled() abort
  return exists('g:gutentags_enabled') && g:gutentags_enabled == 1 && gutentags#statusline() !=# ''
endfunction

function! statusline#gutentags()
  if !statusline#gutentags_enabled()
    return ''
  endif

  return gutentags#statusline('[', '] ')
endfunction

function! s:trim(str)
  if exists('*trim')
    return trim(a:str)
  endif
  return substitute(a:str, '\s\+$', '', '')
endfunction

function! statusline#vc_status() abort
  " let l:mark = ''
  let l:mark = g:vcs_symbol
  let l:branch = gitbranch#name()
  let l:changes = sy#repo#get_stats()
  let l:status = l:changes[0] > 0 ? '+' . l:changes[0] : ''
  let l:prefix = l:changes[0] > 0 ? ' ' : ''
  let l:status = l:changes[1] > 0 ? l:status . l:prefix . '~' . l:changes[1] : l:status
  let l:prefix = l:changes[1] > 0 ? ' ' : ''
  let l:status = l:changes[2] > 0 ? l:status . l:prefix . '-' . l:changes[2] : l:status
  let l:status = l:status ==# '' ? '' : l:status . ' '
  " return l:branch !=# '' ? l:status . l:mark . ' ' . l:branch . ' ' : ''
  return l:branch !=# '' ? l:mark . ' ' . l:branch : ''
endfunction

function! statusline#have_lsp() abort
  return luaeval('#vim.lsp.buf_get_clients() > 0')
endfunction

function! statusline#lsp() abort
  return luaeval("require('lsp-status').status()")
endfunction

function! statusline#lint_lsp()
  let l:segment = ''
  let l:have_ale = v:false
  if statusline#ale_enabled()
    let l:have_ale = v:true
    let l:segment = statusline#ale()
  endif

  if statusline#have_lsp()
    let l:segment = l:segment . statusline#lsp()
  endif

  return l:segment
endfunction

function! statusline#get_mode(mode) abort
  " let l:currentmode={
  "       \'n' : 'Normal',
  "       \'no' : 'N·Operator Pending',
  "       \'v' : 'Visual',
  "       \'V' : 'V·Line',
  "       \'^V' : 'V·Block',
  "       \'s' : 'Select',
  "       \'S': 'S·Line',
  "       \'^S' : 'S·Block',
  "       \'i' : 'Insert',
  "       \'R' : 'Replace',
  "       \'Rv' : 'V·Replace',
  "       \'c' : 'Command',
  "       \'cv' : 'Vim Ex',
  "       \'ce' : 'Ex',
  "       \'r' : 'Prompt',
  "       \'rm' : 'More',
  "       \'r?' : 'Confirm',
  "       \'!' : 'Shell',
  "       \'t' : 'Terminal'
  "       \}

  let l:currentmode = {
        \'n' : 'N',
        \'no' : 'N·O',
        \'v' : 'V',
        \'V' : 'V·Line',
        \'^V' : 'V·Block',
        \'s' : 'S',
        \'S': 'S·Line',
        \'^S' : 'S·Block',
        \'i' : 'I',
        \'R' : 'R',
        \'Rv' : 'V·Replace',
        \'c' : 'C',
        \'cv' : 'Vim·Ex',
        \'ce' : 'Ex',
        \'r' : 'Prompt',
        \'rm' : 'More',
        \'r?' : 'Confirm',
        \'!' : 'Shell',
        \'t' : 'T'
        \}

  return toupper(get(l:currentmode, a:mode, '·'))
endfunction

function! statusline#lineinfo() abort
  let l:percent = line('.') * 100 / line('$') . '%'
  return printf("\ue0a1 %d/%d %d:%d \uf0c9 %s", line('.'), line('$'), col('.'), col('$'), l:percent)
endfunction

function! statusline#filename() abort
  " let base_name = fnamemodify(bufname('%'), ':~:.')
  " let space = min([60, float2nr(floor(0.6 * winwidth(0)))])
  " if len(base_name) <= space
  "   return base_name
  " endif

  " return pathshorten(base_name)

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

  return finalpath
endfunction

function! statusline#lsp_errors() abort
  let l:all_errors = luaeval("vim.lsp.util.buf_diagnostics_count(\"Error\")")
  return l:all_errors == 0 ? '' : printf(g:indicator_errors . '%d', all_errors)
endfunction

function! statusline#lsp_warnings() abort
  let l:all_warns = luaeval("vim.lsp.util.buf_diagnostics_count(\"Warning\")")
  return l:all_warns == 0 ? '' : printf(g:indicator_warnings . '%d', all_warns)
endfunction

function! statusline#lsp_informations() abort
  let l:all_infos = luaeval("vim.lsp.util.buf_diagnostics_count(\"Information\")")
  return l:all_infos == 0 ? '' : printf(g:indicator_infos . '%d', all_infos)
endfunction

function! statusline#lsp_hints() abort
  let l:all_hints = luaeval("vim.lsp.util.buf_diagnostics_count(\"Hint\")")
  return l:all_hints == 0 ? '' : printf(g:indicator_hints . '%d', all_hints)
endfunction
