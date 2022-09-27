// SurfingKeys Config
// ----------------------------------------------------------------------------
// REFS:
// - https://jo-so.de/2021-01/Surfingkeys.js
// - https://github.com/Foldex/surfingkeys-config/blob/master/config.js
// - https://gist.github.com/Stvad/02d3d40b08e9505c548e00bba05ccea0
// - https://github.com/b0o/surfingkeys-conf
// - https://github.com/mindgitrwx/personal_configures/blob/master/Surfingkeys-config-ko-dev.js
// - https://github.com/loyalpartner/surfingkeys-config/blob/master/surfingkeys.js
// - https://github.com/j-hui/pokerus/blob/main/surfingkeys.config/surfingkeys/surfingkeys.js
//
// TODO:
// - https://brookhong.github.io/2018/11/18/bring-focus-back-to-page-content-from-address-bar.html
// - https://github.com/brookhong/Surfingkeys/wiki/FAQ#how-to-go-to-nth-tab
// - https://github.com/glacambre/firenvim
//
// - vivaldi support: https://gist.github.com/coramuirgen/94ba1d587cb2093c71f6ef4f0b371069

const actions = {};
const util = {};
const {
  aceVimMap,
  mapkey,
  unmap,
  vunmap,
  iunmap,
  imap,
  imapkey,
  getClickableElements,
  vmapkey,
  vmap,
  map,
  cmap,
  addSearchAlias,
  removeSearchAlias,
  tabOpenLink,
  readText,
  Clipboard,
  Front,
  Hints,
  Visual,
  Normal,
  RUNTIME,
} = api;
window.skApi = api;

function dbg(s) {
  console.log("[megakeys]: " + s);
}

// -----------------------------------------------------------------------------------------------------------------------
// -- [ SETTINGS ]
// -----------------------------------------------------------------------------------------------------------------------
settings.defaultSearchEngine = "b"; // duck duck go
settings.focusAfterClosed = "right";
settings.hintAlign = "left";
settings.hintExplicit = true;
settings.hintShiftNonActive = true;
settings.smoothScroll = false;
settings.omnibarSuggestionTimeout = 500;
settings.richHintsForKeystroke = 1;
settings.omnibarPosition = "middle";
settings.focusFirstCandidate = false;
settings.scrollStepSize = 100;
settings.tabsThreshold = 0;
settings.modeAfterYank = "Normal";
settings.useNeovim = false;
// blocklist
settings.blocklistPattern = /mail.google.com/;
// order
settings.historyMUOrder = false;
settings.tabsMRUOrder = false;
// Input box true
settings.cursorAtEndOfInput = false;

// -----------------------------------------------------------------------------------------------------------------------
// -- [ HINTS ]
// -----------------------------------------------------------------------------------------------------------------------

Hints.characters = "qwertasdfgzxcvb";
// Hints.characters = "asdfgyuiopqwertnmzxcvb";
// Link Hints
Hints.style(`
    font-family: 'JetBrains Mono';
    font-size: 12px;
    font-weight: normal;
    text-transform: lowercase;
    color: #E5E9F0 !important;
    background: #3B4252 !important;
    border: solid 1px #4C566A !important;
  `);

// Text Hints
Hints.style(
  `
    font-family: 'JetBrains Mono';
    font-size: 12px;
    text-transform: lowercase;
    color: #E5E9F0 !important;
    background: #6272a4 !important;
    border: solid 2px #4C566A !important;
  `,
  "text"
);

// -- Change hints styles
// Hints.characters = "asdfgqwertvbn";
// Hints.style(
//   'border: solid 1px #ff79c6; color:#44475a; background: #f1fa8c; background-color: #f1fa8c; font-size: 10pt; font-family: "Jetbrains Mono"'
// );
// Hints.style('border: solid 8px #ff79c6;padding: 1px;background: #f1fa8c; font-family: "Jetbrains Mono"', "text");

