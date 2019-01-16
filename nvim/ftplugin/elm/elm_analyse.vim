" From @theotherben on https://elmlang.slack.com/archives/C0SR8T090/p1547587416006600

call ale#Set('elm_analyse_executable', 'elm-analyse')
call ale#Set('elm_analyse_use_global', get(g:, 'ale_use_global_executables', 0))
function! elm_analyse#Handle(buffer, lines) abort
  let l:output = []
  let l:parsingHeader = 1
  let l:currentFilename = ''
  for l:line in a:lines
    if l:parsingHeader && matchstr(l:line, "Messages:") isnot# ""
      let l:parsingHeader = 0
    elseif l:parsingHeader == 0 && matchstr(l:line, "- .*") isnot# ""
      let [fullMatch, l:currentFilename; rest] = matchlist(l:line, '- \(.*\)')
    elseif l:parsingHeader == 0 && l:currentFilename ==# expand('%')
      let matches =
            \ matchlist(l:line, '  > \(.*\) at ((\(\d*\),\(\d*\)),(\(\d*\),\(\d*\)))')
      if len(matches) > 0
        let [fullMatch, l:description, l:lnum, l:col, l:end_lnum, l:end_col; rest] = matches
        call add(l:output, {
              \    'lnum': l:lnum,
              \    'col': l:col,
              \    'end_lnum': l:end_lnum,
              \    'end_col': l:end_col,
              \    'type': 'W',
              \    'text': l:description,
              \    'filename': l:currentFilename
              \})
      else
        let [fullMatch, l:error; rest] = matchlist(l:line, '  > \(.*\)')
        call add(l:output, {
              \    'type': 'E',
              \    'lnum': 0,
              \    'col': 0,
              \    'text': 'elm_analyse failed (' . l:error . ')'
              \})
      endif
    endif
  endfor
  return l:output
endfunction
function! elm_analyse#GetPackageFile(buffer) abort
  let l:elm_json = ale#path#FindNearestFile(a:buffer, 'elm.json')
  if empty(l:elm_json)
    " Fallback to Elm 0.18
    let l:elm_json = ale#path#FindNearestFile(a:buffer, 'elm-package.json')
  endif
  return l:elm_json
endfunction
function! elm_analyse#IsVersionGte19(buffer) abort
  let l:elm_json = elm_analyse#GetPackageFile(a:buffer)
  if l:elm_json =~# '-package'
    return 0
  else
    return 1
  endif
endfunction
function! elm_analyse#GetRootDir(buffer) abort
  let l:elm_json = elm_analyse#GetPackageFile(a:buffer)
  if empty(l:elm_json)
    return ''
  else
    return fnamemodify(l:elm_json, ':p:h')
  endif
endfunction
" Return the command to execute the linter in the projects directory.
" If it doesn't, then this will fail when imports are needed.
function! elm_analyse#GetCommand(buffer) abort
  let l:root_dir = elm_analyse#GetRootDir(a:buffer)
  if empty(l:root_dir)
    let l:dir_set_cmd = ''
  else
    let l:dir_set_cmd = 'cd ' . ale#Escape(l:root_dir) . ' && '
  endif
  return l:dir_set_cmd . '%e'
endfunction
function! elm_analyse#GetExecutable(buffer) abort
  return ale#node#FindExecutable(a:buffer, 'elm_analyse', ['node_modules/.bin/elm-analyse'])
endfunction
call ale#linter#Define('elm', {
      \   'name': 'elm_analyse',
      \   'executable_callback': 'elm_analyse#GetExecutable',
      \   'output_stream': 'stdout',
      \   'command_callback': 'elm_analyse#GetCommand',
      \   'read_buffer': 0,
      \   'callback': 'elm_analyse#Handle'
      \})
