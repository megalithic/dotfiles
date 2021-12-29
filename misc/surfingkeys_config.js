// SurfingKeys Config
// ----------------------------------------------------------------------------
// REFS:
// - https://jo-so.de/2021-01/Surfingkeys.js
// - https://github.com/Foldex/surfingkeys-config/blob/master/config.js
// - https://gist.github.com/Stvad/02d3d40b08e9505c548e00bba05ccea0
// - https://github.com/b0o/surfingkeys-conf
// - https://github.com/mindgitrwx/personal_configures/blob/master/Surfingkeys-config-ko-dev.js
//
// TODO:
// - https://brookhong.github.io/2018/11/18/bring-focus-back-to-page-content-from-address-bar.html
// - https://github.com/brookhong/Surfingkeys/wiki/FAQ#how-to-go-to-nth-tab
// - https://github.com/glacambre/firenvim

// DEBUGGING:
console.log(Object.keys(api));

const { map, mapkey, Visual, Hints } = api;

// settings.aceKeybindings = 'emacs';
settings.defaultSearchEngine = "d"; // duck duck go
settings.focusAfterClosed = "left";
settings.hintAlign = "left";
settings.smoothScroll = false;
settings.tabsThreshold = 0;
settings.omnibarSuggestionTimeout = 500;
settings.richHintsForKeystroke = 1;

settings.defaultSearchEngine = "d";
settings.hintAlign = "left";
settings.omnibarPosition = "bottom";
settings.focusFirstCandidate = false;
settings.focusAfterClosed = "last";
settings.scrollStepSize = 200;
settings.tabsThreshold = 7;
settings.modeAfterYank = "Normal";

// set hints style
if (typeof Hints !== "undefined") {
  Hints.characters = "qwertasdfgzxcvb";
  // Hints.characters = "asdfgyuiopqwertnmzxcvb";
  Hints.style("border: solid 2px #4C566A; color:#A3BE8C; background: initial; background-color: #3B4252;");
  Hints.style(
    "border: solid 2px #4C566A !important; padding: 1px !important; color: #E5E9F0 !important; background: #3B4252 !important;",
    "text"
  );
}

// set visual-mode style
if (typeof Visual !== "undefined") {
  Visual.style("marks", "background-color: #A3BE8C99;");
  Visual.style("cursor", "background-color: #88C0D0;");
}

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

// history Back/Forward
map("H", "S");
map("L", "D");
// api.mapkey("K", "#1Click on the previous link on current page", previousPage);
// api.mapkey("J", "#1Click on the next link on current page", nextPage);

// set theme
settings.theme = `
:root {
  --font: "DejaVu Sans", DejaVu, Arial, sans-serif;
  --font-size: 14;
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
  background: var(--bg-dark);
}
.sk_theme #sk_omnibarSearchResult ul li.focused {
  background: var(--border);
}
.sk_theme #sk_omnibarSearchArea {
  border-top-color: var(--border);
  border-bottom-color: var(--border);
}
.sk_theme #sk_omnibarSearchArea input,
.sk_theme #sk_omnibarSearchArea span {
  font-size: var(--font-size);
}
.sk_theme .separator {
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
`;

// const commands = {
//   import: function () {},
//   exec: function () {},
//   def: function () {},
//   list: {},
// };

// commands.import = function (name, keymap, key) {
//   const ks = KeyboardUtils.encodeKeystroke(key);
//   let cmd = keymap.mappings.find(ks);
//   if (!cmd) {
//     throw `${key} (${ks}) not defined in keymap`;
//   }
//   cmd = { ...cmd.meta };
//   delete cmd.word;
//   cmd.name = name;

//   this.list[name] = cmd;
// };

// commands.exec = function (name) {
//   this.list[name].code();
// };

// commands.def = function (name, feature_group, annotation, code) {
//   if (arguments.length < 4) {
//     code = annotation;
//     annotation = feature_group;
//     feature_group = 14;
//   }

//   return (this.list[name] = {
//     name,
//     feature_group,
//     annotation,
//     code,
//     // TODO: repeatIgnore
//   });
// };

// commands.import("beginning-of-page", Normal, "gg");
// commands.import("end-of-page", Normal, "G");
// commands.import("half-page-up", Normal, "<Ctrl-b");
// commands.import("half-page-down", Normal, "<Ctrl-f");
// commands.import("reload", Normal, "r");
// commands.import("select-left-tab", Normal, "<Ctrl-h>");
// commands.import("select-right-tab", Normal, "<Ctrl-l>");
// commands.import("select-tab", Normal, "T");
// commands.import("duplicate-tab", Normal, "yt");
// commands.import("duplicate-tab-background", Normal, "yT");
// commands.import("follow-link", Normal, "f");
// commands.import("follow-link-new-tab", Normal, "af");
// commands.import("follow-link-new-tab-background", Normal, "C");
// commands.import("follow-multiple-links", Normal, "cf");
// commands.import("close-current-tab", Normal, "<Ctrl-w>");
// commands.import("close-left-tab", Normal, "gxt");
// commands.import("close-right-tab", Normal, "gxT");
// commands.import("close-all-left-tabs", Normal, "gx0");
// commands.import("close-all-right-tabs", Normal, "gx$");
// commands.import("undo-last-tab-close", Normal, "X");
// commands.import("copy-tab-url", Normal, "yy");
// commands.import("copy-tab-host", Normal, "yh");
// commands.import("copy-page-title", Normal, "yl");
// commands.import("copy-link-url", Normal, "ya");
// commands.import("copy-element-text", Normal, "yv");
// commands.import("goto-url", Normal, "go");
// commands.import("goto-url-new-tab", Normal, "t");
// commands.import("goto-current-url-without-fragment", Normal, "g#");
// commands.import("goto-current-url-without-query", Normal, "g?");
// commands.import("goto-current-url-root", Normal, "gU");
// commands.import("goto-current-url-parent", Normal, "gu");
// commands.import("goto-clipboard-url-new-tab", Normal, "cc");
// commands.import("goto-vim-mark", Normal, "om");
// commands.import("go-history-backward", Normal, "S");
// commands.import("go-history-forward", Normal, "D");
// commands.import("find", Normal, "/");
// commands.import("eval-expression", Normal, ":");
// commands.import("temporary-pass-through", Normal, "p");
// commands.import("pass-through", Normal, "<Alt-i>");
