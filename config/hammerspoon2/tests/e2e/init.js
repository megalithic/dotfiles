// End-to-end config for the Atlas helper (see tests/e2e/atlas.sh): the real
// layer, HUD and seams, with `shade` and `sup` resolving to stubs that log
// their args (sup's stub exits 69, so the HUD falls back to its canvas).
//
// It never posts key events. A post at the HID level reaches the console
// session (the person's desktop), not the helper. Atlas can't hold F19, so
// held hyper is checked on the real keyboard; here hammerspoon2:// links
// drive the HUD and the Shade seam, and Atlas's own key presses check the tap.

const { startLayer } = require('./lib/hyper_layer.js');

const { createHud } = require('./lib/hud.js');

const { createSeams } = require('./lib/seams.js');

const HOME = '/Users/atlas';

const LOG = `${HOME}/hs2-e2e.log`;

const SHADE = [
  { key: 'n', action: 'write', label: 'Note' },
  { key: 't', action: 'tell', label: 'Tell' },
  { key: 'c', action: 'capture', label: 'Capture' },
];

function log(line) {
  hs.task.create('/bin/sh', ['-c', 'printf "%s\\n" "$1" >> "$2"', 'sh', line, LOG], null).start();
}

const seams = createSeams(hs, { log, bin: `${HOME}/.local/bin` });

const hud = createHud(hs, { rows: SHADE.map(({ key, label }) => ({ key, label })), seams });

function onAction(verb) {
  hud.dismiss();
  seams.shadeToggle(verb);
}

globalThis.hyper = startLayer(hs, {
  bindings: SHADE,
  onAction,
  onHold: () => hud.arm(),
  onRelease: () => hud.dismiss(),
});

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

hs.urlevent.bind('hud', () => {
  hud.arm();
  hs.timer.doAfter(0.5, () => log(`hud showing: ${hud.isShowing()}`));
});

hs.urlevent.bind('hud-off', () => {
  hud.dismiss();
  log(`hud showing: ${hud.isShowing()}`);
});

hs.urlevent.bind('action', (_name, params) => onAction(params.verb));

hs.urlevent.bind('reload', () => hs.reload());

log(
  `loaded; accessibility: ${hs.permissions.checkAccessibility()}, input monitoring: ${hs.permissions.checkInputMonitoring()}`,
);
