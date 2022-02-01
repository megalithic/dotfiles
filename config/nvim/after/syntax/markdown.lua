-- vim.cmd([[
-- syntax match MarkdownDot /\\\./ conceal cchar=.
-- syntax match MarkdownSlash /\\\-/ conceal cchar=-
-- syntax match MarkdownSemicolon /\\\;/ conceal cchar=;
-- syntax match MarkdownColon /\\\:/ conceal cchar=:
-- syntax match MarkdownSQuote /\\\'/ conceal cchar='
-- syntax match MarkdownDQuote /\\\"/ conceal cchar="
-- syntax match MarkdownBackslash /\\\// conceal cchar=/

-- let b:markdown_in_jekyll=0

-- if getline(1) =~ '^---\s*$'
--     let b:markdown_in_jekyll=1

--     syn region markdownJekyllFrontMatter matchgroup=markdownJekyllDelimiter contains=@NoSpell
--     \ start="\%^---" end="^---$" concealends

--     syn region markdownJekyllLiquidTag matchgroup=markdownJekyllDelimiter contains=@NoSpell oneline
--     \ start="{%" end="%}"

--     syn region markdownJekyllClass matchgroup=markdownJekyllDelimiter contains=@NoSpell oneline
--     \ start="{:" end="}"

--     syn region markdownJekyllLiquidOutputTag matchgroup=markdownJekyllDelimiter contains=@NoSpell oneline
--     \ start="{{" skip=/"}}"/ end="}}"

--     syn region markdownJekyllLiquidBlockTag matchgroup=markdownJekyllDelimiter contains=@NoSpell
--     \ start="{%\s*\z(comment\|raw\|highlight\)[^%]*%}" end="{%\s*\%(no\|end\)\z1\s*%}"

--     silent spell! nocomment
--     silent spell! endcomment
--     silent spell! nohighlight
--     silent spell! endhighlight
--     silent spell! noraw
--     silent spell! endraw

--     hi def link markdownJekyllFrontMatter         Comment
--     hi def link markdownJekyllLiquidTag           markdownCodeBlock
--     hi def link markdownJekyllClass               htmlString
--     hi def link markdownJekyllLiquidOutputTag     NonText
--     hi def link markdownJekyllLiquidBlockTag      NonText
--     hi def link markdownJekyllDelimiter           Delimiter
-- endif
-- ]])

-- https://vi.stackexchange.com/a/4003/16249
vim.cmd([[
syntax match MarkdownDot /\\\./ conceal cchar=.
syntax match MarkdownSlash /\\\-/ conceal cchar=-
syntax match MarkdownSemicolon /\\\;/ conceal cchar=;
syntax match MarkdownColon /\\\:/ conceal cchar=:
syntax match MarkdownSQuote /\\\'/ conceal cchar='
syntax match MarkdownDQuote /\\\"/ conceal cchar="
syntax match MarkdownBackslash /\\\// conceal cchar=/
syntax match todoCheckbox "\v.*\[\ \]"hs=e-2 conceal cchar=
syntax match todoCheckbox "\v.*\[x\]"hs=e-2 conceal cchar=
syntax match NoSpellAcronym '\<\(\u\|\d\)\{3,}s\?\>' contains=@NoSpell
]])

mega.highlight("Conceal", { guibg = "NONE" })
