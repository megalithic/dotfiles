// Hammerspoon 2, beside v1 (config/hammerspoon). v1 still owns F19 as the
// hyper hotkey and its modal; this config only watches F19.

const { startLayer } = require('./lib/hyper_layer.js');

const { createHud } = require('./lib/hud.js');

const { createSeams } = require('./lib/seams.js');

// hyper+Return toggles Shade on this verb.
const SHADE_DEFAULT_VERB = 'write';

// Shade's layer: when hyper+Return opens Shade, the layer arms for the rest of
// that hyper hold: its hint shows and a key switches Shade to that verb.
const SHADE = [
  { key: 'n', action: 'write', label: 'Note' },
  { key: 't', action: 'tell', label: 'Tell' },
  { key: 'c', action: 'capture', label: 'Capture' },
  { key: 'e', action: 'edit', label: 'Edit' },
];

const seams = createSeams(hs);

const hud = createHud(hs, { rows: SHADE.map(({ key, label }) => ({ key, label })), seams });

// Kept on globalThis so the tap and HUD are never garbage-collected.
globalThis.hyper = startLayer(hs, {
  trigger: 'return',
  bindings: SHADE,
  onTrigger: (arm) =>
    seams.shadeToggle(SHADE_DEFAULT_VERB, (visible) => {
      if (visible) arm();
    }),
  onArm: () => hud.show(),
  onAction: (verb) => {
    hud.dismiss();
    seams.shadeShow(verb);
  },
  onRelease: () => hud.dismiss(),
});

globalThis.hud = hud;

// Reload from a shell: open -g hammerspoon2://reload
hs.urlevent.bind('reload', () => hs.reload());

console.log('hammerspoon2 loaded');
