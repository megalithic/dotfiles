import { createHash } from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { beamCwds, listeners, ownedPorts, run, type Run } from './beam.ts';

export type Registry = {
  machine: string;
  at: string;
  pis: {
    id: string;
    pid: number;
    sessionId?: string;
    sessionName?: string;
    cwd: string;
    socket: string;
    state?: string;
    statusUpdatedAt?: string;
    ephemeral?: boolean;
    alive: boolean;
    tmux?: { session: string; window: string; pane?: string; windowIndex?: string; paneIndex?: string };
    rex?: { session?: string; block?: string };
  }[];
  apps: {
    port: number;
    origin: string;
    root?: string;
    pid?: number;
    owner:
      | { kind: 'pi'; pid: number; sessionId?: string; socket?: string }
      | { kind: 'ultimate'; project: string; home: string; conversation: number; url: string };
    holder?: { pid: number; sessionId?: string; socket?: string };
    tabs: { id?: string; url: string; lastActiveAt?: number }[];
    followers: number[];
    alive?: false;
  }[];
  ultimates: {
    pid: number;
    port: number;
    url: string;
    project: string;
    /** The instance's home (`~/.ultimate/projects/<slug>`); its conversation worktrees live under `worktrees/`. */
    home?: string;
    hub?: 'primary' | 'secondary';
    alive?: false;
  }[];
};

export type RegistryOptions = { includeDead?: boolean; includeEphemeral?: boolean };

export type UltimateAppDeps = {
  run?: Run;
  probe?: (port: number) => Promise<boolean>;
  env?: (pid: number) => Promise<string>;
  fs?: {
    realpath: (file: string) => Promise<string>;
    readFile: (file: string) => Promise<string>;
  };
};

export const probeApp = async (port: number): Promise<boolean> => {
  let reader: ReadableStreamDefaultReader<Uint8Array> | undefined;

  const reply = (text: string): boolean => {
    try {
      const value: JsonValue = JSON.parse(text);

      // Only a successful initialize counts: an error or an empty result is some other JSON-RPC server.
      return (
        isObject(value) &&
        value.jsonrpc === '2.0' &&
        value.id === 1 &&
        isObject(value.result) &&
        isString(value.result.protocolVersion)
      );
    } catch {
      return false;
    }
  };

  try {
    const response = await fetch(`http://127.0.0.1:${port}/tidewave/mcp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Accept: 'application/json, text/event-stream' },
      body: JSON.stringify({
        jsonrpc: '2.0',
        id: 1,
        method: 'initialize',
        params: {
          protocolVersion: '2025-06-18',
          capabilities: {},
          clientInfo: { name: 'pidewave-probe', version: '1.0.0' },
        },
      }),
      redirect: 'error',
      signal: AbortSignal.timeout(800),
    });

    reader = response.body?.getReader();

    if (!response.ok || !reader) return false;

    const type = response.headers.get('content-type')?.split(';')[0]?.trim();

    if (type === 'application/json') {
      let text = '';
      const decoder = new TextDecoder();

      for (;;) {
        const { done, value } = await reader.read();
        text += decoder.decode(value, { stream: !done });

        if (done) return reply(text);
      }
    }

    if (type !== 'text/event-stream') return false;

    const decoder = new TextDecoder();
    let buffer = '';

    for (;;) {
      const { done, value } = await reader.read();
      buffer += decoder.decode(value, { stream: !done });
      const events = buffer.split(/\r?\n\r?\n/);
      buffer = events.pop()!;

      for (const event of events) {
        const data = event
          .split(/\r?\n/)
          .filter((line) => line.startsWith('data:'))
          .map((line) => line.slice(5).trimStart())
          .join('\n');

        if (reply(data)) return true;
      }

      if (done) return false;
    }
  } catch {
    return false;
  } finally {
    await reader?.cancel().catch(() => {});
  }
};

const envPorts = (env: string, fromFile = false): Map<string, number> => {
  const ports = new Map<string, number>();

  const pattern = fromFile
    ? /^(PHX_PORT|PORT)=["']?(\d+)["']?(?=\s|$)/gm
    : /(?:^|\s)(PHX_PORT|PORT)=["']?(\d+)["']?(?=\s|$)/g;

  for (const match of env.matchAll(pattern)) ports.set(match[1]!, Number(match[2]));

  return ports;
};

/** Opt-in process discovery for the CLI; readRegistry itself stays synchronous and subprocess-free. */
export const withUltimateApps = async (registry: Registry, deps: UltimateAppDeps = {}): Promise<Registry> => {
  const exec = deps.run ?? run;
  const probe = deps.probe ?? probeApp;

  const files = deps.fs ?? {
    realpath: (file: string) => fs.promises.realpath(file),
    readFile: (file: string) => fs.promises.readFile(file, 'utf8'),
  };

  const readEnv = deps.env ?? ((pid: number) => exec('ps', ['-E', '-ww', '-o', 'command=', '-p', String(pid)]));

  const owners = registry.ultimates.flatMap((instance) =>
    instance.alive !== false && instance.home
      ? [
          {
            ...instance,
            home: instance.home,
            hash: createHash('sha256').update(instance.home).digest('hex').slice(0, 6),
          },
        ]
      : [],
  );

  if (!owners.length) return registry;

  const beams = await Promise.all(
    beamCwds(await exec('lsof', ['-a', '-c', 'beam.smp', '-d', 'cwd', '-Fpn'])).map(async (beam) => {
      const root = await files.realpath(beam.cwd).catch(() => undefined);
      const match = root && /^ult-([a-f0-9]{6})-([1-9]\d*)$/.exec(path.basename(root));
      const owner = match && owners.find(({ hash }) => hash === match[1]);
      const conversation = match ? Number(match[2]) : 0;

      return root && owner && Number.isSafeInteger(conversation) && conversation > 0
        ? { pid: beam.pid, root, owner, conversation }
        : undefined;
    }),
  );

  const matched = beams.filter((beam) => beam !== undefined);

  if (!matched.length) return registry;

  const all = listeners(await exec('lsof', ['-iTCP', '-sTCP:LISTEN', '-P', '-n', '-Fpn']));

  const discovered = await Promise.all(
    matched.map(async ({ pid, root, owner, conversation }): Promise<Registry['apps'][number] | undefined> => {
      const ports = ownedPorts(all, new Set([pid]));

      if (!ports.length) return undefined;

      const [processEnv, fileEnv] = await Promise.all([
        readEnv(Number(pid)),
        files.readFile(path.join(root, '.env')).catch(() => ''),
      ]);

      const preferred = new Map([...envPorts(fileEnv, true), ...envPorts(processEnv)]);

      let port = [preferred.get('PHX_PORT'), preferred.get('PORT')].find(
        (value) => value !== undefined && ports.includes(value),
      );

      if (port === undefined) {
        const answers = await Promise.all(ports.map((candidate) => probe(candidate)));
        port = ports.find((_candidate, index) => answers[index]);
      }

      if (port === undefined) return undefined;

      return {
        port,
        origin: `http://localhost:${port}`,
        root,
        pid: Number(pid),
        owner: { kind: 'ultimate', project: owner.project, home: owner.home, conversation, url: owner.url },
        tabs: [],
        followers: [],
      };
    }),
  );

  const apps = [...registry.apps];

  for (const app of discovered) {
    if (app && !apps.some(({ port }) => port === app.port)) apps.push(app);
  }

  return { ...registry, apps };
};

