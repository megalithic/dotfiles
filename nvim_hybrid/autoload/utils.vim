" Operator function to yank directly to the clipboard via the + register
function! utils#clipboard_yank(type, ...) abort
  let sel_save = &selection
  let &selection = 'inclusive'
  if a:0 " Invoked from visual mode
    silent execute 'normal! "+y'
  else " Invoked with a motion
    silent execute 'normal! `[v`]"+y'
  endif

  let &selection = sel_save
endfunction


function! utils#get_color(synID, what, mode) abort
  return synIDattr(synIDtrans(hlID(a:synID)), a:what, a:mode)
endfunction
