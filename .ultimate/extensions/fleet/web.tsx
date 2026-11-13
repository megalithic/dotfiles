import { useEffect } from 'react'
import type { ReactNode } from 'react'
import { ArrowUpRightIcon, NetworkIcon } from 'lucide-react'
import {
  Conversation,
  Dock,
  Header,
  StatusLine,
  actionRef,
  cn,
  defineWebExtension,
  shortenPath,
  useAction,
  useSystem,
  useUltimate,
} from '@/sdk'
import type { Row, State } from './lib.ts'

type Fleet = { machine: string; at: number; instances: Row[] }

/** Every instance's row: this machine's running projects, then `remotes` elsewhere. */
const ListAction = actionRef<null, Fleet>('fleet', 'list')

/** The fleet, polled every `ms` while mounted. */
function useFleet(ms: number) {
  const fleet = useAction(ListAction, null, { onError: () => {} })
  const { refetch } = fleet
  useEffect(() => {
    const timer = setInterval(() => void refetch(), ms)
    return () => clearInterval(timer)
  }, [refetch, ms])
  return fleet
}

/** Where an instance opens: a remote's own URL; a local one on this page's host, so tailnet pages stay on the tailnet. */
function href(row: Row, local: boolean, conversation?: number) {
  const base = local
    ? `${window.location.protocol}//${window.location.hostname}:${new URL(row.url).port}`
    : row.url
  return conversation === undefined ? base : `${base}/?conversation=${conversation}`
}

const dot: Record<State, string> = {
  blocked: 'bg-amber-400',
  working: 'animate-pulse-dot bg-brand',
  idle: 'bg-muted-foreground/40',
  unreachable: 'bg-error',
}

/** The data-status hook of the sidebar's dots, for themes. */
const status: Record<State, string> = {
  blocked: 'waiting',
  working: 'working',
  idle: 'idle',
  unreachable: 'failed',
}

function count(rows: Row[], state: State) {
  return rows.filter((row) => row.state === state).length
}

/** "3 instances · 1 blocked · 2 working", leaving out what is zero. */
function summary(rows: Row[]) {
  return [
    `${rows.length} ${rows.length === 1 ? 'instance' : 'instances'}`,
    ...(['blocked', 'working', 'unreachable'] as const).flatMap((state) => {
      const n = count(rows, state)
      return n ? [`${n} ${state}`] : []
    }),
  ].join(' · ')
}

/** A link to a conversation in an instance: here it switches the docked conversation, elsewhere it opens a tab. */
function Jump({
  row,
  local,
  conversation,
  className,
  children,
}: {
  row: Row
  local: boolean
  conversation: number
  className?: string
  children: ReactNode
}) {
  const { switchConversation } = useUltimate()
  if (row.current)
    return (
      <button
        className={cn('min-w-0 truncate text-left hover:underline', className)}
        onClick={() => switchConversation(conversation)}
        type="button"
      >
        {children}
      </button>
    )
  return (
    <a
      className={cn('min-w-0 truncate hover:underline', className)}
      href={href(row, local, conversation)}
      rel="noreferrer"
      target="_blank"
    >
      {children}
    </a>
  )
}

function Instance({ row, local, nested }: { row: Row; local: boolean; nested?: boolean }) {
  const home = useSystem()?.machine.home
  const working = row.working.slice(0, 3)
  return (
    <div className={cn('flex gap-2.5 px-4 py-2.5', nested && 'pl-9')}>
      <span
        className={cn('mt-[7px] size-1.5 shrink-0 rounded-full', dot[row.state])}
        data-status={status[row.state]}
        title={row.state}
      />
      <div className="min-w-0 flex-1">
        <div className="flex min-w-0 items-baseline gap-2">
          <span className="truncate text-[13px] text-foreground">{row.name}</span>
          {row.role && (
            <span className="shrink-0 font-mono text-[10px] text-muted-foreground uppercase">
              {row.role === 'primary' ? 'primary hub' : 'hub'}
            </span>
          )}
          {row.current && <span className="shrink-0 font-mono text-[10px] text-brand">this one</span>}
          <span className="min-w-0 truncate font-mono text-[11px] text-muted-foreground/70">
            {row.root ? shortenPath(row.root, { home }) : row.url}
          </span>
        </div>
        {row.state === 'unreachable' && (
          <p className="mt-0.5 truncate font-mono text-[11px] text-error">{row.error}</p>
        )}
        {row.question && (
          <p className="mt-0.5 flex min-w-0 gap-1.5 text-[12px] text-amber-700 dark:text-amber-300">
            <Jump conversation={row.question.conversation} local={local} row={row}>
              {row.question.text}
            </Jump>
            {row.question.more > 0 && (
              <span className="shrink-0 font-mono text-[11px]">+{row.question.more}</span>
            )}
          </p>
        )}
        {working.length > 0 && (
          <p className="mt-0.5 flex min-w-0 flex-wrap gap-x-3 text-[12px] text-muted-foreground">
            {working.map((item) => (
              <Jump className="max-w-64" conversation={item.id} key={item.id} local={local} row={row}>
                {item.title}
              </Jump>
            ))}
            {row.working.length > working.length && (
              <span className="font-mono text-[11px]">+{row.working.length - working.length}</span>
            )}
          </p>
        )}
        {(row.failures.count > 0 || row.providers.length > 0) && (
          <p className="mt-0.5 flex min-w-0 gap-3 font-mono text-[11px] text-error">
            {row.failures.last && (
              <Jump conversation={row.failures.last.conversation} local={local} row={row}>
                {row.failures.count} failed today · {row.failures.last.title ?? `#${row.failures.last.conversation}`}:{' '}
                {row.failures.last.error}
              </Jump>
            )}
            {row.providers.length > 0 && (
              <span className="shrink-0">{row.providers.join(', ')} failing</span>
            )}
          </p>
        )}
      </div>
      {!row.current && row.state !== 'unreachable' && (
        <a
          className="flex h-6 shrink-0 items-center gap-1 rounded px-1.5 font-mono text-[11px] text-muted-foreground hover:bg-accent hover:text-foreground"
          href={href(row, local)}
          rel="noreferrer"
          target="_blank"
          title={`Open ${row.name}`}
        >
          open
          <ArrowUpRightIcon className="size-3" />
        </a>
      )}
    </div>
  )
}

