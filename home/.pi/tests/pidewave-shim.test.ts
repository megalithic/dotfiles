import { describe, expect, test } from 'bun:test';
import fs from 'node:fs';
import vm from 'node:vm';

const source = fs.readFileSync(new URL('../agent/extensions/pidewave/shim.js', import.meta.url), 'utf8');

type Listener = (event: FakeEvent) => void;

type FakeEvent = {
  type?: string;
  metaKey?: boolean;
  ctrlKey?: boolean;
  shiftKey?: boolean;
  altKey?: boolean;
  code?: string;
  clipboardData?: { getData(type: string): string };
  prevented?: boolean;
  preventDefault?(): void;
  stopPropagation?(): void;
};

// Runs the production page script against a minimal window, as CDP would inject it.
const page = (pathname = '/orders', top = true) => {
  const sent: { kind: string; text?: string; href?: string }[] = [];
  const written: string[] = [];
  const listeners = new Map<string, Listener[]>();
  const appended: { textContent: string }[] = [];
  let now = 1_000_000;

  const on = (type: string, listener: Listener) => listeners.set(type, [...(listeners.get(type) ?? []), listener]);

  type FakeWindow = {
    __pidewave(payload: string): void;
    addEventListener: typeof on;
    top?: FakeWindow | { other: true };
    __pidewaveToast?: (text: string, ok: boolean) => void;
    __pidewaveOff?: boolean;
  };

  const window: FakeWindow = {
    __pidewave: (payload: string) => {
      sent.push(JSON.parse(payload));
    },
    addEventListener: on,
  };

  window.top = top ? window : { other: true };

  type Field = { value: string; selectionStart: number; selectionEnd: number };

  let focused: Field | null = null;

  const document = {
    get activeElement() {
      return focused;
    },
    visibilityState: 'visible',
    addEventListener: on,
    getSelection: () => '',
    createElement: () => ({ style: {}, setAttribute: () => {}, remove: () => {}, textContent: '' }),
    documentElement: {
      append: (node: { textContent: string }) => {
        appended.push(node);
      },
    },
  };

  const context = vm.createContext({
    window,
    document,
    location: { pathname, href: `http://localhost:4123${pathname}` },
    navigator: {
      clipboard: {
        writeText: async (text: string) => {
          written.push(text);
        },
      },
    },
    Date: { now: () => now },
    JSON,
    String,
    setTimeout: () => 0,
  });

  // `window` properties are globals in a browser; mirror the ones the script reads.
  vm.runInContext('globalThis.__pidewave = (...args) => window.__pidewave(...args);', context);
  const run = () => vm.runInContext(source, context);
  run();

  const fire = (type: string, event: FakeEvent = {}) => {
    const full = { type, preventDefault: () => (full.prevented = true), stopPropagation: () => {}, ...event };

    for (const listener of listeners.get(type) ?? []) listener(full);

    return full;
  };

  return {
    sent,
    written,
    appended,
    window,
    document,
    run,
    fire,
    focus: (field: Field) => {
      focused = field;
    },
    advance: (ms: number) => {
      now += ms;
    },
    writeText: (text: string) => vm.runInContext(`navigator.clipboard.writeText(${JSON.stringify(text)})`, context),
  };
};

describe('pidewave page script', () => {
  test('toolbar prompts are forwarded once and still copied', async () => {
    const p = page();
    await p.writeText('<user_prompt>make it red</user_prompt>');
    await p.writeText('<user_prompt>make it red</user_prompt>');
    await p.writeText('plain copy');
    expect(p.written).toEqual([
      '<user_prompt>make it red</user_prompt>',
      '<user_prompt>make it red</user_prompt>',
      'plain copy',
    ]);
    expect(p.sent).toEqual([
      { kind: 'prompt', text: '<user_prompt>make it red</user_prompt>', href: 'http://localhost:4123/orders' },
    ]);

    p.advance(2_500);
    await p.writeText('<user_prompt>make it red</user_prompt>');
    expect(p.sent).toHaveLength(2);
  });

  test('the copy event path covers the execCommand fallback', () => {
    const p = page();
    p.focus({ value: 'xx<user_prompt>a</user_prompt>yy', selectionStart: 2, selectionEnd: 30 });
    p.fire('copy');
    p.fire('copy', { clipboardData: { getData: () => '<user_prompt>b</user_prompt>' } });
    expect(p.sent.map((message) => message.text)).toEqual([
      '<user_prompt>a</user_prompt>',
      '<user_prompt>b</user_prompt>',
    ]);
  });

  test('Connect copy buttons forward sentences, not the bare MCP URL', async () => {
    const p = page('/tidewave/connect');
    await p.writeText('http://localhost:4123/tidewave/mcp');
    await p.writeText(
      'I have a page open at http://localhost:4123/. Use Tidewave browser_eval tool with sid "a#1" to interact with it.',
    );
    expect(p.sent).toHaveLength(1);
    expect(p.sent[0]!.text).toStartWith('I have a page open');
  });

  test('a selection copied by hand on the Connect page is not a prompt', () => {
    const p = page('/tidewave/connect');
    p.fire('copy', { clipboardData: { getData: () => 'some text the user selected' } });
    expect(p.sent).toEqual([]);
  });

  test('switched off by Pi before it detaches: nothing forwarded, no chord swallowed', async () => {
    const p = page();
    p.window.__pidewaveOff = true;
    await p.writeText('<user_prompt>late</user_prompt>');
    const chord = p.fire('keydown', { metaKey: true, ctrlKey: false, shiftKey: true, altKey: false, code: 'KeyC' });
    expect(p.sent).toEqual([]);
    expect(chord.prevented).toBeUndefined();
  });

  test('chords: Cmd+Shift+C inspects, Ctrl+Shift+P focuses Pi, others pass through', () => {
    const p = page();
    const inspect = p.fire('keydown', { metaKey: true, ctrlKey: false, shiftKey: true, altKey: false, code: 'KeyC' });
    const focus = p.fire('keydown', { metaKey: false, ctrlKey: true, shiftKey: true, altKey: false, code: 'KeyP' });
    const copy = p.fire('keydown', { metaKey: true, ctrlKey: false, shiftKey: false, altKey: false, code: 'KeyC' });
    expect(p.sent.map((message) => message.kind)).toEqual(['inspect', 'focus-pi']);
    expect([inspect.prevented, focus.prevented, copy.prevented]).toEqual([true, true, undefined]);
  });

  test('activity is throttled; a second injection is a no-op; toasts only in the top frame', () => {
    const p = page();
    p.fire('focus');
    p.fire('pointerdown');
    p.advance(1_500);
    p.fire('pointerdown');
    expect(p.sent).toEqual([{ kind: 'active' }, { kind: 'active' }]);

    p.run();
    p.fire('keydown', { metaKey: false, ctrlKey: true, shiftKey: true, altKey: false, code: 'KeyP' });
    expect(p.sent.filter((message) => message.kind === 'focus-pi')).toHaveLength(1);

    expect(p.window.__pidewaveToast).toBeFunction();
    expect(page('/orders', false).window.__pidewaveToast).toBeUndefined();
  });
});
