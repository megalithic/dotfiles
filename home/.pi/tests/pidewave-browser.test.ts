import { afterEach, describe, expect, test } from 'bun:test';
import {
  createBrowserLink,
  type PageMessage,
  parsePageMessage,
  pickTab,
  tabKind,
} from '../agent/extensions/pidewave/browser.ts';
import type { Tab } from '../agent/extensions/pidewave/lease.ts';

const origin = 'http://localhost:4123';

type Sent = { id: number; method: string; params: { [key: string]: string | boolean | number }; sessionId?: string };

const cleanups: (() => void)[] = [];

afterEach(() => {
  for (const cleanup of cleanups.splice(0).reverse()) cleanup();
});

const until = async (check: () => boolean, label: string): Promise<void> => {
  for (let i = 0; i < 100; i += 1) {
    if (check()) return;
    await new Promise((resolve) => setTimeout(resolve, 10));
  }

  throw new Error(`timed out waiting for ${label}`);
};

const targets = [
  { targetId: 'app', type: 'page', url: `${origin}/orders`, title: 'Orders' },
  { targetId: 'connect', type: 'page', url: `${origin}/tidewave/connect`, title: 'Connect' },
  { targetId: 'ide', type: 'page', url: `${origin}/tidewave`, title: 'IDE' },
  { targetId: 'loopback', type: 'page', url: 'http://127.0.0.1:4123/', title: 'Loopback' },
  { targetId: 'foreign', type: 'page', url: 'http://localhost:4999/', title: 'Other app' },
  { targetId: 'worker', type: 'service_worker', url: `${origin}/sw.js`, title: '' },
];

// A fake Chrome: /json/version plus a browser WebSocket that answers CDP commands.
const fakeBrowser = () => {
  const sent: Sent[] = [];
  let peer: { send(text: string): void } | undefined;

  const server = Bun.serve({
    port: 0,
    fetch(request, srv) {
      if (new URL(request.url).pathname === '/json/version') {
        return Response.json({ webSocketDebuggerUrl: `ws://127.0.0.1:${srv.port}/devtools/browser/x` });
      }

      return srv.upgrade(request) ? undefined : new Response('no', { status: 400 });
    },
    websocket: {
      open(ws) {
        peer = ws;
      },
      message(ws, raw) {
        const message: Sent = JSON.parse(String(raw));
        sent.push(message);

        const result =
          message.method === 'Target.attachToTarget'
            ? { sessionId: `s-${message.params.targetId}` }
            : message.method === 'Runtime.evaluate'
              ? { result: { value: 'active' } }
              : {};

        ws.send(JSON.stringify({ id: message.id, result }));

        if (message.method === 'Target.setDiscoverTargets') {
          for (const targetInfo of targets)
            ws.send(JSON.stringify({ method: 'Target.targetCreated', params: { targetInfo } }));
        }
      },
    },
  });

  cleanups.push(() => server.stop(true));

  return {
    endpoint: `http://127.0.0.1:${server.port}`,
    sent,
    emit: (method: string, params: { [key: string]: string | { [key: string]: string } }, sessionId?: string) =>
      peer?.send(JSON.stringify(sessionId ? { method, params, sessionId } : { method, params })),
    commands: (method: string) => sent.filter((message) => message.method === method),
  };
};

const linked = (endpoint: string) => {
  const messages: [PageMessage, Tab][] = [];
  let changes = 0;

  const link = createBrowserLink(
    origin,
    {
      message: (message, tab) => messages.push([message, tab]),
      change: () => {
        changes += 1;
      },
    },
    () => ({ sessionName: 'worker' }),
    endpoint,
  );

  cleanups.push(() => link.stop());

  return { link, messages, changes: () => changes };
};

