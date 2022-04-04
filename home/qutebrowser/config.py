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
# * https://github.com/qutebrowser/qutebrowser/discussions/6555
# : qute://help/configuring.html
# : qute://help/settings.html


# --> IMPORTS:
import os
import platform

from qutebrowser.api import interceptor

# --> PRE:
# Start directly with python configuration; skip ones created with :set
config.load_autoconfig(False)


# --> LOADERS:
USERSCRIPT_PATH = os.path.join(config.configdir, "userscripts")


def userscript(script_name):
    return os.path.join(USERSCRIPT_PATH, script_name)


config.source("themes/material-darker.py")
# Apply splitted configuration
# for source in [
#   # 'aliases',
#   # 'binding',
#   # 'patterns',
#   # 'plugins',
#   # 'redirect',
#   # 'searchengine',
#   'theme',
#   'greasemonkey',
#   'userscripts'
# ]:
#   config.source('{}.py'.format(source))


# --> SETTINGS:
commands = {
    "edit": "kitty launch --cwd=current --type=tab nvim -f {file} -c 'normal {line}G{column0}l'".split(),
    # c.editor.command = ['nvim', '-f', '{file}', '-c', 'normal {line}G{column0}l']
    # 'edit':       'foot -T float vim {file}'.split(),
    # 'pick_dir':   'foot -T float ranger --choosedir={}'.split(),
    # 'pick_files': 'foot -T float ranger --choosefiles={}'.split(),
    # 'pick_file':  'foot -T float ranger --choosefile={}'.split()
}


# --> CONFIG:
c.auto_save.interval = 15000
c.auto_save.session = True
c.completion.open_categories = ["searchengines", "quickmarks", "bookmarks", "history"]
c.completion.quick = False
c.completion.scrollbar.padding = 0
c.completion.scrollbar.width = 8
c.confirm_quit = ["multiple-tabs", "downloads"]
c.downloads.location.remember = False
c.downloads.location.suggestion = "both"
c.downloads.position = "bottom"
c.downloads.location.directory = "$HOME/Downloads"
# c.downloads.remove_finished           = 696969
c.editor.command = commands["edit"]
# c.fileselect.folder.command           = commands["pick_dir"]
# c.fileselect.handler                  = 'external'
# c.fileselect.multiple_files.command   = commands["pick_files"]
# c.fileselect.single_file.command      = commands["pick_file"]
c.fonts.default_family = "JetBrains Mono"
c.fonts.default_size = "14px"
c.fonts.contextmenu = "default_size default_family"
c.fonts.prompts = "default_size default_family"
c.fonts.statusbar = "default_size default_family"
c.hints.chars = "ctsrvdlgh"  # get the keys from our vim config hop/lightspeed/etc; or from surfingkeys
c.history_gap_interval = 240
c.input.escape_quits_reporter = True
c.input.mouse.rocker_gestures = True
c.input.partial_timeout = 10000
c.keyhint.delay = 250
c.messages.timeout = 5000
c.new_instance_open_target = "tab-bg"
c.tabs.last_close = "blank"
c.tabs.position = "top"
c.tabs.show = "multiple"
c.tabs.undo_stack_size = 20
c.tabs.width = "10%"  # 60
c.tabs.close_mouse_button = "right"
c.window.title_format = "{perc}{current_title}{title_sep} browser"


c.url.open_base_url = True
c.url.default_page = "about:blank"
c.url.start_pages = "about:blank"

padding = {
    "top": 8,
    "bottom": 8,
    "right": 8,
    "left": 8,
}
c.statusbar.padding = padding
c.tabs.padding = padding
c.tabs.indicator.width = 2
c.tabs.favicons.scale = 1
c.tabs.title.format_pinned = "{index} {audio}"


# Minimizing fingerprinting and annoying things
u_agent = "Mozilla/5.0 (Windows NT 10.0; rv:91.0) Gecko/20100101 Firefox/91.0"

# User agent to send. (domain/pattern based)..
# The following placeholders are defined:
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

c.content.autoplay = False
c.content.images = True
c.content.javascript.enabled = True
c.content.canvas_reading = True
c.content.cookies.accept = "no-unknown-3rdparty"
c.content.geolocation = False
c.content.headers.user_agent = u_agent
c.content.notifications.enabled = False
c.content.pdfjs = True
c.content.register_protocol_handler = False
c.content.webgl = True
c.content.webrtc_ip_handling_policy = "default-public-interface-only"

c.input.forward_unbound_keys = "all"
c.input.insert_mode.auto_leave = False
c.input.insert_mode.plugins = False

