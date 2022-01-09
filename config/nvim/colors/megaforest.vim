" Lush Notes:
" You probably always want to set this in your vim file
set background=dark
let g:colors_name="megaforest"

" Lush Notes:
" By setting our module to nil, we clear lua's cache,
" which means the require ahead will *always* occur.
"
" This isn't strictly required but it can be a useful trick if you are
" incrementally editing your confit a lot and want to be sure your themes
" changes are being picked up without restarting neovim.
"
" Note if you're working in on your theme and have lush.ify'd the buffer,
" your changes will be applied with our without the following line.
"
" The performance impact of this call can be measured in the hundreds of
" *nanoseconds* and such could be considered "production safe".
lua package.loaded['lush_theme.megaforest'] = nil

" Lush Notes:
" include our theme file and pass it to lush to apply
lua require('lush')(require('lush_theme.megaforest'))