describe('browser link', () => {
  test('attaches app and Connect tabs on the origin, in every form, and nothing else', async () => {
    const browser = fakeBrowser();
    const { link } = linked(browser.endpoint);
    link.start();
    await until(() => browser.commands('Page.addScriptToEvaluateOnNewDocument').length === 3, 'scripts');

    expect(link.state()).toBe('up');
    expect(browser.commands('Target.attachToTarget').map((message) => message.params.targetId)).toEqual([
      'app',
      'connect',
      'loopback',
    ]);
    expect(link.tabs().map((tab) => [tab.targetId, tab.kind])).toEqual([
      ['app', 'app'],
      ['connect', 'connect'],
      ['loopback', 'app'],
    ]);

    for (const sessionId of ['s-app', 's-connect', 's-loopback']) {
      const methods = browser.sent
        .filter((message) => message.sessionId === sessionId)
        .map((message) => message.method);

      expect(methods).toEqual([
        'Runtime.enable',
        'Runtime.addBinding',
        'Page.enable',
        'Page.addScriptToEvaluateOnNewDocument',
      ]);
    }

    const script = browser.commands('Page.addScriptToEvaluateOnNewDocument')[0]!.params;
    expect(script.runImmediately).toBe(true);
    expect(String(script.source)).toStartWith('window.__pidewaveInfo = {"sessionName":"worker"};');
    expect(String(script.source)).toContain('window.__pidewaveShim');
  });

  test('binding calls are trusted by CDP session, not by payload', async () => {
    const browser = fakeBrowser();
    const { link, messages } = linked(browser.endpoint);
    link.start();
    await until(() => link.tabs().length === 3, 'tabs');

    const prompt = JSON.stringify({ kind: 'prompt', text: '<user_prompt>hi</user_prompt>', href: 'http://evil/' });
    browser.emit('Runtime.bindingCalled', { name: '__pidewave', payload: prompt }, 's-app');
    browser.emit('Runtime.bindingCalled', { name: '__pidewave', payload: prompt }, 's-unknown');
    browser.emit('Runtime.bindingCalled', { name: 'other', payload: prompt }, 's-app');
    browser.emit('Runtime.bindingCalled', { name: '__pidewave', payload: '{"kind":"exec"}' }, 's-app');
    browser.emit('Runtime.bindingCalled', { name: '__pidewave', payload: '{"kind":"active"}' }, 's-connect');
    await until(() => messages.length === 2, 'messages');

    expect(messages[0]).toEqual([
      { kind: 'prompt', text: '<user_prompt>hi</user_prompt>' },
      { targetId: 'app', url: `${origin}/orders`, title: 'Orders', kind: 'app' },
    ]);
    expect(messages[1]![0]).toEqual({ kind: 'active' });
    expect(link.tabs().find((tab) => tab.targetId === 'connect')?.lastActiveAt).toBeString();
  });

  test('a tab that navigates away is detached and forgotten', async () => {
    const browser = fakeBrowser();
    const { link } = linked(browser.endpoint);
    link.start();
    await until(() => link.tabs().length === 3, 'tabs');

    browser.emit('Target.targetInfoChanged', {
      targetInfo: { targetId: 'app', type: 'page', url: 'https://example.com/', title: 'x' },
    });
    await until(() => browser.commands('Target.detachFromTarget').length === 1, 'detach');
    expect(browser.commands('Target.detachFromTarget')[0]!.params).toEqual({ sessionId: 's-app' });
    expect(link.tabs().map((tab) => tab.targetId)).toEqual(['connect', 'loopback']);

    browser.emit('Target.targetDestroyed', { targetId: 'connect' });
    await until(() => link.tabs().length === 1, 'destroyed');
  });

  test('inspect runs in the most recently active tab', async () => {
    const browser = fakeBrowser();
    const { link } = linked(browser.endpoint);
    link.start();
    await until(() => link.tabs().length === 3, 'tabs');
    browser.emit('Runtime.bindingCalled', { name: '__pidewave', payload: '{"kind":"active"}' }, 's-loopback');
    await until(() => link.tabs().some((tab) => tab.lastActiveAt), 'active');

    expect(await link.inspect(undefined, false)).toBe('active');
    const evaluate = browser.commands('Runtime.evaluate').at(-1)!;
    expect(evaluate.sessionId).toBe('s-loopback');
    expect(String(evaluate.params.expression)).toContain(JSON.stringify(origin));
  });

  test('stop detaches every tab; no browser means down', async () => {
    const browser = fakeBrowser();
    const { link } = linked(browser.endpoint);
    link.start();
    await until(() => link.tabs().length === 3, 'tabs');
    link.stop();
    expect(link.state()).toBe('down');
    await until(() => browser.commands('Target.detachFromTarget').length === 3, 'detach all');

    const offline = linked('http://127.0.0.1:9');
    offline.link.start();
    await until(() => offline.changes() >= 0 && offline.link.state() === 'down', 'down');
    expect(await offline.link.inspect()).toContain('no CDP');
  });
});

describe('browser helpers', () => {
  test('page messages are parsed strictly', () => {
    expect(parsePageMessage('{"kind":"prompt","text":"x"}')).toEqual({ kind: 'prompt', text: 'x' });
    expect(parsePageMessage('{"kind":"prompt","text":"  "}')).toBeUndefined();
    expect(parsePageMessage('{"kind":"focus-pi","extra":1}')).toEqual({ kind: 'focus-pi' });
    expect(parsePageMessage('{')).toBeUndefined();
    expect(parsePageMessage('[]')).toBeUndefined();
  });

  test('tab kinds and picking', () => {
    const origins = [origin];
    expect(tabKind(`${origin}/x?y#z`, origins)).toBe('app');
    expect(tabKind(`${origin}/tidewave/connect`, origins)).toBe('connect');
    expect(tabKind(`${origin}/tidewave/anything`, origins)).toBeUndefined();
    expect(tabKind('not a url', origins)).toBeUndefined();

    const connect: Tab = { targetId: 'c', url: '', title: '', kind: 'connect' };
    const app: Tab = { targetId: 'a', url: '', title: '', kind: 'app' };
    expect(pickTab([connect, app])?.targetId).toBe('a');
    expect(pickTab([app, { ...connect, lastActiveAt: '2026-01-01T00:00:00.000Z' }])?.targetId).toBe('c');
    expect(pickTab([])).toBeUndefined();
  });
});