c.colors.webpage.darkmode.enabled = True
c.colors.webpage.darkmode.policy.images = "smart"
c.colors.webpage.preferred_color_scheme = "dark"
bg_color = "#000000"
c.colors.webpage.bg = bg_color

c.qt.args = [
    "enable-gpu-rasterization",
    "ignore-gpu-blocklist",
    "enable-accelerated-video-decode",
]

# https://github.com/LaurenceWarne/qute-code-hint
c.hints.selectors["code"] = [
    # Selects all code tags whose direct parent is not a pre tag
    ":not(pre) > code",
    "pre",
]
# Add a specific selectors (tries to select any frame)
c.hints.selectors["frame"] = ["div", "header", "section", "nav"]

# TODO: https://github.com/qutebrowser/qutebrowser/blob/master/scripts/dictcli.py
# c.spellcheck.languages = ["en-US"]


# --> MISC:
# # Put kitty, gvim, etc. in Qutebrowser's PATH, at least on macOS
os.environ["PATH"] = "/usr/local/bin" + os.pathsep + os.environ["PATH"]
# os.environ['PATH'] = os.pathsep + '/usr/local/bin'
# os.environ['NODE_PATH'] = os.pathsep + '/usr/local/lib/node_modules'

# -> ADBLOCK:
def filter_yt(info: interceptor.Request):
    """Block the given request if necessary."""
    url = info.request_url
    if (
        url.host() == "www.youtube.com"
        and url.path() == "/get_video_info"
        and "&adformat=" in url.query()
    ):
        info.block()


interceptor.register(filter_yt)

c.content.blocking.method = "adblock"
c.content.blocking.adblock.lists = [
    "https://easylist.to/easylist/easylist.txt",
    "https://easylist.to/easylist/easyprivacy.txt",
    "https://easylist.to/easylist/fanboy-social.txt",
    "https://secure.fanboy.co.nz/fanboy-annoyance.txt",
    "https://easylist-downloads.adblockplus.org/easylistdutch.txt",
    "https://easylist-downloads.adblockplus.org/abp-filters-anti-cv.txt",
    # "https://gitlab.com/curben/urlhaus-filter/-/raw/master/urlhaus-filter.txt",
    "https://pgl.yoyo.org/adservers/serverlist.php?showintro=0;hostformat=hosts",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/legacy.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2020.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2021.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badware.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/privacy.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badlists.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/resource-abuse.txt",
    "https://www.i-dont-care-about-cookies.eu/abp/",
    "https://secure.fanboy.co.nz/fanboy-cookiemonster.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/unbreak.txt",
]


# --> PATTERNS-EXCEPTIONS:
clipboard_allowed = [
    "https://github.com/*",
    "https://stackoverflow.com/*",
    "https://*.stackexchange.com/*",
    "https://*.google.com/*",
]
for domain in clipboard_allowed:
    with config.pattern(domain) as p:
        p.content.javascript.can_access_clipboard = True
        # config.set('content.javascript.can_access_clipboard', True, site)

javascript_allowed = [
    "https://*.duckduckgo.com/*",
    "https://*.gitlab.com/*",
    "https://*.github.com/*/*/issues",
    "https://*.troupl.in/*",
    "chrome-devtools://*",
    "devtools://*",
    "chrome://*",
    "qute://*",
]
for domain in javascript_allowed:
    with config.pattern(domain) as p:
        p.content.javascript.enabled = True

images_allowed = [
    "file://*",
    "chrome-devtools://*",
    "devtools://*",
    "qute://*",
    "https://*.troupl.in/*",
]
for domain in images_allowed:
    with config.pattern(domain) as p:
        p.content.images = True


# --> EXTERNAL:
# # Open external applications
for site in [
    "zoommtg://*.zoom.us",
    "https://*.slack.com",
]:
    config.set("content.unknown_url_scheme_policy", "allow-all", site)


