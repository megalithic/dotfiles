if !has('nvim-0.5.0')
  finish
endif

let s:load_dir = expand('<sfile>:p:h:h:h')
exec printf('luafile %s/lua/init.lua', s:load_dir)
