import { describe, expect, test } from 'bun:test';
import { F19, createLayer, startLayer } from '../lib/hyper_layer.js';
import { createHud } from '../lib/hud.js';
import { createSeams } from '../lib/seams.js';
import { mockHs } from './mock_hs.js';

const N = 45;

const T = 17;

const J = 38;

function layer() {
  const calls = [];

  const l = createLayer({
    keys: { [N]: 'write', [T]: 'tell' },
    onAction: (a) => calls.push(a),
    onHold: () => calls.push('hold'),
    onRelease: () => calls.push('release'),
  });

  return { l, calls };
}

describe('hyper layer', () => {
  test('hyper always passes through, so v1 keeps its F19 hotkey', () => {
    const { l, calls } = layer();
    expect(l.handle('keyDown', F19)).toBe(true);
    expect(l.handle('keyDown', F19)).toBe(true); // auto-repeat
    expect(l.handle('keyUp', F19)).toBe(true);
    expect(calls).toEqual(['hold', 'release']);
  });

  test('layer keys are consumed and fire only while hyper is held', () => {
    const { l, calls } = layer();
    expect(l.handle('keyDown', N)).toBe(true);
    expect(l.handle('keyUp', N)).toBe(true);
    l.handle('keyDown', F19);
    expect(l.handle('keyDown', N)).toBe(false);
    expect(l.handle('keyDown', N)).toBe(false); // auto-repeat fires once
    expect(l.handle('keyUp', N)).toBe(false);
    expect(l.handle('keyDown', T)).toBe(false);
    expect(l.handle('keyUp', T)).toBe(false);
    l.handle('keyUp', F19);
    expect(l.handle('keyDown', N)).toBe(true);
    expect(calls).toEqual(['hold', 'write', 'tell', 'release']);
  });

  test("other keys pass through while hyper is held (v1's hyper chords)", () => {
    const { l, calls } = layer();
    l.handle('keyDown', F19);
    expect(l.handle('keyDown', J)).toBe(true);
    expect(l.handle('keyUp', J)).toBe(true);
    expect(calls).toEqual(['hold']);
  });

  test("a layer key's release is consumed even after hyper is released first", () => {
    const { l } = layer();
    l.handle('keyDown', F19);
    l.handle('keyDown', N);
    l.handle('keyUp', F19);
    expect(l.handle('keyUp', N)).toBe(false);
    expect(l.handle('keyUp', N)).toBe(true);
  });
});

describe('wired to hs', () => {
  test('tap consumes n while F19 is held and runs shade toggle', () => {
    const hs = mockHs();
    const seams = createSeams(hs);

    const { tap } = startLayer(hs, {
      bindings: [{ key: 'n', action: 'write' }],
      onAction: (verb) => seams.shadeToggle(verb),
    });

    expect(tap.started).toBe(true);
    expect(hs.tap.types).toEqual([10, 11]);
    expect(hs.press('keyDown', F19)).toBe(true);
    expect(hs.press('keyDown', N)).toBe(false);
    expect(hs.press('keyUp', N)).toBe(false);
    expect(hs.press('keyUp', F19)).toBe(true);
    // The mise shim by absolute path: ~/.local/bin/shade was the old Shade.
    expect(hs.tasks.map((t) => [t.path, ...t.args])).toEqual([
      ['/Users/test/.local/share/mise/shims/shade', 'toggle', 'write'],
    ]);
    expect(hs.tasks[0].started).toBe(true);
    // stdin stays open for the child: sup --hold relies on EOF only when HS2 dies.
    expect(hs.tasks[0].inputClosed).toBe(false);
  });

  test('sup shows the hint after the hold delay and release terminates it', () => {
    const hs = mockHs();
    const hud = createHud(hs, { rows: [{ key: 'n', label: 'Note' }], seams: createSeams(hs) });
    hud.arm();
    expect(hud.isShowing()).toBe(false);
    expect(hs.timers[0].seconds).toBe(0.25);
    hud.dismiss();
    expect(hs.timers[0].stopped).toBe(true);
    expect(hs.tasks.length).toBe(0);

    hud.arm();
    hs.timers[1].fire();
    expect(hud.isShowing()).toBe(true);
    const [sup] = hs.tasks;
    expect([sup.path, ...sup.args]).toEqual([
      '/Users/test/.local/share/mise/shims/sup',
      'show',
      'hint',
      '--key',
      'n=Note',
      '--hold',
    ]);
    // --hold also ends on stdin EOF, so stdin must stay open while it's up.
    expect(sup.inputClosed).toBe(false);
    hud.dismiss();
    expect(sup.terminated).toBe(true);
    expect(hud.isShowing()).toBe(false);
    expect(hs.canvases.length).toBe(0);
  });

  test('HUD falls back to its own canvas when sup has no daemon', () => {
    const hs = mockHs();
    const hud = createHud(hs, { rows: [{ key: 'n', label: 'Note' }], seams: createSeams(hs) });
    hud.arm();
    hs.timers[0].fire();
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
