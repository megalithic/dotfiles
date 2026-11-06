/**
 * Browser link: one CDP WebSocket from the lease holder to Helium (port 9223),
 * attached to every page target on this Pi's Phoenix origin in every window,
 * including Tidewave Connect pages. Each attached tab gets `shim.js` and the
 * `__pidewave` binding, so a tab reaches exactly this Pi, and Pi can evaluate
 * in any tab. Runtime.enable is required for Runtime.bindingCalled; the binding
 * and the injected script reach same-origin iframes and survive navigation
 * (checked against Helium/Chrome 150).
 */

import { execFile } from 'node:child_process';
import fs from 'node:fs';
import type { Tab } from './lease.ts';
import { isJsonNumber, isJsonObject, isJsonString, type JsonValue } from './shared.ts';

const BINDING = '__pidewave';

const RETRY_MS = 10_000;

const COMMAND_TIMEOUT_MS = 5_000;

const BROWSER_BUNDLE = 'net.imput.helium';

const SHIM = fs.readFileSync(new URL('./shim.js', import.meta.url), 'utf8');

const INSPECT = fs.readFileSync(new URL('./inspect.js', import.meta.url), 'utf8');

/** The Inspect script as one expression for Runtime.evaluate. */
export const inspectExpression = (origin: string): string =>
  `(${INSPECT.trim().replace(/;$/, '')})(${JSON.stringify(origin)})`;

export type PageMessage =
  | { kind: 'prompt'; text: string }
  | { kind: 'active' }
  | { kind: 'inspect' }
  | { kind: 'focus-pi' };

export type LinkEvents = {
  message(message: PageMessage, tab: Tab): void;
  change(): void;
};

export type BrowserLink = {
  start(): void;
  stop(): void;
  state(): 'up' | 'down';
  tabs(): Tab[];
  evaluate(targetId: string, expression: string): Promise<JsonValue | undefined>;
  inspect(targetId?: string, raise?: boolean): Promise<string>;
};

/** Parse a binding payload; only these messages exist, everything else is dropped. */
export const parsePageMessage = (payload: string): PageMessage | undefined => {
  try {
    const value: JsonValue = JSON.parse(payload);

    if (!isJsonObject(value)) return;

    if (value.kind === 'prompt' && isJsonString(value.text) && value.text.trim()) {
      return { kind: 'prompt', text: value.text };
    }

    if (value.kind === 'active' || value.kind === 'inspect' || value.kind === 'focus-pi') return { kind: value.kind };
  } catch {}
};

/** Tabs on these origins that pidewave links: app pages and the Connect page, not other Tidewave pages. */
export const tabKind = (url: string, origins: string[]): Tab['kind'] | undefined => {
  try {
    const parsed = new URL(url);

    if (!origins.includes(parsed.origin)) return;

    if (parsed.pathname === '/tidewave/connect') return 'connect';

    return parsed.pathname === '/tidewave' || parsed.pathname.startsWith('/tidewave/') ? undefined : 'app';
  } catch {}
};

/** Most recently active tab first; never-active app tabs before Connect tabs. */
export const pickTab = (tabs: Tab[]): Tab | undefined =>
  tabs.toSorted(
    (a, b) =>
      (b.lastActiveAt ?? '').localeCompare(a.lastActiveAt ?? '') ||
      Number(a.kind === 'connect') - Number(b.kind === 'connect'),
  )[0];

type Pending = { resolve(value: { [key: string]: JsonValue }): void; reject(error: Error): void };

type Linked = Tab & { sessionId?: string };