// -----------------------------------------------------------------------------------------------------------------------
// -- [ VISUAL ]
// -----------------------------------------------------------------------------------------------------------------------
// set visual-mode style
Visual.style("marks", "background-color: #A3BE8C; border: 1px solid #3B4252 !important; text-decoration: underline;");
Visual.style(
  "cursor",
  "background-color: #E5E9F0 !important; border: 1px solid #6272a4 !important; border-bottom: 2px solid green !important; padding: 2px !important; outline: 1px solid rgba(255,255,255,.75) !important;"
);
// -- Change search marks and cursor
// Visual.style("marks", "background-color: #f1fa8c;");
// Visual.style(
//   "cursor",
//   "background-color: #6272a4 !important; color: #f8f8f2 !important; border:1px red; font-weight:bold"
// );

// -----------------------------------------------------------------------------------------------------------------------
// -- [ MAPPINGS ]
// -----------------------------------------------------------------------------------------------------------------------

/* Chord prefix mnemonics:
 *
 *   (r)eload: related to current page
 *   (z)oom: related to page resolution
 *   (:): related to omnibar
 *   (g)oto: links, input, and other graphical interaction
 *   (s)croll: select scroll elements
 *   (y)ank: pull to clipboard
 *
 */

// -- UNMAPS
// (Unused; unmap these first so they can be mapped to other things)
//
// could use this: `unmapAllExcept([])`
// https://github.com/brookhong/Surfingkeys/discussions/1679#discussioncomment-2285766
mapkey("w", "Move current tab to another window", function () {
  Front.openOmnibar({ type: "Windows" });
});

unmap(":"); // Lets me map chords beginning with ':'
iunmap(":"); // disable emoji completion
vunmap("t"); // disable google translate of visually selected
unmap("w"); // disable window splitting (i use hammerspoon for that)
unmap(";w"); // Focus top window
unmap("%"); // Scroll to percentage of current page
unmap(";m"); // Mouse out last element
unmap("B"); // Go on tab history back
unmap("gT"); // Go to first activated tab
unmap(";i"); // Insert jquery library on current page
unmap(";t"); // Translate selected text with google
unmap("gr"); // Read selected text or text from clipboard
unmap(";dh"); // Delete history older than 30 days

unmap("<Alt-p>"); // pin/unpin current tab
unmap("<Alt-m>"); // mute/unmute current tab

// Search selection
unmap("sg");
unmap("sd");
unmap("sb");
unmap("sw");
unmap("ss");
unmap("sh");
unmap("sy");

/* (Search selection doesn't make sense for normal mode) */
unmap("sg");
unmap("sd");
unmap("sb");
unmap("sw");
unmap("ss");
unmap("sh");
unmap("sy");

// -- VISUAL
vmap("H", "0");
vmap("L", "$");
// vunmap("gr");
// vunmap("q");

// -- Tab navigation
// previous/next tab
map("<Ctrl-l>", "R");
map("<Ctrl-h>", "E");
// close current tab
map("<Ctrl-w>", "x");
map("<Ctrl-u>", "X");
map("q", "x");
// page up/down
map("<Ctrl-f>", "d");
map("<Ctrl-b>", "e");
// search opened tabs with `gt`
map("gt", "T");
map("<Ctrl-g>", "T");
map("<Ctrl-t>", "t");
// unmap("t"); // we'll use Ctrl-t instead
// unmap("T"); // we'll use Ctrl-g instead

// history Back/Forward
map("H", "S");
map("L", "D");
// first tab/last tab
map("gH", "g0");
map("gL", "g$");
// open link in new tab
map("F", "gf");

mapkey("gl", "#4Go to last used tab", function () {
  RUNTIME("goToLastTab");
});

mapkey("::", "#8Open commands", function () {
  Front.openOmnibar({ type: "Commands" });
});

// -- Clipboard
unmap("yg");
unmap("ygh");

////////////////////////////////////////////////////////////////
// github default shortcut lists                              //
// https:help.github.com/articles/using-keyboard-shortcuts/   //
////////////////////////////////////////////////////////////////

const mapkeyGithub = (...args) => mapkey(...args, { domain: /github\.com/i });

mapkeyGithub("yg", "git clone - git clone address", () =>
  Clipboard.write("git clone " + window.location.href + ".git")
);

mapkeyGithub("yp", "Copy project path", () => {
  const path = new URL(window.location.href).pathname.split("/");
  Clipboard.write(`${path[1]}/${path[2]}`);
});