type JsonValue = null | boolean | number | string | JsonValue[] | { [key: string]: JsonValue };

type JsonObject = { [key: string]: JsonValue };

const isObject = (value: JsonValue | undefined): value is JsonObject =>
  value !== null && typeof value === 'object' && !Array.isArray(value);

const isString = (value: JsonValue | undefined): value is string => typeof value === 'string';

const isPid = (value: JsonValue | undefined): value is number =>
  typeof value === 'number' && Number.isSafeInteger(value) && value > 0;

const text = (value: JsonValue | undefined): string | undefined => (isString(value) ? value : undefined);

const readJson = (file: string): JsonObject | undefined => {
  try {
    const value: JsonValue = JSON.parse(fs.readFileSync(file, 'utf8'));

    return isObject(value) ? value : undefined;
  } catch {
    // Registrations can disappear or be partially written during discovery.
    return undefined;
  }
};

const names = (dir: string): string[] => {
  try {
    return fs.readdirSync(dir).sort();
  } catch {
    return [];
  }
};

const records = (dir: string, suffix: string): JsonObject[] =>
  names(dir).flatMap((name) => {
    const value = name.endsWith(suffix) ? readJson(path.join(dir, name)) : undefined;

    return value ? [value] : [];
  });

const pidAlive = (pid: number): boolean => {
  try {
    process.kill(pid, 0);

    return true;
  } catch (error) {
    return error instanceof Error && 'code' in error && error.code === 'EPERM';
  }
};

const registrationAlive = (record: JsonObject): boolean =>
  isPid(record.pid) &&
  pidAlive(record.pid) &&
  (!record.socket || (isString(record.socket) && fs.existsSync(record.socket)));

const expandHome = (value: string, home: string): string =>
  path.resolve(value === '~' ? home : value.startsWith('~/') ? path.join(home, value.slice(2)) : value);

/** Read only: no Pi packages, subprocess discovery, or writes to live registrations. */
export const readRegistry = (opts: RegistryOptions = {}): Registry => {
  const home = process.env.HOME || os.homedir();

  const state =
    process.env.PI_STATE_DIR || path.join(process.env.XDG_STATE_HOME || path.join(home, '.local/state'), 'pi');

  // ULTIMATE_HOME is instance-local inside Ultimate agents' shells.
  const ultimateHome = process.env.ULTIMATE_USER_HOME || path.join(home, '.ultimate');
  const machine = (process.env.HOSTNAME || os.hostname()).split('.')[0]?.trim() || 'localhost';
  const registry: Registry = { machine, at: new Date().toISOString(), pis: [], apps: [], ultimates: [] };
  const seats = records(path.join(state, 'pidewave/pis'), '.json');

  for (const manifest of records(path.join(state, 'manifests'), '.info')) {
    if (!isPid(manifest.pid) || !isString(manifest.socket) || !manifest.socket) continue;
    const alive = registrationAlive(manifest);
    const ephemeral = manifest.ephemeral === true;

    if ((!alive && !opts.includeDead) || (ephemeral && !opts.includeEphemeral)) continue;
    const sessionId = text(manifest.sessionId);

    const pi: Registry['pis'][number] = {
      // Older manifests without a logical session still need a unique address.
      id: `pi:${machine}:${sessionId ? encodeURIComponent(sessionId) : `pid-${manifest.pid}`}`,
      pid: manifest.pid,
      sessionId,
      sessionName: text(manifest.sessionName),
      cwd: text(manifest.cwd) || '',
      socket: manifest.socket,
      state: text(manifest.state),
      statusUpdatedAt: text(manifest.statusUpdatedAt),
      ephemeral,
      alive,
    };

    const seat = seats.find((entry) => entry.pid === manifest.pid && entry.socket === manifest.socket);
    const terminal = seat && isObject(seat.terminal) ? seat.terminal : undefined;

    // Session/window labels alone may describe Rex, not tmux. A pane identifies tmux.
    if (isString(manifest.pane) && isString(manifest.session) && isString(manifest.window)) {
      pi.tmux = { session: manifest.session, window: manifest.window, pane: manifest.pane };

      if (isString(manifest.windowIndex)) pi.tmux.windowIndex = manifest.windowIndex;

      if (isString(manifest.paneIndex)) pi.tmux.paneIndex = manifest.paneIndex;
    } else if (isString(manifest.rexSession) || isString(manifest.rexBlock)) {
      pi.rex = { session: text(manifest.rexSession), block: text(manifest.rexBlock) };
    } else if (terminal?.kind === 'rex' && isObject(terminal.rex)) {
      pi.rex = { session: text(terminal.rex.session), block: text(terminal.rex.block) };
    }

    registry.pis.push(pi);
  }

  for (const lease of records(path.join(state, 'pidewave/ports'), '.json')) {
    if (lease.v !== 1 || !isPid(lease.port) || lease.port > 65535 || !isPid(lease.pid)) continue;
    const claimedAt = Date.parse(text(lease.claimedAt) || '');
    const alive = registrationAlive(lease) && claimedAt >= Date.now() - os.uptime() * 1000;

    if (!alive && !opts.includeDead) continue;
    const browser = isObject(lease.browser) ? lease.browser : undefined;
    const tabs: Registry['apps'][number]['tabs'] = [];

    for (const tab of Array.isArray(browser?.tabs) ? browser.tabs : []) {
      if (!isObject(tab) || !isString(tab.url)) continue;
      const lastActiveAt = Date.parse(text(tab.lastActiveAt) || '');

      tabs.push({
        id: text(tab.targetId),
        url: tab.url,
        lastActiveAt: Number.isFinite(lastActiveAt) ? lastActiveAt : undefined,
      });
    }

    const app: Registry['apps'][number] = {
      port: lease.port,
      origin: `http://localhost:${lease.port}`,
      root: text(lease.root),
      owner: { kind: 'pi', pid: lease.pid, sessionId: text(lease.sessionId), socket: text(lease.socket) },
      holder: { pid: lease.pid, sessionId: text(lease.sessionId), socket: text(lease.socket) },
      tabs,
      followers: seats.flatMap((seat) =>
        seat.port === lease.port && seat.pid !== lease.pid && isPid(seat.pid) && registrationAlive(seat)
          ? [seat.pid]
          : [],
      ),
    };

    if (!alive) app.alive = false;
    registry.apps.push(app);
  }

  const projects = path.join(ultimateHome, 'projects');
  const liveProjects = new Set<string>();

  for (const name of names(projects)) {
    const lock = readJson(path.join(projects, name, 'ultimate.lock'));

    if (!lock || !isPid(lock.pid) || !isPid(lock.port) || lock.port > 65535 || !isString(lock.project)) continue;
    const alive = pidAlive(lock.pid);

    if (!alive && !opts.includeDead) continue;

    const instance: Registry['ultimates'][number] = {
      pid: lock.pid,
      port: lock.port,
      url: `http://127.0.0.1:${lock.port}`,
      project: lock.project,
      home: path.join(projects, name),
    };

    if (alive) liveProjects.add(expandHome(lock.project, home));
    else instance.alive = false;
    registry.ultimates.push(instance);
  }

  const settings = readJson(path.join(ultimateHome, 'settings.json'));
  const primary = settings && isObject(settings.fleet) ? text(settings.fleet.primary) : undefined;

  for (const instance of registry.ultimates) {
    if (instance.alive === false) continue;
    const project = expandHome(instance.project, home);

    if (primary && project === expandHome(primary, home)) instance.hub = 'primary';
    else if (
      [...liveProjects].some(
        (other) => other !== project && other.startsWith(project.endsWith('/') ? project : `${project}/`),
      )
    )
      instance.hub = 'secondary';
  }

  return registry;
};
