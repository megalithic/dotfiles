import { execFile } from 'node:child_process';
import path from 'node:path';
import { promisify } from 'node:util';
import { Type } from 'typebox';
import { Check } from 'typebox/value';
import { socketRequest, type RequestOptions } from './messaging.ts';
import { readRegistry } from './registry.ts';
import { registryTargets, resolveTargets, type Target } from './tell-targets.ts';

const exec = promisify(execFile);

const quote = (text: string): string => `'${text.replace(/'/g, `'\\''`)}'`;

export const ssh = (
  host: string,
  command: string,
  input?: string,
  timeout = 5000,
  signal?: AbortSignal,
): Promise<string> =>
  new Promise((resolve, reject) => {
    if (!host.trim() || host.startsWith('-') || /\s/.test(host)) return reject(new Error('Invalid SSH host'));

    const child = execFile(
      'ssh',
      ['-o', 'BatchMode=yes', '-o', 'ConnectTimeout=5', '--', host, command],
      { encoding: 'utf8', timeout, signal, maxBuffer: 1024 * 1024 },
      (error, stdout, stderr) => {
        if (error) reject(new Error(`SSH ${host}: ${stderr.trim() || error.message}`));
        else resolve(stdout);
      },
    );

    child.stdin?.on('error', () => {
      /* SSH may exit before reading stdin; its callback reports failure. */
    });
    child.stdin?.end(input === undefined ? undefined : `${input}\n`);
  });

const registrySchema = Type.Object({
  machine: Type.String(),
  pis: Type.Array(
    Type.Object({
      id: Type.String(),
      pid: Type.Integer(),
      socket: Type.String(),
      cwd: Type.String(),
      alive: Type.Boolean(),
      sessionId: Type.Optional(Type.String()),
      sessionName: Type.Optional(Type.String()),
      state: Type.Optional(Type.String()),
      statusUpdatedAt: Type.Optional(Type.String()),
      ephemeral: Type.Optional(Type.Boolean()),
      tmux: Type.Optional(
        Type.Object({
          session: Type.String(),
          window: Type.String(),
          pane: Type.Optional(Type.String()),
          windowIndex: Type.Optional(Type.String()),
          paneIndex: Type.Optional(Type.String()),
        }),
      ),
      rex: Type.Optional(Type.Object({ session: Type.Optional(Type.String()), block: Type.Optional(Type.String()) })),
    }),
  ),
  ultimates: Type.Array(
    Type.Object({
      pid: Type.Integer(),
      port: Type.Integer(),
      url: Type.String(),
      project: Type.String(),
      hub: Type.Optional(Type.Union([Type.Literal('primary'), Type.Literal('secondary')])),
      alive: Type.Optional(Type.Literal(false)),
    }),
  ),
});

export const listTargets = async (host?: string, signal?: AbortSignal): Promise<Target[]> => {
  // Keep stale local registrations for exact-id spooling, never for the live picker.
  let registry = readRegistry({ includeDead: true });
  let remote: string | undefined;

  if (host && !['localhost', '127.0.0.1', registry.machine].includes(host)) {
    remote = host;
    const text = await ssh(host, '~/.dotfiles/bin/agents --json', undefined, 5000, signal);
    let value: unknown;

    try {
      value = JSON.parse(text);
    } catch {
      throw new Error(`Invalid remote registry from ${host}: expected JSON`);
    }

    if (!Check(registrySchema, value)) throw new Error(`Invalid remote registry from ${host}`);
    registry = { ...registry, ...value };
  }

  registry.pis = registry.pis.filter((pi) => !pi.ephemeral);
  registry.ultimates = registry.ultimates.filter((ultimate) => ultimate.alive !== false);

  const targets = await Promise.all(registryTargets(registry, remote).map((target) => probeTarget(target, signal)));

  signal?.throwIfAborted();

  return targets;
};

const responseSchema = Type.Object({
  ok: Type.Boolean(),
  type: Type.Literal('control_response'),
  protocol: Type.Literal('pi.control.v1'),
  id: Type.String(),
  operation: Type.String(),
  error: Type.Optional(Type.String()),
  data: Type.Optional(
    Type.Object({
      message: Type.Optional(
        Type.Union([Type.Null(), Type.Object({ content: Type.String(), timestamp: Type.Optional(Type.Number()) })]),
      ),
      deliveredAs: Type.Optional(Type.String()),
    }),
  ),
});

export type ControlResponse = Type.Static<typeof responseSchema>;

type SendParams = {
  text?: string;
  messageId?: string;
  from?: string;
  fromSocket?: string;
  sessionId?: string;
  sessionName?: string;
  timestamp?: number;
  mode?: 'steer' | 'follow_up' | 'quiet';
  replyTo?: string;
};

export const control = async (
  target: Target,
  operation: string,
  params: SendParams = {},
  id: string = crypto.randomUUID(),
  options: RequestOptions = {},
): Promise<ControlResponse> => {
  if (target.ultimate) throw new Error(`${operation} requires a Pi target`);
  const request = { type: 'control', protocol: 'pi.control.v1', id, operation, params };

  const text = target.host
    ? await ssh(
        target.host,
        `~/.dotfiles/bin/agents send --socket ${quote(target.socket)}`,
        JSON.stringify(request),
        options.timeout,
        options.signal,
      )
    : await socketRequest(target.socket, JSON.stringify(request), options);

  let response: unknown;
  const source = `${target.host ? `${target.host}:` : ''}${target.socket}`;

  try {
    response = JSON.parse(text);
  } catch {
    throw new Error(`Invalid Pi control response from ${source}: expected JSON`);
  }

  if (!Check(responseSchema, response) || response.id !== id || response.operation !== operation)
    throw new Error(`Invalid Pi control response from ${source}`);

  if (!response.ok) throw new Error(`Pi ${operation} on ${source} failed: ${response.error || 'request rejected'}`);

  return response;
};

// message.last is a read-only control ping, supported by existing bridges; no legacy ping or new operation.
const probeTarget = async (target: Target, signal?: AbortSignal): Promise<Target> => {
  if (!target.pi) return { ...target, reachable: true };

  if (!target.pi.alive) return { ...target, reachable: false, unreachableReason: 'Registration is no longer alive' };

  try {
    await control(target, 'message.last', {}, undefined, { timeout: 800, signal });

    return { ...target, reachable: true };
  } catch (error) {
    return { ...target, reachable: false, unreachableReason: error instanceof Error ? error.message : String(error) };
  }
};

export type Origin = { label: string; sessionId: string; socket: string; cwd: string; machine: string };

export const tellUltimate = async (
  target: Target,
  text: string,
  reply: boolean,
  from: Origin,
  id: string,
): Promise<string> => {
  const origin = new URL(target.socket).origin;
  const url = `${origin}/api/extensions/pi-bridge/actions/tell`;
  const body = { args: { text, reply, id, from } };
  let result: { result?: { key?: string; delivered?: boolean } };

  if (target.host) {
    result = JSON.parse(
      await ssh(
        target.host,
        `curl --fail --silent --show-error --max-time 5 -H ${quote(`Origin: ${origin}`)} -H 'Content-Type: application/json' --data-binary @- ${quote(url)}`,
        JSON.stringify(body),
      ),
    );
  } else {
    const response = await fetch(url, {
      method: 'POST',
      headers: { Origin: origin, 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(5000),
    });

    if (!response.ok) throw new Error(`Ultimate rejected tell: HTTP ${response.status}`);
    result = await response.json();
  }

  if (result.result?.delivered !== true || !result.result.key) throw new Error('Invalid Ultimate delivery response');

  return result.result.key;
};

type RexInspect = { label?: string; windows?: { label?: string; layers?: { blocks?: { block_id?: string }[] }[] }[] };

export type InspectRex = (session: string, host?: string) => Promise<RexInspect>;

const inspectRex: InspectRex = async (session, host) => {
  if (host) return JSON.parse(await ssh(host, `rex session inspect ${quote(session)} --json`, undefined, 2000));
  const rex = process.env.REX_BIN_DIR ? path.join(process.env.REX_BIN_DIR, 'rex') : 'rex';

  return JSON.parse((await exec(rex, ['session', 'inspect', session, '--json'], { timeout: 2000 })).stdout);
};

/** Resolve labels on demand for both exact Rex routing and partial picker search. */
export const enrichRexTargets = async (inventory: Target[], inspect: InspectRex = inspectRex): Promise<Target[]> => {
  const sessions = new Map<string, Promise<RexInspect>>();

  return Promise.all(
    inventory.map(async (target) => {
      const session = target.pi?.rex?.session;

      if (!session) return target;
      const key = `${target.host || ''}\u0000${session}`;

      if (!sessions.has(key)) sessions.set(key, inspect(session, target.host));
      // Block/session IDs remain usable when Rex is not installed or a session has closed.
      const info = await sessions.get(key)!.catch(() => undefined);

      const index =
        info?.windows?.findIndex((tab) =>
          tab.layers?.some((layer) => layer.blocks?.some((block) => block.block_id === target.rex?.block)),
        ) ?? -1;

      return {
        ...target,
        rex: {
          ...target.rex,
          session: info?.label || session,
          tab: index < 0 ? undefined : info?.windows?.[index]?.label || String(index + 1),
        },
      };
    }),
  );
};

export const resolveTargetHint = async (
  inventory: Target[],
  hint: string,
  inspect: InspectRex = inspectRex,
): Promise<Target[]> =>
  resolveTargets(/(?:^|\/)rex:/.test(hint) ? await enrichRexTargets(inventory, inspect) : inventory, hint);
