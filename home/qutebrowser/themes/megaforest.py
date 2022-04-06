# taken from:
# https://github.com/nebulaeandstars/dotfiles/blob/master/qutebrowser/.config/qutebrowser/config.py#L73

# color variables
cream = "#ffffd8"
mauve = "#ffd8ff"
sky = "#d8ffff"

black = "#323d43"
red = "#e68183"
green = "#a7c080"
yellow = "#dbbc7f"
blue = "#7fbbb3"
magenta = "#d699b6"
cyan = "#83c092"
white = "#d8cacc"

brightblack = "#2e383e"
brightred = "#c43e1f"
brightgreen = "#6bc46d"
brightyellow = "#FAB005"
brightblue = "#51afef"
brightmagenta = "#c678dd"
brightcyan = "#15AABF"
brightwhite = "#ffffff"

darkblack = "#273433"  # 283534
darkgreen = "#4e6053"
darkblue = "#415c6d"
darkyellow = "#5d5c50"


# COMPLETION WIDGET # COMPLETION WIDGET # COMPLETION WIDGET #

## completion widget category headers
c.colors.completion.category.bg = darkblue
c.colors.completion.category.border.bottom = blue
c.colors.completion.category.border.top = black
c.colors.completion.category.fg = brightwhite

# completion widget rows
c.colors.completion.even.bg = black
c.colors.completion.odd.bg = black

# completion widget columns
c.colors.completion.fg = [brightwhite, brightwhite, brightwhite]

# selected completion item
c.colors.completion.item.selected.bg = darkyellow
c.colors.completion.item.selected.border.bottom = black
c.colors.completion.item.selected.border.top = black
c.colors.completion.item.selected.fg = brightwhite

# completion matches
c.colors.completion.item.selected.match.fg = brightgreen
c.colors.completion.match.fg = brightblue

# widget scrollbar
c.colors.completion.scrollbar.bg = black
c.colors.completion.scrollbar.fg = brightwhite


# CONTEXT MENU # CONTEXT MENU # CONTEXT MENU # CONTEXT MENU # CONTEXT MENU #

# context menu
c.colors.contextmenu.menu.bg = black
c.colors.contextmenu.menu.fg = brightwhite

# context menu selection
c.colors.contextmenu.selected.bg = brightblack
c.colors.contextmenu.selected.fg = brightwhite

# context menu disabled items
c.colors.contextmenu.disabled.bg = black
c.colors.contextmenu.disabled.fg = brightblack


# DOWNLOADS # DOWNLOADS # DOWNLOADS # DOWNLOADS # DOWNLOADS # DOWNLOADS #

# download bar
c.colors.downloads.bar.bg = black
c.colors.downloads.start.bg = blue
c.colors.downloads.start.fg = black
c.colors.downloads.stop.bg = brightgreen
c.colors.downloads.stop.fg = black
c.colors.downloads.system.bg = "rgb"
c.colors.downloads.system.fg = "rgb"

# download bar with errors
c.colors.downloads.error.bg = red
c.colors.downloads.error.fg = brightwhite


# HINTS # HINTS # HINTS # HINTS # HINTS # HINTS # HINTS # HINTS # HINTS #

# hints
c.colors.hints.bg = cyan
c.colors.hints.fg = black
c.hints.border = "2px solid " + black
c.colors.hints.match.fg = brightblack

## keyhint widget
c.colors.keyhint.bg = "rgba(10, 10, 10, 80%)"
c.colors.keyhint.fg = brightwhite

# keys to complete chain in keyhint widget
c.colors.keyhint.suffix.fg = brightblue


# MESSAGES # MESSAGES # MESSAGES # MESSAGES # MESSAGES # MESSAGES #

# error messages
c.colors.messages.error.bg = red
c.colors.messages.error.border = red
c.colors.messages.error.fg = brightwhite

# info messages
c.colors.messages.info.bg = black
c.colors.messages.info.border = black
c.colors.messages.info.fg = brightwhite