/** One machine's instances: hubs first with their members under them, then the rest. */
function Machine({ name, rows, local }: { name: string; rows: Row[]; local: boolean }) {
  const order = (row: Row) => (row.role === 'primary' ? 0 : row.role === 'secondary' ? 1 : 2)
  const top = rows.filter((row) => !row.hub).toSorted((a, b) => order(a) - order(b) || a.name.localeCompare(b.name))
  const members = (hub: string): Row[] =>
    rows
      .filter((row) => row.hub === hub)
      .toSorted((a, b) => a.name.localeCompare(b.name))
      .flatMap((row) => [row, ...(row.root && row.role ? members(row.root) : [])])
  return (
    <section className="border-b border-border/70">
      <h2 className="flex items-baseline gap-2 px-4 pt-3 pb-1 font-mono text-[11px] text-muted-foreground">
        <span className="text-foreground/80">{name}</span>
        {local && <span>this machine</span>}
        <span className="ml-auto">{summary(rows)}</span>
      </h2>
      <div className="divide-y divide-border/40">
        {top.map((row) => (
          <div key={row.url || row.name}>
            <Instance local={local} row={row} />
            {row.root &&
              members(row.root).map((member) => (
                <Instance key={member.url || member.name} local={local} nested row={member} />
              ))}
          </div>
        ))}
      </div>
    </section>
  )
}

function FleetSurface() {
  const fleet = useFleet(10_000)
  const data = fleet.data
  const machines = data
    ? [data.machine, ...new Set(data.instances.map((row) => row.machine).filter((name) => name !== data.machine))]
    : []
  return (
    <>
      <Header>
        <span className="text-[13px]">Fleet</span>
        {data && (
          <span className="font-mono text-[11px] text-muted-foreground">{summary(data.instances)}</span>
        )}
      </Header>
      <div className="flex min-h-0 flex-1">
        <main className="min-w-0 flex-1 overflow-y-auto">
          {!data && (
            <p className="px-4 py-3 font-mono text-[12px] text-muted-foreground">
              {fleet.error ? `fleet: ${fleet.error.message}` : 'looking for instances…'}
            </p>
          )}
          {machines.map((machine) => (
            <Machine
              key={machine}
              local={machine === data!.machine}
              name={machine}
              rows={data!.instances.filter((row) => row.machine === machine)}
            />
          ))}
        </main>
        <Dock>
          <Conversation variant="dock" />
        </Dock>
      </div>
      <StatusLine />
    </>
  )
}

/** The status line's fleet summary; it opens the Fleet surface. */
function FleetStatus() {
  const { data } = useFleet(30_000)
  const { showSurface, surface } = useUltimate()
  if (!data || surface === 'fleet') return null
  const blocked = count(data.instances, 'blocked')
  const working = count(data.instances, 'working')
  const down = count(data.instances, 'unreachable')
  return (
    <button
      className="flex items-center gap-1.5 text-muted-foreground hover:text-foreground"
      onClick={() => showSurface('fleet')}
      title="Show the Fleet"
      type="button"
    >
      <NetworkIcon className="size-3" />
      {data.instances.length}
      {blocked > 0 && <span className="text-amber-700 dark:text-amber-300">· {blocked} blocked</span>}
      {working > 0 && <span>· {working} working</span>}
      {down > 0 && <span className="text-error">· {down} down</span>}
    </button>
  )
}

export default defineWebExtension({
  surfaces: [
    {
      id: 'fleet',
      title: 'Fleet',
      icon: NetworkIcon,
      description: 'Every Ultimate instance and what it is doing',
      component: FleetSurface,
    },
  ],
  slots: { 'statusline.right': [FleetStatus] },
})
