/** Fleet: every Ultimate instance on this machine, and those named in `remotes`, with what each is doing. */
import { readFile } from 'node:fs/promises'
import { hostname } from 'node:os'
import { join } from 'node:path'
import { defineExtension } from '@earendil-works/pi-durable'
import { arrange, expandHome, row, unreachable } from './lib.ts'
import type { Conversation, Status, Target } from './lib.ts'

// Only public host capabilities: a project extension cannot import the clone's modules.
type Host = {
  userHome: string
  projects(): Promise<{ name: string; root?: string; current: boolean; running?: { url: string } }[]>
  conversations(): Conversation[]
  invoke(name: string, action: string, args: unknown, signal: AbortSignal): Promise<unknown>
}
type Context = { host: Host; signal?: AbortSignal }

/** How long one instance may take to answer before its row says unreachable. */
const TIMEOUT = 3000
const DAY = 24 * 60 * 60_000

const object = (value: unknown) =>
  value && typeof value === 'object' && !Array.isArray(value) ? (value as Record<string, unknown>) : {}

/** `fleet.primary` and `remotes` from user settings, where registry.ts reads them too. */
async function settings(userHome: string) {
  const text = await readFile(join(userHome, '.ultimate/settings.json'), 'utf8').catch(() => '{}')
  const parsed = object(JSON.parse(text))
  const primary = object(parsed.fleet).primary
  return {
    primary: typeof primary === 'string' ? expandHome(primary, userHome) : undefined,
    remotes: Object.entries(object(parsed.remotes)).flatMap(([machine, projects]) =>
      Object.entries(object(projects)).flatMap(([name, url]) =>
        typeof url === 'string' ? [{ machine, name, url }] : [],
      ),
    ),
  }
}

/** Calls `extension/action` on another instance, admitted as its own origin. */
async function call(url: string, extension: string, action: string, args: unknown, signal: AbortSignal) {
  const response = await fetch(`${url}/api/extensions/${extension}/actions/${action}`, {
    method: 'POST',
    headers: { Origin: new URL(url).origin, 'Content-Type': 'application/json' },
    body: JSON.stringify({ args }),
    signal,
  })
  const body = object(await response.json().catch(() => ({})))
  if (response.status === 403) throw new Error('refused: not in its tailscale.allow')
  if (!response.ok) throw new Error(typeof body.error === 'string' ? body.error : `HTTP ${response.status}`)
  return body.result
}

async function probe(host: Host, target: Target, since: number, outer?: AbortSignal) {
  const signal = AbortSignal.any([AbortSignal.timeout(TIMEOUT), ...(outer ? [outer] : [])])
  try {
    const [status, conversations] = target.current
      ? [await host.invoke('status', 'status', { since }, signal), host.conversations()]
      : await Promise.all([
          call(target.url, 'status', 'status', { since }, signal),
          call(target.url, 'codemode', 'read', { op: 'conversations', args: [] }, signal),
        ])
    return row(target, status as Status, Array.isArray(conversations) ? (conversations as Conversation[]) : [])
  } catch (error) {
    const reason =
      error instanceof Error && error.name === 'TimeoutError'
        ? `no answer in ${TIMEOUT / 1000} s`
        : error instanceof Error
          ? error.message
          : String(error)
    return unreachable(target, reason)
  }
}

export const actions = {
  /** Every instance's row: this machine's running projects first, then `remotes` on other machines. */
  async list(_args: unknown, { host, signal }: Context) {
    const machine = hostname().split('.')[0]!
    const { primary, remotes } = await settings(host.userHome)
    const local: Target[] = (await host.projects()).flatMap((project) =>
      project.running || project.current
        ? [
            {
              name: project.name,
              ...(project.root ? { root: project.root } : {}),
              url: project.running?.url ?? '',
              machine,
              current: project.current,
            },
          ]
        : [],
    )
    // remotes is shared by every machine through dotfiles: this machine's own entries are already local.
    const remote: Target[] = remotes
      .filter((item) => item.machine !== machine)
      .map((item) => ({ name: item.name, url: item.url.replace(/\/$/, ''), machine: item.machine, current: false }))
    const since = Date.now() - DAY
    const rows = await Promise.all([...local, ...remote].map((target) => probe(host, target, since, signal)))
    return { machine, at: Date.now(), instances: arrange(rows, machine, primary) }
  },
}

/** The surface polls `list`; the trace counts those calls instead of writing each. */
export const pollActions = ['list']

export default defineExtension({ name: 'fleet' })
