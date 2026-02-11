// enable url reading in safari sk extension:
// document.getElementById("localPathForSettings").style.display = ""

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

function dbg(s) {
  console.log("[megakeys]: " + s);
}

// -----------------------------------------------------------------------------------------------------------------------
// -- [ SETTINGS ]
// -----------------------------------------------------------------------------------------------------------------------
settings.defaultSearchEngine = "k"; // (k)agi, (b)rave, (n)eeva, etc
settings.focusAfterClosed = "right";
settings.hintAlign = "left";
settings.hintExplicit = true;
settings.hintShiftNonActive = true;
settings.smoothScroll = false;
// settings.enableAutoFocus = false;
settings.stealFocusOnLoad = false; // allows canonize.app to work for %k
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

// -- UNMAPS
// (Unused; unmap these first so they can be mapped to other things)
//
// could use this: `unmapAllExcept([])`
// https://github.com/brookhong/Surfingkeys/discussions/1679#discussioncomment-2285766
mapkey("w", "Move current tab to another window", function () {
  Front.openOmnibar({ type: "Windows" });
});

unmap("<Meta-k>"); // search

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

unmap("<Ctrl-t>");
unmap("<Ctrl-g>");

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

// -- disable neovim related things
unmap(";v");
unmap("<Ctrl-i>");
unmap("<Ctrl-Alt-i>");

////////////////////////////////////////////////////////////////
// github default shortcut lists                              //
// https:help.github.com/articles/using-keyboard-shortcuts/   //
////////////////////////////////////////////////////////////////

const mapkeyGithub = (...args) => mapkey(...args, { domain: /github\.com/i });

mapkeyGithub("yp", "Copy project path", () => {
  const path = new URL(window.location.href).pathname.split("/");
  Clipboard.write(`${path[1]}/${path[2]}`);
});

mapkeyGithub("ygh", "Copy project path", () => {
  const path = new URL(window.location.href).pathname.split("/");
  Clipboard.write(`${path[1]}/${path[2]}`);
});

mapkeyGithub("ygl", "Copy git clone url", () => {
  let url = window.location.href;
  // url = url:replace("/tree/master", "");
  // url = url:replace("/tree/main", "");

  Clipboard.write("git clone " + url + ".git");
});

mapkeyGithub("ygc", "Copy project url", () => {
  let url = window.location.href;
  // url = url:replace("/tree/master", "");
  // url = url:replace("/tree/main", "");

  Clipboard.write(url);
});

mapkeyGithub("yv", "Copy for vim", () => {
  const path = new URL(window.location.href).pathname.split("/");
  Clipboard.write(`use({"${path[1]}/${path[2]}"})`);
});

mapkeyGithub(";gC", "Go to the code tab", () => {
  document
    .querySelectorAll(".js-selected-navigation-item.reponav-item")[0]
    .click();
});

mapkeyGithub(";gI", "Go to the Issues tab", () => {
  document
    .querySelectorAll(".js-selected-navigation-item.reponav-item")[1]
    .click();
});

mapkeyGithub(";gP", "Go to the Pull requests tab", () => {
  document
    .querySelectorAll(".js-selected-navigation-item.reponav-item")[2]
    .click();
});

mapkeyGithub(";gB", "Go to the Projects tab", () => {
  document
    .querySelectorAll(".js-selected-navigation-item.reponav-item")[3]
    .click();
});

