function! s:nova_engage() abort
  " -- clears
  hi clear SpellBad
  hi clear SpellCap

  " -- nova color constants --

  let g:normal_text = "#c5d4dd"
  let g:bg = "#3c4c55"
  let g:default = "#83afe5"
  let g:selection = "#7fc1ca"
  let g:ok = "#a8ce93"
  let g:error = "#df8c8c"
  " let g:warning = "#dada93"
  let g:warning = "#f2c38f"
  let g:hint = "#dddddd"
  let g:information = "#aaaaaa"
  let g:cursorlinenr = "#db9c5e"
  let g:added = g:ok
  let g:removed = g:error
  let g:changed = "#ecc48d"
  let g:separator = "#666666"
  let g:incsearch = "#fffacd"


  " -- statusline constants --

  let g:light_red     = g:error
  let g:dark_red      = "#d75f5f"
  let g:green         = g:ok
  let g:blue          = g:default
  let g:cyan          = g:selection
  let g:magenta       = "#9a93e1"
  let g:light_yellow  = "#dada93"
  let g:dark_yellow   = "#dada93"

  let g:black         = g:bg
  let g:white         = "#c5d4dd"
  let g:comment_grey  = "#c5d4dd"
  let g:gutter_grey   = "#899ba6"
  " middle
  let g:cursor_grey   = g:bg
  " second
  let g:visual_grey   = "#6A7D89"
  let g:menu_grey     = g:visual_grey
  let g:special_grey  = "#1E272C"
  let g:vertsplit     = "#181a1f"


  " -- set custom colorscheme highlights --

  exe 'hi CursorLineNr guibg=#333333 gui=italic guifg=' . g:cursorlinenr
  exe 'hi VertSplit guibg=NONE gui=NONE guifg=' . g:separator

  exe 'hi ErrorMsg guifg=' . g:error
  exe 'hi WarningMsg guifg=' . g:warning
  exe 'hi HintMsg gui=italic guifg=' . g:hint
  exe 'hi InformationMsg gui=italic guifg=' . g:information

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

  exe 'hi Visual guifg=' . g:bg . ' guibg=' . g:selection
  exe 'hi Normal guifg=' . g:normal_text . ' guibg=NONE'

  hi htmlArg cterm=italic gui=italic
  hi xmlAttrib cterm=italic gui=italic
  hi Type cterm=italic gui=italic
  hi Comment cterm=italic term=italic gui=italic

  " highlight conflicts
  match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'


  hi SignColumn guibg=NONE

  hi illuminatedWord cterm=underline gui=underline
  hi MatchWord cterm=underline gui=underline,italic
  hi MatchParen cterm=underline gui=underline,italic

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


  " -- statusline highlights --

  " exe 'hi Statusline gui=bold guifg=' . g:magenta . ' guibg=NONE'
  " exe 'hi Statusline gui=bold guifg=' . g:dark_red . ' guibg=NONE'
  hi! link StatuslineSeparator VertSplit
  " hi StatuslineFiletype guifg=#d9d9d9 gui=none guibg=#3a3a3a
  exe 'hi StatuslineFiletype gui=bold guifg=' . g:light_red . ' guibg=' . g:black
  " hi StatuslinePercentage guibg=#3a3a3a gui=none guifg=#dab997
  exe 'hi StatuslinePercentage gui=bold guifg=' . g:light_red . ' guibg=' . g:black
  " hi StatuslineNormal guibg=#3a3a3a gui=none guifg=#e9e9e9
  exe 'hi StatuslineNormal gui=bold guifg=' . g:light_red . ' guibg=' . g:black
  " hi StatuslineVC guibg=#3a3a3a gui=none guifg=#a9a9a9
  exe 'hi StatuslineVC gui=bold guifg=' . g:light_red . ' guibg=' . g:black
  " hi StatuslineLintWarn guibg=#3a3a3a gui=none guifg=#ffcf00
  exe 'hi StatuslineLintWarn gui=bold guifg=' . g:light_red . ' guibg=' . g:black
  " hi StatuslineLintChecking guibg=#3a3a3a gui=none guifg=#458588
  exe 'hi StatuslineLintChecking gui=bold guifg=' . g:light_red . ' guibg=' . g:black
  " hi StatuslineLintError guibg=#3a3a3a gui=none guifg=#d75f5f
  exe 'hi StatuslineLintError gui=bold guifg=' . g:light_red . ' guibg=' . g:black
  " hi StatuslineLintOk guibg=#3a3a3a gui=none guifg=#b8bb26
  exe 'hi StatuslineLintOk gui=bold guifg=' . g:light_red . ' guibg=' . g:black
  " hi StatuslineLint guibg=#e9e9e9 guifg=#3a3a3a
  exe 'hi StatuslineLint gui=bold guifg=' . g:light_red . ' guibg=' . g:black
  " hi StatuslineLineCol guibg=#3a3a3a gui=none guifg=#878787
  exe 'hi StatuslineCol gui=bold guifg=' . g:light_red . ' guibg=' . g:black
  " hi StatuslineFiletype guibg=#3a3a3a gui=none guifg=#e9e9e9
  exe 'hi StatuslineFiletype gui=bold guifg=' . g:light_red . ' guibg=' . g:black


  " -- load colorizer --
  " FIXME: does this belong here?

  lua require'colorizer'.setup()
endfunction

augroup nova_colors
  au!
  au ColorScheme * call s:nova_engage()
augroup END

call s:nova_engage()