# --> SEARCHENGINES:
searchengines = """
ddg  : https://start.duckduckgo.com/?kae=t&q={}
gtr  : https://translate.google.com/#auto/en/{}
rsub : https://reddit.com/r/{}
rs   : https://reddit.com/r/{}
r    : https://www.reddit.com/search?q={}
amz  : https://www.amazon.com/s/?tag=duc0a-21&url=search-alias%3Daps&field-keywords={}
w  : https://en.wikipedia.org/wiki/Special:Search?search={}
gh   : https://github.com/search?utf8=%E2%9C%93&q={}
dh   : https://hub.docker.com/search/?q={}&page=1&isAutomated=0&isOfficial=0&starCount=0&pullCount=0
rtfd : https://{}.rtfd.io
rtfm : https://{}.rtfd.io
g    : https://www.google.com/search?q={}
yt   : https://www.youtube.com/results?search_query={}
cmd  : https://www.reddit.com/r/commandline/search?q={}&restrict_sr=on&sort=relevance&t=all
srht : https://sr.ht/projects?search={}&sort=recently-updated
st   : https://sr.ht/projects?search={}&sort=recently-updated
gm   : https://maps.google.com/maps?q={}
gmaps: https://maps.google.com/maps?q={}
osm  : https://www.openstreetmap.org/search?query={}
gi   : https://www.google.com/search?tbm=isch&q={}
i    : https://duckduckgo.com/?ia=images&iax=images&q={}
ss   : https://github.com/koalaman/shellcheck/wiki/SC{}
"""

# Clean the searchengines list
# c.url.searchengines = {}

# Fill the searchengines list (DEFAULT is the first in the list)
# c.url.searchengines["DEFAULT"] = "https://duckduckgo.com/?q={}"
for se in searchengines.splitlines():
    if se:
        bang, url = se.split(":", 1)
        if not c.url.searchengines:
            c.url.searchengines[bang] = url.strip()
            c.url.searchengines["!" + bang] = url.strip()


# --> ALIASES:
# - https://github.com/qutebrowser/qutebrowser/blob/master/doc/help/commands.asciidoc
c.aliases = {
    "q": "close",
    "qa": "quit",
    "w": "session-save",
    "wq": "quit --save",
    "sz": "config-source",
    "o": "open",
    "O": "open --tab",
    "L": "open --background",
    "h": "help",
    "?": "help",
    "noh": "search",
    "clr": "clear-messages",
    "q": "close",
    "qa": "quite",
    "w": "session-save",
    "wq": "quit --save",
    "wqa": "quit --save",
    "pin": "tab-pin",
    "priv": "open --private",
    "bm": "open -t qute://bookmarks/",
    "mpv": "spawn mpv --autofit=100%x100% --force-window=immediate --keep-open=yes {url}",
    "ompv": "hint links spawn mpv --autofit=100%x100% --force-window=immediate {hint-url}",
    "hmpv": 'hint links spawn nohup mpv --cache=yes --demuxer-max-bytes=500M --demuxer-max-back-bytes=500M -ytdl-format="bv[ext=mp4]+ba/b" --force-window=immediate {hint-url}',
    "dl": "spawn --userscript open_download",
}

c.aliases["b"] = "tab-focus"
for i in range(1, 20):
    c.aliases["b" + str(i)] = "tab-focus " + str(i)


## open in alternate browsers:
c.aliases["chrome"] = 'spawn open -a "Google Chrome" {url}'
c.aliases["hchrome"] = 'hint all spawn open -a "Google Chrome" {hint-url}'
c.aliases["brave"] = 'spawn open -a "Brave Browser" {url}'
c.aliases["hbrave"] = 'hint all spawn open -a "Brave Browser" {hint-url}'
c.aliases["safari"] = 'spawn open -a "Safari" {url}'
c.aliases["hsafari"] = 'hint all spawn open -a "Safari" {hint-url}'
c.aliases["firefox"] = 'spawn open -a "Firefox Developer Edition" {url}'
c.aliases["hfirefox"] = 'hint all spawn open -a "Firefox Developer Edition" {hint-url}'
# TODO: add ms edge

c.aliases["user"] = "spawn --userscript"
c.aliases["pass"] = "spawn --userscript 1password"
c.aliases["readability"] = "spawn --userscript readability"
c.aliases["reader"] = "spawn --userscript readability"
c.aliases["bib"] = "spawn --userscript getbib"
c.aliases["pocket"] = "spawn --userscript qutepocket"

c.aliases["bg-norm"] = "set colors.webpage.bg #ffffff"
c.aliases["bg-dark"] = "set colors.webpage.bg " + bg_color
c.aliases["dg-toggle"] = "jseval --quiet --world main DarkReader.toggle()"


# --> BINDINGS:
# Remove all default keys
c.bindings.default = {}

# Convenience helpers
def nmap(key, cmd):
    config.bind(key, cmd, mode="normal")


def vmap(key, cmd):
    config.bind(key, cmd, mode="caret")


def imap(key, cmd):
    config.bind(key, cmd, mode="insert")


def cmap(key, cmd):
    config.bind(key, cmd, mode="command")