export const createBrowserLink = (
  origin: string,
  events: LinkEvents,
  info: () => { [key: string]: JsonValue },
  endpoint = `http://127.0.0.1:${process.env.PIDEWAVE_CDP_PORT || '9223'}`,
): BrowserLink => {
  const origins = [origin, origin.replace('//localhost', '//127.0.0.1')];
  const tabs = new Map<string, Linked>();
  const pending = new Map<number, Pending>();
  let socket: WebSocket | undefined;
  let up = false;
  let stopped = true;
  let nextId = 0;
  let retry: ReturnType<typeof setTimeout> | undefined;

  const send = (method: string, params: { [key: string]: JsonValue } = {}, sessionId?: string) =>
    new Promise<{ [key: string]: JsonValue }>((resolve, reject) => {
      const ws = socket;

      if (!ws || ws.readyState !== WebSocket.OPEN) return reject(new Error('CDP is not connected'));
      const id = ++nextId;

      const timer = setTimeout(() => {
        pending.delete(id);
        reject(new Error(`CDP ${method} timed out`));
      }, COMMAND_TIMEOUT_MS);

      timer.unref?.();
      pending.set(id, {
        resolve: (value) => {
          clearTimeout(timer);
          resolve(value);
        },
        reject: (error) => {
          clearTimeout(timer);
          reject(error);
        },
      });
      ws.send(JSON.stringify(sessionId ? { id, method, params, sessionId } : { id, method, params }));
    });

  const attach = async (tab: Linked): Promise<void> => {
    try {
      const { sessionId } = await send('Target.attachToTarget', { targetId: tab.targetId, flatten: true });

      if (!isJsonString(sessionId)) return;
      tab.sessionId = sessionId;
      const source = `window.__pidewaveInfo = ${JSON.stringify(info())};\n${SHIM}`;
      await send('Runtime.enable', {}, sessionId);
      await send('Runtime.addBinding', { name: BINDING }, sessionId);
      await send('Page.enable', {}, sessionId);
      await send('Page.addScriptToEvaluateOnNewDocument', { source, runImmediately: true }, sessionId);
      events.change();
    } catch {
      tabs.delete(tab.targetId);
    }
  };

  const forget = (targetId: string): void => {
    if (tabs.delete(targetId)) events.change();
  };

  const onTarget = (target: JsonValue | undefined): void => {
    if (!isJsonObject(target) || !isJsonString(target.targetId) || !isJsonString(target.url)) return;
    const kind = target.type === 'page' ? tabKind(target.url, origins) : undefined;
    const known = tabs.get(target.targetId);

    if (!kind) {
      if (known?.sessionId) void send('Target.detachFromTarget', { sessionId: known.sessionId }).catch(() => {});

      return forget(target.targetId);
    }

    const title = isJsonString(target.title) ? target.title : '';

    if (known) {
      known.url = target.url;
      known.title = title;
      known.kind = kind;

      return events.change();
    }

    const tab: Linked = { targetId: target.targetId, url: target.url, title, kind };
    tabs.set(tab.targetId, tab);
    void attach(tab);
  };

  const onBinding = (params: { [key: string]: JsonValue }, sessionId: JsonValue | undefined): void => {
    if (params.name !== BINDING || !isJsonString(params.payload)) return;
    const tab = [...tabs.values()].find((candidate) => candidate.sessionId === sessionId);

    // The caller is identified by its CDP session, and its URL must still be on our origin.
    if (!tab || !tabKind(tab.url, origins)) return;
    const message = parsePageMessage(params.payload);

    if (!message) return;

    if (message.kind === 'active') {
      tab.lastActiveAt = new Date().toISOString();
      events.change();
    }

    const { sessionId: _session, ...plain } = tab;
    events.message(message, plain);
  };

  const onMessage = (raw: string): void => {
    let message: JsonValue;

    try {
      message = JSON.parse(raw);
    } catch {
      return;
    }

    if (!isJsonObject(message)) return;

    if (isJsonNumber(message.id)) {
      const waiter = pending.get(message.id);
      pending.delete(message.id);

      if (isJsonObject(message.error)) {
        waiter?.reject(new Error(isJsonString(message.error.message) ? message.error.message : 'CDP error'));
      } else waiter?.resolve(isJsonObject(message.result) ? message.result : {});

      return;
    }

    const params = isJsonObject(message.params) ? message.params : {};

    switch (message.method) {
      case 'Target.targetCreated':
      case 'Target.targetInfoChanged':
        return onTarget(params.targetInfo);
      case 'Target.targetDestroyed':
        return isJsonString(params.targetId) ? forget(params.targetId) : undefined;
      case 'Target.detachedFromTarget': {
        const tab = [...tabs.values()].find((candidate) => candidate.sessionId === params.sessionId);

        return tab ? forget(tab.targetId) : undefined;
      }

      case 'Runtime.bindingCalled':
        return onBinding(params, message.sessionId);
    }
  };

  const setUp = (next: boolean): void => {
    if (up === next) return;
    up = next;
    events.change();
  };

  const scheduleRetry = (): void => {
    if (stopped || retry) return;
    retry = setTimeout(() => {
      retry = undefined;
      void connect();
    }, RETRY_MS);
    retry.unref?.();
  };

  const drop = (): void => {
    socket = undefined;
    tabs.clear();

    for (const waiter of pending.values()) waiter.reject(new Error('CDP closed'));
    pending.clear();
    setUp(false);
    scheduleRetry();
  };

  const connect = async (): Promise<void> => {
    if (stopped || socket) return;

    try {
      const response = await fetch(`${endpoint}/json/version`, { signal: AbortSignal.timeout(2_000) });
      const version: JsonValue = await response.json();

      if (!isJsonObject(version) || !isJsonString(version.webSocketDebuggerUrl)) throw new Error('no CDP');

      if (stopped) return;
      const ws = new WebSocket(version.webSocketDebuggerUrl);
      socket = ws;

      ws.addEventListener('message', (event) => {
        onMessage(String(event.data));
      });
      ws.addEventListener('close', () => {
        if (socket === ws) drop();
      });
      ws.addEventListener('error', () => ws.close());
      ws.addEventListener('open', () => {
        setUp(true);
        void send('Target.setDiscoverTargets', { discover: true }).catch(() => ws.close());
      });
    } catch {
      setUp(false);
      scheduleRetry();
    }
  };

  const evaluate = async (targetId: string, expression: string): Promise<JsonValue | undefined> => {
    const sessionId = tabs.get(targetId)?.sessionId;

    if (!sessionId) throw new Error('tab is not linked');
    const result = await send('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true }, sessionId);

    return isJsonObject(result.result) ? result.result.value : undefined;
  };

  const raiseBrowser = (): Promise<void> =>
    new Promise((resolve) => execFile('open', ['-b', BROWSER_BUNDLE], { timeout: 3_000 }, () => resolve()));

  const waitForTab = async (targetId: string): Promise<boolean> => {
    for (let i = 0; i < 50; i += 1) {
      if (tabs.get(targetId)?.sessionId) return true;
      await new Promise((resolve) => setTimeout(resolve, 100));
    }

    return false;
  };

  const inspect = async (targetId?: string, raise = true): Promise<string> => {
    if (!up) return 'Helium has no CDP on port 9223; start it with helium-launch.';
    let tab = targetId ? tabs.get(targetId) : pickTab([...tabs.values()]);

    if (!tab) {
      const created = await send('Target.createTarget', { url: `${origin}/` });

      if (!isJsonString(created.targetId) || !(await waitForTab(created.targetId))) {
        return `Could not open ${origin} in Helium.`;
      }

      tab = tabs.get(created.targetId);
    }

    if (!tab) return `No tab on ${origin}.`;

    if (raise) {
      await send('Target.activateTarget', { targetId: tab.targetId });
      await raiseBrowser();
    }

    const result = await evaluate(tab.targetId, inspectExpression(origin)).catch((error: Error) => error.message);

    return result === 'active' ? 'active' : `Tidewave Inspect did not start (${String(result)}).`;
  };

  return {
    start: () => {
      stopped = false;
      void connect();
    },
    stop: () => {
      stopped = true;
      clearTimeout(retry);
      retry = undefined;
      const ws = socket;

      // Detach so the binding and script stop reaching a Pi that no longer holds the port.
      for (const tab of tabs.values()) {
        if (tab.sessionId) void send('Target.detachFromTarget', { sessionId: tab.sessionId }).catch(() => {});
      }

      socket = undefined;
      tabs.clear();
      setTimeout(() => ws?.close(), 200).unref?.();
      setUp(false);
    },
    state: () => (up ? 'up' : 'down'),
    tabs: () => [...tabs.values()].map(({ sessionId: _session, ...tab }) => tab),
    evaluate,
    inspect,
  };
};
