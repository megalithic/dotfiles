noremap <plug>(slash-after) zz

if has('timers')
  " Blink 4 times with 50ms interval
  noremap <expr> <plug>(slash-after) slash#blink(4, 50)
endif
