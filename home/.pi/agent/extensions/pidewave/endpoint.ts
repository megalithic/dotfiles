/**
 * Tidewave MCP ownership: read `.pi/mcp.json` `pidewave.url`, resolve the port,
 * register MCP server `tidewave` with Pi's built-in MCP support, and probe it.
 *
 * Pi's MCP connection reconnects lazily when a call finds it gone (Phoenix
 * restarts), but a server whose first connect failed never lists tools. So the
 * first successful probe after a failed start registers the server again.
 */

import type { ExtensionAPI, ExtensionContext } from '@earendil-works/pi-coding-agent';
import { execFile, execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { isJsonObject, isJsonString, type JsonValue } from './shared.ts';

export const SERVER_NAME = 'tidewave';

export const PING_INTERVAL_MS = 10_000;

const PING_TIMEOUT_MS = 3_000;

// While Tidewave is down, re-run phx-port.sh every this many failed ticks to catch a moved port.
const DRIFT_CHECK_TICKS = 3;

/** Liveness probe: Pi's own MCP client, connected to the registered URL. */
export type Probe = { ping(options?: { timeoutMs?: number }): Promise<void>; close(): Promise<void> };

export type Connect = (url: URL) => Promise<Probe>;

/** Returns the Phoenix port for a worktree, or undefined. */
export type ResolvePort = (cwd: string) => string | undefined;

// `@earendil-works/pi-mcp` is ESM-only and not jiti-aliased for extensions, so
// resolve its manifest from the running Pi install (node >= 22.14).
export const connectTidewave: Connect = async (url) => {
  const [{ getPackageDir }, { findPackageJSON }] = await Promise.all([
    import('@earendil-works/pi-coding-agent'),
    import('node:module'),
  ]);

  const manifest = findPackageJSON(
    '@earendil-works/pi-mcp',
    pathToFileURL(path.join(getPackageDir(), 'package.json')).href,
  );

  if (!manifest) throw new Error('@earendil-works/pi-mcp is not installed next to Pi');
  const pkg: JsonValue = JSON.parse(fs.readFileSync(manifest, 'utf8'));
  const main = isJsonObject(pkg) && isJsonString(pkg.main) ? pkg.main : 'dist/index.js';

  const { McpClient, StreamableHttpTransport } = await import(
    pathToFileURL(path.join(path.dirname(manifest), main)).href
  );

  const client = new McpClient({ name: 'pidewave', version: '1.0.0', requestTimeoutMs: PING_TIMEOUT_MS });

  await client.connect(new StreamableHttpTransport({ url, openGetStream: false }));

  return client;
};

const PHX_PORT_SCRIPT = path.join(process.env.HOME ?? '', '.dotfiles/config/mise/tmpls/elixir/scripts/phx-port.sh');

/** phx-port.sh: `$PORT`, else the live phx.server port for this checkout, else the cached hash port. */
export const portFromScript: ResolvePort = (cwd) => {
  try {
    const out = execFileSync('bash', [PHX_PORT_SCRIPT], {
      cwd,
      encoding: 'utf8',
      timeout: 3_000,
      stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();

    return /^\d+$/.test(out) ? out : undefined;
  } catch {
    return undefined;
  }
};

const portFromScriptAsync = (cwd: string): Promise<string | undefined> =>
  new Promise((resolve) =>
    execFile('bash', [PHX_PORT_SCRIPT], { cwd, encoding: 'utf8', timeout: 3_000 }, (error, stdout) => {
      const out = stdout.trim();
      resolve(!error && /^\d+$/.test(out) ? out : undefined);
    }),
  );

/** The raw `pidewave.url` template, or undefined when the project has none. Throws only own messages. */
const readTemplate = (ctx: ExtensionContext): string | undefined => {
  if (ctx.isProjectTrusted?.() !== true) return;
  const file = path.join(ctx.cwd, '.pi', 'mcp.json');

  if (!fs.existsSync(file)) return;
  const config: JsonValue = JSON.parse(fs.readFileSync(file, 'utf8'));

  if (!isJsonObject(config) || config.pidewave === undefined) return;

  if (!isJsonObject(config.pidewave) || !isJsonString(config.pidewave.url)) {
    throw new Error('Invalid Pidewave configuration');
  }

  // A configured server of the same name takes precedence over our registration.
  if (isJsonObject(config.mcpServers) && config.mcpServers[SERVER_NAME] !== undefined) {
    throw new Error('Configured tidewave server shadows Pidewave');
  }

  return config.pidewave.url;
};

export const usesPhxPort = (template: string): boolean =>
  /\$\{PHX_PORT\}|\$env:PHX_PORT\b|\{env:PHX_PORT\}/.test(template);

const expand = (template: string, value: (name: string) => string): string =>
  template
    .replace(/\$\{(\w+)\}/g, (_match, name: string) => value(name))
    .replace(/\$env:(\w+)/g, (_match, name: string) => value(name))
    .replace(/\{env:(\w+)\}/g, (_match, name: string) => value(name));

const safeUrl = (literal: string): URL => {
  if (!/^https?:\/\/(?:localhost|127\.0\.0\.1)(?::[1-9]\d{0,4})?\/tidewave\/mcp$/.test(literal)) {
    throw new Error('Unsafe Pidewave endpoint');
  }

  const url = new URL(literal);
  const port = Number(url.port || (url.protocol === 'https:' ? 443 : 80));

  if (url.href !== literal || port < 1 || port > 65535 || port === 9832) {
    throw new Error('Unsafe Pidewave endpoint');
  }

  return url;
};

/**
 * Resolve the endpoint. `PHX_PORT` falls back to phx-port.sh, so a Pi started
 * from a shell without mise's environment still finds its worktree's port.
 * `override` replaces PHX_PORT (port drift).
 */
export const readEndpoint = (
  ctx: ExtensionContext,
  resolvePort: ResolvePort = portFromScript,
  override?: string,
): URL | undefined => {
  const template = readTemplate(ctx);

  if (template === undefined) return;

  const value = (name: string): string => {
    const found = name === 'PHX_PORT' ? override || process.env.PHX_PORT || resolvePort(ctx.cwd) : process.env[name];

    if (!found) throw new Error('Missing Pidewave environment variable');

    return found;
  };

  return safeUrl(expand(template, value));
};

// Only our own messages reach the UI; JSON, URL, and Pi error text could echo file contents.
const OWN_FAILURES = [
  'Invalid Pidewave configuration',
  'Missing Pidewave environment variable',
  'Unsafe Pidewave endpoint',
  'Configured tidewave server shadows Pidewave',
  'MCP registration refused',
];

export const endpointFailureReason = (error: Error): string =>
  OWN_FAILURES.includes(error.message) ? error.message : 'unreadable .pi/mcp.json or endpoint URL';

export const asError = <T>(thrown: T): Error => (thrown instanceof Error ? thrown : new Error());

type PidewaveRecord = { event: string; at: string; [key: string]: string | boolean | undefined };

// Durable trace kept out of model context (pi.appendEntry). Unavailable before a
// session exists, so a failure to record never breaks the endpoint itself.
export const record = (pi: ExtensionAPI, event: string, data: Omit<PidewaveRecord, 'event' | 'at'> = {}): void => {
  try {
    pi.appendEntry<PidewaveRecord>('pidewave', { event, at: new Date().toISOString(), ...data });
  } catch {}
};

export type Endpoint = {
  start(ctx: ExtensionContext, override?: string): void;
  stop(): Promise<void>;
  check(): Promise<void>;
  url(): URL | undefined;
  live(): boolean;
};

export const createEndpoint = (
  pi: ExtensionAPI,
  connect: Connect,
  resolvePort: ResolvePort,
  onChange: () => void,
): Endpoint => {
  let ctxRef: ExtensionContext | undefined;
  let monitor: ReturnType<typeof setInterval> | undefined;
  let registeredUrl: URL | undefined;
  let probe: Probe | undefined;
  let checking: Promise<void> | undefined;
  let live = false;
  // Bumped by an external stop, so a port-drift restart never outlives session_shutdown.
  let generation = 0;
  let failedTicks = 0;

  const register = (url: URL): void => {
    try {
      pi.registerMcpServer(SERVER_NAME, { url: url.href, exposure: 'direct' });
    } catch {
      throw new Error('MCP registration refused');
    }
  };

  const setLive = (next: boolean): void => {
    if (next === live) return;
    live = next;
    record(pi, 'status', { status: next ? 'connected' : 'unreachable', url: registeredUrl?.origin });

    // After any outage, register again: Pi's own connection may have failed while ours
    // still answered (a server that failed its first connect never lists tools).
    if (next && failedTicks > 0 && registeredUrl) {
      try {
        pi.unregisterMcpServer(SERVER_NAME);
        register(registeredUrl);
        record(pi, 'reregistered', { url: registeredUrl.origin });
      } catch {}
    }

    if (next) failedTicks = 0;

    onChange();
  };

  // One MCP session per registration; a failed ping drops it and the next tick reconnects.
  const run = async (): Promise<void> => {
    const url = registeredUrl;

    if (!url) return;

    try {
      const current = probe ?? (await connect(url));

      // Stopped or re-registered while connecting.
      if (registeredUrl !== url) {
        await current.close().catch(() => {});

        return;
      }

      probe = current;
      await current.ping({ timeoutMs: PING_TIMEOUT_MS });

      if (registeredUrl === url) setLive(true);
    } catch {
      const dead = probe;
      probe = undefined;

      if (registeredUrl === url) {
        failedTicks += 1;
        setLive(false);
      }

      await dead?.close().catch(() => {});
    }
  };

  const check = (): Promise<void> => {
    checking ??= run().finally(() => {
      checking = undefined;
    });

    return checking;
  };

  const halt = async (): Promise<void> => {
    clearInterval(monitor);
    monitor = undefined;
    const url = registeredUrl;
    registeredUrl = undefined;
    const dead = probe;
    probe = undefined;
    failedTicks = 0;
    setLive(false);

    if (url) {
      try {
        pi.unregisterMcpServer(SERVER_NAME);
      } catch {} // The runtime may already be shutting down.
    }

    await dead?.close().catch(() => {});
  };

  const stop = (): Promise<void> => {
    generation += 1;

    return halt();
  };

  // Phoenix may come back on another port (a PORT override); phx-port.sh reports the live one.
  const checkDrift = async (): Promise<void> => {
    const ctx = ctxRef;
    const url = registeredUrl;
    const token = generation;

    if (live || !ctx || !url || failedTicks === 0 || failedTicks % DRIFT_CHECK_TICKS !== 0) return;

    try {
      const template = readTemplate(ctx);

      if (!template || !usesPhxPort(template)) return;
      // phx-port.sh runs pgrep, ps and lsof: off the TUI thread when it is the real one.
      const port = resolvePort === portFromScript ? await portFromScriptAsync(ctx.cwd) : resolvePort(ctx.cwd);

      if (!port || port === url.port || token !== generation || registeredUrl !== url) return;
      record(pi, 'port-moved', { from: url.port, to: port });
      await halt();

      if (token === generation) start(ctx, port);
    } catch {}
  };

  const start = (ctx: ExtensionContext, override?: string): void => {
    ctxRef = ctx;

    if (registeredUrl) return;

    try {
      const url = readEndpoint(ctx, resolvePort, override);

      if (!url) return;
      register(url);
      registeredUrl = url;
      record(pi, 'registered', { url: url.origin });
      monitor = setInterval(() => void check().then(checkDrift), PING_INTERVAL_MS);
      monitor.unref();
      void check();
    } catch (error) {
      const reason = endpointFailureReason(asError(error));
      record(pi, 'unavailable', { reason, trusted: ctx.isProjectTrusted?.() === true });

      if (ctx.hasUI) ctx.ui.notify(`Pidewave endpoint unavailable: ${reason}.`, 'warning');
    } finally {
      onChange();
    }
  };

  return { start, stop, check, url: () => registeredUrl, live: () => live };
};