nmap("h", "scroll left")
nmap("j", "scroll down")
nmap("k", "scroll up")
nmap("l", "scroll right")

nmap("<Ctrl+d>", "scroll-page 0 0.5")
nmap("<Ctrl+u>", "scroll-page 0 -0.5")
nmap("<Ctrl+f>", "scroll-page 0 0.5")
nmap("<Ctrl+b>", "scroll-page 0 -0.5")

nmap("gg", "scroll-to-perc 0")
nmap("G", "scroll-to-perc")

nmap("-", "zoom-out")
nmap("+", "zoom-in")
nmap("=", "zoom")

nmap("x", "tab-close")
nmap("<Meta+w>", "tab-close")
nmap("u", "undo")

nmap("r", "reload")
nmap("R", "reload --force")

nmap("J", "tab-next")
nmap("K", "tab-prev")
nmap("<Ctrl+l>", "tab-next")
nmap("<Ctrl+h>", "tab-prev")

nmap("H", "back")
nmap("L", "forward")
nmap("<Back>", "back")
nmap("<Forward>", "forward")

nmap("n", "search-next")
nmap("N", "search-prev")

nmap("[[", "navigate prev")
nmap("]]", "navigate next")

nmap("f", "hint")
nmap("F", "hint all tab")

nmap("i", "mode-enter insert")
nmap("v", "mode-enter caret")
nmap("V", "mode-enter caret ;; selection-toggle --line")

## (yank)
nmap("yy", "yank")  # url
nmap("yt", "yank title")
nmap("yd", "yank domain")
nmap("yp", "yank pretty-url")
nmap("ym", "yank inline [{title}]({url})")  # markdown style
nmap("ygh", "yank inline {url:path}")  # markdown style

nmap("pp", "open -- {clipboard}")

nmap(":", "set-cmd-text :")
nmap(";", "set-cmd-text :")
nmap("/", "set-cmd-text /")
nmap("?", "set-cmd-text ?")

nmap("o", "set-cmd-text -s :open")
nmap("O", "set-cmd-text -s :open --tab")

nmap("m", "quickmark-save")
nmap("b", "set-cmd-text -s :quickmark-load")
nmap("B", "set-cmd-text -s :quickmark-load --tab")

## hints (t*)
nmap("T", "hint --first inputs")
nmap("tt", "hint inputs")
nmap("tf", "hint --rapid links tab-bg")
nmap("ty", "hint links yank")
nmap("td", "hint links download")
nmap("tD", "hint --rapid links download")
nmap("to", "hint links fill :open {hint-url}")
nmap("tO", "hint links fill :open --tab --related {hint-url}")
nmap("th", "hint all hover")
nmap("ti", "hint images")
nmap("tI", "hint images tab")

## goto: (g*)
nmap("gp", "open -- {clipboard}")
nmap("gP", "open --tab -- {clipboard}")
nmap("gc", "tab-clone")
nmap("gC", "tab-clone --tab")
nmap("gK", "tab-move -")
nmap("gJ", "tab-move +")
nmap("gL", "forward --tab")
nmap("gH", "back --tab")
nmap("gi", "hint --first inputs")
nmap("go", "set-cmd-text -s :open --bg")
nmap("gt", "set-cmd-text -s :open --tab")

## current page: (c*)
nmap("co", "set-cmd-text :open {url:pretty}")
nmap("cO", "set-cmd-text :open --tab {url:pretty}")
nmap("cs", "navigate strip")
nmap("cS", "navigate --tab strip")

## (visual)
vmap("v", "toggle-selection")
vmap("V", "toggle-selection --line")
vmap("h", "move-to-prev-char")
vmap("j", "move-to-next-line")
vmap("k", "move-to-prev-line")
vmap("l", "move-to-next-char")
vmap("e", "move-to-end-of-word")
vmap("w", "move-to-next-word")
vmap("b", "move-to-prev-word")
vmap("0", "move-to-start-of-line")
vmap("$", "move-to-end-of-line")
vmap("gg", "move-to-start-of-document")
vmap("G", "move-to-end-of-document")
vmap("y", "yank selection")
vmap("[", "move-to-start-of-prev-block")
vmap("]", "move-to-start-of-next-block")
vmap("{", "move-to-end-of-prev-block")
vmap("}", "move-to-end-of-next-block")

for mode in ["prompt", "register", "hint", "yesno", "caret", "insert", "command"]:
    config.bind("<Escape>", "mode-leave", mode=mode)

