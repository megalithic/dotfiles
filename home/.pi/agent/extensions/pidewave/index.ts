/**
 * Pidewave: one Pi <-> one Tidewave (Phoenix port) <-> every browser tab on it.
 *
 * - endpoint.ts registers MCP server `tidewave` from `.pi/mcp.json` `pidewave.url`
 *   and probes it.
 * - lease.ts names the Pi that receives browser prompts for the port. An
 *   interactive Pi claims a free or dead lease at start; `/pidewave claim` takes it.
 *
 * Status for the footer: `ctx.ui.setStatus('pidewave', JSON)` (hidden unless
 * Tidewave answers) and `pi.events` `pidewave:status:v1`.
 */

import type { ExtensionAPI, ExtensionContext } from '@earendil-works/pi-coding-agent';
import { execFileSync } from 'node:child_process';
import path from 'node:path';
import { type BrowserLink, createBrowserLink, type PageMessage } from './browser.ts';
import {
  asError,
  type Connect,
  connectTidewave,
  createEndpoint,
  endpointFailureReason,
  portFromScript,
  readEndpoint,
  record,
  type ResolvePort,
} from './endpoint.ts';
import {
  claimLease,
  holderAlive,
  type Lease,
  readLease,
  releaseLease,
  type Tab,
  terminalFromEnv,
  updateLease,
} from './lease.ts';
import { promptRequest, sendControl, tellId } from './shared.ts';
import { focusTerminal } from './terminal.ts';

export const STATUS_EVENT = 'pidewave:status:v1';

// Lease changes by other Pis are noticed within this interval (fs.watch teardown is slow and flaky on macOS).
const RECONCILE_MS = 5_000;

type Role = 'holder' | 'follower' | 'none';

export type PidewaveStatus = {
  version: 1;
  url?: string;
  port?: number;
  connected: boolean;
  role: Role;
  holder?: { tellId: string | null; sessionName: string | null; pid: number };
  cdp: 'up' | 'down' | 'off';
  tabs: number;
  lastPromptAt: string | null;
};

const sleep = (ms: number): Promise<void> => new Promise((resolve) => setTimeout(resolve, ms));

const portOf = (url: URL): number => Number(url.port || (url.protocol === 'https:' ? 443 : 80));

