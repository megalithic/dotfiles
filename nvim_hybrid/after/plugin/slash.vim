noremap <plug>(slash-after) zz

if has('timers')
  " Blink (n) times with 50ms interval
  " noremap <expr> <plug>(slash-after) slash#blink(4, 50)
  noremap <expr> <plug>(slash-after) 'zz'.slash#blink(4, 50)
endif