config.bind("<Return>", "command-accept", mode="command")

config.bind("<Shift+Escape>", "mode-leave", mode="passthrough")

config.bind("<Return>", "hint-follow", mode="hint")

config.bind("<Return>", "prompt-accept", mode="prompt")
config.bind("<Up>", "prompt-item-focus prev", mode="prompt")
config.bind("<Down>", "prompt-item-focus next", mode="prompt")
config.bind("<Shift+Tab>", "prompt-item-focus prev", mode="prompt")
config.bind("<Tab>", "prompt-item-focus next", mode="prompt")

config.bind("<Return>", "prompt-accept", mode="yesno")
config.bind("y", "prompt-accept yes", mode="yesno")
config.bind("n", "prompt-accept no", mode="yesno")
config.bind("Y", "prompt-accept --save yes", mode="yesno")
config.bind("N", "prompt-accept --save no", mode="yesno")

## muscle memory from days of yore..
nmap("<Meta+n>", "open --tab")
nmap("<Meta+Shift+n>", "open --private")
nmap("<Meta+t>", "open --tab")
nmap("<Meta+Shift+t>", "open --tab")
nmap("<F5>", "reload")
for i in range(9):
    nmap("<Ctrl+{}>".format(i), "tab-focus {}".format(i))
# }}}

## misc..
nmap("<Esc>", "fake-key <Esc>")
nmap("<Ctrl+[>", "clear-messages")
imap("<Ctrl+o>", "open-editor")
nmap(",sz", "sz")

## userscript/externally-dependent bindings..
nmap("yc", "hint code userscript " + userscript("code_select"))
nmap("<Ctrl+g>", c.aliases["dg-toggle"])
nmap(",eq", "config-edit")
nmap(",p", "config-cycle -p content.plugins ;; reload")
nmap(
    ",pk",
    "jseval (function () { "
    + '  var i, elements = document.querySelectorAll("body *");'
    + ""
    + "  for (i = 0; i < elements.length; i++) {"
    + "    var pos = getComputedStyle(elements[i]).position;"
    + '    if (pos === "fixed" || pos == "sticky") {'
    + "      elements[i].parentNode.removeChild(elements[i]);"
    + "    }"
    + "  }"
    + "})();",
)
nmap(",1p", "spawn --userscript 1p")

nmap(",bs", "safari")
nmap(",bb", "brave")
nmap(",bc", "chrome")
nmap(",bf", "firefox")
nmap(",hbs", "hsafari")
nmap(",hbb", "hbrave")
nmap(",hbc", "hchrome")
nmap(",hbf", "hfirefox")
# nmap(",be", "oedge")
# nmap(",b", "spawn --userscript buku-add")
# nmap(",f", "spawn --userscript buku-add favourites")
# nmap(",c", "spawn --userscript clipper")
# nmap(",r", "spawn --userscript readability/readability-js")


## macos-style/readline..
# config.bind("<Ctrl+n>", "prompt-item-focus next", mode="prompt")
# config.bind("<Ctrl+p>", "prompt-item-focus prev", mode="prompt")

# config.bind("<Ctrl+n>", "completion-item-focus --history next", mode="command")
# config.bind("<Ctrl+p>", "completion-item-focus --history prev", mode="command")

# config.bind("<Ctrl+n>", "command-history-next", mode="command")
# config.bind("<Ctrl+p>", "command-history-prev", mode="command")

for mode in ["command", "prompt"]:
    # Readline-style mode
    config.bind("<Ctrl+d>", "rl-delete-char", mode=mode)
    config.bind("<Alt+d>", "rl-kill-word", mode=mode)
    config.bind("<Ctrl+k>", "rl-kill-line", mode=mode)
    config.bind("<Ctrl+y>", "rl-yank", mode=mode)

    config.bind("<Ctrl+h>", "rl-backward-delete-char", mode=mode)
    config.bind("<Alt+Backspace>", "rl-backward-kill-word", mode=mode)
    config.bind("<Ctrl+Alt+h>", "rl-backward-kill-word", mode=mode)
    config.bind("<Ctrl+w>", "rl-backward-kill-word", mode=mode)
    config.bind("<Ctrl+u>", "rl-unix-line-discard", mode=mode)

    config.bind("<Ctrl+b>", "rl-backward-char", mode=mode)
    config.bind("<Ctrl+f>", "rl-forward-char", mode=mode)
    config.bind("<Alt+b>", "rl-backward-word", mode=mode)
    config.bind("<Alt+f>", "rl-forward-word", mode=mode)
    config.bind("<Ctrl+a>", "rl-beginning-of-line", mode=mode)
    config.bind("<Ctrl+e>", "rl-end-of-line", mode=mode)

