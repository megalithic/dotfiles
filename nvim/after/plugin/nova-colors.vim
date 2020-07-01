hi clear SpellBad
hi clear SpellCap

hi htmlArg cterm=italic gui=italic
hi xmlAttrib cterm=italic gui=italic
hi Type cterm=italic gui=italic
hi Comment cterm=italic term=italic gui=italic
hi CursorLineNr guibg=#333333 guifg=#ffffff guifg=#db9c5e gui=italic

" FIXME: IncSearch negatively affects my FZF colors
" hi IncSearch guifg=#FFFACD

" highlight conflicts
match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'

hi SpellBad gui=undercurl,underline guifg=#DF8C8C guibg=#3C4C55
hi SpellCap gui=undercurl,underline guifg=#DF8C8C guibg=#3C4C55
hi SpellRare gui=undercurl,underline guifg=#DF8C8C guibg=#3C4C55
hi SpellLocal gui=undercurl,underline guifg=#DF8C8C guibg=#3C4C55

hi VertSplit guifg=#666666 guibg=NONE

hi SignColumn guibg=NONE
" https://neovim.io/doc/user/sign.html#:sign

hi ErrorMsg guifg=#DF8C8C
hi WarningMsg guifg=#F2C38F
hi InformationMsg guifg=#666666
hi HintMsg guifg=#707070

hi! link LspDiagnosticsError ErrorMsg
hi! link LspDiagnosticsWarning WarningMsg
hi! link LspDiagnosticsInformation InformationMsg
hi! link LspDiagnosticsHint HintMsg

hi! link Debug ErrorMsg
hi! link Exception ErrorMsg

hi Blamer guifg=#707070

hi ModifiedColor guifg=#DF8C8C guibg=NONE gui=bold
hi illuminatedWord cterm=underline gui=underline
hi MatchWord cterm=underline gui=underline,italic
hi MatchParen cterm=underline gui=underline,italic

hi Visual guifg=#3C4C55 guibg=#7FC1CA
hi Normal guifg=#C5D4DD guibg=NONE

hi QuickScopePrimary guifg='#afff5f' guibg=#222222 gui=underline
hi QuickScopeSecondary guifg='#5fffff' guibg=#222222 gui=underline

hi gitCommitOverflow guibg=#DF8C8C guifg=#333333 gui=underline
hi DiffAdd guifg=#A8CE93
hi DiffDelete guifg=#DF8C8C
hi DiffAdded guifg=#A8CE93
hi DiffRemoved guifg=#DF8C8C

hi SignifySignAdd    ctermfg=green  guifg=#A8CE93 term=NONE gui=NONE
hi SignifySignDelete ctermfg=red    guifg=#DF8C8C cterm=NONE gui=NONE
hi SignifySignChange ctermfg=yellow guifg=#ffff00 cterm=NONE gui=NONE
hi! link SignifySignAdd             diffAdded
hi! link SignifySignDelete          diffRemoved
hi SignifySignChange ctermfg=222 guifg=#ecc48d cterm=NONE gui=NONE
hi! link SignifySignChangeDelete    SignifySignChange
hi! link SignifySignDeleteFirstLine SignifySignDelete

hi HighlightedyankRegion term=bold ctermbg=0 guibg=#13354A

" Header such as 'Commit:', 'Author:'
hi! link gitmessengerHeader Identifier
" Commit hash at 'Commit:' header
hi! link gitmessengerHash Comment
" History number at 'History:' header
hi! link gitmessengerHistory Constant
" Normal color. This color is the most important
hi! link gitmessengerPopupNormal CursorLine
" Color of 'end of buffer'. To hide '~' in popup window, I recommend to use the same background
" color as gitmessengerPopupNormal.
hi gitmessengerEndOfBuffer term=None guifg=None guibg=None ctermfg=None ctermbg=None

" hi Pmenu guifg=lightgrey guibg=#4e4e4e ctermbg=239 ctermfg=lightgrey
" hi Directory guifg=#DF8C8C

" " Make `defp` stand out from `def` in Elixir.
" hi elixirPrivateDefine guifg=#ecc48d
" hi elixirPrivateFunctionDeclaration guifg=#ecc48d
