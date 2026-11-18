import { describe, expect, test } from 'bun:test';
import { F19, createLayer, startLayer } from '../lib/hyper_layer.js';
import { createHud } from '../lib/hud.js';
import { createSeams } from '../lib/seams.js';
import { mockHs } from './mock_hs.js';

const RETURN = 36;

const N = 45;

const T = 17;

const J = 38;

const SHIMS = '/Users/test/.local/share/mise/shims';

// A layer whose trigger hands its arm callback to the test.
function layer() {
  const calls = [];
  const arms = [];

  const l = createLayer({
    trigger: RETURN,
    keys: { [N]: 'write', [T]: 'tell' },
    onTrigger: (arm) => {
      calls.push('trigger');
      arms.push(arm);
    },
    onAction: (a) => calls.push(a),
    onArm: () => calls.push('arm'),
    onRelease: () => calls.push('release'),
  });

  return { l, calls, arms };
}

describe('hyper layer', () => {
  test('hyper always passes through, so v1 keeps its F19 hotkey', () => {
    const { l, calls } = layer();
    expect(l.handle('keyDown', F19)).toBe(true);
    expect(l.handle('keyDown', F19)).toBe(true); // auto-repeat
    expect(l.handle('keyUp', F19)).toBe(true);
    expect(calls).toEqual(['release']);
  });

  test('a plain hyper hold never arms: n/t pass through to v1', () => {
    const { l, calls } = layer();
    l.handle('keyDown', F19);
    expect(l.handle('keyDown', N)).toBe(true);
    expect(l.handle('keyUp', N)).toBe(true);
    expect(l.handle('keyDown', J)).toBe(true);
    l.handle('keyUp', F19);
    expect(calls).toEqual(['release']);
  });

  test('Return is consumed only while hyper is held', () => {
    const { l, calls } = layer();
    expect(l.handle('keyDown', RETURN)).toBe(true);
    expect(l.handle('keyUp', RETURN)).toBe(true);
    l.handle('keyDown', F19);
    expect(l.handle('keyDown', RETURN)).toBe(false);
    expect(l.handle('keyDown', RETURN)).toBe(false); // auto-repeat triggers once
    expect(l.handle('keyUp', RETURN)).toBe(false);
    expect(calls).toEqual(['trigger']);
  });

  test('when the trigger arms, layer keys are consumed until hyper is released', () => {
    const { l, calls, arms } = layer();
    l.handle('keyDown', F19);
    l.handle('keyDown', RETURN);
    l.handle('keyUp', RETURN);
    arms[0]();
    arms[0](); // arming twice is harmless
    expect(l.isArmed()).toBe(true);
    expect(l.handle('keyDown', N)).toBe(false);
    expect(l.handle('keyUp', N)).toBe(false);
    expect(l.handle('keyDown', T)).toBe(false);
    expect(l.handle('keyUp', T)).toBe(false);
    expect(l.handle('keyDown', J)).toBe(true); // other v1 chords still pass
    l.handle('keyUp', F19);
    expect(l.isArmed()).toBe(false);
    l.handle('keyDown', F19);
    expect(l.handle('keyDown', N)).toBe(true);
    expect(calls).toEqual(['trigger', 'arm', 'write', 'tell', 'release']);
  });

  test("a late arm from an earlier hold doesn't arm the next one", () => {
    const { l, calls, arms } = layer();
    l.handle('keyDown', F19);
    l.handle('keyDown', RETURN);
    l.handle('keyUp', F19);
    arms[0](); // Shade answered after hyper was released
    l.handle('keyDown', F19);
    arms[0]();
    expect(l.isArmed()).toBe(false);
    expect(l.handle('keyDown', N)).toBe(true);
    expect(calls).toEqual(['trigger', 'release']);
  });

  test("a consumed key's release is consumed even after hyper is released first", () => {
    const { l, arms } = layer();
    l.handle('keyDown', F19);
    l.handle('keyDown', RETURN);
    arms[0]();
    l.handle('keyDown', N);
    l.handle('keyUp', F19);
    expect(l.handle('keyUp', N)).toBe(false);
    expect(l.handle('keyUp', RETURN)).toBe(false);
    expect(l.handle('keyUp', N)).toBe(true);
  });
});

