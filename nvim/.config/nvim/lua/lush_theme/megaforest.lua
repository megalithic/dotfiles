--
-- Built with,
--
--        ,gggg,
--       d8" "8I                         ,dPYb,
--       88  ,dP                         IP'`Yb
--    8888888P"                          I8  8I
--       88                              I8  8'
--       88        gg      gg    ,g,     I8 dPgg,
--  ,aa,_88        I8      8I   ,8'8,    I8dP" "8I
-- dP" "88P        I8,    ,8I  ,8'  Yb   I8P    I8
-- Yb,_,d88b,,_   ,d8b,  ,d8b,,8'_   8) ,d8     I8,
--  "Y8P"  "Y888888P'"Y88P"`Y8P' "YY8P8P88P     `Y8
--
-- @megalithic

local set = vim.g

local lush = require("lush")
local palette = require("colors")
local cs = palette.cs

local italics = "italic"

local bg0 = cs.bg0
local bg1 = cs.bg1
local bg2 = cs.bg2
local bg3 = cs.bg3
local bg4 = cs.bg4
local bg_visual = cs.bg_visual
local bg_red = cs.bg_red
local bg_green = cs.bg_green
local bg_blue = cs.bg_blue
local bg_yellow = cs.bg_yellow
local grey0 = cs.grey0
local grey1 = cs.grey1
local grey2 = cs.grey2
local fg = cs.fg
local red = cs.red
local orange = cs.orange
local yellow = cs.yellow
local green = cs.green
local cyan = cs.cyan
local aqua = cs.aqua
local blue = cs.blue
local purple = cs.purple

local tc = {
	black = bg0,
	red = red,
	yellow = yellow,
	green = green,
	cyan = aqua,
	blue = blue,
	purple = purple,
	white = fg,
}

set.terminal_color_0 = tc.black
set.terminal_color_1 = tc.red
set.terminal_color_2 = tc.green
set.terminal_color_3 = tc.yellow
set.terminal_color_4 = tc.blue
set.terminal_color_5 = tc.purple
set.terminal_color_6 = tc.cyan
set.terminal_color_7 = tc.white
set.terminal_color_8 = tc.black
set.terminal_color_9 = tc.red
set.terminal_color_10 = tc.green
set.terminal_color_11 = tc.yellow
set.terminal_color_12 = tc.blue
set.terminal_color_13 = tc.purple
set.terminal_color_14 = tc.cyan
set.terminal_color_15 = tc.white
set.terminal_color_background = tc.black
set.terminal_color_foreground = tc.white

set.fzf_colors = {
	fg = { "fg", "Normal" },
	bg = { "bg", "Normal" },
	hl = { "fg", "Green" },
	["fg+"] = { "fg", "CursorLine", "CursorColumn", "Normal" },
	["bg+"] = { "bg", "CursorLine", "CursorColumn" },
	["hl+"] = { "fg", "Cyan" },
	info = { "fg", "Aqua" },
	prompt = { "fg", "Orange" },
	pointer = { "fg", "Blue" },
	marker = { "fg", "Yellow" },
	spinner = { "fg", "Yellow" },
	header = { "fg", "Grey" },
}

set.VM_Mono_hl = "Cursor"
set.VM_Extend_hl = "Visual"
set.VM_Cursor_hl = "Cursor"
set.VM_Insert_hl = "Cursor"

return lush(function()
	return {
		---- :help highlight-default -------------------------------
		ColorColumn({ fg = nil, bg = bg1 }), -- used for the columns set with 'colorcolumn'
		Conceal({ fg = grey1, bg = nil }), -- placeholder characters substituted for concealed text (see 'conceallevel')
		Cursor({ fg = nil, bg = nil, gui = "reverse" }), -- character under the cursor
		lCursor({ Cursor }), -- the character under the cursor when |language-mapping| is used (see 'guicursor')
		iCursor({ Cursor }),
		vCursor({ Cursor }),
		CursorIM({ Cursor }), -- like Cursor, but used when in IME mode |CursorIM|
		CursorColumn({ fg = nil, bg = bg1 }), -- Screen-column at the cursor, when 'cursorcolumn' is set.
		CursorLine({ fg = nil, bg = bg1 }), -- Screen-line at the cursor, when 'cursorline' is set.  Low-priority if foreground (ctermfg OR guifg) is not set.
		Directory({ fg = green, bg = nil }), -- directory names (and other special names in listings)
		DiffAdd({ fg = nil, bg = bg_green }), -- diff mode: Added line |diff.txt|
		DiffChange({ fg = nil, bg = bg_blue }), -- diff mode: Changed line |diff.txt|
		DiffDelete({ fg = nil, bg = bg_red }), -- diff mode: Deleted line |diff.txt|
		DiffText({ fg = bg0, bg = fg }), -- diff mode: Changed text within a changed line |diff.txt|
		EndOfBuffer({ fg = bg0, bg = bg0 }), -- filler lines (~) after the end of the buffer.  By default, this is highlighted like |hl-NonText|.
		TermCursor({ Cursor }), -- cursor in a focused terminal
		TermCursorNC({ Cursor }), -- cursor in an unfocused terminal
		ErrorMsg({ fg = red, bg = nil, gui = "bold,underline" }), -- error messages on the command line
		VertSplit({ fg = bg4, bg = nil }), -- the column separating vertically split windows
		Folded({ fg = grey1, bg = bg1 }), -- line used for closed folds
		FoldColumn({ fg = grey1, bg = bg1 }), -- 'foldcolumn'
		SignColumn({ fg = fg, bg = bg0 }), -- column where |signs| are displayed
		IncSearch({ fg = bg0, bg = red }), -- 'incsearch' highlighting; also used for the text replaced with ":s///c"
		Substitute({ fg = bg0, bg = yellow }), -- |:substitute| replacement text highlighting
		LineNr({ fg = grey0, bg = nil }), -- Line number for ":number" and ":#" commands, and when 'number' or 'relativenumber' option is set.
		CursorLineNr({ fg = fg, bg = bg1 }), -- Like LineNr when 'cursorline' or 'relativenumber' is set for the cursor line.
		MatchParen({ fg = nil, bg = bg4 }), -- The character under the cursor or just before it, if it is a paired bracket, and its match. |pi_paren.txt|
		ModeMsg({ fg = fg, bg = nil, gui = "bold" }), -- 'showmode' message (e.g., "-- INSERT -- ")
		-- MsgArea      { }, -- Area for messages and cmdline
		-- MsgSeparator { }, -- Separator for scrolled messages, `msgsep` flag of 'display'
		MoreMsg({ fg = yellow, bg = nil, gui = "bold" }), -- |more-prompt|
		NonText({ fg = bg4, bg = nil }), -- '@' at the end of the window, characters from 'showbreak' and other characters that do not really exist in the text (e.g., ">" displayed when a double-wide character doesn't fit at the end of the line). See also |hl-EndOfBuffer|.
		Normal({ fg = fg, bg = bg0 }), -- normal text
		NormalFloat({ fg = fg, bg = bg2 }), -- Normal text in floating windows.
		-- NormalNC     { }, -- normal text in non-current windows
		Pmenu({ fg = fg, bg = bg2 }), -- Popup menu: normal item.
		PmenuSel({ fg = green, bg = nil }), -- Popup menu: selected item.
		PmenuSbar({ fg = nil, bg = bg2 }), -- Popup menu: scrollbar.
		PmenuThumb({ fg = nil, bg = grey1 }), -- Popup menu: Thumb of the scrollbar.
		Question({ fg = yellow, bg = nil }), -- |hit-enter| prompt and yes/no questions
		QuickFixLine({ fg = purple, bg = nil, gui = "bold" }), -- Current |quickfix| item in the quickfix window. Combined with |hl-CursorLine| when the cursor is there.
		Search({ fg = bg0, bg = green }), -- Last search pattern highlighting (see 'hlsearch').  Also used for similar items that need to stand out.
		SpecialKey({ fg = bg3, bg = nil }), -- Unprintable characters: text displayed differently from what it really is.  But not 'listchars' whitespace. |hl-Whitespace| SpellBad  Word that is not recognized by the spellchecker. |spell| Combined with the highlighting used otherwise.  SpellCap  Word that should start with a capital. |spell| Combined with the highlighting used otherwise.  SpellLocal  Word that is recognized by the spellchecker as one that is used in another region. |spell| Combined with the highlighting used otherwise.
		SpellBad({ fg = red, bg = nil, gui = "undercurl", sp = red }),
		SpellCap({ fg = blue, bg = nil, gui = "undercurl", sp = blue }),
		SpellLocal({ fg = cyan, bg = nil, gui = "undercurl", sp = cyan }),
		SpellRare({ fg = purple, bg = nil, gui = "undercurl", sp = purple }), -- Word that is recognized by the spellchecker as one that is hardly ever used.  |spell| Combined with the highlighting used otherwise.
		StatusLine({ fg = grey1, bg = bg1 }), -- status line of current window
		StatusLineTerm({ fg = grey1, bg = bg1 }), -- status line of current window
		StatusLineNC({ fg = grey1, bg = bg0 }), -- status lines of not-current windows Note: if this is equal to "StatusLine" Vim will use "^^^" in the status line of the current window.
		StatusLineTermNC({ fg = grey1, bg = bg0 }), -- status lines of not-current windows Note: if this is equal to "StatusLine" Vim will use "^^^" in the status line of the current window.
		TabLine({ fg = grey2, bg = bg3 }), -- tab pages line, not active tab page label
		TabLineFill({ fg = grey1, bg = bg1 }), -- tab pages line, where there are no labels
		TabLineSel({ fg = bg0, bg = green }), -- tab pages line, active tab page label
		-- Title        { }, -- titles for output from ":set all", ":autocmd" etc.
		Visual({ fg = nil, bg = bg_visual }), -- Visual mode selection
		VisualNOS({ fg = nil, bg = bg_visual }), -- Visual mode selection when vim is "Not Owning the Selection".
		WarningMsg({ fg = yellow, bg = nil }), -- warning messages
		Whitespace({ fg = bg3, bg = nil }), -- "nbsp", "space", "tab" and "trail" in 'listchars'
		--
		WildMenu({ PmenuSel }), -- current match in 'wildmenu' completion
		-- These groups are not listed as default vim groups,
		-- but they are defacto standard group names for syntax highlighting.
		-- commented out groups should chain up to their "preferred" group by
		-- default,
		-- Uncomment and edit if you want more specific syntax highlighting.
		Boolean({ fg = purple, bg = nil }),
		Number({ fg = purple, bg = nil }),
		Float({ fg = purple, bg = nil }),
		PreProc({ fg = purple, bg = nil, gui = italics }),
		PreCondit({ fg = purple, bg = nil, gui = italics }),
		Include({ fg = purple, bg = nil, gui = italics }),
		Define({ fg = purple, bg = nil, gui = italics }),
		Conditional({ fg = red, bg = nil, gui = italics }),
		Repeat({ fg = red, bg = nil, gui = italics }),
		Keyword({ fg = red, bg = nil, gui = italics }),
		Typedef({ fg = red, bg = nil, gui = italics }),
		Exception({ fg = red, bg = nil, gui = italics }),
		Statement({ fg = red, bg = nil, gui = italics }),
		Error({ fg = red, bg = nil }),
		StorageClass({ fg = orange, bg = nil }),
		Tag({ fg = orange, bg = nil }),
		Label({ fg = orange, bg = nil }),
		Structure({ fg = orange, bg = nil }),
		Operator({ fg = orange, bg = nil }),
		Title({ fg = orange, bg = nil, gui = "bold" }),
		Special({ fg = yellow, bg = nil }),
		SpecialChar({ fg = yellow, bg = nil }),
		Type({ fg = yellow, bg = nil }),
		Function({ fg = green, bg = nil }),
		String({ fg = green, bg = nil }),
		Character({ fg = green, bg = nil }),
		Constant({ fg = aqua, bg = nil }),
		Macro({ fg = aqua, bg = nil }),
		Identifier({ fg = blue, bg = nil }),
		Comment({ fg = grey1, bg = nil, gui = italics }),
		SpecialComment({ fg = grey1, bg = nil, gui = italics }),
		Todo({ fg = purple, bg = nil, gui = italics }),
		Delimiter({ fg = fg, bg = nil }),
		Ignore({ fg = grey1, bg = nil }),
		Underlined({ fg = nil, bg = nil, gui = "underline" }),
		Debug({ fg = orange, bg = nil }), --    debugging statements
		debugPC({ fg = bg0, bg = green }), --    debugging statements
		debugBreakpoint({ fg = bg0, bg = red }), --    debugging statements
		Bold({ gui = "bold" }),
		Italic({ gui = "italic" }),
		CurrentWord({ fg = nil, bg = nil }),
		RedSign({ fg = red, bg = bg1 }),
		OrangeSign({ fg = orange, bg = bg1 }),
		YellowSign({ fg = yellow, bg = bg1 }),
		GreenSign({ fg = green, bg = bg1 }),
		AquaSign({ fg = cyan, bg = bg1 }),
		BlueSign({ fg = blue, bg = bg1 }),
		PurpleSign({ fg = purple, bg = bg1 }),
		Fg({ fg = fg, bg = nil }),
		Grey({ fg = grey1, bg = nil }),
		Red({ fg = red, bg = nil }),
		Orange({ fg = orange, bg = nil }),
		Yellow({ fg = yellow, bg = nil }),
		Green({ fg = green, bg = nil }),
		Aqua({ fg = aqua, bg = nil }),
		Blue({ fg = blue, bg = nil }),
		Purple({ fg = purple, bg = nil }),
		RedItalic({ fg = red, bg = nil, gui = italics }),
		OrangeItalic({ fg = orange, bg = nil, gui = italics }),
		YellowItalic({ fg = yellow, bg = nil, gui = italics }),
		GreenItalic({ fg = green, bg = nil, gui = italics }),
		AquaItalic({ fg = cyan, bg = nil, gui = italics }),
		BlueItalic({ fg = blue, bg = nil, gui = italics }),
		PurpleItalic({ fg = purple, bg = nil, gui = italics }),
		ErrorText({ fg = nil, bg = bg_red, gui = "undercurl", sp = red }),
		WarningText({ fg = nil, bg = bg_yellow, gui = "undercurl", sp = yellow }),
		InfoText({ fg = nil, bg = bg_blue, gui = "undercurl", sp = blue }),
		HintText({ fg = nil, bg = bg_green, gui = "undercurl", sp = green }),
		ErrorLine({ fg = nil, bg = bg_red }),
		WarningLine({ fg = nil, bg = bg_yellow }),
		InfoLine({ fg = nil, bg = bg_blue }),
		HintLine({ fg = nil, bg = bg_green }),
		ErrorFloat({ fg = red, bg = bg2 }),
		WarningFloat({ fg = yellow, bg = bg2 }),
		InfoFloat({ fg = blue, bg = bg2 }),
		HintFloat({ fg = green, bg = bg2 }),
		LspDiagnosticsFloatingError({ ErrorFloat }),
		LspDiagnosticsFloatingWarning({ WarningFloat }),
		LspDiagnosticsFloatingInformation({ InfoFloat }),
		LspDiagnosticsFloatingHint({ HintFloat }),
		LspDiagnosticsDefaultError({ ErrorText }),
		LspDiagnosticsDefaultWarning({ WarningText }),
		LspDiagnosticsDefaultInformation({ InfoText }),
		LspDiagnosticsDefaultHint({ HintText }),
		LspDiagnosticsVirtualTextError({ ErrorFloat }),
		LspDiagnosticsVirtualTextWarning({ WarningFloat }),
		LspDiagnosticsVirtualTextInformation({ InfoFloat }),
		LspDiagnosticsVirtualTextHint({ HintFloat }),
		LspDiagnosticsUnderlineError({ ErrorText }),
		LspDiagnosticsUnderlineWarning({ WarningText }),
		LspDiagnosticsUnderlineInformation({ InfoText }),
		LspDiagnosticsUnderlineHint({ HintText }),
		LspDiagnosticsSignError({ RedSign }),
		LspDiagnosticsSignWarning({ YellowSign }),
		LspDiagnosticsSignInformation({ BlueSign }),
		LspDiagnosticsSignHint({ AquaSign }),
		LspReferenceText({ CurrentWord }),
		LspReferenceRead({ CurrentWord }),
		LspReferenceWrite({ CurrentWord }),
		TermCursor({ Cursor }),
		healthError({ Red }),
		healthSuccess({ Green }),
		healthWarning({ Yellow }),
		-- These groups are for the neovim tree-sitter highlights.
		-- As of writing, tree-sitter support is a WIP, group names may change.
		-- By default, most of these groups link to an appropriate Vim group,
		-- TSError -> Error for example, so you do not have to define these unless
		-- you explicitly want to support Treesitter's improved syntax awareness.

		markdownH1({ fg = red, bg = nil, gui = "bold" }),
		markdownH2({ fg = orange, bg = nil, gui = "bold" }),
		markdownH3({ fg = yellow, bg = nil, gui = "bold" }),
		markdownH4({ fg = green, bg = nil, gui = "bold" }),
		markdownH5({ fg = blue, bg = nil, gui = "bold" }),
		markdownH6({ fg = purple, bg = nil, gui = "bold" }),
		markdownUrl({ fg = blue, bg = nil, gui = "underline" }),
		markdownItalic({ fg = nil, bg = nil, gui = "italic" }),
		markdownBold({ fg = nil, bg = nil, gui = "bold" }),
		markdownItalicDelimiter({ fg = grey1, bg = nil, gui = "italic" }),
		markdownCode({ Green }),
		markdownCodeBlock({ Aqua }),
		markdownCodeDelimiter({ Aqua }),
		markdownBlockquote({ Grey }),
		markdownListMarker({ Red }),
		markdownOrderedListMarker({ Red }),
		markdownRule({ Purple }),
		markdownHeadingRule({ Grey }),
		markdownUrlDelimiter({ Grey }),
		markdownLinkDelimiter({ Grey }),
		markdownLinkTextDelimiter({ Grey }),
		markdownHeadingDelimiter({ Grey }),
		markdownLinkText({ Purple }),
		markdownUrlTitleDelimiter({ Green }),
		markdownIdDeclaration({ markdownLinkText }),
		markdownBoldDelimiter({ Grey }),
		markdownId({ Yellow }),
		TSAnnotation({ Purple }),
		TSAttribute({ Purple }),
		TSBoolean({ Purple }),
		TSCharacter({ Yellow }),
		TSComment({ Grey }),
		TSConditional({ Red }),
		TSConstBuiltin({ PurpleItalic }),
		TSConstMacro({ Purple }),
		TSConstant({ PurpleItalic }),
		TSConstructor({ Fg }),
		TSError({ ErrorText }),
		TSException({ Red }),
		TSField({ Green }),
		TSFloat({ Purple }),
		TSFuncBuiltin({ Green }),
		TSFuncMacro({ Green }),
		TSFunction({ Green }),
		TSInclude({ PurpleItalic }),
		TSKeyword({ Red }),
		TSKeywordFunction({ Red }),
		TSLabel({ Orange }),
		TSMethod({ Green }),
		TSNamespace({ BlueItalic }),
		TSNumber({ Purple }),
		TSOperator({ Orange }),
		TSParameter({ Fg }),
		TSParameterReference({ Fg }),
		TSProperty({ Green }),
		TSPunctBracket({ Fg }),
		TSPunctDelimiter({ Grey }),
		TSPunctSpecial({ Fg }),
		TSRepeat({ Red }),
		TSString({ Yellow }),
		TSStringEscape({ Green }),
		TSStringRegex({ Green }),
		TSStructure({ Orange }),
		TSTag({ Orange }),
		TSTagDelimiter({ Green }),
		TSText({ Green }),
		TSType({ Aqua }),
		TSTypeBuiltin({ BlueItalic }),
		TSURI({ markdownUrl }),
		TSVariable({ Fg }),
		TSVariableBuiltin({ PurpleItalic }),
		TSEmphasis({ fg = nil, bg = nil, gui = "bold" }),
		TSUnderline({ fg = nil, bg = nil, gui = "underline" }),
		GitGutterAdd({ GreenSign }),
		GitGutterChange({ BlueSign }),
		GitGutterDelete({ RedSign }),
		GitGutterChangeDelete({ PurpleSign }),
		diffAdded({ Green }),
		diffRemoved({ Red }),
		diffChanged({ Blue }),
		diffOldFile({ Yellow }),
		diffNewFile({ Orange }),
		diffFile({ Aqua }),
		diffLine({ Grey }),
		diffIndexLine({ Purple }),
		netrwDir({ Green }),
		netrwClassify({ Green }),
		netrwLink({ Grey }),
		netrwSymLink({ Fg }),
		netrwExe({ Yellow }),
		netrwComment({ Grey }),
		netrwList({ Aqua }),
		netrwHelpCmd({ Blue }),
		netrwCmdSep({ Grey }),
		netrwVersion({ Orange }),
		elixirStringDelimiter({ Green }),
		elixirKeyword({ Orange }),
		elixirInterpolation({ Yellow }),
		elixirInterpolationDelimiter({ Yellow }),
		elixirSelf({ Purple }),
		elixirPseudoVariable({ Purple }),
		elixirModuleDefine({ PurpleItalic }),
		elixirBlockDefinition({ RedItalic }),
		elixirDefine({ RedItalic }),
		elixirPrivateDefine({ RedItalic }),
		elixirGuard({ RedItalic }),
		elixirPrivateGuard({ RedItalic }),
		elixirProtocolDefine({ RedItalic }),
		elixirImplDefine({ RedItalic }),
		elixirRecordDefine({ RedItalic }),
		elixirPrivateRecordDefine({ RedItalic }),
		elixirMacroDefine({ RedItalic }),
		elixirPrivateMacroDefine({ RedItalic }),
		elixirDelegateDefine({ RedItalic }),
		elixirOverridableDefine({ RedItalic }),
		elixirExceptionDefine({ RedItalic }),
		elixirCallbackDefine({ RedItalic }),
		elixirStructDefine({ RedItalic }),
		elixirExUnitMacro({ RedItalic }),
		gitcommitSummary({ Red }),
		gitcommitUntracked({ Grey }),
		gitcommitDiscarded({ Grey }),
		gitcommitSelected({ Grey }),
		gitcommitUnmerged({ Grey }),
		gitcommitOnBranch({ Grey }),
		gitcommitArrow({ Grey }),
		gitcommitFile({ Green }),

		-- 		Normal({ fg = cs.fg, bg = cs.bg0 }), -- normal text
		-- 		NormalFloat({ fg = cs.fg, bg = cs.bg2 }), -- Normal text in floating windows.
		-- 		-- NormalNC     { }, -- normal text in non-current windows
		--
		-- 		Conceal({ fg = cs.grey1, bg = nil }), -- placeholder characters substituted for concealed text (see 'conceallevel')
		--
		-- 		Cursor({ fg = nil, bg = nil, gui = "reverse" }), -- character under the cursor
		-- 		lCursor({ Cursor }), -- the character under the cursor when |language-mapping| is used (see 'guicursor')
		-- 		iCursor({ Cursor }),
		-- 		vCursor({ Cursor }),
		-- 		CursorIM({ Cursor }), -- like Cursor, but used when in IME mode |CursorIM|
		-- 		TermCursor({ Cursor }), -- cursor in a focused terminal
		-- 		TermCursorNC({ Cursor }), -- cursor in an unfocused terminal
		--
		-- 		ColorColumn({ fg = nil, bg = cs.bg1 }), -- used for the columns set with 'colorcolumn'
		-- 		CursorColumn({ fg = nil, bg = cs.bg1 }), -- Screen-column at the cursor, when 'cursorcolumn' is set.
		-- 		CursorLine({ fg = nil, bg = cs.bg1 }), -- Screen-line at the cursor, when 'cursorline' is set.  Low-priority if foreground (ctermfg OR guifg) is not set.
		-- 		CursorLineNr({ fg = cs.fg, bg = cs.bg1 }), -- Like LineNr when 'cursorline' or 'relativenumber' is set for the cursor line.
		-- 		LineNr({ fg = cs.grey0, bg = nil }), -- Line number for ":number" and ":#" commands, and when 'number' or 'relativenumber' option is set.
		-- 		VertSplit({ fg = cs.bg4, bg = nil }), -- the column separating vertically split windows
		--
		-- 		Directory({ fg = cs.green, bg = nil }), -- directory names (and other special names in listings)
		--
		-- 		DiffAdd({ fg = nil, bg = cs.bg_green }), -- diff mode: Added line |diff.txt|
		-- 		DiffChange({ fg = nil, bg = cs.bg_blue }), -- diff mode: Changed line |diff.txt|
		-- 		DiffDelete({ fg = nil, bg = cs.bg_red }), -- diff mode: Deleted line |diff.txt|
		-- 		DiffText({ fg = cs.bg0, bg = cs.fg }), -- diff mode: Changed text within a changed line |diff.txt|
		--
		-- 		EndOfBuffer({ fg = cs.bg0, bg = cs.bg0 }), -- filler lines (~) after the end of the buffer.  By default, this is highlighted like |hl-NonText|.
		--
		-- 		ErrorMsg({ fg = cs.red, bg = nil, gui = "bold,underline" }), -- error messages on the command line
		-- 		WarningMsg({ fg = cs.yellow, bg = nil }), -- warning messages
		-- 		ModeMsg({ fg = cs.fg, bg = nil, gui = "bold" }), -- 'showmode' message (e.g., "-- INSERT -- ")
		-- 		MoreMsg({ fg = cs.yellow, bg = nil, gui = "bold" }), -- |more-prompt|
		-- 		-- MsgArea      { }, -- Area for messages and cmdline
		-- 		-- MsgSeparator { }, -- Separator for scrolled messages, `msgsep` flag of 'display'
		--
		-- 		Folded({ fg = cs.grey1, bg = cs.bg1 }), -- line used for closed folds
		-- 		FoldColumn({ fg = cs.grey1, bg = cs.bg1 }), -- 'foldcolumn'
		--
		-- 		SignColumn({ fg = cs.fg, bg = cs.bg0 }), -- column where |signs| are displayed
		--
		-- 		IncSearch({ fg = cs.bg0, bg = cs.red }), -- 'incsearch' highlighting; also used for the text replaced with ":s///c"
		-- 		Search({ fg = cs.bg0, bg = cs.green }), -- Last search pattern highlighting (see 'hlsearch').  Also used for similar items that need to stand out.
		--
		-- 		Substitute({ fg = cs.bg0, bg = cs.yellow }), -- |:substitute| replacement text highlighting
		-- 		MatchParen({ fg = nil, bg = cs.bg4 }), -- The character under the cursor or just before it, if it is a paired bracket, and its match. |pi_paren.txt|
		-- 		NonText({ fg = cs.bg4, bg = nil }), -- '@' at the end of the window, characters from 'showbreak' and other characters that do not really exist in the text (e.g., ">" displayed when a double-wide character doesn't fit at the end of the line). See also |hl-EndOfBuffer|.
		--
		-- 		Pmenu({ fg = cs.fg, bg = cs.bg2 }), -- Popup menu: normal item.
		-- 		PmenuSel({ fg = cs.green, bg = nil }), -- Popup menu: selected item.
		-- 		PmenuSbar({ fg = nil, bg = cs.bg2 }), -- Popup menu: scrollbar.
		-- 		PmenuThumb({ fg = nil, bg = cs.grey1 }), -- Popup menu: Thumb of the scrollbar.
		--
		-- 		Question({ fg = cs.yellow, bg = nil }), -- |hit-enter| prompt and yes/no questions
		-- 		QuickFixLine({ fg = cs.purple, bg = nil, gui = "bold" }), -- Current |quickfix| item in the quickfix window. Combined with |hl-CursorLine| when the cursor is there.
		-- 		SpecialKey({ fg = cs.bg3, bg = nil }), -- Unprintable characters: text displayed differently from what it really is.  But not 'listchars' whitespace. |hl-Whitespace| SpellBad  Word that is not recognized by the spellchecker. |spell| Combined with the highlighting used otherwise.  SpellCap  Word that should start with a capital. |spell| Combined with the highlighting used otherwise.  SpellLocal  Word that is recognized by the spellchecker as one that is used in another region. |spell| Combined with the highlighting used otherwise.
		--
		-- 		SpellBad({ fg = cs.red, bg = nil, gui = "undercurl", sp = cs.red }),
		-- 		SpellCap({ fg = cs.blue, bg = nil, gui = "undercurl", sp = cs.blue }),
		-- 		SpellLocal({ fg = cs.cyan, bg = nil, gui = "undercurl", sp = cs.cyan }),
		-- 		SpellRare({ fg = cs.purple, bg = nil, gui = "undercurl", sp = cs.purple }), -- Word that is recognized by the spellchecker as one that is hardly ever used.  |spell| Combined with the highlighting used otherwise.
		--
		-- 		StatusLine({ fg = cs.grey1, bg = cs.bg1 }), -- status line of current window
		-- 		StatusLineTerm({ fg = cs.grey1, bg = cs.bg1 }), -- status line of current window
		-- 		StatusLineNC({ fg = cs.grey1, bg = cs.bg0 }), -- status lines of not-current windows Note: if this is equal to "StatusLine" Vim will use "^^^" in the status line of the current window.
		-- 		StatusLineTermNC({ fg = cs.grey1, bg = cs.bg0 }), -- status lines of not-current windows Note: if this is equal to "StatusLine" Vim will use "^^^" in the status line of the current window.
		--
		-- 		TabLine({ fg = cs.grey2, bg = cs.bg3 }), -- tab pages line, not active tab page label
		-- 		TabLineFill({ fg = cs.grey1, bg = cs.bg1 }), -- tab pages line, where there are no labels
		-- 		TabLineSel({ fg = cs.bg0, bg = cs.green }), -- tab pages line, active tab page label
		--
		-- 		-- Title        { }, -- titles for output from ":set all", ":autocmd" etc.
		--
		-- 		Visual({ fg = nil, bg = cs.bg_visual }), -- Visual mode selection
		-- 		VisualNOS({ fg = nil, bg = cs.bg_visual }), -- Visual mode selection when vim is "Not Owning the Selection".
		--
		-- 		Whitespace({ fg = cs.bg3, bg = nil }), -- "nbsp", "space", "tab" and "trail" in 'listchars'
		--
		-- 		WildMenu({ PmenuSel }), -- current match in 'wildmenu' completion
		--
		-- 		-- These groups are not listed as default vim groups,
		-- 		-- but they are defacto standard group names for syntax highlighting.
		-- 		-- commented out groups should chain up to their "preferred" group by
		-- 		-- default,
		-- 		-- Uncomment and edit if you want more specific syntax highlighting.
		-- 		Boolean({ fg = cs.purple, bg = nil }),
		-- 		Number({ fg = cs.purple, bg = nil }),
		-- 		Float({ fg = cs.purple, bg = nil }),
		-- 		PreProc({ fg = cs.purple, bg = nil, gui = "italic" }),
		-- 		PreCondit({ fg = cs.purple, bg = nil, gui = "italic" }),
		-- 		Include({ fg = cs.purple, bg = nil, gui = "italic" }),
		-- 		Define({ fg = cs.purple, bg = nil, gui = "italic" }),
		-- 		Conditional({ fg = cs.red, bg = nil, gui = "italic" }),
		-- 		Repeat({ fg = cs.red, bg = nil, gui = "italic" }),
		-- 		Keyword({ fg = cs.red, bg = nil, gui = "italic" }),
		-- 		Typedef({ fg = cs.red, bg = nil, gui = "italic" }),
		-- 		Exception({ fg = cs.red, bg = nil, gui = "italic" }),
		-- 		Statement({ fg = cs.red, bg = nil, gui = "italic" }),
		-- 		StorageClass({ fg = cs.orange, bg = nil }),
		-- 		Tag({ fg = cs.orange, bg = nil }),
		-- 		Label({ fg = cs.orange, bg = nil }),
		-- 		Structure({ fg = cs.orange, bg = nil }),
		-- 		Operator({ fg = cs.orange, bg = nil }),
		-- 		Title({ fg = cs.orange, bg = nil, gui = "bold" }),
		-- 		Special({ fg = cs.yellow, bg = nil }),
		-- 		SpecialChar({ fg = cs.yellow, bg = nil }),
		-- 		Type({ fg = cs.yellow, bg = nil }),
		-- 		Function({ fg = cs.green, bg = nil }),
		-- 		String({ fg = cs.green, bg = nil }),
		-- 		Character({ fg = cs.green, bg = nil }),
		-- 		Constant({ fg = cs.aqua, bg = nil }),
		-- 		Macro({ fg = cs.aqua, bg = nil }),
		-- 		Identifier({ fg = cs.blue, bg = nil }),
		-- 		Comment({ fg = cs.grey1, bg = nil, gui = "italic" }),
		-- 		SpecialComment({ fg = cs.grey1, bg = nil, gui = "italic" }),
		-- 		Delimiter({ fg = cs.fg, bg = nil }),
		--
		-- 		Debug({ fg = cs.orange, bg = nil }), --    debugging statements
		-- 		debugPC({ fg = cs.bg0, bg = cs.green }), --    debugging statements
		-- 		debugBreakpoint({ fg = cs.bg0, bg = cs.red }), --    debugging statements
		--
		-- 		CurrentWord({ fg = nil, bg = nil }),
		--
		-- 		Bold({ gui = "bold" }),
		-- 		Italic({ gui = "italic" }),
		-- 		Underlined({ fg = nil, bg = nil, gui = "underline" }),
		--
		-- 		Ignore({ fg = cs.grey1, bg = nil }),
		-- 		Error({ fg = cs.red, bg = nil }),
		-- 		Todo({ fg = cs.purple, bg = nil, gui = "italic" }),
		--
		-- 		RedSign({ fg = cs.red, bg = cs.bg1 }),
		-- 		OrangeSign({ fg = cs.orange, bg = cs.bg1 }),
		-- 		YellowSign({ fg = cs.yellow, bg = cs.bg1 }),
		-- 		GreenSign({ fg = cs.green, bg = cs.bg1 }),
		-- 		AquaSign({ fg = cs.aqua, bg = cs.bg1 }),
		-- 		BlueSign({ fg = cs.blue, bg = cs.bg1 }),
		-- 		PurpleSign({ fg = cs.purple, bg = cs.bg1 }),
		--
		-- 		Fg({ fg = cs.fg, bg = nil }),
		-- 		Grey({ fg = cs.grey1, bg = nil }),
		-- 		Red({ fg = cs.red, bg = nil }),
		-- 		Orange({ fg = cs.orange, bg = nil }),
		-- 		Yellow({ fg = cs.yellow, bg = nil }),
		-- 		Green({ fg = cs.green, bg = nil }),
		-- 		Aqua({ fg = cs.aqua, bg = nil }),
		-- 		Blue({ fg = cs.blue, bg = nil }),
		-- 		Purple({ fg = cs.purple, bg = nil }),
		--
		-- 		RedItalic({ fg = cs.red, bg = nil, gui = "italic" }),
		-- 		OrangeItalic({ fg = cs.orange, bg = nil, gui = "italic" }),
		-- 		YellowItalic({ fg = cs.yellow, bg = nil, gui = "italic" }),
		-- 		GreenItalic({ fg = cs.green, bg = nil, gui = "italic" }),
		-- 		AquaItalic({ fg = cs.aqua, bg = nil, gui = "italic" }),
		-- 		BlueItalic({ fg = cs.blue, bg = nil, gui = "italic" }),
		-- 		PurpleItalic({ fg = cs.purple, bg = nil, gui = "italic" }),
		--
		-- 		ErrorText({ fg = nil, bg = cs.bg_red, gui = "undercurl", sp = cs.red }),
		-- 		WarningText({ fg = nil, bg = cs.bg_yellow, gui = "undercurl", sp = cs.yellow }),
		-- 		InfoText({ fg = nil, bg = cs.bg_blue, gui = "undercurl", sp = cs.blue }),
		-- 		HintText({ fg = nil, bg = cs.bg_green, gui = "undercurl", sp = cs.green }),
		--
		-- 		ErrorLine({ fg = nil, bg = cs.bg_red }),
		-- 		WarningLine({ fg = nil, bg = cs.bg_yellow }),
		-- 		InfoLine({ fg = nil, bg = cs.bg_blue }),
		-- 		HintLine({ fg = nil, bg = cs.bg_green }),
		--
		-- 		ErrorFloat({ fg = cs.red, bg = cs.bg2 }),
		-- 		WarningFloat({ fg = cs.yellow, bg = cs.bg2 }),
		-- 		InfoFloat({ fg = cs.blue, bg = cs.bg2 }),
		-- 		HintFloat({ fg = cs.green, bg = cs.bg2 }),
		--
		-- 		LspDiagnosticsFloatingError({ ErrorFloat }),
		-- 		LspDiagnosticsFloatingWarning({ WarningFloat }),
		-- 		LspDiagnosticsFloatingInformation({ InfoFloat }),
		-- 		LspDiagnosticsFloatingHint({ HintFloat }),
		-- 		LspDiagnosticsDefaultError({ ErrorText }),
		-- 		LspDiagnosticsDefaultWarning({ WarningText }),
		-- 		LspDiagnosticsDefaultInformation({ InfoText }),
		-- 		LspDiagnosticsDefaultHint({ HintText }),
		-- 		LspDiagnosticsVirtualTextError({ ErrorFloat }),
		-- 		LspDiagnosticsVirtualTextWarning({ WarningFloat }),
		-- 		LspDiagnosticsVirtualTextInformation({ InfoFloat }),
		-- 		LspDiagnosticsVirtualTextHint({ HintFloat }),
		-- 		LspDiagnosticsUnderlineError({ ErrorText }),
		-- 		LspDiagnosticsUnderlineWarning({ WarningText }),
		-- 		LspDiagnosticsUnderlineInformation({ InfoText }),
		-- 		LspDiagnosticsUnderlineHint({ HintText }),
		-- 		LspDiagnosticsSignError({ RedSign }),
		-- 		LspDiagnosticsSignWarning({ YellowSign }),
		-- 		LspDiagnosticsSignInformation({ BlueSign }),
		-- 		LspDiagnosticsSignHint({ AquaSign }),
		-- 		LspReferenceText({ CurrentWord }),
		-- 		LspReferenceRead({ CurrentWord }),
		-- 		LspReferenceWrite({ CurrentWord }),
		-- 		TermCursor({ Cursor }),
		-- 		healthError({ Red }),
		-- 		healthSuccess({ Green }),
		-- 		healthWarning({ Yellow }),
		-- 		-- These groups are for the neovim tree-sitter highlights.
		-- 		-- As of writing, tree-sitter support is a WIP, group names may change.
		-- 		-- By default, most of these groups link to an appropriate Vim group,
		-- 		-- TSError -> Error for example, so you do not have to define these unless
		-- 		-- you explicitly want to support Treesitter's improved syntax awareness.
		--
		-- 		markdownH1({ fg = cs.red, bg = nil, gui = "bold" }),
		-- 		markdownH2({ fg = cs.orange, bg = nil, gui = "bold" }),
		-- 		markdownH3({ fg = cs.yellow, bg = nil, gui = "bold" }),
		-- 		markdownH4({ fg = cs.green, bg = nil, gui = "bold" }),
		-- 		markdownH5({ fg = cs.blue, bg = nil, gui = "bold" }),
		-- 		markdownH6({ fg = cs.purple, bg = nil, gui = "bold" }),
		-- 		markdownUrl({ fg = cs.blue, bg = nil, gui = "underline" }),
		-- 		markdownItalic({ fg = nil, bg = nil, gui = "italic" }),
		-- 		markdownBold({ fg = nil, bg = nil, gui = "bold" }),
		-- 		markdownItalicDelimiter({ fg = cs.grey1, bg = nil, gui = "italic" }),
		-- 		markdownCode({ Green }),
		-- 		markdownCodeBlock({ Aqua }),
		-- 		markdownCodeDelimiter({ Aqua }),
		-- 		markdownBlockquote({ Grey }),
		-- 		markdownListMarker({ Red }),
		-- 		markdownOrderedListMarker({ Red }),
		-- 		markdownRule({ Purple }),
		-- 		markdownHeadingRule({ Grey }),
		-- 		markdownUrlDelimiter({ Grey }),
		-- 		markdownLinkDelimiter({ Grey }),
		-- 		markdownLinkTextDelimiter({ Grey }),
		-- 		markdownHeadingDelimiter({ Grey }),
		-- 		markdownLinkText({ Purple }),
		-- 		markdownUrlTitleDelimiter({ Green }),
		-- 		markdownIdDeclaration({ markdownLinkText }),
		-- 		markdownBoldDelimiter({ Grey }),
		-- 		markdownId({ Yellow }),
		-- 		TSAnnotation({ Purple }),
		-- 		TSAttribute({ Purple }),
		-- 		TSBoolean({ Purple }),
		-- 		TSCharacter({ Yellow }),
		-- 		TSComment({ Grey }),
		-- 		TSConditional({ Red }),
		-- 		TSConstBuiltin({ PurpleItalic }),
		-- 		TSConstMacro({ Purple }),
		-- 		TSConstant({ PurpleItalic }),
		-- 		TSConstructor({ Fg }),
		-- 		TSError({ ErrorText }),
		-- 		TSException({ Red }),
		-- 		TSField({ Green }),
		-- 		TSFloat({ Purple }),
		-- 		TSFuncBuiltin({ Green }),
		-- 		TSFuncMacro({ Green }),
		-- 		TSFunction({ Green }),
		-- 		TSInclude({ PurpleItalic }),
		-- 		TSKeyword({ Red }),
		-- 		TSKeywordFunction({ Red }),
		-- 		TSLabel({ Orange }),
		-- 		TSMethod({ Green }),
		-- 		TSNamespace({ BlueItalic }),
		-- 		TSNumber({ Purple }),
		-- 		TSOperator({ Orange }),
		-- 		TSParameter({ Fg }),
		-- 		TSParameterReference({ Fg }),
		-- 		TSProperty({ Green }),
		-- 		TSPunctBracket({ Fg }),
		-- 		TSPunctDelimiter({ Grey }),
		-- 		TSPunctSpecial({ Fg }),
		-- 		TSRepeat({ Red }),
		-- 		TSString({ Yellow }),
		-- 		TSStringEscape({ Green }),
		-- 		TSStringRegex({ Green }),
		-- 		TSStructure({ Orange }),
		-- 		TSTag({ Orange }),
		-- 		TSTagDelimiter({ Green }),
		-- 		TSText({ Green }),
		-- 		TSType({ Aqua }),
		-- 		TSTypeBuiltin({ BlueItalic }),
		-- 		TSURI({ markdownUrl }),
		-- 		TSVariable({ Fg }),
		-- 		TSVariableBuiltin({ PurpleItalic }),
		-- 		TSEmphasis({ fg = nil, bg = nil, gui = "bold" }),
		-- 		TSUnderline({ fg = nil, bg = nil, gui = "underline" }),
		-- 		GitGutterAdd({ GreenSign }),
		-- 		GitGutterChange({ BlueSign }),
		-- 		GitGutterDelete({ RedSign }),
		-- 		GitGutterChangeDelete({ PurpleSign }),
		-- 		diffAdded({ Green }),
		-- 		diffRemoved({ Red }),
		-- 		diffChanged({ Blue }),
		-- 		diffOldFile({ Yellow }),
		-- 		diffNewFile({ Orange }),
		-- 		diffFile({ Aqua }),
		-- 		diffLine({ Grey }),
		-- 		diffIndexLine({ Purple }),
		-- 		netrwDir({ Green }),
		-- 		netrwClassify({ Green }),
		-- 		netrwLink({ Grey }),
		-- 		netrwSymLink({ Fg }),
		-- 		netrwExe({ Yellow }),
		-- 		netrwComment({ Grey }),
		-- 		netrwList({ Aqua }),
		-- 		netrwHelpCmd({ Blue }),
		-- 		netrwCmdSep({ Grey }),
		-- 		netrwVersion({ Orange }),
		-- 		elixirStringDelimiter({ Green }),
		-- 		elixirKeyword({ Orange }),
		-- 		elixirInterpolation({ Yellow }),
		-- 		elixirInterpolationDelimiter({ Yellow }),
		-- 		elixirSelf({ Purple }),
		-- 		elixirPseudoVariable({ Purple }),
		-- 		elixirModuleDefine({ PurpleItalic }),
		-- 		elixirBlockDefinition({ RedItalic }),
		-- 		elixirDefine({ RedItalic }),
		-- 		elixirPrivateDefine({ RedItalic }),
		-- 		elixirGuard({ RedItalic }),
		-- 		elixirPrivateGuard({ RedItalic }),
		-- 		elixirProtocolDefine({ RedItalic }),
		-- 		elixirImplDefine({ RedItalic }),
		-- 		elixirRecordDefine({ RedItalic }),
		-- 		elixirPrivateRecordDefine({ RedItalic }),
		-- 		elixirMacroDefine({ RedItalic }),
		-- 		elixirPrivateMacroDefine({ RedItalic }),
		-- 		elixirDelegateDefine({ RedItalic }),
		-- 		elixirOverridableDefine({ RedItalic }),
		-- 		elixirExceptionDefine({ RedItalic }),
		-- 		elixirCallbackDefine({ RedItalic }),
		-- 		elixirStructDefine({ everforestRedItalic }),
		-- 		elixirExUnitMacro({ RedItalic }),
		-- 		gitcommitSummary({ Red }),
		-- 		gitcommitUntracked({ Grey }),
		-- 		gitcommitDiscarded({ Grey }),
		-- 		gitcommitSelected({ Grey }),
		-- 		gitcommitUnmerged({ Grey }),
		-- 		gitcommitOnBranch({ Grey }),
		-- 		gitcommitArrow({ Grey }),
		-- 		gitcommitFile({ Green }),
	}
end)

-- vi:nowrap
