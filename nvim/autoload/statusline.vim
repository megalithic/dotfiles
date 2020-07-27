function! statusline#icon() abort
  return winwidth(0) > 70 ? (strlen(&filetype) ? WebDevIconsGetFileTypeSymbol() : '') : ''
endfunction

function! statusline#filetype() abort
  return winwidth(0) > 70 ? (strlen(&filetype) ? &filetype : 'no ft') : ''
endfunction

function! s:trim(str)
  if exists('*trim')
    return trim(a:str)
  endif
  return substitute(a:str, '\s\+$', '', '')
endfunction

function! statusline#vc_status() abort
  let l:mark = g:vcs_symbol
  let l:branch = gitbranch#name()
  let l:changes = sy#repo#get_stats()
  let l:status = l:changes[0] > 0 ? "" . l:changes[0] : ''
  let l:prefix = l:changes[0] > 0 ? ' ' : ''
  let l:status = l:changes[1] > 0 ? l:status . l:prefix . '~' . l:changes[1] : l:status
  let l:prefix = l:changes[1] > 0 ? ' ' : ''
  let l:status = l:changes[2] > 0 ? l:status . l:prefix . '-' . l:changes[2] : l:status
  let l:status = l:status ==# '' ? '' : l:status . ' '
  return l:branch !=# '' ? l:mark . ' ' . l:branch . ' ' . l:status : ''
  " return l:branch !=# '' ? l:status . l:mark . ' ' . l:branch . ' ' : ''
  " return l:branch !=# '' ? l:mark . ' ' . l:branch : ''
endfunction

function! statusline#have_lsp() abort
  return luaeval('#vim.lsp.buf_get_clients() > 0')
endfunction

function! statusline#lsp() abort
  return luaeval("require('lsp-status').status()")
endfunction

function! statusline#get_mode(mode) abort
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
        \'t' : g:term_mode
        \}

  return toupper(get(l:currentmode, a:mode, '·'))
endfunction

function! statusline#lineinfo() abort
  let l:percent = line('.') * 100 / line('$') . '%'
  return printf("%s %d/%d %s %d:%d %s %s", g:ln_sep, line('.'), line('$'), g:col_sep, col('.'), col('$'), g:perc_sep, l:percent)
endfunction

function! statusline#filename() abort
  " Get the full path of the current file if big enough, other wise, just file
  " name and extension.
  let filepath = winwidth(0) > 70 ? expand('%:p') : expand('%:t')

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
  return l:all_errors == 0 ? '' : printf(" " . g:indicator_errors . " %d ", all_errors)
endfunction

function! statusline#lsp_warnings() abort
  let l:all_warns = luaeval("vim.lsp.util.buf_diagnostics_count(\"Warning\")")
  return l:all_warns == 0 ? '' : printf(" " . g:indicator_warnings . " %d ", all_warns)
endfunction

function! statusline#lsp_informations() abort
  let l:all_infos = luaeval("vim.lsp.util.buf_diagnostics_count(\"Information\")")
  return l:all_infos == 0 ? '' : printf(" " . g:indicator_infos . " %d ", all_infos)
endfunction

function! statusline#lsp_hints() abort
  let l:all_hints = luaeval("vim.lsp.util.buf_diagnostics_count(\"Hint\")")
  return l:all_hints == 0 ? '' : printf(" " . g:indicator_hints . " %d ", all_hints)
endfunction

" function! statusline#lsp() abort
"   let l:sl = ''
"   let l:errors = luaeval('vim.lsp.util.buf_diagnostics_count("Error")')
"   let l:warnings = luaeval('vim.lsp.util.buf_diagnostics_count("Warning")')
"   let l:infos = luaeval('vim.lsp.util.buf_diagnostics_count("Information")')
"   let l:hints = luaeval('vim.lsp.util.buf_diagnostics_count("Hint")')

"   if l:errors
"     let l:sl .= ' %#StatuslineError %< '
"     let l:sl .= ' %#StatuslineError#' .. g:indicator_errors .. l:errors
"     let l:sl .= ' %#StatuslineError %< '
"   endif

"   if l:warnings
"     let l:sl .= ' %#StatuslineWarning# %< '
"     let l:sl .= ' %#StatuslineWarning#' .. g:indicator_warnings .. l:warnings
"     let l:sl .= ' %#StatuslineWarning# %< '
"   endif

"   if l:infos
"     let l:sl .= ' %#StatuslineInformation# %< '
"     let l:sl .= ' %#StatuslineInformation#' .. g:indicator_infos .. l:infos
"     let l:sl .= ' %#StatuslineInformation# %< '
"   endif

"   if l:hints
"     let l:sl .= ' %#StatuslineHint# %< '
"     let l:sl .= ' %#StatuslineHint#' .. g:indicator_hints .. l:hints
"     let l:sl .= ' %#StatuslineHint# %< '
"   endif

"   return printf("%s", l:sl)
" endfunction
