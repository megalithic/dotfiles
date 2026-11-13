/**
 * Fleet's pure parts: which instances are hubs, which hub each belongs to, and one row of state per instance.
 * Hub roles follow home/.pi/agent/lib/registry.ts and states follow the rex-status extension, so the Fleet
 * screen, `bin/agents` and Rex tabs agree.
 */

/** An instance to probe: a running project on this machine, or one named in `remotes`. */
export type Target = { name: string; root?: string; url: string; machine: string; current: boolean }

/** The fields of the `status` action that Fleet reads. */
export type Status = {
  busy: number
  questions: { count: number; first?: { text: string; conversation: number } }
  failures?: { conversation: number; title?: string; error: string }[]
  providers?: { provider: string; state: string }[]
  head?: { behind: number }
}

/** A conversation summary as `codemode.read {op: 'conversations'}` lists it. */
export type Conversation = { id: number; title?: string; label?: string; busy?: boolean; concluded?: boolean }

export type State = 'blocked' | 'working' | 'idle' | 'unreachable'

export type Row = {
  name: string
  root?: string
  url: string
  machine: string
  current: boolean
  role?: 'primary' | 'secondary'
  /** The root of the deepest hub on this machine whose folder holds this instance. */
  hub?: string
  state: State
  /** Why it is unreachable. */
  error?: string
  question?: { text: string; conversation: number; more: number }
  working: { id: number; title: string }[]
  failures: { count: number; last?: { conversation: number; title?: string; error: string } }
  providers: string[]
  behind?: number
}

const within = (root: string, folder: string) =>
  root !== folder && root.startsWith(folder.endsWith('/') ? folder : `${folder}/`)

export const expandHome = (path: string, home: string) =>
  path === '~' ? home : path.startsWith('~/') ? `${home}${path.slice(1)}` : path

/**
 * Each local root's hub role: `primary` when it is `fleet.primary`, `secondary` when its folder holds another
 * running instance, as registry.ts decides.
 */
export function roles(roots: string[], primary?: string) {
  const role = new Map<string, 'primary' | 'secondary'>()
  for (const root of roots) {
    if (primary && root === primary) role.set(root, 'primary')
    else if (roots.some((other) => within(other, root))) role.set(root, 'secondary')
  }
  return role
}

/** The deepest hub among `hubs` whose folder holds `root`. */
export function hubOf(root: string, hubs: string[]) {
  return hubs.filter((hub) => within(root, hub)).toSorted((a, b) => b.length - a.length)[0]
}

/** The rex-status mapping: an open question blocks, a busy conversation works, else idle. */
export function state(status: Status): Exclude<State, 'unreachable'> {
  if (status.questions.count > 0) return 'blocked'
  if (status.busy > 0) return 'working'
  return 'idle'
}

/** One instance's row from its status and conversations. */
export function row(
  target: Target,
  status: Status,
  conversations: Conversation[],
): Omit<Row, 'role' | 'hub'> {
  const first = status.questions.first
  const failures = status.failures ?? []
  const last = failures[0]
  return {
    ...target,
    state: state(status),
    ...(first
      ? {
          question: {
            text: first.text.replace(/\s+/g, ' ').trim(),
            conversation: first.conversation,
            more: status.questions.count - 1,
          },
        }
      : {}),
    working: conversations
      .filter((conversation) => conversation.busy && conversation.title)
      .map(({ id, title }) => ({ id, title: title! })),
    failures: {
      count: failures.length,
      ...(last ? { last: { conversation: last.conversation, title: last.title, error: last.error } } : {}),
    },
    providers: (status.providers ?? [])
      .filter((provider) => provider.state === 'failing')
      .map((provider) => provider.provider),
    ...(status.head ? { behind: status.head.behind } : {}),
  }
}

/** A row for an instance that did not answer. */
export function unreachable(target: Target, error: string): Omit<Row, 'role' | 'hub'> {
  return { ...target, state: 'unreachable', error, working: [], failures: { count: 0 }, providers: [] }
}

/** Adds hub roles and memberships to this machine's rows; remote rows stay as they are. */
export function arrange(rows: Omit<Row, 'role' | 'hub'>[], machine: string, primary?: string): Row[] {
  // Every running local instance counts, answering or not, as in registry.ts.
  const local = rows.filter((item) => item.machine === machine && item.root)
  const role = roles(
    local.map((item) => item.root!),
    primary,
  )
  const hubs = [...role.keys()]
  return rows.map((item) => {
    if (item.machine !== machine || !item.root) return item
    const hub = hubOf(item.root, hubs)
    return {
      ...item,
      ...(role.has(item.root) ? { role: role.get(item.root) } : {}),
      ...(hub ? { hub } : {}),
    }
  })
}
