// End-to-end config for the Atlas helper (see tests/e2e/atlas.sh): the real
// layer, HUD and seams, with `shade` resolving to a stub that logs its args.
// `open hammerspoon2://e2e` posts a hyper sequence at the HID level, so it
// passes through every session tap and Carbon hotkey as kanata's F19 does.
// It only posts while TextEdit is frontmost, the window atlas.sh opened.

const { startLayer } = require('./lib/hyper_layer.js');

const { createHud } = require('./lib/hud.js');

const { createSeams } = require('./lib/seams.js');

const HOME = '/Users/atlas';

const LOG = `${HOME}/hs2-e2e.log`;

const SHADE = [
  { key: 'n', action: 'write', label: 'Write' },
  { key: 't', action: 'tell', label: 'Tell' },
  { key: 'c', action: 'capture', label: 'Capture' },
];

function log(line) {
  hs.task.create('/bin/sh', ['-c', 'printf "%s\\n" "$1" >> "$2"', 'sh', line, LOG], null).start();
}

const seams = createSeams(hs, { log, path: `${HOME}/.local/bin:/usr/bin:/bin` });

const hud = createHud(hs, { rows: SHADE.map(({ key, label }) => ({ key, label })) });

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

// [delay in seconds, key, down?, note]
const STEPS = [
  [2.0, 'f19', true], // time for atlas.sh to bring TextEdit back to the front
  [3.0, 'hud'], // HUD should be up; atlas.sh screenshots it meanwhile
  [0.1, 'n', true],
  [0.1, 'n', false],
  [0.3, 't', true],
  [0.1, 't', false],
  [0.3, 'c', true],
  [0.1, 'c', false],
  [0.3, 'j', true], // not a layer key: passes on (to TextEdit, or v1's hyper+j)
  [0.1, 'j', false],
  [0.3, 'f19', false],
  [0.3, 'x', true], // plain typing after release
  [0.1, 'x', false],
  [0.5, 'done'],
];

function post(key, down) {
  hs.eventtap.makeKeyEventWithCode(hs.keycodes.map[key], down).post();
}

function run() {
  let at = 0;

  globalThis.e2eTimers = STEPS.map(([delay, key, down]) => {
    at += delay;

    return hs.timer.doAfter(at, () => {
      const front = hs.application.frontmost();

      if (!front || front.bundleID !== 'com.apple.TextEdit') {
        log(`abort: frontmost is ${front && front.bundleID}`);
        globalThis.e2eTimers.forEach((t) => t.stop());

        return;
      }

      if (key === 'hud') return log(`hud showing: ${hud.isShowing()}`);

      if (key === 'done') return log(`done; hyper held: ${globalThis.hyper.layer.isHeld()}`);

      post(key, down);
    });
  });
}

hs.urlevent.bind('e2e', run);

hs.urlevent.bind('reload', () => hs.reload());

log('hammerspoon2 e2e loaded');