mapkeyGithub("ygh", "Copy project path", () => {
  const path = new URL(window.location.href).pathname.split("/");
  // mapkey("ygh", "Copy GitHub repo base", function () {
  Clipboard.write(`${path[1]}/${path[2]}`);
  // Clipboard.write(actions.parseRepo(window.location.href).repoPluginPath);
});

mapkeyGithub("yv", "Copy for vim", () => {
  const path = new URL(window.location.href).pathname.split("/");
  Clipboard.write(`use({"${path[1]}/${path[2]}"})`);
});

mapkeyGithub(";gC", "Go to the code tab", () => {
  document.querySelectorAll(".js-selected-navigation-item.reponav-item")[0].click();
});

mapkeyGithub(";gI", "Go to the Issues tab", () => {
  document.querySelectorAll(".js-selected-navigation-item.reponav-item")[1].click();
});

mapkeyGithub(";gP", "Go to the Pull requests tab", () => {
  document.querySelectorAll(".js-selected-navigation-item.reponav-item")[2].click();
});

mapkeyGithub(";gB", "Go to the Projects tab", () => {
  document.querySelectorAll(".js-selected-navigation-item.reponav-item")[3].click();
});

mapkeyGithub(";gW", "Go to the Wiki tab", () => {
  document.querySelectorAll(".js-selected-navigation-item.reponav-item")[4].click();
});

mapkeyGithub(";gO", "Go to the Overview tab", () => {
  document.querySelectorAll(".UnderlineNav-item")[0].click();
});
mapkeyGithub(";gR", "Go to the Repository tab", () => {
  document.querySelectorAll(".UnderlineNav-item")[1].click();
});
mapkeyGithub(";gS", "Go to the Stars tab", () => {
  document.querySelectorAll(".UnderlineNav-item")[2].click();
});

api.mapkey("ye", "Copy src URL of an image", function () {
  Hints.create("img[src]", (element, _evt) => {
    api.Clipboard.write(element.src);
  });
});

// -- ESC hatch
imap("<Ctrl-[>", "<Esc>");
imap("<Ctrl-c>", "<Esc>");
cmap("<Ctrl-[>", "<Esc>");
cmap("<Ctrl-c>", "<Esc>");

vmapkey("<Ctrl-[>", "#9Exit visual mode", function () {
  if (Visual.state > 1) {
    Visual.hideCursor();
    Visual.selection.collapse(selection.anchorNode, selection.anchorOffset);
    Visual.showCursor();
  } else {
    Visual.visualClear();
    Visual.exit();
  }
  Visual.state--;
  Visual._onStateChange();
});

vmapkey("<Ctrl-c>", "#9Exit visual mode", function () {
  Visual.exit();
});

// set quick-tab-opening for `<C-1>`-`<C-0>` for tabs 1-10
for (let i = 1; i <= 9; i++) {
  unmap(`<Ctrl-${i}>`);
  mapkey(`<Ctrl-${i}>`, `Jump to tab ${i}`, function () {
    Normal.feedkeys(`${i}T`);
  });
}

// -- EDITOR/ACE
aceVimMap(",w", ":w", "normal");
aceVimMap(",q", ":q", "normal");
aceVimMap("kj", "<Esc>", "insert");
aceVimMap("<C-c>", "<Esc>", "insert");

// custom actions
actions.showSquirt = () => {
  const script = document.createElement("script");
  script.innerHTML = `(() => {
    const sq = window.sq || {}
    window.sq = sq
    if (sq.script) {
      sq.again()
    } else if (sq.context !== "inner") {
      sq.bookmarkletVersion = "0.3.0"
      sq.iframeQueryParams = { host: "//squirt.io" }
      sq.script = document.createElement("script")
      sq.script.src = \`\${sq.iframeQueryParams.host}/bookmarklet/frame.outer.js\`
      document.body.appendChild(sq.script)
    }
  })()`;
  document.body.appendChild(script);
};
unmap(";s");
mapkey(";s", "-> Open Squirt", actions.showSquirt);

actions.sendToInstapaper = () => {
  const script = document.createElement("script");
  script.innerHTML = `(() => { var d=document;try{if(!d.body)throw(0);window.location='http://www.instapaper.com/text?u='+encodeURIComponent(d.location.href);}catch(e){alert('Please wait until the page has loaded.');} })()`;
  document.body.appendChild(script);
};
unmap(";i");
mapkey(";i", "-> Send to Instapaper", actions.sendToInstapaper);