// Wires the layer the way init.js does.
function wired() {
  const hs = mockHs();
  const seams = createSeams(hs, { log: () => {} });
  const hud = createHud(hs, { rows: [{ key: 'n', label: 'Note' }], seams });

  const { tap } = startLayer(hs, {
    trigger: 'return',
    bindings: [{ key: 'n', action: 'write' }],
    onTrigger: (arm) => seams.shadeToggle('write', (visible) => visible && arm()),
    onArm: () => hud.show(),
    onAction: (verb) => {
      hud.dismiss();
      seams.shadeShow(verb);
    },
    onRelease: () => hud.dismiss(),
  });

  return { hs, hud, tap };
}

const settle = () => new Promise((resolve) => setTimeout(resolve, 0));

describe('wired to hs', () => {
  test('hyper+Return opens Shade, arms, shows the hint; n switches the verb', async () => {
    const { hs, hud, tap } = wired();
    expect(tap.started).toBe(true);
    expect(hs.tap.types).toEqual([10, 11]);
    hs.press('keyDown', F19);
    expect(hs.press('keyDown', RETURN)).toBe(false);
    // The mise shim by absolute path: ~/.local/bin/shade was the old Shade.
    expect([hs.runs[0].path, ...hs.runs[0].args]).toEqual([`${SHIMS}/shade`, 'toggle', 'write']);
    hs.runs[0].resolve({ exitCode: 0, stdout: '{"ok":true,"result":{"visible":"true"}}\n' });
    await settle();

    expect(hud.isShowing()).toBe(true);
    const [sup] = hs.tasks;
    expect([sup.path, ...sup.args]).toEqual([`${SHIMS}/sup`, 'show', 'hint', '--key', 'n=Note', '--hold']);
    // --hold also ends on stdin EOF, so stdin must stay open while it's up.
    expect(sup.inputClosed).toBe(false);

    expect(hs.press('keyDown', N)).toBe(false);
    expect(sup.terminated).toBe(true);
    expect([hs.runs[1].path, ...hs.runs[1].args]).toEqual([`${SHIMS}/shade`, 'show', 'write']);
    hs.press('keyUp', F19);
    expect(hud.isShowing()).toBe(false);
  });

  test('when the toggle hid Shade nothing arms, and n passes through', async () => {
    const { hs, hud } = wired();
    hs.press('keyDown', F19);
    hs.press('keyDown', RETURN);
    hs.runs[0].resolve({ exitCode: 0, stdout: '{"ok":true,"result":{"visible":"false"}}\n' });
    await settle();
    expect(hud.isShowing()).toBe(false);
    expect(hs.tasks.length).toBe(0);
    expect(hs.press('keyDown', N)).toBe(true);
  });

  test('Shade not running (exit 69): nothing arms', async () => {
    const { hs, hud } = wired();
    hs.press('keyDown', F19);
    hs.press('keyDown', RETURN);
    hs.runs[0].reject({ exitCode: 69, stdout: '' });
    await settle();
    expect(hud.isShowing()).toBe(false);
    expect(hs.press('keyDown', N)).toBe(true);
  });

  test('releasing hyper ends the hint', async () => {
    const { hs, hud } = wired();
    hs.press('keyDown', F19);
    hs.press('keyDown', RETURN);
    hs.runs[0].resolve({ exitCode: 0, stdout: '{"ok":true,"result":{"visible":"true"}}' });
    await settle();
    hs.press('keyUp', F19);
    expect(hs.tasks[0].terminated).toBe(true);
    expect(hud.isShowing()).toBe(false);
  });

  test('the HUD falls back to its own canvas when sup has no daemon', () => {
    const hs = mockHs();
    const hud = createHud(hs, { rows: [{ key: 'n', label: 'Note' }], seams: createSeams(hs) });
    hud.show();
    hs.tasks[0].exit(1);
    expect(hud.isShowing()).toBe(true);
    const canvas = hs.canvases[0];
    expect(canvas.shown).toBe(true);
    expect(canvas.levelName).toBe('overlay');
    expect(canvas.elements.filter((e) => e.type === 'text').map((e) => e.text)).toEqual(['n', 'Note']);
    hud.dismiss();
    expect(canvas.destroyed).toBe(true);
    expect(hud.isShowing()).toBe(false);
  });
});
