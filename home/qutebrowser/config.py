# --> REFS:
# - https://git.sr.ht/~palb91/dotfiles/tree/main/item/qutebrowser/config.py
# - https://github.com/neeasade/dotfiles/blob/master/qutebrowser/.config/qutebrowser/config.py
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
import operator
import os
import platform

from qutebrowser.api import interceptor, message
from qutebrowser.config.config import ConfigContainer  # noqa: F401
from qutebrowser.config.configfiles import ConfigAPI  # noqa: F401

# import socket
# import subprocess
# from shutil import which


config = config  # type: ConfigAPI # noqa: F821
c = c  # type: ConfigContainer # noqa: F821

# --> PRE:
# Start directly with python configuration; skip ones created with :set
config.load_autoconfig(False)

# used in our redirect interceptor scripts
initial_start = c.tabs.background == False


# --> LOADERS:
## userscripts:
def userscript(script_name):
    return os.path.join(os.path.join(config.configdir, "userscripts"), script_name)


## theme:
config.source("themes/megaforest.py")


# --> SETTINGS:
editor = [
    "kitty",
    "@ --to tcp:localhost:45876 --type=tab launch nvim",
    "-f {file}",
    # "tmux attach -t mega;",
    # "new-window nvim",
    # "-f{file}",
]