if platform.system() == "Linux":
    # Readline-style insert mode
    config.bind("<Ctrl+f>", "fake-key <Right>", mode="insert")
    config.bind("<Ctrl+b>", "fake-key <Left>", mode="insert")
    config.bind("<Ctrl+a>", "fake-key <Home>", mode="insert")
    config.bind("<Ctrl+e>", "fake-key <End>", mode="insert")
    config.bind("<Ctrl+n>", "fake-key <Down>", mode="insert")
    config.bind("<Ctrl+p>", "fake-key <Up>", mode="insert")
    config.bind("<Alt+f>", "fake-key <Ctrl+Right>", mode="insert")
    config.bind("<Alt+b>", "fake-key <Ctrl+Left>", mode="insert")
    config.bind("<Ctrl+d>", "fake-key <Delete>", mode="insert")
    config.bind("<Alt+d>", "fake-key <Ctrl+Delete>", mode="insert")
    config.bind("<Alt+Backspace>", "fake-key <Ctrl+Backspace>", mode="insert")
    config.bind("<Ctrl+w>", "fake-key <Ctrl+Backspace>", mode="insert")
    config.bind("<Ctrl+y>", "insert-text {primary}", mode="insert")
    config.bind("<Ctrl+h>", "fake-key <Backspace>", mode="insert")

    # macOS-like cut/copy/paste/select-all
    config.bind(
        "<Meta+c>",
        'fake-key <Ctrl+c>;;message-info "copied to clipboard"',
        mode="normal",
    )
    config.bind(
        "<Meta+v>",
        'fake-key <Ctrl+v>;;message-info "pasted from clipboard"',
        mode="normal",
    )
    config.bind(
        "<Meta+x>", 'fake-key <Ctrl+x>;;message-info "cut to clipboard"', mode="normal"
    )
    config.bind("<Meta+a>", "fake-key <Ctrl+a>", mode="normal")

    config.bind("<Meta+a>", "fake-key <Ctrl+a>", mode="insert")

    for mode in ["insert", "command", "prompt"]:
        config.bind(
            "<Meta+x>",
            'fake-key -g <Ctrl+x>;;message-info "cut to clipboard"',
            mode=mode,
        )
        config.bind(
            "<Meta+c>",
            'fake-key -g <Ctrl+c>;;message-info "copied to clipboard"',
            mode=mode,
        )
        config.bind(
            "<Meta+v>",
            'fake-key -g <Ctrl+v>;;message-info "pasted from clipboard"',
            mode=mode,
        )


if platform.system() == "Darwin":
    # Readline-style insert mode
    config.bind("<Ctrl+n>", "fake-key <Down>", mode="insert")
    config.bind("<Ctrl+p>", "fake-key <Up>", mode="insert")
    config.bind("<Ctrl+w>", "fake-key <Alt+Backspace>", mode="insert")


# TODO: FIND A MAP FOR:
# <Ctrl+L>         clear-messages ;; download-clear
# <Ctrl+H>         history -t

