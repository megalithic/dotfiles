# Qutebrowser's theme

scheme = {
    'main_bg': '#000000',
    'priv_bg': '#111111',
    'main_fg': '#777777',
    'select':  '#FFFFFF',
    'info':    '#0077FF',
    'error':   '#FF0000',
    'warning': '#FF7700',
    'hint':    'qlineargradient(x1:0,y1:0,x2:0,y2:0.5,stop:0 #F00,stop:1 #000)'
}


c.colors.completion.fg                          = [scheme['info'],
                                                   scheme['main_fg'],
                                                   scheme['info']]
c.colors.completion.odd.bg                      = scheme['main_bg']
c.colors.completion.even.bg                     = scheme['main_bg']
c.colors.completion.category.fg                 = scheme['info']
c.colors.completion.category.bg                 = scheme['main_bg']
c.colors.completion.category.border.top         = scheme['main_bg']
c.colors.completion.category.border.bottom      = scheme['main_fg']
c.colors.completion.item.selected.fg            = scheme['select']
c.colors.completion.item.selected.bg            = scheme['main_bg']
c.colors.completion.item.selected.border.top    = scheme['main_bg']
c.colors.completion.item.selected.border.bottom = scheme['main_bg']
c.colors.completion.item.selected.match.fg      = scheme['error']
c.colors.completion.match.fg                    = scheme['error']
c.colors.completion.scrollbar.fg                = scheme['info']
c.colors.completion.scrollbar.bg                = scheme['main_bg']

#c.colors.contextmenu.bg                        =
#c.colors.contextmenu.fg                        =
#c.colors.contextmenu.menu.bg                   =
#c.colors.contextmenu.menu.fg                   =
#c.colors.contextmenu.selected.bg               =
#c.colors.contextmenu.selected.fg               =
#c.colors.contextmenu.disabled.bg               =
#c.colors.contextmenu.disabled.fg               =

c.colors.downloads.bar.bg                       = scheme['main_bg']
c.colors.downloads.start.fg                     = scheme['info']
c.colors.downloads.start.bg                     = scheme['main_bg']
c.colors.downloads.stop.fg                      = scheme['main_bg']
c.colors.downloads.stop.bg                      = scheme['main_fg']
c.colors.downloads.error.fg                     = scheme['error']
c.colors.downloads.error.bg                     = scheme['main_bg']

c.colors.hints.fg                               = scheme['select']
c.colors.hints.bg                               = scheme['hint']
c.colors.hints.match.fg                         = scheme['error']
c.hints.border                                  = '1 solid ' + scheme['error']
c.hints.radius                                  = 0

c.colors.keyhint.fg                             = scheme['main_fg']
c.colors.keyhint.suffix.fg                      = scheme['info']
c.colors.keyhint.bg                             = scheme['main_bg']

c.colors.messages.error.fg                      = scheme['error']
c.colors.messages.error.bg                      = scheme['main_bg']
c.colors.messages.error.border                  = scheme['error']
c.colors.messages.warning.fg                    = scheme['warning']
c.colors.messages.warning.bg                    = scheme['main_bg']
c.colors.messages.warning.border                = scheme['warning']
c.colors.messages.info.fg                       = scheme['info']
c.colors.messages.info.bg                       = scheme['main_bg']
c.colors.messages.info.border                   = scheme['info']

c.colors.prompts.fg                             = scheme['main_fg']
c.colors.prompts.border                         = 'none'
c.colors.prompts.bg                             = scheme['main_bg']
c.colors.prompts.selected.fg                    = scheme['select']
c.colors.prompts.selected.bg                    = scheme['main_bg']

c.colors.statusbar.normal.fg                    = scheme['select']
c.colors.statusbar.normal.bg                    = scheme['main_bg']
c.colors.statusbar.insert.fg                    = scheme['info']
c.colors.statusbar.insert.bg                    = scheme['main_bg']
c.colors.statusbar.passthrough.fg               = scheme['warning']
c.colors.statusbar.passthrough.bg               = scheme['main_bg']
c.colors.statusbar.private.fg                   = scheme['select']
c.colors.statusbar.private.bg                   = scheme['priv_bg']
c.colors.statusbar.command.fg                   = scheme['select']
c.colors.statusbar.command.bg                   = scheme['main_bg']
c.colors.statusbar.command.private.fg           = scheme['select']
c.colors.statusbar.command.private.bg           = scheme['priv_bg']
c.colors.statusbar.caret.fg                     = scheme['info']
c.colors.statusbar.caret.bg                     = scheme['main_bg']
c.colors.statusbar.caret.selection.fg           = scheme['info']
c.colors.statusbar.caret.selection.bg           = scheme['main_bg']
c.colors.statusbar.progress.bg                  = scheme['info']
c.colors.statusbar.url.fg                       = scheme['info']
c.colors.statusbar.url.error.fg                 = scheme['error']
c.colors.statusbar.url.hover.fg                 = scheme['info']
c.colors.statusbar.url.success.http.fg          = scheme['warning']
c.colors.statusbar.url.success.https.fg         = scheme['select']
c.colors.statusbar.url.warn.fg                  = scheme['warning']

c.colors.tabs.bar.bg                            = scheme['main_bg']
c.colors.tabs.indicator.start                   = scheme['main_fg']
c.colors.tabs.indicator.stop                    = scheme['info']
c.colors.tabs.indicator.error                   = scheme['error']
c.colors.tabs.odd.fg                            = scheme['main_fg']
c.colors.tabs.odd.bg                            = scheme['main_bg']
c.colors.tabs.even.fg                           = scheme['main_fg']
c.colors.tabs.even.bg                           = scheme['main_bg']
c.colors.tabs.selected.odd.fg                   = scheme['info']
c.colors.tabs.selected.odd.bg                   = scheme['main_bg']
c.colors.tabs.selected.even.fg                  = scheme['info']
c.colors.tabs.selected.even.bg                  = scheme['main_bg']
c.colors.tabs.pinned.odd.fg                     = scheme['info']
c.colors.tabs.pinned.odd.bg                     = scheme['main_bg']
c.colors.tabs.pinned.even.fg                    = scheme['info']
c.colors.tabs.pinned.even.bg                    = scheme['main_bg']
c.colors.tabs.pinned.selected.odd.fg            = scheme['info']
c.colors.tabs.pinned.selected.odd.bg            = scheme['main_bg']
c.colors.tabs.pinned.selected.even.fg           = scheme['info']
c.colors.tabs.pinned.selected.even.bg           = scheme['main_bg']

c.colors.webpage.bg                             = scheme['priv_bg']
c.colors.webpage.darkmode.enabled               = True
c.colors.webpage.darkmode.threshold.background  = 205
c.colors.webpage.darkmode.threshold.text        = 150
c.colors.webpage.preferred_color_scheme         = 'dark'
