// Hammerspoon 2, beside v1 (config/hammerspoon). v1 still owns F19 as the
// hyper hotkey and its modal; this config only watches F19.

const { startLayer } = require('./lib/hyper_layer.js');

const { createHud } = require('./lib/hud.js');

const { createSeams } = require('./lib/seams.js');

// Shade's layer: hold hyper, press a key, Shade toggles that verb.
const SHADE = [
  { key: 'n', action: 'write', label: 'Write' },
  { key: 't', action: 'tell', label: 'Tell' },
  { key: 'c', action: 'capture', label: 'Capture' },
];

const seams = createSeams(hs);

const hud = createHud(hs, { rows: SHADE.map(({ key, label }) => ({ key, label })) });

// Kept on globalThis so the tap and HUD are never garbage-collected.
globalThis.hyper = startLayer(hs, {
  bindings: SHADE,
  onAction: (verb) => {
    hud.dismiss();
    seams.shadeToggle(verb);
  },
  onHold: () => hud.arm(),
  onRelease: () => hud.dismiss(),
});

globalThis.hud = hud;

// Reload from a shell: open -g hammerspoon2://reload
hs.urlevent.bind('reload', () => hs.reload());

console.log('hammerspoon2 loaded');