# bindings = """
# normal
#   <Escape>         clear-keychain ;; search ;; fullscreen --leave
#   <Ctrl+c>         clear-keychain ;; search ;; fullscreen --leave
#   /                set-cmd-text /
#   ?                set-cmd-text ?
#   :                set-cmd-text :
#   !                set-cmd-text :open -t !
#   o                set-cmd-text -s :open -s
#   go               set-cmd-text :open {url:pretty}
#   O                set-cmd-text -s :open -ts
#   gO               set-cmd-text :open -t -r {url:pretty}
#   J                tab-next
#   K                tab-prev
#   <Ctrl+l>         tab-next
#   <Ctrl+h>         tab-prev
#   x                tab-close
#   T                tab-focus
#   tc               tab-clone
#   tj               tab-move +
#   tk               tab-move -
#   tm               tab-mute
#   tn               tab-next
#   to               tab-only -f
#   tp               tab-prev
#   t0               tab-focus 1
#   t$               tab-focus last
#   g0               tab-focus 1
#   g$               tab-focus -1
#   <Ctrl+p>         tab-pin
#   gt               set-cmd-text -s :tab-select
#   r                reload
#   <F5>             reload
#   <Ctrl+r>         reload -f
#   <Ctrl+F5>        reload -f
#   <Ctrl+Shift+r>   restart
#   H                back
#   <Back>           back
#   th               back -t
#   L                forward
#   <Forward>        forward
#   tl               forward -t
#   f                hint
#   F                hint all tab
#   ,H               hint --rapid all hover
#   ,I               hint images tab
#   ,d               hint links download
#   ,f               hint frame
#   ,h               hint all hover
#   ,i               hint inputs
#   ,o               hint links fill :open {hint-url}
#   ,p               hint links userscript view_in_mpv
#   ,r               hint --rapid links tab-bg
#   ,y               hint links yank
#   gi               hint inputs
#   I                hint inputs --first
#   h                scroll left
#   j                scroll down
#   k                scroll up
#   l                scroll right
#   u                undo
#   gg               scroll-to-perc 0
#   G                scroll-to-perc
#   n                search-next
#   N                search-prev
#   i                mode-enter insert
#   v                mode-enter caret
#   V                mode-enter caret ;; selection-toggle --line
#   <Shift+Escape>   mode-enter passthrough
#   `                mode-enter set_mark
#   '                mode-enter jump_mark
#   yy               yank
#   yt               yank title
#   yd               yank domain
#   yp               yank pretty-url
#   ys               yank selection
#   pp               set-cmd-text -- :open -- {clipboard}
#   pP               set-cmd-text -- :open -t -- {clipboard}
#   m                quickmark-save
#   b                set-cmd-text -s :quickmark-load
#   B                set-cmd-text -s :quickmark-load -t
#   M                bookmark-add
#   gb               set-cmd-text -s :bookmark-load
#   gB               set-cmd-text -s :bookmark-load -t
#   ss               set-cmd-text -s :set -t
#   -                zoom-out
#   +                zoom-in
#   =                zoom
#   {                navigate prev
#   }                navigate next
#   <Alt+Left>       navigate prev
#   <Alt+Right>      navigate next
#   <Ctrl+a>         navigate increment
#   <Ctrl+x>         navigate decrement
#   <Alt++>          navigate increment
#   <Alt+->          navigate decrement
#   wh               devtools left
#   wj               devtools bottom
#   wk               devtools top
#   wl               devtools right
#   ww               devtools window
#   wf               devtools-focus
#   gd               spawn -u -- jsdownload
#   gD               download-cancel
#   <Ctrl+u>         view-source
#   <Ctrl+e>         view-source --edit
#   ZQ               quit
#   ZZ               quit --save
#   <Ctrl+s>         stop
#   <Ctrl+m>         messages -w
#   <Return>         selection-follow
#   <Ctrl+Return>    selection-follow -t
#   .                repeat-command
#   q                macro-record
#   @                macro-run
#   cb               spawn -u -- domcycle content.javascript.can_access_clipboard
#   cj               spawn -u -- domcycle content.javascript.enabled
#   cJ               config-cycle -pt content.javascript.enabled ;; reload
#   ci               spawn -u -- domcycle content.images
#   cp               config-cycle -pt content.proxy system http://localhost:8080
#   ct               config-cycle -t tabs.width 300 60
#   cd               devtools
#   gs               set-cmd-text -s -- :spawn -u substiqute
#   gS               set-cmd-text -s -- :spawn -u substiqute -t
#   gc               spawn -u -- gitclone
#   gp               spawn -u -- view_in_mpv
#   <Alt+l>          mode-enter insert ;; spawn -- bwm -b {url}
#   <Alt+o>          mode-enter insert ;; spawn -- bwm -o {url}
#   <Alt+p>          mode-enter insert ;; spawn -- bwm    {url}
#   <Alt+u>          mode-enter insert ;; spawn -- bwm -u {url}

# caret
#   <Escape>         mode-leave
#   q                mode-leave
#   v                selection-toggle
#   V                selection-toggle --line
#   <Space>          selection-drop
#   j                move-to-next-line
#   k                move-to-prev-line
#   l                move-to-next-char
#   h                move-to-prev-char
#   e                move-to-end-of-word
#   w                move-to-next-word
#   b                move-to-prev-word
#   o                selection-reverse
#   ]                move-to-start-of-next-block
#   [                move-to-start-of-prev-block
#   }                move-to-end-of-next-block
#   {                move-to-end-of-prev-block
#   0                move-to-start-of-line
#   $                move-to-end-of-line
#   gg               move-to-start-of-document
#   G                move-to-end-of-document
#   Y                yank selection -s
#   y                yank selection
#   <Return>         yank selection
#   H                scroll left
#   J                scroll down
#   K                scroll up
#   L                scroll right

