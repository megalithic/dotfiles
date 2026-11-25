import type { ConversationId } from '@earendil-works/pi-durable'
import type { JSX } from '@solidjs/web'
import { For, Show } from 'solid-js'
import { ArrowUpRightIcon, NetworkIcon } from '@lucide/solid'
import { Button } from '@/components/ui/button.solid.tsx'
import {
  Conversation,
  Dock,
  Header,
  StatusLine,
  actionRef,
  cn,
  defineWebExtension,
  shortenPath,
  keepLast,
  useAction,
  useSystem,
  useSurface,
  showSurface,
  switchConversation,
} from '@/sdk/solid'
import { href } from './links.ts'
import type { Row, State } from './lib.ts'

type Fleet = { machine: string; at: number; instances: Row[] }
const ListAction = actionRef<null, Fleet>('fleet', 'list')
function useFleet(ms: number) {
  return useAction(ListAction, null, { onError: keepLast, every: ms })
}
const dot: Record<State, string> = {
  blocked: 'bg-amber-400',
  working: 'animate-pulse-dot bg-brand',
  idle: 'bg-muted-foreground/40',
  unreachable: 'bg-error',
}
const status: Record<State, string> = {
  blocked: 'waiting',
  working: 'working',
  idle: 'idle',
  unreachable: 'failed',
}
function count(rows: Row[], state: State) {
  return rows.filter((row) => row.state === state).length
}
function summary(rows: Row[]) {
  return [
    `${rows.length} ${rows.length === 1 ? 'instance' : 'instances'}`,
    ...(['blocked', 'working', 'unreachable'] as const).flatMap((state) => {
      const n = count(rows, state)
      return n ? [`${n} ${state}`] : []
    }),
  ].join(' · ')
}
function Jump(props: {
  row: Row
  local: boolean
  conversation: number
  class?: string
  children: JSX.Element
  kind: string
}) {
  const link = () => href(props.row, props.local, window.location, props.conversation)
  return (
    <Show
      when={props.row.current}
      fallback={
        <Show
          when={link()}
          fallback={<span class={cn('min-w-0 truncate', props.class)}>{props.children}</span>}
        >
          {(url) => (
            <a
              class={cn('min-w-0 truncate hover:underline', props.class)}
              href={url()}
              rel="noreferrer"
              target="_blank"
            >
              {props.children}
            </a>
          )}
        </Show>
      }
    >
      <Button
        aria-label={`${props.kind}: ${props.row.name} #${props.conversation}`}
        class={cn(
          'inline-block h-auto min-w-0 shrink truncate text-left text-[length:inherit] font-normal hover:underline',
          props.class,
        )}
        onClick={() => switchConversation(props.conversation as ConversationId)}
        size={null}
        variant={null}
      >
        {props.children}
      </Button>
    </Show>
  )
}
function Instance(props: { row: Row; local: boolean; nested?: boolean }) {
  const system = useSystem()
  const working = () => props.row.working.slice(0, 3)
  const link = () => href(props.row, props.local, window.location)
  return (
    <div class={cn('flex gap-2.5 px-4 py-2.5', props.nested && 'pl-9')}>
      <span
        class={cn('mt-[7px] size-1.5 shrink-0 rounded-full', dot[props.row.state])}
        data-status={status[props.row.state]}
        title={props.row.state}
      />
      <div class="min-w-0 flex-1">
        <div class="flex min-w-0 items-baseline gap-2">
          <span class="truncate text-[13px] text-foreground">{props.row.name}</span>
          <Show when={props.row.role}>
            <span class="shrink-0 font-mono text-[10px] text-muted-foreground uppercase">
              {props.row.role === 'primary' ? 'primary hub' : 'hub'}
            </span>
          </Show>
          <Show when={props.row.current}>
            <span class="shrink-0 font-mono text-[10px] text-brand">this one</span>
          </Show>
          <span class="min-w-0 truncate font-mono text-[11px] text-muted-foreground/70">
            {props.row.root
              ? shortenPath(props.row.root, { home: system()?.machine.home })
              : props.row.url}
          </span>
        </div>
        <Show when={props.row.state === 'unreachable'}>
          <p class="mt-0.5 truncate font-mono text-[11px] text-error">{props.row.error}</p>
        </Show>
        <Show when={props.row.question}>
          {(question) => (
            <p class="mt-0.5 flex min-w-0 gap-1.5 text-[12px] text-amber-700 dark:text-amber-300">
              <Jump
                kind="Question"
                conversation={question().conversation}
                local={props.local}
                row={props.row}
              >
                {question().text}
              </Jump>
              <Show when={question().more > 0}>
                <span class="shrink-0 font-mono text-[11px]">+{question().more}</span>
              </Show>
            </p>
          )}
        </Show>
        <Show when={working().length > 0}>
          <p class="mt-0.5 flex min-w-0 flex-wrap gap-x-3 text-[12px] text-muted-foreground">
            <For each={working()} keyed={(item) => item.id}>
              {(item) => (
                <Jump
                  kind="Working conversation"
                  class="max-w-64"
                  conversation={item().id}
                  local={props.local}
                  row={props.row}
                >
                  {item().title}
                </Jump>
              )}
            </For>
            <Show when={props.row.working.length > working().length}>
              <span class="font-mono text-[11px]">
                +{props.row.working.length - working().length}
              </span>
            </Show>
          </p>
        </Show>
        <Show when={props.row.failures.count > 0 || props.row.providers.length > 0}>
          <p class="mt-0.5 flex min-w-0 gap-3 font-mono text-[11px] text-error">
            <Show when={props.row.failures.last}>
              {(last) => (
                <Jump
                  kind="Failed conversation"
                  conversation={last().conversation}
                  local={props.local}
                  row={props.row}
                >
                  {props.row.failures.count} failed today ·{' '}
                  {last().title ?? `#${last().conversation}`}: {last().error}
                </Jump>
              )}
            </Show>
            <Show when={props.row.providers.length > 0}>
              <span class="shrink-0">{props.row.providers.join(', ')} failing</span>
            </Show>
          </p>
        </Show>
      </div>
      <Show when={!props.row.current && props.row.state !== 'unreachable' && link()}>
        {(url) => (
          <a
            aria-label={`Open ${props.row.machine}: ${props.row.name}`}
            class="flex h-6 shrink-0 items-center gap-1 rounded px-1.5 font-mono text-[11px] text-muted-foreground hover:bg-accent hover:text-foreground"
            href={url()}
            rel="noreferrer"
            target="_blank"
            title={`Open ${props.row.name}`}
          >
            open
            <ArrowUpRightIcon class="size-3" />
          </a>
        )}
      </Show>
    </div>
  )
}
function Machine(props: { name: string; rows: Row[]; local: boolean }) {
  const order = (row: Row) => (row.role === 'primary' ? 0 : row.role === 'secondary' ? 1 : 2)
  const top = () =>
    props.rows
      .filter((row) => !row.hub)
      .toSorted((a, b) => order(a) - order(b) || a.name.localeCompare(b.name))
  const members = (hub: string): Row[] =>
    props.rows
      .filter((row) => row.hub === hub)
      .toSorted((a, b) => a.name.localeCompare(b.name))
      .flatMap((row) => [row, ...(row.root && row.role ? members(row.root) : [])])
  return (
    <section class="border-b border-border/70">
      <h2 class="flex items-baseline gap-2 px-4 pt-3 pb-1 font-mono text-[11px] text-muted-foreground">
        <span class="text-foreground/80">{props.name}</span>
        <Show when={props.local}>
          <span>this machine</span>
        </Show>
        <span class="ml-auto">{summary(props.rows)}</span>
      </h2>
      <div class="divide-y divide-border/40">
        <For each={top()} keyed={(row) => row.url || row.name}>
          {(row) => (
            <div>
              <Instance local={props.local} row={row()} />
              <Show when={row().root}>
                {(root) => (
                  <For each={members(root())} keyed={(member) => member.url || member.name}>
                    {(member) => <Instance local={props.local} nested row={member()} />}
                  </For>
                )}
              </Show>
            </div>
          )}
        </For>
      </div>
    </section>
  )
}
function FleetSurface() {
  const fleet = useFleet(10_000)
  const data = fleet.data
  const machines = () => {
    const current = data()
    return current
      ? [
          current.machine,
          ...new Set(
            current.instances.map((row) => row.machine).filter((name) => name !== current.machine),
          ),
        ]
      : []
  }
  return (
    <>
      <Header>
        <span class="text-[13px]">Fleet</span>
        <Show when={data()}>
          {(value) => (
            <span class="font-mono text-[11px] text-muted-foreground">
              {summary(value().instances)}
            </span>
          )}
        </Show>
      </Header>
      <div class="flex min-h-0 flex-1">
        <main class="min-w-0 flex-1 overflow-y-auto">
          <Show when={!data()}>
            <p class="px-4 py-3 font-mono text-[12px] text-muted-foreground">
              {fleet.error() ? `fleet: ${fleet.error()!.message}` : 'looking for instances…'}
            </p>
          </Show>
          <For each={machines()}>
            {(machine) => (
              <Machine
                local={machine === data()!.machine}
                name={machine}
                rows={data()!.instances.filter((row) => row.machine === machine)}
              />
            )}
          </For>
        </main>
        <Dock>
          <Conversation variant="dock" />
        </Dock>
      </div>
      <StatusLine />
    </>
  )
}
function FleetStatus() {
  const { data } = useFleet(30_000)
  const surface = useSurface()
  const blocked = () => count(data()?.instances ?? [], 'blocked')
  const working = () => count(data()?.instances ?? [], 'working')
  const down = () => count(data()?.instances ?? [], 'unreachable')
  return (
    <Show when={data() && surface() !== 'fleet'}>
      <Button
        aria-label="Show the Fleet"
        class="flex h-auto items-center gap-1.5 text-[length:inherit] font-normal text-muted-foreground hover:text-foreground"
        onClick={() => showSurface('fleet')}
        title="Show the Fleet"
        size={null}
        variant={null}
      >
        <NetworkIcon class="size-3" />
        {data()!.instances.length}
        <Show when={blocked() > 0}>
          <span class="text-amber-700 dark:text-amber-300">· {blocked()} blocked</span>
        </Show>
        <Show when={working() > 0}>
          <span>· {working()} working</span>
        </Show>
        <Show when={down() > 0}>
          <span class="text-error">· {down()} down</span>
        </Show>
      </Button>
    </Show>
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