mapkeyGithub(";gW", "Go to the Wiki tab", () => {
  document
    .querySelectorAll(".js-selected-navigation-item.reponav-item")[4]
    .click();
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
  script.innerHTML =
    `(() => { var d=document;try{if(!d.body)throw(0);window.location='http://www.instapaper.com/text?u='+encodeURIComponent(d.location.href);}catch(e){alert('Please wait until the page has loaded.');} })()`;
  document.body.appendChild(script);
};
unmap(";i");
mapkey(";i", "-> Send to Instapaper", actions.sendToInstapaper);

actions.sendToOmnivore = () => {
  window.open(
    "https://omnivore.app/api/save?url=" +
      encodeURIComponent(window.location.href),
    "_blank",
  );
};
unmap(";o");
mapkey(";o", "-> Send to Omnivore", actions.sendToOmnivore);

// const browserName = getBrowserName();
// if (browserName === "Chrome") {
// imapkey("<Ctrl-Alt-i>", "#15Open neovim for current input", function () {
//   openVim(true);
// });
mapkey(";pdf", "Toggle PDF viewer from SurfingKeys", function () {
  var pdfUrl = window.location.href;
  if (pdfUrl.indexOf(chrome.extension.getURL("/pages/pdf_viewer.html")) === 0) {
    pdfUrl = window.location.search.substr(3);
    chrome.storage.local.set({ noPdfViewer: 1 }, function () {
      window.location.replace(pdfUrl);
    });
  } else {
    if (
      document.querySelector("EMBED") &&
      document.querySelector("EMBED").getAttribute("type") === "application/pdf"
    ) {
      chrome.storage.local.remove("noPdfViewer", function () {
        window.location.replace(pdfUrl);
      });
    } else {
      chrome.storage.local.get("noPdfViewer", function (resp) {
        if (!resp.noPdfViewer) {
          chrome.storage.local.set({ noPdfViewer: 1 }, function () {
            showBanner("PDF viewer disabled.");
          });
        } else {
          chrome.storage.local.remove("noPdfViewer", function () {
            showBanner("PDF viewer enabled.");
          });
        }
      });
    }
  }
});
// }

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
  },
);

removeSearchAlias("n");
addSearchAlias(
  "n",
  "neeva",
  "https://neeva.com/search?q=",
  "s",
  "https://neeva.com/search?q=",
  function (response) {
    var res = JSON.parse(response.text);
    return res.map(function (r) {
      return r.phrase;
    });
  },
);

addSearchAlias(
  "hex",
  "hexdocs",
  "https://hexdocs.pm/",
  "",
  "https://hexdocs.pm/",
  function (response) {
    var res = JSON.parse(response.text);
    return res.map(function (r) {
      return r.phrase;
    });
  },
);

addSearchAlias(
  "tw",
  "tailwindcss",
  "https://tailwindcss.com/docs/",
  "",
  "https://tailwindcss.com/docs/",
  function (response) {
    var res = JSON.parse(response.text);
    return res.map(function (r) {
      return r.phrase;
    });
  },
);

addSearchAlias(
  "gh",
  "github search",
  "https://github.com/search?utf8=%E2%9C%93&q=",
);

addSearchAlias(
  "!gh",
  "github search",
  "https://github.com/search?utf8=%E2%9C%93&q=",
);

addSearchAlias(
  "ghc",
  "github code search",
  "https://github.com/search?type=Code&utf8=%E2%9C%93&q=",
);

addSearchAlias(
  "!ghc",
  "github code search",
  "https://github.com/search?type=Code&utf8=%E2%9C%93&q=",
);

addSearchAlias(
  "!ghnix",
  "github .nix code search",
  "https://github.com/search?type=Code&utf8=%E2%9C%93&q=language:nix ",
);

addSearchAlias(
  "!ghlua",
  "github .lua code search",
  "https://github.com/search?type=Code&utf8=%E2%9C%93&q=language:lua ",
);

addSearchAlias(
  "!nix",
  "nix package and options search",
  "https://mynixos.com/search?q=",
);

addSearchAlias(
  "!hm",
  "nix home-manager options search",
  "https://home-manager-options.extranix.com/?release=master&query=",
);

addSearchAlias(
  "!flakes",
  "nix community flakes search",
  "https://community.flake.parts/",
);

addSearchAlias(
  "!casks",
  "nix casks search",
  "https://nix-casks.yorganci.dev/search?q=",
);

addSearchAlias(
  "d",
  "duckduckgo",
  "https://duckduckgo.com/?q=",
  "s",
  "https://duckduckgo.com/ac/?q=",
  function (response) {
    var res = JSON.parse(response.text);
    return res.map(function (r) {
      return r.phrase;
    });
  },
);

addSearchAlias(
  "k",
  "kagi",
  "https://kagi.com/search?q=",
  "s",
  "https://kagi.com/search?q=",
  function (response) {
    var res = JSON.parse(response.text);
    return res.map(function (r) {
      return r.phrase;
    });
  },
);