util.getCurrentLocation = (prop = "href") => {
  if (typeof window === "undefined") {
    return "";
  }
  return window.location[prop];
};

actions.parseRepo = (url = util.getCurrentLocation(), rootOnly = false) => {
  const u = url instanceof URL ? url : new URL(url);
  const [user, repo, ...rest] = u.pathname.split("/").filter((s) => s !== "");
  const isRoot = rest.length === 0;
  const cond =
    u.origin === util.getCurrentLocation("origin") &&
    typeof user === "string" &&
    user.length > 0 &&
    typeof repo === "string" &&
    repo.length > 0 &&
    (isRoot || rootOnly === false) &&
    /^([a-zA-Z0-9]+-?)+$/.test(user);
  // && !ghReservedNames.check(user);
  return cond
    ? {
        type: "repo",
        user,
        repo,
        owner: user,
        name: repo,
        href: url,
        url: u,
        repoBase: `/${user}/${repo}`,
        repoPluginPath: `${user}/${repo}`,
        repoRoot: isRoot,
        repoPath: rest,
      }
    : null;
};

// add search engines
// REF: https://gist.github.com/chixing/82767d49380294ad7b298554e2c0e59b
removeSearchAlias("b");
addSearchAlias(
  "b",
  "brave",
  "https://search.brave.com/search?q=",
  "s",
  "https://search.brave.com/search?q=",
  function (response) {
    var res = JSON.parse(response.text);
    return res.map(function (r) {
      return r.phrase;
    });
  }
);

