# --> REFS:
# - https://git.sr.ht/~palb91/dotfiles/tree/main/item/qutebrowser/config.py
# - https://github.com/j-hui/pokerus/tree/main/qutebrowser/.qutebrowser
# - https://github.com/The-Compiler/dotfiles/blob/master/qutebrowser/gruvbox.py
# - https://github.com/dracula/qutebrowser
# = https://qutebrowser.org/img/cheatsheet-big.png
# + https://www.ii.com/qutebrowser-configpy/
# + https://www.ii.com/qutebrowser-tips-fragments/#_my_configpy_settings
# + https://www.qutebrowser.org/doc/help/configuring.html
# * https://github.com/qutebrowser/qutebrowser/tree/master/misc/userscripts
# : qute://help/configuring.html
# : qute://help/settings.html


# --> IMPORTS:
import os


# --> PRE:
# Start directly with python configuration; skip ones created with :set
config.load_autoconfig(False)


# --> LOADERS:
# Apply splitted configuration
# for source in [
#         'aliases',
#         'binding',
#         'patterns',
#         'plugins',
#         'redirect',
#         'searchengine',
#         'theme'
#     ]:
#     config.source('settings/{}.py'.format(source))


# --> SETTINGS:
commands = {
# c.editor.command = ["kitty", "nvim", "-f", "{file}", "-c", "normal {line}G{column0}l"]
  'edit':       "kitty nvim -f {file} -c normal {line}G{column0}l".split(),
  # 'edit':       'foot -T float vim {file}'.split(),
  # 'pick_dir':   'foot -T float ranger --choosedir={}'.split(),
  # 'pick_files': 'foot -T float ranger --choosefiles={}'.split(),
  # 'pick_file':  'foot -T float ranger --choosefile={}'.split()
}


# --> CONFIG:
c.auto_save.interval                = 15000
c.auto_save.session                 = True
c.completion.open_categories        = ['quickmarks','history','searchengines']
c.completion.quick                  = False
c.completion.scrollbar.padding      = 0
c.completion.scrollbar.width        = 8
c.confirm_quit                      = ['multiple-tabs','downloads']
c.downloads.location.remember       = False
c.downloads.location.suggestion     = 'both'
c.downloads.position                = 'bottom'
# c.downloads.remove_finished         = 696969
c.editor.command                    = commands["edit"]
# c.fileselect.folder.command         = commands["pick_dir"]
# c.fileselect.handler                = 'external'
# c.fileselect.multiple_files.command = commands["pick_files"]
# c.fileselect.single_file.command    = commands["pick_file"]
c.fonts.contextmenu                 = 'default_size default_family'
c.fonts.default_family              = 'JetBrains Mono'
c.fonts.default_size                = '14px'
c.fonts.prompts                     = 'default_size default_family'
c.hints.chars                       = 'ctsrvdlgh'
c.history_gap_interval              = 240
c.input.escape_quits_reporter       = True
c.input.mouse.rocker_gestures       = True
c.input.partial_timeout             = 10000
c.keyhint.delay                     = 250
c.messages.timeout                  = 5000
c.new_instance_open_target          = 'tab-bg'
c.tabs.last_close                   = 'blank'
c.tabs.position                     = 'top'
c.tabs.show                         = 'multiple'
c.tabs.undo_stack_size              = 20
c.tabs.width                        = "10%" # 60
c.tabs.close_mouse_button           = 'right'
c.url.open_base_url                 = True
c.url.default_page                  = 'about:blank'
c.url.start_pages                   = 'about:blank'

padding = {
    'top': 6,
    'bottom': 6,
    'right': 8,
    'left': 8,
}
c.statusbar.padding                 = padding
c.tabs.padding                      = padding
c.tabs.indicator.width              = 1
c.tabs.favicons.scale               = 1

# Minimizing fingerprinting and annoying things
u_agent = 'Mozilla/5.0 (Windows NT 10.0; rv:91.0) Gecko/20100101 Firefox/91.0'
# User agent to send.  The following placeholders are defined:
# * `{os_info}`: Something like "X11; Linux x86_64".
# * `{webkit_version}`: The underlying WebKit version
#       (set to a fixed value with QtWebEngine).
# * `{qt_key}`: "Qt" for QtWebKit, "QtWebEngine" for QtWebEngine.
# * `{qt_version}`: The underlying Qt version.
# * `{upstream_browser_key}`: "Version" for QtWebKit, "Chrome" for QtWebEngine.
# * `{upstream_browser_version}`: The corresponding Safari/Chrome version.
# * `{qutebrowser_version}`: The currently running qutebrowser version.
#       The default value is equal to the unchanged user agent of QtWebKit/QtWebEngine.
#       Note that the value read from JavaScript is always the global value.
# Type: FormatString
# config.set('content.headers.user_agent', 'Mozilla/5.0 ({os_info}) AppleWebKit/{webkit_version} (KHTML, like Gecko) {upstream_browser_key}/{upstream_browser_version} Safari/{webkit_version}', 'https://web.whatsapp.com/')
# config.set('content.headers.user_agent', 'Mozilla/5.0 ({os_info}; rv:71.0) Gecko/20100101 Firefox/71.0', 'https://accounts.google.com/*')
# config.set('content.headers.user_agent', 'Mozilla/5.0 ({os_info}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99 Safari/537.36', 'https://*.slack.com/*')
# config.set('content.headers.user_agent', 'Mozilla/5.0 ({os_info}; rv:71.0) Gecko/20100101 Firefox/71.0', 'https://docs.google.com/*')

# Load images automatically in web pages. Type: Bool
config.set('content.images', True, 'chrome-devtools://*')
config.set('content.images', True, 'devtools://*')

# Enable JavaScript. Type: Bool
config.set('content.javascript.enabled', True, 'chrome-devtools://*')
config.set('content.javascript.enabled', True, 'devtools://*')
config.set('content.javascript.enabled', True, 'chrome://*/*')
config.set('content.javascript.enabled', True, 'qute://*/*')

c.content.autoplay                  = False
c.content.images                    = True
c.content.javascript.enabled        = False
c.content.canvas_reading            = False
c.content.cookies.accept            = 'no-unknown-3rdparty'
c.content.geolocation               = False
c.content.headers.user_agent        = u_agent
c.content.notifications.enabled     = False
c.content.pdfjs                     = True
c.content.register_protocol_handler = False
c.content.webgl                     = False
c.content.webrtc_ip_handling_policy = 'default-public-interface-only'

c.colors.webpage.darkmode.enabled       = True
c.colors.webpage.darkmode.policy.images = 'smart'
c.colors.webpage.preferred_color_scheme = 'dark'
c.colors.webpage.bg                 = "#000000"


# --> MISC:
# # Put kitty, gvim, etc. in Qutebrowser's PATH, at least on macOS
os.environ['PATH'] = '/usr/local/bin' + os.pathsep + os.environ['PATH']


# https://github.com/LaurenceWarne/qute-code-hint
c.hints.selectors["code"] = [
    # Selects all code tags whose direct parent is not a pre tag
    ":not(pre) > code",
    "pre"
]


# --> PATTERNS-EXCEPTIONS:
clipboard_allowed = [
    'https://github.com/*',
    'https://stackoverflow.com/*',
    'https://*.stackexchange.com/*',
    'https://*.google.com/*',
]

javascript_allowed = [
    'https://*.duckduckgo.com/*',
    'https://*.gitlab.com/*',
    'https://*.github.com/*/*/issues',
    'https://*.troupl.in/*'
]

# images_allowed = [
#     'file://*',
#     'qute://*',
#     'https://*.troupl.in/*'
# ]

for domain in javascript_allowed:
    with config.pattern(domain) as p:
        p.content.javascript.enabled = True

# for domain in images_allowed:
#     with config.pattern(domain) as p:
#         p.content.images = True

for domain in clipboard_allowed:
    with config.pattern(domain) as p:
        p.content.javascript.can_access_clipboard = True
        # config.set('content.javascript.can_access_clipboard', True, site)


# --> EXTERNAL:
# # Open external applications
for site in [
            'zoommtg://*.zoom.us',
            'https://*.slack.com',
        ]:
    config.set('content.unknown_url_scheme_policy', 'allow-all', site)


# --> SEARCHENGINES:
searchengines = """
ddg   https://start.duckduckgo.com/?kae=t&q={}
gtr   https://translate.google.com/#auto/en/{}
rsub  https://reddit.com/r/{}
rs    https://reddit.com/r/{}
r     https://www.reddit.com/search?q={}
amz   https://www.amazon.com/s/?tag=duc0a-21&url=search-alias%3Daps&field-keywords={}
w     https://fr.wikipedia.org/wiki/Special:Search?search={}&go=GO
wfr   https://fr.wikipedia.org/wiki/Special:Search?search={}&go=GO
wen   https://en.wikipedia.org/wiki/Special:Search?search={}
gh    https://github.com/search?utf8=%E2%9C%93&q={}
dh    https://hub.docker.com/search/?q={}&page=1&isAutomated=0&isOfficial=0&starCount=0&pullCount=0
rtfd  https://{}.rtfd.io
rtfm  https://{}.rtfd.io
g     https://www.google.com/search?q={}
yt    https://www.youtube.com/results?search_query={}
cmd   https://www.reddit.com/r/commandline/search?q={}&restrict_sr=on&sort=relevance&t=all
srht  https://sr.ht/projects?search={}&sort=recently-updated
st    https://sr.ht/projects?search={}&sort=recently-updated
gm    https://maps.google.com/maps?q={}
gmaps https://maps.google.com/maps?q={}
osm   https://www.openstreetmap.org/search?query={}
gi    https://www.google.com/search?tbm=isch&q={}
i     https://duckduckgo.com/?ia=images&iax=images&q={}
ss    https://github.com/koalaman/shellcheck/wiki/SC{}
"""

# Clean the searchengines list
#c.url.searchengines = {}

# Fill the searchengines list (DEFAULT is the first in the list)
for se in searchengines.splitlines():
    if se:
        bang, url = se.split(' ', 1)
        if not c.url.searchengines:
            c.url.searchengines['DEFAULT'] = url.strip()
        c.url.searchengines['!' + bang] = url.strip()


# --> ALIASES:
c.aliases = {
  'q':     'close',
  'qa':    'quit',
  'w':     'session-save',
  'wq':    'quit --save',
  'qr':    'spawn -u -- qr',
  'clone': 'spawn -u -- gitclone'
}


# --> BINDINGS:
# Remove all default keys
c.bindings.default = {}


# Convenience helpers
def nmap(key, cmd):
    config.bind(key, cmd, mode='normal')
def vmap(key, cmd):
    config.bind(key, cmd, mode='caret')
def imap(key, cmd):
    config.bind(key, cmd, mode='insert')
def cmap(key, cmd):
    config.bind(key, cmd, mode='command')

# Add a specific selectors (tries to select any frame)
c.hints.selectors['frame'] = ['div', 'header', 'section', 'nav']

# TODO: FIND A MAP FOR:
# <Ctrl+L>         clear-messages ;; download-clear
# <Ctrl+H>         history -t

