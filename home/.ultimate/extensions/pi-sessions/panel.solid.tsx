import { createSignal, createMemo, For, Show } from 'solid-js'
import { ArrowLeftIcon, ChevronRightIcon, HandIcon, RotateCwIcon, Undo2Icon } from '@lucide/solid'
import { Button } from '@/components/ui/button.solid.tsx'
import {
  api,
  cn,
  formatAgo,
  shortenPath,
  useAction,
  useNow,
  useSystem,
  writingAs,
  keepLast,
} from '@/sdk/solid'
import {
  Act,
  BatonChip,
  Confirm,
  HolderLink,
  PickupAction,
  SessionAction,
  SessionsAction,
  StateDot,
  label,
  release,
  stateText,
  topState,
} from './parts.solid.tsx'
import type { Worktree } from './parts.solid.tsx'
import { useShow } from './parts.solid.tsx'
import { Brief } from './brief.solid.tsx'

const name = (row: Worktree) => (row.main ? 'main' : (row.path.split('/').at(-1) ?? row.path))
function summary(rows: Worktree[]) {
  const pis = rows.flatMap((row) => row.pis)
  const count = (state: string) => pis.filter((pi) => pi.state === state).length
  const waiting = count('input_needed') + count('asking')
  return [
    `${rows.length} ${rows.length === 1 ? 'worktree' : 'worktrees'}`,
    count('working') && `${count('working')} working`,
    waiting && `${waiting} waiting`,
  ]
    .filter(Boolean)
    .join(' · ')
}
type Mode = 'pickup' | 'release' | undefined
function Moves(props: {
  row: Worktree
  mode: Mode
  setMode: (mode: Mode) => void
  refetch: () => unknown
}) {
  const show = useShow()
  const working = () => props.row.pis.find((pi) => pi.state === 'working')
  const held = () => props.row.baton?.holder === 'ultimate'
  return (
    <Show
      when={props.mode === 'pickup'}
      fallback={
        <Show
          when={props.mode === 'release'}
          fallback={
            <div class="flex shrink-0 items-center gap-0.5">
              <Show when={held() && props.row.baton}>
                {(baton) => (
                  <HolderLink
                    baton={baton()}
                    name={`Open baton conversation for ${props.row.path}`}
                    class="hover:no-underline"
                  />
                )}
              </Show>
              <Show
                when={held()}
                fallback={
                  <Act
                    aria-label={`Pick up ${props.row.path}`}
                    disabled={!!working()}
                    onClick={() => props.setMode('pickup')}
                    primary
                    title={
                      working()
                        ? `pi ${working()!.label ?? working()!.pid} is working; pick up once it stops`
                        : 'Continue in a new Ultimate conversation that holds the baton'
                    }
                  >
                    <HandIcon />
                    pick up
                  </Act>
                }
              >
                <Act
                  aria-label={`Release ${props.row.path}`}
                  onClick={() => props.setMode('release')}
                  primary
                  title="Hand the baton back to pi"
                >
                  <Undo2Icon />
                  release
                </Act>
              </Show>
            </div>
          }
        >
          <Confirm
            name={props.row.path}
            action="Hand back to pi"
            busyLabel="Handing back…"
            hint={
              props.row.pis.length
                ? `The summary goes to pi ${props.row.pis[0]!.label ?? props.row.pis[0]!.pid}.`
                : 'No live pi: its rex agent tab restarts with the summary.'
            }
            onCancel={() => props.setMode(undefined)}
            placeholder="Summary for pi (optional): what changed, what's next"
            onConfirm={(text, source) => {
              const setMode = props.setMode
              const refetch = props.refetch
              return release(props.row.path, text, props.row.baton?.ultimate?.conversation).then(
                () =>
                  writingAs(source, () => {
                    setMode(undefined)
                    void refetch()
                  }),
              )
            }}
          />
        </Show>
      }
    >
      <Confirm
        name={props.row.path}
        action="Pick up"
        busyLabel="Picking up…"
        hint="A new conversation works in this checkout and holds the baton; pi cannot edit until you release."
        onCancel={() => props.setMode(undefined)}
        placeholder="Goal for Ultimate (optional): continue pi's work"
        onConfirm={(goal, source) => {
          const setMode = props.setMode
          const refetch = props.refetch
          return api
            .action(PickupAction, { cwd: props.row.path, ...(goal ? { goal } : {}) })
            .then((result) =>
              writingAs(source, () => {
                setMode(undefined)
                void refetch()
                show(result.conversation)
              }),
            )
        }}
      />
    </Show>
  )
}
function Meta(props: { row: Worktree; now: number }) {
  const system = useSystem()
  return (
    <div class="flex min-w-0 items-baseline gap-2 font-mono text-[11px] text-muted-foreground/75">
      <span class="min-w-0 truncate" title={props.row.path}>
        {shortenPath(props.row.path, { home: system()?.machine.home })}
      </span>
      <span class="ml-auto flex shrink-0 gap-2">
        {props.row.dirty > 0 && (
          <span class="text-warning/90" title={`${props.row.dirty} uncommitted files`}>
            ±{props.row.dirty}
          </span>
        )}
        {props.row.ahead ? (
          <span title={`${props.row.ahead} commits ahead of main`}>↑{props.row.ahead}</span>
        ) : null}
        {props.row.sessionAt && (
          <span title={`Session saved ${props.row.sessionAt}`}>
            {formatAgo(Date.parse(props.row.sessionAt), props.now)}
          </span>
        )}
      </span>
    </div>
  )
}
function Pis(props: { row: Worktree; all?: boolean }) {
  const max = () => (props.all ? Infinity : 2)
  const order = ['working', 'input_needed', 'asking', 'error']
  const pis = () =>
    props.row.pis.toSorted(
      (a, b) => (order.indexOf(a.state) + 1 || 9) - (order.indexOf(b.state) + 1 || 9),
    )
  return (
    <Show when={pis().length}>
      <ul class="mt-1 flex flex-col gap-0.5">
        <For each={pis().slice(0, max())} keyed={(pi) => pi.sessionId ?? pi.pid}>
          {(pi) => (
            <li class="flex min-w-0 items-baseline gap-2 text-[12px]">
              <span
                class={cn(
                  'w-[74px] shrink-0 font-mono text-[11px] text-muted-foreground',
                  stateText[pi().state],
                )}
              >
                {label(pi().state)}
              </span>
              <span class="min-w-0 truncate text-muted-foreground" title={pi().label}>
                {pi().label ?? `pid ${pi().pid}`}
              </span>
            </li>
          )}
        </For>
        {pis().length > max() && (
          <li class="pl-[82px] font-mono text-[11px] text-muted-foreground/60">
            +{pis().length - max()} more
          </li>
        )}
      </ul>
    </Show>
  )
}
function Row(props: { row: Worktree; now: number; onOpen: () => void; refetch: () => unknown }) {
  const [mode, setMode] = createSignal<Mode>()
  return (
    <li class="group/row px-3 py-2.5" data-worktree={props.row.path}>
      <div class="flex min-w-0 items-center gap-2">
        <StateDot state={topState(props.row.pis)} />
        <Button
          aria-label={`Read pi's session: ${props.row.path}`}
          class="flex min-w-0 flex-1 items-center gap-2 text-left font-normal whitespace-normal"
          size={null}
          variant={null}
          onClick={props.onOpen}
          title="Read pi's session"
          type="button"
        >
          <span class="truncate text-[13px] text-foreground group-hover/row:underline">
            {name(props.row)}
          </span>
          {props.row.branch && props.row.branch !== name(props.row) && (
            <span class="min-w-0 truncate font-mono text-[11px] text-muted-foreground/75">
              {props.row.branch}
            </span>
          )}
          <ChevronRightIcon class="size-3 shrink-0 text-muted-foreground/50" />
        </Button>
        <BatonChip baton={props.row.baton} />
      </div>
      <div class="pl-3.5">
        <Meta now={props.now} row={props.row} />
        <Pis row={props.row} />
        <div class={cn(!mode() && '-mr-1.5 mt-1 flex justify-end')}>
          <Moves mode={mode()} refetch={props.refetch} row={props.row} setMode={setMode} />
        </div>
      </div>
    </li>
  )
}
function Session(props: { row: Worktree; onBack: () => void; refetch: () => unknown }) {
  const brief = useAction(
    SessionAction,
    {
      get worktree() {
        return props.row.path
      },
    },
    { onError: keepLast },
  )
  const [mode, setMode] = createSignal<Mode>()
  const now = useNow(60_000)
  return (
    <div class="flex min-h-0 flex-col">
      <div class="sticky top-0 z-10 border-b border-border/60 bg-background px-3 pt-1.5 pb-2.5">
        <div class="flex min-w-0 items-center gap-1.5">
          <Act class="-ml-1.5" onClick={props.onBack} title="All worktrees">
            <ArrowLeftIcon />
            worktrees
          </Act>
          <Act
            aria-label={`Refresh session: ${props.row.path}`}
            class="ml-auto"
            disabled={brief.loading()}
            onClick={() => brief.refetch()}
            title="Read the session again"
          >
            <RotateCwIcon class={cn(brief.loading() && 'animate-spin')} />
          </Act>
        </div>
        <div class="mt-1 flex min-w-0 items-center gap-2">
          <StateDot state={topState(props.row.pis)} />
          <span class="truncate text-[14px] font-medium text-foreground">{name(props.row)}</span>
          {props.row.branch && props.row.branch !== name(props.row) && (
            <span class="min-w-0 truncate font-mono text-[11px] text-muted-foreground/75">
              {props.row.branch}
            </span>
          )}
          <span class="ml-auto" />
          <BatonChip baton={props.row.baton} />
        </div>
        <div class="pl-3.5">
          <Meta now={now()} row={props.row} />
          <Pis all row={props.row} />
          <div class={cn(!mode() && '-mr-1.5 mt-1 flex justify-end')}>
            <Moves
              mode={mode()}
              refetch={() => {
                void props.refetch()
                void brief.refetch()
              }}
              row={props.row}
              setMode={setMode}
            />
          </div>
        </div>
      </div>
      <div class="px-3 py-3">
        {brief.error() && (
          <p class="mb-3 font-mono text-[11.5px] break-words text-error">
            {brief.error()?.message}
          </p>
        )}
        <Show
          when={brief.data()}
          fallback={
            !brief.error() && (
              <p class="font-mono text-[11.5px] text-muted-foreground">reading pi's session…</p>
            )
          }
        >
          {(data) => <Brief sections={data().sections} />}
        </Show>
      </div>
    </div>
  )
}
export function PiPanel() {
  const sessions = useAction(SessionsAction, null, {
    every: 15_000,
    focus: true,
    onError: keepLast,
  })
  const [open, setOpen] = createSignal<string>()
  const now = useNow(60_000)
  const rows = sessions.data
  const refetch = () => sessions.refetch()
  const shown = createMemo(() => (open() ? rows()?.find((row) => row.path === open()) : undefined))
  return (
    <Show
      when={shown()}
      fallback={
        <div class="pb-4">
          <div class="flex h-8 items-center gap-2 border-b border-border/60 pr-1.5 pl-3">
            <span class="section-label">pi sessions</span>
            {rows() && (
              <span class="min-w-0 truncate font-mono text-[11px] text-muted-foreground/70">
                {summary(rows()!)}
              </span>
            )}
            <Act
              aria-label="Refresh pi worktrees"
              class="ml-auto"
              disabled={sessions.loading()}
              onClick={refetch}
              title="Refresh (every 15 s while open)"
            >
              <RotateCwIcon class={cn(sessions.loading() && 'animate-spin')} />
            </Act>
          </div>
          {rows() && sessions.error() && (
            <p class="border-b border-border/60 px-3 py-2 font-mono text-[11.5px] break-words text-error">
              refresh failed, showing the last list: {sessions.error()?.message}
            </p>
          )}
          <Show
            when={rows()}
            fallback={
              <p class="px-3 py-3 font-mono text-[11.5px] break-words text-muted-foreground">
                {sessions.error() ? (
                  <span class="text-error">{sessions.error()?.message}</span>
                ) : (
                  'looking for pi worktrees…'
                )}
              </p>
            }
          >
            {(data) => (
              <Show
                when={data().length}
                fallback={
                  <p class="px-3 py-6 text-center text-[12.5px] text-muted-foreground">
                    No worktree has a pi, a saved session or a baton.
                  </p>
                }
              >
                <ul class="divide-y divide-border/50">
                  <For each={data()} keyed={(row) => row.path}>
                    {(row) => (
                      <Row
                        now={now()}
                        onOpen={() => setOpen(row().path)}
                        refetch={refetch}
                        row={row()}
                      />
                    )}
                  </For>
                </ul>
              </Show>
            )}
          </Show>
        </div>
      }
    >
      {(row) => <Session onBack={() => setOpen(undefined)} refetch={refetch} row={row()} />}
    </Show>
  )
}
