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
  reachable?: boolean;
  unreachableReason?: string;
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
type MessagingRegistry = Pick<Registry, 'machine' | 'pis' | 'ultimates'>;

export const registryTargets = (registry: MessagingRegistry, host?: string): Target[] => [
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

/** Shared by exact legacy routing and the picker's partial-address filter. */
export const targetAliases = (target: Target): string[] => {
  const aliases = [target.id, target.socket, target.pi?.sessionId, target.pi?.sessionName].flatMap((value) =>
    value ? [value] : [],
  );

  const tmux = target.pi?.tmux;

  if (tmux) {
    aliases.push(tmux.session, `tmux:${tmux.session}`);
    const windows = new Set([tmux.window, tmux.windowIndex].flatMap((value) => (value ? [value] : [])));
    const panes = new Set([tmux.pane, tmux.paneIndex].flatMap((value) => (value ? [value] : [])));
    aliases.push(...panes);

    for (const window of windows) {
      const address = `${tmux.session}:${window}`;
      aliases.push(window, address, `tmux:${address}`);

      if (tmux.pane) aliases.push(`${address} ${tmux.pane}`);

      for (const pane of panes) aliases.push(`${address}.${pane}`, `tmux:${address}.${pane}`);
    }
  }

  const rex = target.rex;

  for (const session of new Set([rex?.session, target.pi?.rex?.session].flatMap((value) => (value ? [value] : [])))) {
    const address = `rex:${session}`;
    aliases.push(address);

    if (rex?.tab) aliases.push(`${address}/${rex.tab}`);

    if (rex?.block) {
      aliases.push(`${address}#${rex.block}`);

      if (rex.tab) aliases.push(`${address}/${rex.tab}#${rex.block}`);
    }
  }

  if (target.ultimate) {
    aliases.push(`ultimate:${path.basename(target.ultimate.project)}`);

    if (target.ultimate.hub === 'primary') aliases.push('ultimate:hub');
  }

  return aliases;
};

export const matchesTargetQuery = (target: Target, query: string): boolean =>
  [target.kind, target.label, target.cwd, ...targetAliases(target)]
    .join(' ')
    .toLowerCase()
    .includes(query.toLowerCase());

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

  const exact = targets.filter((target) => targetAliases(target).includes(hint));

  if (exact.length) return exact;
  const query = hint.toLowerCase();

  return targets.filter((target) => !target.current && matchesTargetQuery(target, query));
};