c.colors.messages.warning.bg = brightyellow
c.colors.messages.warning.border = brightyellow
c.colors.messages.warning.fg = black


# PROMPTS # PROMPTS # PROMPTS # PROMPTS # PROMPTS # PROMPTS # PROMPTS #

# prompts
c.colors.prompts.bg = black
c.colors.prompts.border = "1px solid " + brightblack
c.colors.prompts.fg = brightwhite

## selected item in filename prompts
c.colors.prompts.selected.bg = brightblack


# STATUSBAR # STATUSBAR # STATUSBAR # STATUSBAR # STATUSBAR # STATUSBAR #

# statusbar in normal mode
c.colors.statusbar.normal.bg = darkblack
c.colors.statusbar.normal.fg = brightwhite

# statusbar in caret mode
c.colors.statusbar.caret.bg = blue
c.colors.statusbar.caret.fg = brightwhite

# statusbar in caret mode with selection
c.colors.statusbar.caret.selection.bg = blue
c.colors.statusbar.caret.selection.fg = brightwhite

# statusbar in command mode
c.colors.statusbar.command.bg = black
c.colors.statusbar.command.fg = brightwhite

# statusbar in command mode with private browsing
c.colors.statusbar.command.private.bg = magenta
c.colors.statusbar.command.private.fg = brightwhite

# statusbar in insert mode
c.colors.statusbar.insert.bg = green
c.colors.statusbar.insert.fg = brightwhite

# statusbar in passthrough mode
c.colors.statusbar.passthrough.bg = cyan
c.colors.statusbar.passthrough.fg = brightwhite

# statusbar in private browsing mode
c.colors.statusbar.private.bg = magenta
c.colors.statusbar.private.fg = brightwhite

# statusbar url
c.colors.statusbar.url.fg = brightwhite  # while loading
c.colors.statusbar.url.success.http.fg = brightyellow  # loaded http
c.colors.statusbar.url.success.https.fg = brightgreen  # loaded https

c.colors.statusbar.url.hover.fg = brightcyan  # hovering over links
c.colors.statusbar.url.error.fg = brightred  # with error
c.colors.statusbar.url.warn.fg = yellow  # with warning

# progress bar
c.colors.statusbar.progress.bg = brightwhite


# TABS # TABS # TABS # TABS # TABS # TABS # TABS # TABS # TABS # TABS #

# tab bar
c.colors.tabs.bar.bg = brightblack

# tab indicator
c.colors.tabs.indicator.start = blue
c.colors.tabs.indicator.stop = brightgreen
c.colors.tabs.indicator.system = "rgb"

c.colors.tabs.indicator.error = red

# unselected tabs
c.colors.tabs.even.bg = black
c.colors.tabs.even.fg = white
c.colors.tabs.odd.bg = black
c.colors.tabs.odd.fg = white

# pinned unselected tabs
c.colors.tabs.pinned.even.bg = darkblack
c.colors.tabs.pinned.even.fg = cyan
c.colors.tabs.pinned.odd.bg = darkblack
c.colors.tabs.pinned.odd.fg = cyan

# selected tabs
c.colors.tabs.selected.even.bg = darkblue
c.colors.tabs.selected.even.fg = brightwhite
c.colors.tabs.selected.odd.bg = darkblue
c.colors.tabs.selected.odd.fg = brightwhite

# pinned selected tabs
c.colors.tabs.pinned.selected.even.bg = darkblue
c.colors.tabs.pinned.selected.even.fg = brightcyan
c.colors.tabs.pinned.selected.odd.bg = darkblue
c.colors.tabs.pinned.selected.odd.fg = brightcyan


# OTHER # OTHER # OTHER # OTHER # OTHER # OTHER # OTHER # OTHER # OTHER #

# default background color for webpages if unset
c.colors.webpage.bg = black

# force `prefers-color-scheme: dark` for websites.
c.colors.webpage.preferred_color_scheme = "dark"