const gitRoot = (cwd: string): string => {
  try {
    return execFileSync('git', ['rev-parse', '--show-toplevel'], {
      cwd,
      encoding: 'utf8',
      timeout: 2_000,
      stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
  } catch {
    return cwd;
  }
};

// Subagents and headless or throwaway Pis use Tidewave's tools but never take browser prompts.
const canHold = (ctx: ExtensionContext): boolean =>
  ctx.hasUI && !process.env.PI_SUBAGENT_NAME && process.env.PI_EPHEMERAL !== '1';

export default function (
  pi: ExtensionAPI,
  connect: Connect = connectTidewave,
  resolvePort: ResolvePort = portFromScript,
  createLink: typeof createBrowserLink = createBrowserLink,
): void {
  let ctxRef: ExtensionContext | undefined;
  let role: Role = 'none';
  let mine: Lease | undefined;
  let other: Lease | null = null;
  let root: string | undefined;
  let lastStatus: string | undefined;
  let reconcileTimer: ReturnType<typeof setInterval> | undefined;
  let link: BrowserLink | undefined;
  let linkOrigin: string | undefined;

  const status = (): PidewaveStatus => {
    const url = endpoint.url();
    const holder = role === 'holder' ? mine : other;

    return {
      version: 1,
      url: url?.origin,
      port: url ? portOf(url) : undefined,
      connected: endpoint.live(),
      role,
      holder: holder ? { tellId: holder.tellId, sessionName: holder.sessionName, pid: holder.pid } : undefined,
      cdp: link?.state() ?? 'off',
      tabs: link?.tabs().length ?? 0,
      lastPromptAt: mine?.lastPromptAt ?? null,
    };
  };

  const publishStatus = (): void => {
    const current = status();
    pi.events.emit(STATUS_EVENT, current);
    const ctx = ctxRef;

    if (!ctx?.hasUI) return;

    // custom-footer.ts reads url, connected and boundHere; it hides the segment unless connected.
    const text =
      current.connected && current.url
        ? JSON.stringify({
            url: current.url,
            boundHere: role === 'holder',
            connected: true,
            port: current.port,
            role,
            cdp: current.cdp,
            tabs: current.tabs,
          })
        : undefined;

    if (text !== lastStatus) {
      ctx.ui.setStatus('pidewave', text);
      lastStatus = text;
    }
  };

  const buildLease = (ctx: ExtensionContext, url: URL): Lease => {
    root ??= gitRoot(ctx.cwd);
    const sessionId = ctx.sessionManager?.getSessionId?.() || null;

    return {
      v: 1,
      port: portOf(url),
      origin: url.origin,
      root,
      cwd: ctx.cwd,
      pid: process.pid,
      sessionId,
      sessionName: ctx.sessionManager?.getSessionName?.() || null,
      tellId: sessionId ? tellId(sessionId) : null,
      socket: process.env.PI_SOCKET || null,
      terminal: terminalFromEnv(),
      claimedAt: mine?.claimedAt ?? new Date().toISOString(),
      browser: link ? { cdp: link.state(), tabs: link.tabs() } : { cdp: 'off', tabs: [] },
      lastPromptAt: mine?.lastPromptAt ?? null,
    };
  };

  const demote = (holder: Lease | null): void => {
    const wasHolder = role === 'holder';
    role = 'follower';
    mine = undefined;
    other = holder;

    if (wasHolder && ctxRef?.hasUI) {
      ctxRef.ui.notify(`Pidewave: browser prompts moved to ${holder?.sessionName ?? holder?.tellId ?? 'another Pi'}.`);
    }
  };

  const claim = (ctx: ExtensionContext, url: URL, force: boolean): boolean => {
    const lease = buildLease(ctx, url);

    try {
      const result = claimLease(lease, force);

      if (result.held) {
        role = 'holder';
        mine = lease;
        other = null;
        record(pi, 'lease', { port: String(lease.port), force });

        return true;
      }

      demote(result.holder);
    } catch {
      role = 'none';
    }

    return false;
  };

  // Keep the lease true to this process, and take it over when its holder is gone.
  const reconcile = (): void => {
    const ctx = ctxRef;
    const url = endpoint.url();

    if (!ctx || !url || !canHold(ctx)) return publishStatus();
    const port = portOf(url);

    // The endpoint moved (port drift or /pidewave with a new URL).
    if (mine && mine.port !== port) {
      releaseLease(mine.port, process.pid);
      mine = undefined;
      role = 'none';
    }

    if (role === 'holder' && mine) {
      const current = readLease(port);

      if (current?.pid !== process.pid) {
        demote(current);
      } else {
        const next = buildLease(ctx, url);

        if (JSON.stringify(next) !== JSON.stringify(mine) && updateLease(next)) mine = next;
      }
    } else {
      const current = readLease(port);

      // A reload runs a fresh copy of this extension in the same process: adopt our own lease.
      if (current?.pid === process.pid) {
        role = 'holder';
        mine = current;
        other = null;
      } else if (!current || !holderAlive(current)) claim(ctx, url, false);
      else other = current;

      if (role === 'none') role = 'follower';
    }

    syncLink();
    publishStatus();
  };

  // Tab and CDP changes only touch the lease and the status, never the claim.
  const linkChanged = (): void => {
    const ctx = ctxRef;
    const url = endpoint.url();

    if (ctx && url && role === 'holder' && mine) {
      const next = buildLease(ctx, url);

      if (updateLease(next)) mine = next;
    }

    publishStatus();
  };

  const toast = (tab: Tab, text: string, ok: boolean): void => {
    const call = `window.__pidewaveToast && window.__pidewaveToast(${JSON.stringify(text)}, ${ok})`;
    void link?.evaluate(tab.targetId, call).catch(() => {});
  };

  // Same path as every other external prompt: bridge.ts delivers it as a Tidewave tell.
  const deliver = async (text: string, tab: Tab): Promise<void> => {
    const socket = process.env.PI_SOCKET;
    const response = socket ? await sendControl(socket, promptRequest(text)) : null;
    let ok = response?.ok === true;

    if (!socket) {
      try {
        pi.sendUserMessage(text, { deliverAs: 'followUp' });
        ok = true;
      } catch {}
    }

    record(pi, 'prompt', { ok, url: tab.url });

    if (ok && mine) mine = { ...mine, lastPromptAt: new Date().toISOString() };
    linkChanged();
    const name = mine?.sessionName ?? 'Pi';
    toast(tab, ok ? `Sent to ${name}` : `${name} did not accept the prompt: ${response?.error ?? 'no answer'}`, ok);

    if (!ok && ctxRef?.hasUI) ctxRef.ui.notify('Pidewave: a browser prompt could not be delivered.', 'error');
  };

  const onPageMessage = (message: PageMessage, tab: Tab): void => {
    if (message.kind === 'prompt') void deliver(message.text, tab);

    if (message.kind === 'focus-pi') {
      void focusTerminal(terminalFromEnv()).then((error) => {
        if (error) toast(tab, error, false);
      });
    }

    if (message.kind === 'inspect') {
      void link?.inspect(tab.targetId, false).then((result) => {
        if (result !== 'active') toast(tab, result, false);
      });
    }
  };

  // Only the holder keeps a browser link, on its current origin.
  const syncLink = (): void => {
    const url = endpoint.url();
    const want = role === 'holder' && url ? url.origin : undefined;

    if (link && linkOrigin !== want) {
      link.stop();
      link = undefined;
      linkOrigin = undefined;
    }

    if (link || !want) return;
    linkOrigin = want;

    link = createLink(want, { message: onPageMessage, change: linkChanged }, () => ({
      sessionName: mine?.sessionName ?? null,
      tellId: mine?.tellId ?? null,
    }));

    link.start();
  };

  const endpoint = createEndpoint(pi, connect, resolvePort, reconcile);

  const startWatching = (): void => {
    reconcileTimer = setInterval(reconcile, RECONCILE_MS);
    reconcileTimer.unref();
  };

  const stopWatching = (): void => {
    clearInterval(reconcileTimer);
    reconcileTimer = undefined;
  };

  const leaseLine = (): string => {
    if (role === 'holder') return 'browser prompts come here';

    if (other) return `browser prompts go to ${other.sessionName ?? other.tellId ?? `pid ${other.pid}`}`;

    return 'this Pi does not take browser prompts';
  };

  // Pi resolves project trust once at startup; a reload keeps the old state.
  // Saving the decision here still needs a restart before readEndpoint sees it.
  const ensureTrusted = async (ctx: ExtensionContext): Promise<boolean> => {
    if (ctx.isProjectTrusted?.() === true) return true;

    const cwd = path.resolve(ctx.cwd);
    const parent = path.dirname(cwd);
    const options = ['Trust this folder', `Trust parent folder (${parent})`, 'Cancel'];
    const selected = await ctx.ui.select(`Pidewave needs project trust to read .pi/mcp.json.\n${cwd}`, options);
    const target = selected === options[0] ? cwd : selected === options[1] ? parent : undefined;

    if (!target) {
      record(pi, 'trust-declined', { cwd });
      ctx.ui.notify('Pidewave: project is not trusted, so no Tidewave endpoint can be registered.', 'warning');

      return false;
    }

    const { getAgentDir, ProjectTrustStore } = await import('@earendil-works/pi-coding-agent');
    new ProjectTrustStore(getAgentDir()).set(target, true);
    record(pi, 'trust-saved', { path: target });
    ctx.ui.notify(`Pidewave: trusted ${target}. Restart Pi, then run /pidewave again.`, 'info');

    return false;
  };

  const reconnect = async (ctx: ExtensionContext): Promise<void> => {
    if (!(await ensureTrusted(ctx))) return;

    let url: URL | undefined;

    try {
      url = readEndpoint(ctx, resolvePort);
    } catch (error) {
      ctx.ui.notify(`Pidewave: ${endpointFailureReason(asError(error))}.`, 'error');

      return;
    }

    if (!url) {
      ctx.ui.notify('Pidewave: no pidewave.url in .pi/mcp.json; run `mise run bootstrap` to generate it.', 'warning');

      return;
    }

    // Re-registering forces Pi's MCP connection to reconnect, not only our probe.
    await endpoint.stop();
    endpoint.start(ctx);
    const registered = endpoint.url();

    if (!registered) return; // start already said why.
    await endpoint.check();

    if (endpoint.live()) {
      record(pi, 'reconnected', { url: registered.origin });
      ctx.ui.notify(`Pidewave: Tidewave connected at ${registered.origin}.`, 'info');

      return;
    }

    record(pi, 'reconnect-failed', { url: registered.origin });
    ctx.ui.notify(
      `Pidewave: Tidewave did not answer at ${registered.origin}; start Phoenix there with \`mise run start:server\`.`,
      'error',
    );
  };

  // Take the port (if needed), then focus the most recently used tab and start Tidewave Inspect.
  const inspectFromPi = async (ctx: ExtensionContext): Promise<void> => {
    if (!takeOver(ctx)) return;
    const fresh = link?.state() !== 'up';

    for (let i = 0; i < 30 && link?.state() !== 'up'; i += 1) await sleep(100);

    // A new link is still attaching its tabs; give it a moment before picking one.
    if (fresh) await sleep(500);
    const result = (await link?.inspect(undefined, true)) ?? 'no browser link';

    if (result !== 'active') ctx.ui.notify(`Pidewave: ${result}`, 'warning');
  };

  const takeOver = (ctx: ExtensionContext): boolean => {
    const url = endpoint.url();

    if (!url) {
      ctx.ui.notify('Pidewave: no Tidewave endpoint is registered for this project.', 'warning');

      return false;
    }

    if (!canHold(ctx)) {
      ctx.ui.notify('Pidewave: only an interactive Pi can take browser prompts.', 'warning');

      return false;
    }

    if (role !== 'holder') claim(ctx, url, true);
    syncLink();
    publishStatus();

    return role === 'holder';
  };

  pi.registerShortcut('ctrl+shift+i', {
    description: 'Pidewave: take browser prompts here and start Tidewave Inspect in the app tab',
    handler: (ctx) => inspectFromPi(ctx),
  });

  pi.registerCommand('pidewave', {
    description:
      'Tidewave link: no args reconnects; `status` reports; `claim` takes browser prompts; `inspect` starts Tidewave Inspect',
    getArgumentCompletions: (prefix: string) =>
      ['status', 'claim', 'inspect', 'focus'].flatMap((value) =>
        value.startsWith(prefix) ? [{ value, label: value }] : [],
      ),
    handler: async (args, ctx) => {
      const sub = args.trim();

      if (sub === 'claim') {
        if (takeOver(ctx)) ctx.ui.notify(`Pidewave: browser prompts for ${linkOrigin} now come here.`, 'info');

        return;
      }

      if (sub === 'inspect') return inspectFromPi(ctx);

      if (sub === 'focus') {
        const error = await focusTerminal(terminalFromEnv());

        return error ? ctx.ui.notify(`Pidewave: ${error}`, 'warning') : undefined;
      }

      if (sub === 'status') {
        const s = status();

        const lines = [
          `Pidewave: ${s.url ?? 'no endpoint'} (${s.connected ? 'connected' : 'not answering'})`,
          `- ${leaseLine()}`,
          `- browser: ${s.cdp === 'up' ? `${s.tabs} tab(s) linked` : s.cdp === 'down' ? 'no CDP on 9223' : 'not linked'}`,
        ];

        if (s.lastPromptAt) lines.push(`- last prompt: ${s.lastPromptAt}`);

        return ctx.ui.notify(lines.join('\n'), 'info');
      }

      await reconnect(ctx);
    },
  });

  pi.on('session_start', (_e, ctx) => {
    ctxRef = ctx;
    lastStatus = undefined;
    stopWatching();

    if (ctx.hasUI) {
      ctx.ui.setWidget('pidewave', undefined);
      ctx.ui.setStatus('pidewave', undefined);
    }

    endpoint.start(ctx);

    if (canHold(ctx) && endpoint.url()) startWatching();
  });

  pi.on('before_agent_start', () => reconcile());

  pi.on('session_shutdown', async (event, ctx) => {
    stopWatching();
    link?.stop();
    link = undefined;
    linkOrigin = undefined;
    const quitting = event.reason === undefined || event.reason === 'quit';

    // Reload, new, resume and fork keep this process, so they keep the lease.
    if (mine && quitting) {
      releaseLease(mine.port, process.pid);
      mine = undefined;
      role = 'none';
    }

    ctxRef = undefined;
    lastStatus = undefined;

    if (ctx.hasUI) ctx.ui.setStatus('pidewave', undefined);
    await endpoint.stop();
  });
}
