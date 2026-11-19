// End-to-end config for the Atlas helper (see tests/e2e/atlas.sh): the real
// layer (lib/hyper.js, as init.js wires it), HUD and seams, with `shade` and
// `sup` resolving to stubs that log their args (sup's stub has nothing to act
// on or open, and no daemon for hints, so the HUD falls back to its canvas).
//
// It never posts key events. A post at the HID level reaches the console
// session (the person's desktop), not the helper. Atlas can't hold F19, so
// held hyper is checked on the real keyboard; here hammerspoon2:// links
// drive the HUD and the Shade seam, and Atlas's own key presses check the tap.

const { startHyper } = require('./lib/hyper.js');

const { createHud } = require('./lib/hud.js');

const { createSeams } = require('./lib/seams.js');

const HOME = '/Users/atlas';

const LOG = `${HOME}/hs2-e2e.log`;

const SHADE = [
  { key: 'n', action: 'write', label: 'Note' },
  { key: 't', action: 'tell', label: 'Tell' },
  { key: 'c', action: 'capture', label: 'Capture' },
  { key: 'e', action: 'edit', label: 'Edit' },
];

function log(line) {
  hs.task.create('/bin/sh', ['-c', 'printf "%s\\n" "$1" >> "$2"', 'sh', line, LOG], null).start();
}

const seams = createSeams(hs, { log, bin: `${HOME}/.local/bin` });

const hud = createHud(hs, { rows: SHADE.map(({ key, label }) => ({ key, label })), seams });

// The same wiring as init.js, its seams logging Shade's answer.
const logged = {
  ...seams,
  shadeToggle: (verb, onShown) =>
    seams.shadeToggle(verb, (visible) => {
      log(`shade visible: ${visible}`);
      onShown(visible);
    }),
};

globalThis.hyper = startHyper(hs, { seams: logged, hud, bindings: SHADE, verb: 'write' });

// Atlas can't hold F19, so the links below drive the layer's handler with the
// key codes a hold would send: F19 down, then Return or Escape, then F19 up.
const { layer } = globalThis.hyper;

const F19 = 80;

function chord(key) {
  layer.handle('keyDown', F19);
  layer.handle('keyDown', hs.keycodes.map[key]);
  layer.handle('keyUp', hs.keycodes.map[key]);
}

globalThis.hud = hud;

// Logs every key event a second, listen-only tap sees.
globalThis.e2eWatch = hs.eventtap.addWatcher(
  [hs.eventtap.eventTypes.keyDown, hs.eventtap.eventTypes.keyUp],
  (event) => {
    log(`tap saw type ${event.type} key ${event.keyCode}`);

    return hs.eventtap.emit;
  },
  true,
);

globalThis.e2eWatch.start();

// hyper+Return: sup has nothing to open, so Shade toggles and the layer arms.
hs.urlevent.bind('trigger', () => {
  chord('return');
  hs.timer.doAfter(0.5, () => log(`hud showing: ${hud.isShowing()}`));
});

hs.urlevent.bind('dismiss', () => chord('escape'));

hs.urlevent.bind('hud-off', () => {
  layer.handle('keyUp', F19);
  log(`hud showing: ${hud.isShowing()}`);
});

// An armed layer key, as hyper+n/t/c/e would send.
hs.urlevent.bind('action', (_name, params) => {
  chord('return');
  hs.timer.doAfter(0.5, () => {
    layer.handle('keyDown', hs.keycodes.map[SHADE.find(({ action }) => action === params.verb).key]);
    layer.handle('keyUp', F19);
  });
});

hs.urlevent.bind('reload', () => hs.reload());

log(
  `loaded; accessibility: ${hs.permissions.checkAccessibility()}, input monitoring: ${hs.permissions.checkInputMonitoring()}`,
);