// set theme
settings.theme = `
  :root {
    --font: "JetBrains Mono", Arial, sans-serif;
    --font-size: 16px;
    --font-weight: bold;
    --fg: #E5E9F0;
    --bg: #3B4252;
    --bg-dark: #2E3440;
    --border: #4C566A;
    --main-fg: #88C0D0;
    --accent-fg: #A3BE8C;
    --info-fg: #5E81AC;
    --select: #4C566A;
    --orange: #D08770;
    --red: #BF616A;
    --yellow: #EBCB8B;
  }
  /* ---------- Generic ---------- */
  .sk_theme {
  background: var(--bg);
  color: var(--fg);
    background-color: var(--bg);
    border-color: var(--border);
    font-family: var(--font);
    font-size: var(--font-size);
    font-weight: var(--font-weight);
  }
  input {
    font-family: var(--font);
    font-weight: var(--font-weight);
  }

  div.surfingkeys_cursor {
    background-color: #0642CE;
    color: red;
  }
  .sk_theme tbody {
    color: var(--fg);
  }
  .sk_theme input {
    color: var(--fg);
  }
  /* Hints */
  #sk_hints .begin {
    color: var(--accent-fg) !important;
  }
  #sk_tabs .sk_tab {
    background: var(--bg-dark);
    border: 1px solid var(--border);
  }
  #sk_tabs .sk_tab_title {
    color: var(--fg);
  }
  #sk_tabs .sk_tab_url {
    color: var(--main-fg);
  }
  #sk_tabs .sk_tab_hint {
    background: var(--bg);
    border: 1px solid var(--border);
    color: var(--accent-fg);
  }
  .sk_theme #sk_frame {
    background: var(--bg);
    opacity: 0.2;
    color: var(--accent-fg);
  }
  /* ---------- Omnibar ---------- */
  /* Uncomment this and use settings.omnibarPosition = 'bottom' for Pentadactyl/Tridactyl style bottom bar */
  /* .sk_theme#sk_omnibar {
    width: 100%;
    left: 0;
  } */
  .sk_theme .title {
    color: var(--accent-fg);
  }
  .sk_theme .url {
    color: var(--main-fg);
  }
  .sk_theme .annotation {
    color: var(--accent-fg);
  }
  .sk_theme .omnibar_highlight {
    color: var(--accent-fg);
  }
  .sk_theme .omnibar_timestamp {
    color: var(--info-fg);
  }
  .sk_theme .omnibar_visitcount {
    color: var(--accent-fg);
  }
  .sk_theme #sk_omnibarSearchResult ul li .url {
    font-size: calc(var(--font-size) - 2px);
  }
  .sk_theme #sk_omnibarSearchResult ul li:nth-child(odd) {
    background: var(--border);
    padding: 5px;
  }
  .sk_theme #sk_omnibarSearchResult ul li:nth-child(even) {
    background: var(--border);
    padding: 5px;
  }
  .sk_theme #sk_omnibarSearchResult ul li.focused {
    background: var(--bg-dark);
    border-left: 2px solid var(--orange);
    padding: 5px;
    padding-left: 15px;
  }
  .sk_theme #sk_omnibarSearchArea {
    border-top-color: var(--border);
    border-bottom-color: transparent;
    margin: 0;
    padding: 5px 10px;
  }
  .sk_theme #sk_omnibarSearchArea input,
  .sk_theme #sk_omnibarSearchArea span {
    font-size: 20px;
    padding:10px 0;
  }
  .sk_theme .prompt {
    text-transform: uppercase;
  }
  .sk_theme .separator {
    color: var(--bg);
    /* margin-right: 10px;
    * color: var(--accent-fg);
    */
  }
  .sk_theme .separator:after {
    content: "\u1405";
    display: inline-block;
    margin-left: -10px;
    margin-right: 5px;
    color: var(--accent-fg);
  }
  /* ---------- Popup Notification Banner ---------- */
  #sk_banner {
    font-family: var(--font);
    font-size: var(--font-size);
    font-weight: var(--font-weight);
    background: var(--bg);
    border-color: var(--border);
    color: var(--fg);
    opacity: 0.9;
  }
  /* ---------- Popup Keys ---------- */
  #sk_keystroke {
    background-color: var(--bg);
  }
  .sk_theme kbd .candidates {
    color: var(--info-fg);
  }
  .sk_theme span.annotation {
    color: var(--accent-fg);
  }
  /* ---------- Popup Translation Bubble ---------- */
  #sk_bubble {
    background-color: var(--bg) !important;
    color: var(--fg) !important;
    border-color: var(--border) !important;
  }
  #sk_bubble * {
    color: var(--fg) !important;
  }
  #sk_bubble div.sk_arrow div:nth-of-type(1) {
    border-top-color: var(--border) !important;
    border-bottom-color: var(--border) !important;
  }
  #sk_bubble div.sk_arrow div:nth-of-type(2) {
    border-top-color: var(--bg) !important;
    border-bottom-color: var(--bg) !important;
  }
  /* ---------- Search ---------- */
  #sk_status,
  #sk_find {
    font-size: var(--font-size);
    border-color: var(--border);
  }
  .sk_theme kbd {
    background: var(--bg-dark);
    border-color: var(--border);
    box-shadow: none;
    color: var(--fg);
  }
  .sk_theme .feature_name span {
    color: var(--main-fg);
  }
  /* ---------- ACE Editor ---------- */
  #sk_editor {
    background: var(--bg-dark) !important;
    height: 50% !important;
    /* Remove this to restore the default editor size */
  }
  .ace_dialog-bottom {
    border-top: 1px solid var(--bg) !important;
  }
  .ace-chrome .ace_print-margin,
  .ace_gutter,
  .ace_gutter-cell,
  .ace_dialog {
    background: var(--bg) !important;
  }
  .ace-chrome {
    color: var(--fg) !important;
  }
  .ace_gutter,
  .ace_dialog {
    color: var(--fg) !important;
  }
  .ace_cursor {
    color: var(--fg) !important;
  }
  .normal-mode .ace_cursor {
    background-color: var(--fg) !important;
    border: var(--fg) !important;
    opacity: 0.7 !important;
  }
  .ace_marker-layer .ace_selection {
    background: var(--select) !important;
  }
  .ace_editor,
  .ace_dialog span,
  .ace_dialog input {
    font-family: var(--font);
    font-size: var(--font-size);
    font-weight: var(--font-weight);
  }

  /* Disable RichHints CSS animation */
  .expandRichHints {
      animation: 0s ease-in-out 1 forwards expandRichHints;
  }
  .collapseRichHints {
      animation: 0s ease-in-out 1 forwards collapseRichHints;
  }
  `;