// -----------------------------------------------------------------------------------------------------------------------
// -- [ HINTS ]
// -----------------------------------------------------------------------------------------------------------------------

Hints.characters = "qwertasdfgzxcvb";
// Hints.characters = "asdfgyuiopqwertnmzxcvb";
// Link Hints
Hints.style(`
    font-family: 'JetBrainsMono Nerd Font Mono', 'SF Pro', monospace;
    font-size: 15px;
    font-weight: bold;
    text-transform: lowercase;
    color: #E5E9F0 !important;
    background: #3B4252 !important;
    border: solid 1px #4C566A !important;
    text-align: center;
    padding: 5px;
    line-height: 1;
  `);

// Text Hints
Hints.style(
  `
    font-family: 'JetBrainsMono Nerd Font Mono', 'SF Pro', monospace;
    font-size: 15px;
    font-weight: bold;
    text-transform: lowercase;
    color: #E5E9F0 !important;
    background: #6272a4 !important;
    border: solid 2px #4C566A !important;
    text-align: center;
    padding: 5px;
    line-height: 1;
  `,
  "text",
);

// set visual-mode style
Visual.style(
  "marks",
  "background-color: #d9bb80; border: 1px solid #3b4252 !important; text-decoration: underline;",
);
Visual.style(
  "cursor",
  "background-color: #E5E9F0 !important; border: 1px solid #6272a4 !important; border-bottom: 2px solid green !important; padding: 2px !important; outline: 1px solid rgba(255,255,255,.75) !important;",
);

// -----------------------------------------------------------------------------------------------------------------------
// -- [ THEME ]
// -----------------------------------------------------------------------------------------------------------------------
settings.theme = `
  :root {
    --font: "JetBrainsMono Nerd Font Mono", Arial, sans-serif;
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
  .sk_theme #sk_omnibarSearchArea:before {
    content: "󱋤";
    display: inline-block;
    margin-left: 5px;
    font-size: 22px;
  }
  .sk_theme #sk_omnibarSearchArea input,
  .sk_theme #sk_omnibarSearchArea span {
    font-size: 20px;
    padding:10px 0;
  }
  .sk_theme #sk_omnibarSearchArea .prompt {
    text-transform: uppercase;
    padding-left: 10px;
  }
  .sk_theme #sk_omnibarSearchArea .prompt:after {
    content: "";
    display: inline-block;
    padding: 0 5px;
    color: var(--accent-fg);
  }
  .sk_theme #sk_omnibarSearchArea .separator {
    color: var(--bg);
    display: none;
  }
  .sk_theme #sk_omnibarSearchArea .separator:after {
    content: "";
    display: inline-block;
    padding: 0 5px;
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

// -----------------------------------------------------------------------------
// CUSTOM "IIFE"-like FNS
// -----------------------------------------------------------------------------
const inspect = (obj) => {
  return JSON.stringify(obj, null, 4);
};

const embiggenInputs = () => {
  const isBlacklisted = (domain) => {
    return domain && domain.test(new URL(window.location.href).host);
  };

  const blacklisted = [/outstand\.com/i, /outstand\.test/i, /linear\.app/i];
  const ignored = blacklisted.find((domain) => isBlacklisted(domain));

  if (typeof ignored === "undefined") {
    // const firenvim = document.querySelector("body span[tabindex='-1']");
    // console.debug(inspect(firenvim));
    // Give a slight delay, some sites, like linear.app, do some dom things,
    // so it doesn't show just yet..
    window.setTimeout(() => {
      const textareas = document.querySelectorAll("textarea");
      textareas.forEach((el) => {
        el.style = `min-height: 300px`;
      });

      const divs = document.querySelectorAll("div[contenteditable=true]");
      divs.forEach((el) => {
        el.style = `min-height: 300px`;
      });
    }, 1000);
  }
};

// const handleFocus = () => {
//   document.addEventListener("focus", (evt) => {
//     console.log("focus");
//     window.setTimeout(() => {
//       const firenvim = document.querySelector("body span[tabindex='-1']");
//       console.log("firenvim?");
//       console.debug(inspect(firenvim));
//     }, 2000);
//     // console.debug(`initial click ${evt.target}`);
//     if (evt.target.nodeName === "TEXTAREA") {
//       console.debug(evt.target);
//       // let el = evt.target;
//       // // el.style = `height: ${el.clientHeight + 500}px`;
//       // el.style = `height: 800px`;
//       evt.target.style = `min-height: 250px`;
//     } else {
//       let textareas = document.querySelectorAll("textarea");
//       textareas.forEach((el) => {
//         el.style = ``;
//       });
//     }
//   });
// };

const handleLoaded = (evt) => {
  console.debug(`loaded via ${inspect(evt)}`);
  embiggenInputs();
  // handleFocus();
};

const runningAt = (() => {
  let getBackgroundPage = chrome?.extension?.getBackgroundPage;
  if (getBackgroundPage) {
    return getBackgroundPage() === window ? "BACKGROUND" : "POPUP";
  }
  return chrome?.runtime?.onMessage ? "CONTENT" : "WEB";
})();

// if (["complete", "loaded", "interactive"].indexOf(document.readyState) >= 0) {
//   handleLoaded();
// } else {
//   document.addEventListener("DOMContentLoaded", (evt) => handleLoaded(evt));
// }

// EVERFOREST THEMES:
// https://github.com/neuromaancer/everforest_collection/blob/main/SurfingKeys/settings.js
api.Hints.style(`
border: solid 1px #859289;
color:#D3C6AA;
background: initial;
background-color: #2D353B;
    font-family: 'JetBrainsMono Nerd Font Mono', 'SF Pro', monospace;

    font-size: 15px;
