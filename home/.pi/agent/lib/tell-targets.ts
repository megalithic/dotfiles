import path from 'node:path';
import type { Registry } from './registry.ts';

export type Target = {
  kind: 'pi' | 'tmux' | 'rex' | 'ultimate';
  id: string;
  machine: string;
  host?: string;
  label: string;
  socket: string;
  cwd: string;
  state?: string;
  current: boolean;
  rex?: { session?: string; tab?: string; block?: string };
  pi?: Registry['pis'][number];
  ultimate?: Registry['ultimates'][number];
};

export const sessionTarget = (machine: string, sessionId: string): string =>
  `pi:${machine}:${encodeURIComponent(sessionId)}`;

export const parseSessionTarget = (target: string): { machine: string; sessionId: string } | undefined => {
  const match = /^pi:([^:/\s]+):([^:\s]+)$/.exec(target);

  if (!match) return undefined;

  try {
    return { machine: match[1]!, sessionId: decodeURIComponent(match[2]!) };
  } catch {
    return undefined;
  }
};

/** Machine prefixes do not consume slashes inside Rex addresses or folder hints. */
export const targetRoute = (target: string) => {
  const prefix = /^([^/:\s]+)\/(.+)$/.exec(target);

  if (prefix && !['.', '..', '~'].includes(prefix[1]!)) return { machine: prefix[1], target: prefix[2]! };

  return { machine: parseSessionTarget(target)?.machine, target };
};

/** A Pi is listed once, under its most specific terminal kind. All aliases still resolve. */
export const registryTargets = (registry: Registry, host?: string): Target[] => [
  ...registry.pis.map((pi): Target => {
    const kind = pi.tmux ? 'tmux' : pi.rex ? 'rex' : 'pi';

    return {
      kind,
      id: pi.id,
      machine: registry.machine,
      host,
      label: pi.sessionName || path.basename(pi.cwd) || pi.id,
      socket: pi.socket,
      cwd: pi.cwd,
      state: pi.state,
      current: !host && pi.pid === process.pid,
      pi,
      rex: pi.rex,
    };
  }),
  ...registry.ultimates.map((ultimate): Target => ({
    kind: 'ultimate',
    id: `ultimate:${ultimate.project}`,
    machine: registry.machine,
    host,
    label: `${ultimate.project}${ultimate.hub ? ` · ${ultimate.hub} hub` : ''}`,
    socket: ultimate.url,
    cwd: ultimate.project,
    current: false,
    ultimate,
  })),
];

/** Pure resolution: explicit kind addresses never fall back to fuzzy matching. */
export const resolveTargets = (inventory: Target[], raw: string): Target[] => {
  const route = targetRoute(raw.trim());

  const onMachine = (target: Target, machine: string) =>
    [target.machine, target.host].includes(machine) || (!target.host && ['localhost', '127.0.0.1'].includes(machine));

  const targets = inventory.filter((target) => !route.machine || onMachine(target, route.machine));
  const hint = route.target;
  const identity = parseSessionTarget(hint);

  if (identity)
    return targets.filter(
      (target) =>
        onMachine(target, identity.machine) && (target.pi?.sessionId === identity.sessionId || target.id === hint),
    );

  if (hint.startsWith('pi:')) return [];

  if (hint.startsWith('tmux:')) {
    const match = /^tmux:([^:]+)(?::([^.]*)?(?:\.(.+))?)?$/.exec(hint);

    if (!match) return [];

    return targets.filter(
      ({ pi }) =>
        pi?.tmux?.session === match[1] &&
        (!match[2] || pi.tmux.window === match[2] || pi.tmux.windowIndex === match[2]) &&
        (!match[3] || pi.tmux.pane === match[3] || pi.tmux.paneIndex === match[3]),
    );
  }

  if (hint.startsWith('rex:')) {
    const match = /^rex:([^/#]+)(?:\/([^#]+))?(?:#(.+))?$/.exec(hint);

    if (!match) return [];

    return targets.filter(
      ({ pi, rex }) =>
        (rex?.session === match[1] || pi?.rex?.session === match[1]) &&
        (!match[2] || rex?.tab === match[2]) &&
        (!match[3] || rex?.block === match[3]),
    );
  }

  if (hint.startsWith('ultimate:')) {
    const project = hint.slice('ultimate:'.length);

    return targets.filter(
      ({ ultimate }) =>
        ultimate &&
        (project === 'hub'
          ? ultimate.hub === 'primary'
          : ultimate.project === project || path.basename(ultimate.project) === project),
    );
  }

  const exact = targets.filter((target) =>
    [target.id, target.socket, target.pi?.sessionName, target.pi?.sessionId].includes(hint),
  );

  if (exact.length) return exact;
  const query = hint.toLowerCase();

  return targets.filter((target) => !target.current && `${target.label} ${target.cwd}`.toLowerCase().includes(query));
};
