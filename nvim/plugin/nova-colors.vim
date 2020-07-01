function! s:nova_engage() abort
  " -- clears
  hi clear SpellBad
  hi clear SpellCap

  " -- nova color constants

  let g:bg = "#3c4c55"
  let g:default = "#83afe5"
  let g:selection = "#7fc1ca"
  let g:ok = "#a8ce93"
  let g:error = "#df8c8c"
  let g:warning = "#f2c38f"
  let g:hint = "#ffffff"
  let g:information = "#aaaaaa"
  let g:cursorlinenr = "#db9c5e"
  let g:added = g:ok
  let g:removed = g:error
  let g:changed = "#ecc48d"
  let g:separator = "#666666"

  " -- set color highlights

  exe 'hi CursorLineNr guibg=#333333 gui=italic guifg=' . g:cursorlinenr
  exe 'hi VertSplit guibg=NONE gui=NONE guifg=' . g:separator

  exe 'hi ErrorMsg guifg=' . g:error
  exe 'hi WarningMsg guifg=' . g:warning
  exe 'hi HintMsg guifg=' . g:hint
  exe 'hi InformationMsg guifg=' . g:information

  hi! link LspDiagnosticsError ErrorMsg
  hi! link LspDiagnosticsWarning WarningMsg
  hi! link LspDiagnosticsInformation InformationMsg
  hi! link LspDiagnosticsHint HintMsg

  hi! link Debug ErrorMsg
  hi! link Exception ErrorMsg

  exe 'hi SpellBad gui=undercurl,underline guifg=' . g:error . ' guibg=' . g:bg
  exe 'hi SpellCap gui=undercurl,underline guifg=' . g:error . ' guibg=' . g:bg
  exe 'hi SpellRare gui=undercurl,underline guifg=' . g:error . ' guibg=' . g:bg
  exe 'hi SpellLocal gui=undercurl,underline guifg=' . g:error . ' guibg=' . g:bg

  exe 'hi ModifiedColor guibg=NONE gui=bold guifg=' . g:error

  exe 'hi gitCommitOverflow guifg=#333333 gui=underline guibg=' . g:error

  exe 'hi DiffAdd gui=NONE guifg=' . g:added . ' guibg=' . g:bg
  exe 'hi DiffDelete gui=NONE guifg=' . g:removed . ' guibg=' . g:bg
  exe 'hi DiffChange gui=NONE guifg=' . g:changed . ' guibg=' . g:bg

  hi! link DiffAdded DiffAdd
  hi! link DiffDeleted DiffDelete
  hi! link DiffRemove DiffDelete
  hi! link DiffRemoved DiffDelete
  hi! link DiffChanged DiffChanged

  hi! link SignifySignAdd DiffAdd
  hi! link SignifySignDelete DiffDelete
  hi! link SignifySignChange DiffChanged
  hi! link SignifySignChangeDelete SignifySignChange
  hi! link SignifySignDeleteFirstLine SignifySignDelete

  hi htmlArg cterm=italic gui=italic
  hi xmlAttrib cterm=italic gui=italic
  hi Type cterm=italic gui=italic
  hi Comment cterm=italic term=italic gui=italic

  " FIXME: IncSearch negatively affects my FZF colors
  " hi IncSearch guifg=#FFFACD

  " highlight conflicts
  match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'


  hi SignColumn guibg=NONE

  hi illuminatedWord cterm=underline gui=underline
  hi MatchWord cterm=underline gui=underline,italic
  hi MatchParen cterm=underline gui=underline,italic

  hi Visual guifg=#3C4C55 guibg=#7FC1CA
  hi Normal guifg=#C5D4DD guibg=NONE

  hi QuickScopePrimary guifg='#afff5f' guibg=#222222 gui=underline
  hi QuickScopeSecondary guifg='#5fffff' guibg=#222222 gui=underline

  hi HighlightedyankRegion gui=bold ctermbg=0 guibg=#13354A

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

  " -- statusline

  " hi StatusLine          guifg=#d485ad     guibg=NONE     gui=NONE
  " hi StatusLineNC        guifg=#d75f5f     guibg=NONE     gui=bold
  hi! link StatuslineSeparator VertSplit
  " hi! link StatuslineAccent VertSplit
  hi StatuslineFiletype guifg=#d9d9d9 gui=none guibg=#3a3a3a
  hi StatuslinePercentage guibg=#3a3a3a gui=none guifg=#dab997
  hi StatuslineNormal guibg=#3a3a3a gui=none guifg=#e9e9e9
  hi StatuslineVC guibg=#3a3a3a gui=none guifg=#a9a9a9
  hi StatuslineLintWarn guibg=#3a3a3a gui=none guifg=#ffcf00
  hi StatuslineLintChecking guibg=#3a3a3a gui=none guifg=#458588
  hi StatuslineLintError guibg=#3a3a3a gui=none guifg=#d75f5f
  hi StatuslineLintOk guibg=#3a3a3a gui=none guifg=#b8bb26
  hi StatuslineLint guibg=#e9e9e9 guifg=#3a3a3a
  hi StatuslineLineCol guibg=#3a3a3a gui=none guifg=#878787
  hi StatuslineFiletype guibg=#3a3a3a gui=none guifg=#e9e9e9
endfunction

augroup nova_colors
  au!
  au ColorScheme * call s:nova_engage()
augroup END

call s:nova_engage()