`);
api.Hints.style(
  `
border: solid 1px #859289 !important;
padding: 1px !important;
color: #83C092 !important;
background: #2D353B !important;

    font-family: 'JetBrainsMono Nerd Font Mono', 'SF Pro', monospace !important;
    font-size: 15px;
`,
  "text",
);
api.Visual.style("marks", "background-color: #EBCB8B99;");
api.Visual.style("cursor", "background-color: #D3C6AA;");

/* set theme */
settings.theme = `
  :root {
    --font: "JetBrainsMono Nerd Font Mono", Arial, sans-serif;
    --font-size: 16px;
    --font-weight: bold;
    --fg: #E5E9F0;
    --bg: #3B4252;
    --bg-dark: #2b383f;
    --border: #4C566A;
    --main-fg: #88C0D0;
    --accent-fg: #A3BE8C;
    --info-fg: #5E81AC;
    --select: #4C566A;
    --orange: #D08770;
    --red: #BF616A;
    --yellow: #EBCB8B;
  }

.sk_theme {
  font-family: var(--font);
  font-size: var(--font-size);
  background: var(--bg-dark);
  color: #ebdbb2;
}

.sk_theme tbody {
  color: #b8bb26;
}

.sk_theme input {
  color: #d9dce0;
}

.sk_theme .url {
  color: #38971a;
}

.sk_theme .annotation {
  color: #b16286;
}

#sk_omnibar {
  width: 60%;
  left: 20%;
  box-shadow: 0px 3px 5px rgba(0, 0, 0, 0.3);
}

.sk_omnibar_middle {
  top: 15%;
  border-radius: 10px;
}


.sk_theme .omnibar_highlight {
  color: #ebdbb2;
}

.sk_theme #sk_omnibarSearchResult ul li:nth-child(odd) {
  background: #2D353B;
}

.sk_theme #sk_omnibarSearchResult {
  max-height: 60vh;
  overflow: hidden;
  margin: 0rem 0rem;
}

#sk_omnibarSearchResult>ul {
  padding: 1.0em;
  padding-top: 0;
}

.sk_theme #sk_omnibarSearchResult ul li {
  margin-block: 0.5rem;
  padding-left: 0.4rem;
  overflow: hidden;
}

#sk_omnibarSearchResult li.focused div.url {
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
}

.sk_theme #sk_omnibarSearchResult ul li .url {
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 1;
  -webkit-box-orient: vertical;
}

.sk_theme #sk_omnibarSearchResult ul li.focused {
  background: #475258;
  border-color: #475258;
  border-radius: 12px;
  position: relative;
}


#sk_omnibarSearchArea>input {
  display: inline-block;
  width: 100%;
  flex: 1;
  font-size: 20px;
  margin-bottom: 0;
  padding: 0px 0px 0px 0.5rem;
  background: transparent;
  border-style: none;
  outline: none;
  padding-left: 18px;
}

#sk_banner {
  background: #3D484D;
  color: #D3C6AA;
  border-color: #3D484D;
  left: unset;
  right: 10rem;
  width: 30%;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box !important;
  -webkit-line-clamp: 1;
  -webkit-box-orient: vertical;
  padding: 1rem;
  transition: top ease-out .1s;
}

#sk_tabs {
  position: fixed;
  top: 0;
  left: 0;
  background-color: rgba(0, 0, 0, 0);
  overflow: auto;
  z-index: 2147483000;
  box-shadow: 0px 30px 50px rgba(0, 0, 0, 0.3);
  margin-left: 1rem;
  margin-top: 1.5rem;
  border: solid 1px #2D353B;
  border-radius: 15px;
  background-color: #2D353B;
  padding-top: 10px;
  padding-bottom: 10px;

}

#sk_tabs div.sk_tab {
  vertical-align: bottom;
  display: flex;
  align-items: center;
  justify-items: center;
  border-radius: 0px;
  background: #2D353B;

  margin: 0px;
  box-shadow: 0px 0px 0px 0px rgba(245, 245, 0, 0.3);
  box-shadow: 0px 0px 0px 0px rgba(0, 0, 0, 0.3) !important;

  /* padding-top: 2px; */
  border-top: solid 0px black;
  margin-block: 0rem;
}


#sk_tabs div.sk_tab:not(:has(.sk_tab_hint)) {
  background-color: #475258 !important;
  border: 1px solid #475258;
  border-radius: 20px;
  position: relative;
  z-index: 1;
  margin-left: 1.8rem;
  padding-left: 0rem;
  margin-right: 0.7rem;
}


#sk_tabs div.sk_tab_title {
  display: inline-block;
  vertical-align: middle;
  font-size: 10pt;
  white-space: nowrap;
  text-overflow: ellipsis;
  overflow: hidden;
  padding-left: 12px;
  color: #ebdbb2;
}

#sk_tabs div.sk_tab_icon>img {
  display: block;
}

#sk_tabs.vertical div.sk_tab_hint {
  position: inherit;
  left: 8pt;
  margin-top: 3px;
  border: solid 1px #859289;
  color: #D3C6AA;
  background: initial;
  background-color: #272822;
  font-family: Cascadia Mono;
}

#sk_tabs.vertical div.sk_tab_wrap {
  display: inline-flex;
  align-items: center;
  margin-left: 0pt;
  margin-top: 0px;
  padding-left: 15px;
}

#sk_tabs.vertical div.sk_tab_title {
  min-width: 100pt;
  max-width: 20vw;
}

#sk_usage,
#sk_popup,
#sk_editor {
  overflow: auto;
  position: fixed;
  width: 80%;
  max-height: 80%;
  top: 10%;
  left: 10%;
  text-align: left;
  box-shadow: 0px 3px 5px rgba(0, 0, 0, 0.3);
  z-index: 2147483298;
  padding: 1rem;
  border: 1px solid #2D353B;
  border-radius: 10px;
}

#sk_keystroke {
  padding: 6px;
  position: fixed;
  float: right;
  bottom: 0px;
  z-index: 2147483000;
  right: 0px;
  background: #2D353B;
  color: #fff;
  border: 1px solid #181818;
  border-radius: 10px;
  margin-bottom: 1rem;
  margin-right: 1rem;
  box-shadow: 0px 3px 5px rgba(0, 0, 0, 0.3);
}

#sk_status {
  position: fixed;
  /* top: 0; */
  bottom: 0;
  right: 39%;
  z-index: 2147483000;
  padding: 8px 8px 8px 8px;
  border-radius: 5px;
  border: 1px solid #2D353B;
  font-size: 12px;
  box-shadow: 0px 2px 4px 2px rgba(0, 0, 0, 0.3);
  /* margin-bottom: 1rem; */
  width: 20%;
  margin-bottom: 1rem;
}


#sk_omnibarSearchArea {
  border-bottom: 0px solid #2D353B;
  margin: 0.8rem 1rem !important;
}


#sk_omnibarSearchArea .resultPage {
  display: inline-block;
  font-size: 12pt;
  font-style: italic;
  width: auto;
}

div.surfingkeys_match_mark {
    background-color: var(--accent-fg);
    color: #000;
    opacity: 0.7;
}

div.surfingkeys_selection_mark {
    background-color: var(--info-fg);
    color: #000;
    opacity: 0.7;
}

  #sk_omnibarSearchArea {
    border-top-color: var(--border);
    border-bottom-color: transparent;
    margin: 0;
    padding: 5px 10px;
  }
  #sk_omnibarSearchArea:before {
    content: "󱋤";
    display: inline-block;
    margin-left: 5px;
    font-size: 22px;
  }
  #sk_omnibarSearchArea input,
  #sk_omnibarSearchArea span {
    font-size: 20px;
    padding:10px 0;
  }
  #sk_omnibarSearchArea .prompt {
    text-transform: uppercase;
    padding-left: 10px;
  }
  #sk_omnibarSearchArea .prompt:after {
    content: "";
    display: inline-block;
    padding: 0 5px;
    color: var(--accent-fg);
  }
  #sk_omnibarSearchArea .separator {
    color: var(--bg);
    display: none;
  }
  #sk_omnibarSearchArea .separator:after {
    content: "";
    display: inline-block;
    padding: 0 5px;
    color: var(--accent-fg);
  }

#sk_omnibarSearchResult li div.url {
  font-weight: normal;
  white-space: nowrap;
  color: #aaa;
}

.sk_theme .omnibar_highlight {
  color: #A7C080;
  font-weight: bold;
}

.sk_theme .omnibar_folder {
  border: 1px solid #188888;
  border-radius: 5px;
  background: #188888;
  color: #aaa;
  box-shadow: 1px 1px 5px rgba(0, 8, 8, 0.3);
}

.sk_theme .omnibar_timestamp {
  background: transparent;
  border: 1px solid transparent;
  border-radius: 5px;
  color: #aaa;
  box-shadow: 1px 1px 5px rgba(0, 8, 8, 0.3);
}

#sk_omnibarSearchResult li div.title {
  text-align: left;
  max-width: 100%;
  white-space: nowrap;
  overflow: clip;
}

.sk_theme .separator {
  color: #2D353B;
}

.sk_theme .prompt {
  color: #7A8478;
  border-radius: 10px;
  padding-left: 4px;
  /* padding: ; */
  font-weight: bold;
  display: inline-flex !important;
  align-items: center;
}

.sk_theme .prompt .separator {
  display: none;
  width: 0;
  color: transparent;
}

#sk_status,
#sk_find {
  font-size: 10pt;
  font-weight: bold;
  text-align: center;
  padding-right: 8px;
  width: auto;
}

#sk_status span[style*="border-right: 1px solid rgb(153, 153, 153);"] {
  display: none;
}

.expandRichHints span.annotation {
  color: #D3C6AA;
  padding-left: 8px;
}

#sk_editor {
  background: #2D353B !important;
  color: #D3C6AA;
}

.normal-mode .ace_hidden-cursors .ace_cursor {
  border-color: #9DA9A0;
}

.normal-mode .ace_cursor {
  background: #9DA9A099;
}

.ace-chrome .ace_cursor {
  color: #9DA9A099;
}

.ace-chrome .ace_marker-layer .ace_selection {
  background-color: #543A4899 !important;
}

.ace-chrome .ace_gutter {
  background: #2D353B;
}

.ace_gutter-cell {
  color: #7A8478;
}

.ace-chrome .ace_print-margin {
  background: transparent;
}

.ace-chrome .ace_marker-layer .ace_active-line {
  background: #343F44;
}

.ace-chrome .ace_gutter-active-line {
  color: #9DA9A0;
  background: #2D353B;
}
`;
