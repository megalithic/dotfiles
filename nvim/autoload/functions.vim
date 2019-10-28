" Display relative line numbers in the active window and display absolute
" numbers in inactive windows.
"
function! relative_number#Activity(mode) abort
    if &diff
        " For diffs, do nothing since we want relativenumbers in all windows.
        return
    endif
    if &buftype == "nofile" || &buftype == "nowrite"
        setlocal nonumber
    elseif a:mode == "active"
        setlocal relativenumber
    else
        setlocal norelativenumber
    endif
endfunction
