#### Documentation ####
#
#   qute://help/configuring.html
#   qute://help/settings.html
#
#######################

#### Configuration ####

### System/environment boilerplate {{{

import os
import platform

import dracula.draw

# Load existing settings made via :set
config.load_autoconfig()

config.source('themes/material-darker.py')

# dracula.draw.blood(c, {
#     'spacing': {
#         'vertical': 6,
#         'horizontal': 8
#     }
# })
# bg_color = "#a89984"
bg_color = '#000000'
# c.colors.webpage.bg = bg_color

# c.colors.webpage.darkmode.enabled = True
# c.colors.webpage.darkmode.policy.images = 'smart'

# Put kitty, gvim, etc. in Qutebrowser's PATH, at least on macOS
os.environ['PATH'] = '/usr/local/bin' + os.pathsep + os.environ['PATH']

### System/environment boilerplate }}}

### Custom Userscripts {{{

USERSCRIPT_PATH = os.path.join(config.configdir, 'userscripts')

def userscript(script_name):
    return os.path.join(USERSCRIPT_PATH, script_name)

###### code_select ######
# https://github.com/LaurenceWarne/qute-code-hint

c.hints.selectors["code"] = [
    # Selects all code tags whose direct parent is not a pre tag
    ":not(pre) > code",
    "pre"
]

### Custom Userscripts }}}

### Assorted configs {{{

# Time interval (in milliseconds) between auto-saves of config/cookies/etc.
c.auto_save.interval = 15000

# Always restore open sites when qutebrowser is reopened. Type: Bool
c.auto_save.session = True

c.editor.command = ["kitty", "nvim", "-f", "{file}", "-c", "normal {line}G{column0}l"]

c.content.pdfjs = False
c.content.autoplay = False
c.tabs.background = True
c.tabs.close_mouse_button = 'right'

c.colors.webpage.preferred_color_scheme = 'dark'

c.downloads.remove_finished = 696969

c.tabs.last_close = 'default-page'
c.tabs.width = '10%'
c.tabs.mousewheel_switching = False

c.zoom.mouse_divider = 0

padding = {
    'top': 6,
    'bottom': 6,
    'right': 8,
    'left': 8,
}
c.statusbar.padding = padding
c.tabs.padding = padding
c.tabs.indicator.width = 1
c.tabs.favicons.scale = 1

# Open external applications
for site in [
            'zoommtg://*.zoom.us',
            'https://*.slack.com',
        ]:
    config.set('content.unknown_url_scheme_policy', 'allow-all', site)

# Acess clipboard
for site in [
            'https://github.com/*',
            'https://stackoverflow.com/*',
            'https://*.stackexchange.com/*',
            'https://*.google.com/*',
        ]:
    config.set('content.javascript.can_access_clipboard', True, site)

### Assorted configs }}}
