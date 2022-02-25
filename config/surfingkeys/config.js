// SurfingKeys Config
// ----------------------------------------------------------------------------
// REFS:
// - https://jo-so.de/2021-01/Surfingkeys.js
// - https://github.com/Foldex/surfingkeys-config/blob/master/config.js
// - https://gist.github.com/Stvad/02d3d40b08e9505c548e00bba05ccea0
// - https://github.com/b0o/surfingkeys-conf
// - https://github.com/mindgitrwx/personal_configures/blob/master/Surfingkeys-config-ko-dev.js
// - https://github.com/loyalpartner/surfingkeys-config/blob/master/surfingkeys.js
//
// TODO:
// - https://brookhong.github.io/2018/11/18/bring-focus-back-to-page-content-from-address-bar.html
// - https://github.com/brookhong/Surfingkeys/wiki/FAQ#how-to-go-to-nth-tab
// - https://github.com/glacambre/firenvim

const actions = {};

if (typeof api !== "undefined") {
  setup_surfingkeys({ api: api });
} else {
  const api = {
    aceVimMap,
    mapkey,
    unmap,
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
    RUNTIME,
  };

  setup_surfingkeys({ api: api });
}

function setup_surfingkeys({ api: api }) {
  // console.log(Object.keys(api));
  const {
    aceVimMap,
    mapkey,
    unmap,
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
    RUNTIME,
  } = api;

  // settings
  settings.defaultSearchEngine = "d"; // duck duck go
  settings.focusAfterClosed = "right";
  settings.hintAlign = "left";
  settings.smoothScroll = false;
  settings.omnibarSuggestionTimeout = 500;
  settings.richHintsForKeystroke = 1;
  settings.omnibarPosition = "middle";
  settings.focusFirstCandidate = false;
  settings.scrollStepSize = 100;
  settings.tabsThreshold = 0;
  settings.modeAfterYank = "Normal";
  settings.useNeovim = false;

  // prev/next link
  // settings.nextLinkRegex = /((>>|next)|>|›|»|→|次へ|次のページ+)/i;
  // settings.prevLinkRegex = /((<<|prev(ious)?)|<|‹|«|←|前へ|前のページ+)/i;
  // blocklist
  settings.blocklistPattern = /mail.google.com/;
  // order
  settings.historyMUOrder = false;
  settings.tabsMRUOrder = false;
  // Input box trueだとiなどで入力ボックスに切り替えてもリンクキーが表示されたままに 切り替えたリンクキーが最後に入力されることも
  settings.cursorAtEndOfInput = false;

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

  // set visual-mode style
  Visual.style("marks", "background-color: #A3BE8C; border: 1px solid #3B4252 !important; text-decoration: underline;");
  Visual.style(
    "cursor",
    "background-color: #E5E9F0 !important; border: 1px solid #6272a4 !important; border-bottom: 2px solid green !important; padding: 2px !important; outline: 1px solid rgba(255,255,255,.75) !important;"
  );

  // -----------------------------------------------------------------------------------------------------------------------
  // Change hints styles
  // -----------------------------------------------------------------------------------------------------------------------
  // Hints.characters = "asdfgqwertvbn";
  // Hints.style(
  //   'border: solid 1px #ff79c6; color:#44475a; background: #f1fa8c; background-color: #f1fa8c; font-size: 10pt; font-family: "Jetbrains Mono"'
  // );
  // Hints.style('border: solid 8px #ff79c6;padding: 1px;background: #f1fa8c; font-family: "Jetbrains Mono"', "text");
  // // -----------------------------------------------------------------------------------------------------------------------
  // // Change search marks and cursor
  // // -----------------------------------------------------------------------------------------------------------------------
  // Visual.style("marks", "background-color: #f1fa8c;");
  // Visual.style(
  //   "cursor",
  //   "background-color: #6272a4 !important; color: #f8f8f2 !important; border:1px red; font-weight:bold"
  // );

  mapkey("w", "Move current tab to another window", function () {
    Front.openOmnibar({ type: "Windows" });
  });

  unmap("w");
  unmap("t");

  vmap("H", "0");
  vmap("L", "$");
  // vunmap("gr");
  // vunmap("q");

  // previous/next tab
  map("<Ctrl-l>", "R");
  map("<Ctrl-h>", "E");

  // close current tab
  map("<Ctrl-w>", "x");

  // page up/down
  map("<Ctrl-f>", "d");
  map("<Ctrl-b>", "e");

  // search opened tabs with `gt`
  map("gt", "T");
  map("<Ctrl-g>", "T");

  // history Back/Forward
  map("H", "S");
  map("L", "D");
  // api.mapkey("K", "#1Click on the previous link on current page", previousPage);
  // api.mapkey("J", "#1Click on the next link on current page", nextPage);

  // first tab/last tab
  map("gH", "g0");
  map("gL", "g$");

  // open link in new tab
  map("F", "gf");

  aceVimMap(",w", ":w", "normal");
  aceVimMap(",q", ":q", "normal");

  // set quick-tab-opening for `<C-1>`-`<C-0>` for tabs 1-10
  for (let i = 0; i <= 9; i++) {
    // unmap(`<Ctrl-${i}>`);
    console.log(`<Ctrl-${i}> -> ${i}T`);

    if (i === 0) {
      map("<Ctrl-0>", "10T");
      map("0t", "10T");
    } else {
      map(`<Ctrl-${i}>`, `${i}T`);
      map(`${i}t`, `${i}T`);
    }
  }

  // custom actions
  actions.showSpeedReader = () => {
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
  mapkey(";s", "-> Open Squirt", actions.showSpeedReader);

  actions.sendToInstapaper = () => {
    const script = document.createElement("script");
    script.innerHTML = `(() => {
    var d=document;try{if(!d.body)throw(0);window.location='http://www.instapaper.com/text?u='+encodeURIComponent(d.location.href);}catch(e){alert('Please wait until the page has loaded.');}
  })()`;
    document.body.appendChild(script);
  };
  unmap(";i");
  mapkey(";i", "-> Send to Instapaper", actions.sendToInstapaper);

  // set theme
  settings.theme = `
  :root {
    --font: "JetBrains Mono", Arial, sans-serif;
    --font-size: 16;
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
    padding: 5px;
    padding-left: 15px;
  }
  .sk_theme #sk_omnibarSearchArea {
    border-top-color: var(--border);
    border-bottom-color: var(--border);
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
    margin-left: -5px;
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
}
