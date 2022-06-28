-- vim.cmd([[
-- syntax match MarkdownDot /\\\./ conceal cchar=.
-- syntax match MarkdownSlash /\\\-/ conceal cchar=-
-- syntax match MarkdownSemicolon /\\\;/ conceal cchar=;
-- syntax match MarkdownColon /\\\:/ conceal cchar=:
-- syntax match MarkdownSQuote /\\\'/ conceal cchar='
-- syntax match MarkdownDQuote /\\\"/ conceal cchar="
-- syntax match MarkdownBackslash /\\\// conceal cchar=/
-- syntax match todoCheckbox "\v.*\[\ \]"hs=e-2 conceal cchar=
-- syntax match todoCheckbox "\v.*\[x\]"hs=e-2 conceal cchar=
-- syntax match todoCheckbox "\v.*\[X\]"hs=e-2 conceal cchar=
-- syntax match NoSpellAcronym '\<\(\u\|\d\)\{3,}s\?\>' contains=@NoSpell
-- ]])

-- REF:
-- https://github.com/mickael-menu/zk-nvim#syntax-highlighting-tips
vim.cmd([[
" markdownWikiLink is a new region
syn region markdownWikiLink matchgroup=markdownLinkDelimiter start="\[\[" end="\]\]" contains=markdownUrl keepend oneline concealends
" markdownLinkText is copied from runtime files with 'concealends' appended
syn region markdownLinkText matchgroup=markdownLinkTextDelimiter start="!\=\[\%(\%(\_[^][]\|\[\_[^][]*\]\)*]\%( \=[[(]\)\)\@=" end="\]\%( \=[[(]\)\@=" nextgroup=markdownLink,markdownId skipwhite contains=@markdownInline,markdownLineStart concealends
" markdownLink is copied from runtime files with 'conceal' appended
syn region markdownLink matchgroup=markdownLinkDelimiter start="(" end=")" contains=markdownUrl keepend contained conceal
]])