commands = {
    "edit": "kitty @ --to tcp:localhost:45876 launch --type=tab nvim -f {file}".split()
    # "edit": editor
    # [which("qutebrowser-edit"), '-l{line}', '-c{column}', '-f{file}']
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
c.completion.shrink = True
c.confirm_quit = ["downloads"]  # ["multiple-tabs", "downloads"]
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
c.fonts.completion.category = "default_size default_family"
c.fonts.completion.entry = "default_size default_family"
c.fonts.debug_console = "default_size default_family"
c.fonts.default_family = "Source Code Pro Medium"
c.fonts.downloads = "default_size default_family"
c.fonts.hints = "bold 13px default_family"
c.fonts.keyhint = "default_size default_family"
c.fonts.messages.error = "default_size default_family"
c.fonts.messages.info = "default_size default_family"
c.fonts.messages.warning = "default_size default_family"
c.fonts.prompts = "default_size default_family"
c.fonts.statusbar = "default_size default_family"
c.fonts.tabs.selected = "12px default_family"
c.fonts.tabs.unselected = "12px default_family"
c.hints.chars = "etovxqpdygfbzcisuran"  # get the keys from our vim config hop/lightspeed/etc; or from surfingkeys
c.history_gap_interval = 240
c.input.escape_quits_reporter = True
c.input.mouse.rocker_gestures = True
c.input.partial_timeout = 10000
c.keyhint.delay = 250
c.messages.timeout = 5000
c.new_instance_open_target = "tab"  # or perhaps, tab-bg

# c.tabs.position = "top"
c.tabs.last_close = "blank"
# c.tabs.width = "10%"  # for left-positioned tab bar
# c.tabs.max_width = 50
# c.tabs.min_width = 50
c.tabs.show = "always"  # only shows tab_bar when > 1 tab with "multiple"
c.tabs.undo_stack_size = 20
c.tabs.close_mouse_button = "right"
c.tabs.indicator.width = 1
# c.tabs.indicator.padding = {
#     "top": 5,
#     "bottom": 5,
#     "right": 5,
#     "left": 5,
# }
c.tabs.favicons.scale = 1
c.tabs.favicons.show = "always"
# c.tabs.title.alignment = "center"
c.tabs.title.format = "{audio}{current_title}"
c.tabs.title.format_pinned = "{audio}{current_title}"
padding = {
    "top": 8,
    "bottom": 8,
    "right": 8,
    "left": 8,
}
c.tabs.padding = padding

c.completion.scrollbar.width = 10

c.scrolling.smooth = False

c.statusbar.padding = padding
c.statusbar.widgets = ["progress", "keypress", "url", "history"]

c.window.hide_decoration = False
c.window.title_format = "{perc}{current_title}{title_sep} qutebrowser"

c.url.open_base_url = True
c.url.default_page = "about:blank"
c.url.start_pages = "about:blank"


# Minimizing fingerprinting and annoying things
u_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36"

c.content.autoplay = False
c.content.images = True
c.content.javascript.enabled = True
c.content.canvas_reading = True
c.content.cookies.accept = "no-unknown-3rdparty"
c.content.site_specific_quirks.enabled = False
c.content.geolocation = False
c.content.headers.user_agent = u_agent
c.content.notifications.enabled = True
c.content.pdfjs = True
c.content.register_protocol_handler = False
c.content.webgl = True
c.content.webrtc_ip_handling_policy = "default-public-interface-only"
c.content.default_encoding = "utf-8"

c.input.forward_unbound_keys = "all"
c.input.insert_mode.auto_leave = False
c.input.insert_mode.plugins = False

# c.colors.webpage.darkmode.enabled = True
c.colors.webpage.darkmode.policy.images = "smart"
# c.colors.webpage.preferred_color_scheme = "dark"
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


# -> URL_REDIRECTS:
## REF: https://github.com/neeasade/dotfiles/blob/master/qutebrowser/.config/qutebrowser/config.py#L275-L296
REDIRECT_MAP = {
    # note: the redirect stuff needs a newish version of qb (at least, newer than nixpkgs stable)
    "reddit.com": operator.methodcaller("setHost", "old.reddit.com"),
    "www.reddit.com": operator.methodcaller("setHost", "old.reddit.com"),
}


def redirect_intercept(info):
    """Block the given request if necessary."""
    if (
        info.resource_type != interceptor.ResourceType.main_frame
        or info.request_url.scheme() in {"data", "blob"}
    ):
        return

    url = info.request_url
    # message.info(url.host())
    redir = REDIRECT_MAP.get(url.host())
    if redir is not None and redir(url) is not False:
        message.info("Redirecting to " + url.toString())
        info.redirect(url)


# idea here: you could have an interceptor that does the url note check for emacs
if initial_start:
    interceptor.register(redirect_intercept)


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

c.content.blocking.enabled = True
c.content.blocking.method = "adblock"
c.content.blocking.whitelist = ["https://atlas.test/*"]
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
DEFAULT    : https://search.brave.com/search?q={}
ddg        : https://start.duckduckgo.com/?kae=t&q={}
gtr        : https://translate.google.com/#auto/en/{}
rsub       : https://reddit.com/r/{}
rs         : https://reddit.com/r/{}
r          : https://www.reddit.com/search?q={}
amz        : https://www.amazon.com/s/?tag=duc0a-21&url=search-alias%3Daps&field-keywords={}
w          : https://en.wikipedia.org/wiki/Special:Search?search={}
gh         : https://github.com/search?utf8=%E2%9C%93&q={}
dh         : https://hub.docker.com/search/?q={}&page=1&isAutomated=0&isOfficial=0&starCount=0&pullCount=0
rtfd       : https://{}.rtfd.io
rtfm       : https://{}.rtfd.io
g          : https://www.google.com/search?q={}
yt         : https://www.youtube.com/results?search_query={}
cmd        : https://www.reddit.com/r/commandline/search?q={}&restrict_sr=on&sort=relevance&t=all
srht       : https://sr.ht/projects?search={}&sort=recently-updated
st         : https://sr.ht/projects?search={}&sort=recently-updated
gm         : https://maps.google.com/maps?q={}
gmaps      : https://maps.google.com/maps?q={}
osm        : https://www.openstreetmap.org/search?query={}
gi         : https://www.google.com/search?tbm=isch&q={}
i          : https://duckduckgo.com/?ia=images&iax=images&q={}
ss         : https://github.com/koalaman/shellcheck/wiki/SC{}
"""

# Clean the searchengines list
# c.url.searchengines = {}

# Fill the searchengines list (DEFAULT is the first in the list)
# c.url.searchengines["DEFAULT"] = "https://search.brave.com/search?q={}"
for se in searchengines.splitlines():
    if se:
        bang, url = se.split(":", 1)
        if not c.url.searchengines:
            c.url.searchengines[bang] = url.strip()
            c.url.searchengines["!" + bang] = url.strip()


# --> PER-DOMAIN:
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

config.set("content.register_protocol_handler", True, "*://calendar.google.com")
config.set("content.register_protocol_handler", False, "*://outlook.office365.com")

# config.set("content.media.audio_video_capture", True, "*://app.wire.com")
# config.set("content.media.audio_capture", True, "*://app.wire.com")
# config.set("content.media.video_capture", True, "*://app.wire.com")
# config.set("content.desktop_capture", True, "*://app.wire.com")
# config.set("content.desktop_capture", True, "*://app.wire.com")
# config.set("content.notifications.show_origin", False, "*://app.wire.com")

# config.set("content.register_protocol_handler", True, "*://teams.microsoft.com")
# config.set("content.media.audio_video_capture", True, "*://teams.microsoft.com")
# config.set("content.media.audio_capture", True, "*://teams.microsoft.com")
# config.set("content.media.video_capture", True, "*://teams.microsoft.com")
# config.set("content.desktop_capture", True, "*://teams.microsoft.com")
# config.set("content.cookies.accept", "all", "*://teams.microsoft.com")


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
    "proc": "open -t ;; process",
    "mess": "open -t qute://log/",
    "mpv": "spawn mpv --autofit=100%x100% --force-window=immediate --keep-open=yes {url}",
    # "ompv": "hint links spawn mpv --autofit=100%x100% --force-window=immediate {hint-url}",
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
c.aliases["edge"] = 'spawn open -a "Microsoft Edge" {url}'
c.aliases["hedge"] = 'hint all spawn open -a "Microsoft Edge" {hint-url}'

c.aliases["1p"] = "spawn --userscript 1password"
c.aliases["1password"] = "spawn --userscript 1password"
c.aliases["readability"] = "spawn --userscript readability"
c.aliases["reader"] = "spawn --userscript readability"
# c.aliases["bib"] = "spawn --userscript getbib"
c.aliases["pocket"] = "spawn --userscript qutepocket"

# c.aliases["bg-norm"] = "set colors.webpage.bg #ffffff"
# c.aliases["bg-dark"] = "set colors.webpage.bg " + bg_color
# c.aliases["dg-toggle"] = "jseval --quiet --world main DarkReader.toggle()"
# c.aliases[
#     "insta"
# ] = "jseval const script = document.createElement('script'); script.innerHTML = `(() => { var d=document;try{if(!d.body)throw(0);window.location='http://www.instapaper.com/text?u='+encodeURIComponent(d.location.href);}catch(e){alert('Please wait until the page has loaded.');} })()`; document.body.appendChild(script);"


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


# config.bind('<Shift-h>', 'run-with-count 20 scroll left')
# config.bind('<Shift-j>', 'run-with-count 20 scroll down')
# config.bind('<Shift-k>', 'run-with-count 20 scroll up')
# config.bind('<Shift-l>', 'run-with-count 20 scroll right')

# config.bind('<', 'back')
# config.bind('>', 'forward')
nmap("h", "run-with-count 2 scroll left")
nmap("j", "run-with-count 2 scroll down")
nmap("k", "run-with-count 2 scroll up")
nmap("l", "run-with-count 2 scroll right")

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
nmap(",q", "tab-close")
nmap("<Meta+w>", "tab-close")
nmap("<Ctrl+w>", "tab-close")
nmap("u", "undo")

nmap("r", "reload")
nmap("R", "reload --force")

nmap("J", "tab-next")
nmap("K", "tab-prev")
nmap("<Ctrl+l>", "tab-next")
nmap("<Ctrl+h>", "tab-prev")
nmap("<Ctrl+j>", "tab-next")
nmap("<Ctrl+k>", "tab-prev")

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
nmap("go", "set-cmd-text -s :open {url}")
# nmap("go", "set-cmd-text -s :open --bg")
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
nmap("<Meta+r>", "reload")
for i in range(9):
    nmap("<Ctrl+{}>".format(i), "tab-focus {}".format(i))
# }}}

## misc..
nmap("<Esc>", "fake-key <Esc>")
nmap("<Ctrl+[>", "clear-messages")
imap("<Ctrl+o>", "open-editor")

## userscript/externally-dependent bindings..
nmap("yc", "hint code userscript " + userscript("code_select"))
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

## leader-key bindings..
nmap(",eq", "config-edit ;; message-info 'config opening..'")
nmap(",p", "config-cycle -p content.plugins ;; reload")
nmap(",1p", "1p")
nmap(",tp", "tab-pin")
nmap(",bs", "safari")
nmap(",bb", "brave")
nmap(",bc", "chrome")
nmap(",bf", "firefox")
nmap(",hbs", "hsafari")
nmap(",hbb", "hbrave")
nmap(",hbc", "hchrome")
nmap(",hbf", "hfirefox")
nmap(",sz", "sz ;; message-info 'config sourced..'")
nmap(",df", "devtools-focus")
nmap(",dt", "devtools")
nmap(",gt", "set-cmd-text --space :tab-select")
nmap("<Ctrl+g>", "set-cmd-text --space :tab-select")
# nmap(",be", "oedge")
# nmap(",b", "spawn --userscript buku-add")
# nmap(",f", "spawn --userscript buku-add favourites")
# nmap(",c", "spawn --userscript clipper")
# nmap(",r", "spawn --userscript readability/readability-js")


## macos-style/readline..
config.bind("<Ctrl+n>", "prompt-item-focus next", mode="prompt")
config.bind("<Ctrl+p>", "prompt-item-focus prev", mode="prompt")

config.bind("<Ctrl+n>", "completion-item-focus --history next", mode="command")
config.bind("<Ctrl+p>", "completion-item-focus --history prev", mode="command")

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


# vim: set ts=4 sw=2 tw=80 et foldmethod=marker foldlevel=0:
