// debugging:
// console.log(Object.keys(api))

api.map("<Ctrl-l>", "R");
api.map("<Ctrl-h>", "E");
api.map("<Ctrl-w>", "x");
api.map("<Ctrl-f>", "d");
api.map("<Ctrl-b>", "e");

settings.theme = `
    #sk_status, #sk_find {
        font-size: 18pt;
    }
}`;

// settings.aceKeybindings = 'emacs';
settings.defaultSearchEngine = "d"; // duck duck go
settings.focusAfterClosed = "left";
settings.hintAlign = "left";
settings.smoothScroll = false;
settings.tabsThreshold = 0;

const commands = {
  import: function () {},
  exec: function () {},
  def: function () {},
  list: {},
};

commands.import = function (name, keymap, key) {
  const ks = KeyboardUtils.encodeKeystroke(key);
  let cmd = keymap.mappings.find(ks);
  if (!cmd) {
    throw `${key} (${ks}) not defined in keymap`;
  }
  cmd = { ...cmd.meta };
  delete cmd.word;
  cmd.name = name;

  this.list[name] = cmd;
};

commands.exec = function (name) {
  this.list[name].code();
};

commands.def = function (name, feature_group, annotation, code) {
  if (arguments.length < 4) {
    code = annotation;
    annotation = feature_group;
    feature_group = 14;
  }

  return (this.list[name] = {
    name,
    feature_group,
    annotation,
    code,
    // TODO: repeatIgnore
  });
};

commands.import("beginning-of-page", Normal, "gg");
commands.import("end-of-page", Normal, "G");
commands.import("half-page-up", Normal, "<Ctrl-b");
commands.import("half-page-down", Normal, "<Ctrl-f");
commands.import("reload", Normal, "r");
commands.import("select-left-tab", Normal, "<Ctrl-h>");
commands.import("select-right-tab", Normal, "<Ctrl-l>");
commands.import("select-tab", Normal, "T");
commands.import("duplicate-tab", Normal, "yt");
commands.import("duplicate-tab-background", Normal, "yT");
commands.import("follow-link", Normal, "f");
commands.import("follow-link-new-tab", Normal, "af");
commands.import("follow-link-new-tab-background", Normal, "C");
commands.import("follow-multiple-links", Normal, "cf");
commands.import("close-current-tab", Normal, "<Ctrl-w>");
commands.import("close-left-tab", Normal, "gxt");
commands.import("close-right-tab", Normal, "gxT");
commands.import("close-all-left-tabs", Normal, "gx0");
commands.import("close-all-right-tabs", Normal, "gx$");
commands.import("undo-last-tab-close", Normal, "X");
commands.import("copy-tab-url", Normal, "yy");
commands.import("copy-tab-host", Normal, "yh");
commands.import("copy-page-title", Normal, "yl");
commands.import("copy-link-url", Normal, "ya");
commands.import("copy-element-text", Normal, "yv");
commands.import("goto-url", Normal, "go");
commands.import("goto-url-new-tab", Normal, "t");
commands.import("goto-current-url-without-fragment", Normal, "g#");
commands.import("goto-current-url-without-query", Normal, "g?");
commands.import("goto-current-url-root", Normal, "gU");
commands.import("goto-current-url-parent", Normal, "gu");
commands.import("goto-clipboard-url-new-tab", Normal, "cc");
commands.import("goto-vim-mark", Normal, "om");
commands.import("go-history-backward", Normal, "S");
commands.import("go-history-forward", Normal, "D");
commands.import("find", Normal, "/");
commands.import("eval-expression", Normal, ":");
commands.import("temporary-pass-through", Normal, "p");
commands.import("pass-through", Normal, "<Alt-i>");