bindings = """
normal
  <Escape>         clear-keychain ;; search ;; fullscreen --leave
  <Ctrl+c>         clear-keychain ;; search ;; fullscreen --leave
  /                set-cmd-text /
  ?                set-cmd-text ?
  :                set-cmd-text :
  !                set-cmd-text :open -t !
  o                set-cmd-text -s :open -s
  go               set-cmd-text :open {url:pretty}
  O                set-cmd-text -s :open -ts
  gO               set-cmd-text :open -t -r {url:pretty}
  J                tab-next
  K                tab-prev
  <Ctrl+l>         tab-next
  <Ctrl+h>         tab-prev
  x                tab-close
  T                tab-focus
  tc               tab-clone
  tj               tab-move +
  tk               tab-move -
  tm               tab-mute
  tn               tab-next
  to               tab-only -f
  tp               tab-prev
  t0               tab-focus 1
  t$               tab-focus last
  g0               tab-focus 1
  g$               tab-focus -1
  <Ctrl+p>         tab-pin
  gt               set-cmd-text -s :tab-select
  r                reload
  <F5>             reload
  <Ctrl+r>         reload -f
  <Ctrl+F5>        reload -f
  <Ctrl+Shift+r>   restart
  H                back
  <Back>           back
  th               back -t
  L                forward
  <Forward>        forward
  tl               forward -t
  f                hint
  F                hint all tab
  ,H               hint --rapid all hover
  ,I               hint images tab
  ,d               hint links download
  ,f               hint frame
  ,h               hint all hover
  ,i               hint inputs
  ,o               hint links fill :open {hint-url}
  ,p               hint links userscript view_in_mpv
  ,r               hint --rapid links tab-bg
  ,y               hint links yank
  gi               hint inputs
  I                hint inputs --first
  h                scroll left
  j                scroll down
  k                scroll up
  l                scroll right
  u                undo
  gg               scroll-to-perc 0
  G                scroll-to-perc
  n                search-next
  N                search-prev
  i                mode-enter insert
  v                mode-enter caret
  V                mode-enter caret ;; selection-toggle --line
  <Shift+Escape>   mode-enter passthrough
  `                mode-enter set_mark
  '                mode-enter jump_mark
  yy               yank
  yt               yank title
  yd               yank domain
  yp               yank pretty-url
  ys               yank selection
  pp               set-cmd-text -- :open -- {clipboard}
  pP               set-cmd-text -- :open -t -- {clipboard}
  m                quickmark-save
  b                set-cmd-text -s :quickmark-load
  B                set-cmd-text -s :quickmark-load -t
  M                bookmark-add
  gb               set-cmd-text -s :bookmark-load
  gB               set-cmd-text -s :bookmark-load -t
  ss               set-cmd-text -s :set -t
  -                zoom-out
  +                zoom-in
  =                zoom
  {                navigate prev
  }                navigate next
  <Alt+Left>       navigate prev
  <Alt+Right>      navigate next
  <Ctrl+a>         navigate increment
  <Ctrl+x>         navigate decrement
  <Alt++>          navigate increment
  <Alt+->          navigate decrement
  wh               devtools left
  wj               devtools bottom
  wk               devtools top
  wl               devtools right
  ww               devtools window
  wf               devtools-focus
  gd               spawn -u -- jsdownload
  gD               download-cancel
  <Ctrl+u>         view-source
  <Ctrl+e>         view-source --edit
  ZQ               quit
  ZZ               quit --save
  <Ctrl+s>         stop
  <Ctrl+m>         messages -w
  <Return>         selection-follow
  <Ctrl+Return>    selection-follow -t
  .                repeat-command
  q                macro-record
  @                macro-run
  cb               spawn -u -- domcycle content.javascript.can_access_clipboard
  cj               spawn -u -- domcycle content.javascript.enabled
  cJ               config-cycle -pt content.javascript.enabled ;; reload
  ci               spawn -u -- domcycle content.images
  cp               config-cycle -pt content.proxy system http://localhost:8080
  ct               config-cycle -t tabs.width 300 60
  cd               devtools
  gs               set-cmd-text -s -- :spawn -u substiqute
  gS               set-cmd-text -s -- :spawn -u substiqute -t
  gc               spawn -u -- gitclone
  gp               spawn -u -- view_in_mpv
  <Alt+l>          mode-enter insert ;; spawn -- bwm -b {url}
  <Alt+o>          mode-enter insert ;; spawn -- bwm -o {url}
  <Alt+p>          mode-enter insert ;; spawn -- bwm    {url}
  <Alt+u>          mode-enter insert ;; spawn -- bwm -u {url}

caret
  <Escape>         mode-leave
  q                mode-leave
  v                selection-toggle
  V                selection-toggle --line
  <Space>          selection-drop
  j                move-to-next-line
  k                move-to-prev-line
  l                move-to-next-char
  h                move-to-prev-char
  e                move-to-end-of-word
  w                move-to-next-word
  b                move-to-prev-word
  o                selection-reverse
  ]                move-to-start-of-next-block
  [                move-to-start-of-prev-block
  }                move-to-end-of-next-block
  {                move-to-end-of-prev-block
  0                move-to-start-of-line
  $                move-to-end-of-line
  gg               move-to-start-of-document
  G                move-to-end-of-document
  Y                yank selection -s
  y                yank selection
  <Return>         yank selection
  H                scroll left
  J                scroll down
  K                scroll up
  L                scroll right

command
  <Escape>         mode-leave
  <Ctrl+p>         command-history-prev
  <Ctrl+n>         command-history-next
  <Up>             completion-item-focus --history prev
  <Down>           completion-item-focus --history next
  <Shift+Tab>      completion-item-focus prev
  <Tab>            completion-item-focus next
  <Ctrl+Tab>       completion-item-focus next-category
  <Ctrl+Shift+Tab> completion-item-focus prev-category
  <PgDown>         completion-item-focus next-page
  <PgUp>           completion-item-focus prev-page
  <Ctrl+d>         completion-item-del
  <Shift+Del>      completion-item-del
  <Ctrl+c>         completion-item-yank
  <Ctrl+Shift+c>   completion-item-yank --sel
  <Return>         command-accept
  <Ctrl+Return>    command-accept --rapid
  <Ctrl+b>         rl-backward-char
  <Ctrl+f>         rl-forward-char
  <Alt+b>          rl-backward-word
  <Alt+f>          rl-forward-word
  <Ctrl+a>         rl-beginning-of-line
  <Ctrl+e>         rl-end-of-line
  <Ctrl+u>         rl-unix-line-discard
  <Ctrl+k>         rl-kill-line
  <Alt+d>          rl-kill-word
  <Ctrl+w>         rl-unix-word-rubout
  <Alt+Backspace>  rl-backward-kill-word
  <Ctrl+y>         rl-yank
  <Ctrl+?>         rl-delete-char
  <Ctrl+h>         rl-backward-delete-char

hint
  <Escape>         mode-leave
  q                mode-leave
  <Return>         hint-follow
  <Ctrl+r>         hint --rapid links tab-bg
  <Ctrl+f>         hint links
  <Ctrl+b>         hint all tab-bg

insert
  <Ctrl+e>         edit-text
  <Shift+Ins>      insert-text -- {primary}
  <Escape>         mode-leave
  <Shift+Escape>   fake-key <Escape>
  <Alt+l>          spawn -- bwm -b {url}
  <Alt+o>          spawn -- bwm -o {url}
  <Alt+p>          spawn -- bwm    {url}
  <Alt+u>          spawn -- bwm -u {url}

passthrough
  <Shift+Escape>   mode-leave
  <Alt+l>          spawn -- bwm -b {url}
  <Alt+o>          spawn -- bwm -o {url}
  <Alt+p>          spawn -- bwm    {url}
  <Alt+u>          spawn -- bwm -u {url}

prompt
  <Return>         prompt-accept
  <Ctrl+x>         prompt-open-download
  <Ctrl+p>         prompt-open-download --pdfjs
  <Shift+Tab>      prompt-item-focus prev
  <Up>             prompt-item-focus prev
  <Tab>            prompt-item-focus next
  <Down>           prompt-item-focus next
  <Alt+y>          prompt-yank
  <Alt+Shift+y>    prompt-yank --sel
  <Ctrl+b>         rl-backward-char
  <Ctrl+f>         rl-forward-char
  <Alt+b>          rl-backward-word
  <Alt+f>          rl-forward-word
  <Ctrl+a>         rl-beginning-of-line
  <Ctrl+e>         rl-end-of-line
  <Ctrl+u>         rl-unix-line-discard
  <Ctrl+k>         rl-kill-line
  <Alt+d>          rl-kill-word
  <Ctrl+w>         rl-unix-word-rubout
  <Alt+Backspace>  rl-backward-kill-word
  <Ctrl+?>         rl-delete-char
  <Ctrl+h>         rl-backward-delete-char
  <Ctrl+y>         rl-yank
  <Escape>         mode-leave

register
  <Escape>         mode-leave

yesno
  <Return>         prompt-accept
  y                prompt-accept yes
  n                prompt-accept no
  Y                prompt-accept --save yes
  N                prompt-accept --save no
  <Alt+y>          prompt-yank
  <Alt+Shift+y>    prompt-yank --sel
  <Escape>         mode-leave
"""

# Map all bindings
for line in bindings.splitlines():
    if line.strip():
        if line[0] != ' ':
            mode = line.strip()
            continue

        key, command = line.strip().split(' ', 1)
        config.bind(key, command.strip(), mode=mode)