# command
#   <Escape>         mode-leave
#   <Ctrl+p>         command-history-prev
#   <Ctrl+n>         command-history-next
#   <Up>             completion-item-focus --history prev
#   <Down>           completion-item-focus --history next
#   <Shift+Tab>      completion-item-focus prev
#   <Tab>            completion-item-focus next
#   <Ctrl+Tab>       completion-item-focus next-category
#   <Ctrl+Shift+Tab> completion-item-focus prev-category
#   <PgDown>         completion-item-focus next-page
#   <PgUp>           completion-item-focus prev-page
#   <Ctrl+d>         completion-item-del
#   <Shift+Del>      completion-item-del
#   <Ctrl+c>         completion-item-yank
#   <Ctrl+Shift+c>   completion-item-yank --sel
#   <Return>         command-accept
#   <Ctrl+Return>    command-accept --rapid
#   <Ctrl+b>         rl-backward-char
#   <Ctrl+f>         rl-forward-char
#   <Alt+b>          rl-backward-word
#   <Alt+f>          rl-forward-word
#   <Ctrl+a>         rl-beginning-of-line
#   <Ctrl+e>         rl-end-of-line
#   <Ctrl+u>         rl-unix-line-discard
#   <Ctrl+k>         rl-kill-line
#   <Alt+d>          rl-kill-word
#   <Ctrl+w>         rl-unix-word-rubout
#   <Alt+Backspace>  rl-backward-kill-word
#   <Ctrl+y>         rl-yank
#   <Ctrl+?>         rl-delete-char
#   <Ctrl+h>         rl-backward-delete-char

# hint
#   <Escape>         mode-leave
#   q                mode-leave
#   <Return>         hint-follow
#   <Ctrl+r>         hint --rapid links tab-bg
#   <Ctrl+f>         hint links
#   <Ctrl+b>         hint all tab-bg

# insert
#   <Ctrl+e>         edit-text
#   <Shift+Ins>      insert-text -- {primary}
#   <Escape>         mode-leave
#   <Shift+Escape>   fake-key <Escape>
#   <Alt+l>          spawn -- bwm -b {url}
#   <Alt+o>          spawn -- bwm -o {url}
#   <Alt+p>          spawn -- bwm    {url}
#   <Alt+u>          spawn -- bwm -u {url}

# passthrough
#   <Shift+Escape>   mode-leave
#   <Alt+l>          spawn -- bwm -b {url}
#   <Alt+o>          spawn -- bwm -o {url}
#   <Alt+p>          spawn -- bwm    {url}
#   <Alt+u>          spawn -- bwm -u {url}

# prompt
#   <Return>         prompt-accept
#   <Ctrl+x>         prompt-open-download
#   <Ctrl+p>         prompt-open-download --pdfjs
#   <Shift+Tab>      prompt-item-focus prev
#   <Up>             prompt-item-focus prev
#   <Tab>            prompt-item-focus next
#   <Down>           prompt-item-focus next
#   <Alt+y>          prompt-yank
#   <Alt+Shift+y>    prompt-yank --sel
#   <Ctrl+b>         rl-backward-char
#   <Ctrl+f>         rl-forward-char
#   <Alt+b>          rl-backward-word
#   <Alt+f>          rl-forward-word
#   <Ctrl+a>         rl-beginning-of-line
#   <Ctrl+e>         rl-end-of-line
#   <Ctrl+u>         rl-unix-line-discard
#   <Ctrl+k>         rl-kill-line
#   <Alt+d>          rl-kill-word
#   <Ctrl+w>         rl-unix-word-rubout
#   <Alt+Backspace>  rl-backward-kill-word
#   <Ctrl+?>         rl-delete-char
#   <Ctrl+h>         rl-backward-delete-char
#   <Ctrl+y>         rl-yank
#   <Escape>         mode-leave

# register
#   <Escape>         mode-leave

# yesno
#   <Return>         prompt-accept
#   y                prompt-accept yes
#   n                prompt-accept no
#   Y                prompt-accept --save yes
#   N                prompt-accept --save no
#   <Alt+y>          prompt-yank
#   <Alt+Shift+y>    prompt-yank --sel
#   <Escape>         mode-leave
# """

# # Map all bindings
# for line in bindings.splitlines():
#     if line.strip():
#         if line[0] != ' ':
#             mode = line.strip()
#             continue

#         key, command = line.strip().split(' ', 1)
#         config.bind(key, command.strip(), mode=mode)

# vim: set ts=4 sw=2 tw=80 et foldmethod=marker foldlevel=0:
