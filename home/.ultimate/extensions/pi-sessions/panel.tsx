/** The pi panel: every worktree with a pi, who holds its baton, and one tap to pick it up or hand it back. */
import { useState } from 'react'
import {
  ArrowLeftIcon,
  ArrowUpRightIcon,
  ChevronRightIcon,
  HandIcon,
  RotateCwIcon,
  Undo2Icon,
} from 'lucide-react'
import {
  api,
  cn,
  formatAgo,
  shortenPath,
  useAction,
  useNow,
  useSystem,
} from '@/sdk'
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
  useLocalBaton,
  useShow,
} from './parts.tsx'
import type { Worktree } from './parts.tsx'
import { Brief } from './brief.tsx'

/** `main` for the main checkout, else the worktree folder's name. */
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

/** What Seth can do with a worktree, decided by its baton and its pis. */
function useMoves(row: Worktree) {
  const local = useLocalBaton(row.baton)
  const working = row.pis.find((pi) => pi.state === 'working')
  const held = row.baton?.holder === 'ultimate'
  return {
    held,
    local,
    working,
    /** Pick up needs a quiet pi and a baton Ultimate does not already hold (force stays with agents). */
    canPickUp: !held && !working,
  }
}

type Mode = 'pickup' | 'release' | undefined

/** Pick up or release in place, then refresh the list; a pickup switches to its new conversation. */
function Moves({
  row,
  mode,
  setMode,
  refetch,
}: {
  row: Worktree
  mode: Mode
  setMode: (mode: Mode) => void
  refetch: () => unknown
}) {
  const show = useShow()
  const { held, local, working, canPickUp } = useMoves(row)
  if (mode === 'pickup')
    return (
      <Confirm
        action="Pick up"
        busyLabel="Picking up…"
        hint="A new conversation works in this checkout and holds the baton; pi cannot edit until you release."
        onCancel={() => setMode(undefined)}
        placeholder="Goal for Ultimate (optional): continue pi's work"
        submit={async (goal) => {
          const result = await api.action(PickupAction, { cwd: row.path, ...(goal ? { goal } : {}) })
          setMode(undefined)
          void refetch()
          show(result.conversation)
        }}
      />
    )
  if (mode === 'release')
    return (
      <Confirm
        action="Hand back to pi"
        busyLabel="Handing back…"
        hint={
          row.pis.length
            ? `The summary goes to pi ${row.pis[0]!.label ?? row.pis[0]!.pid}.`
            : 'No live pi: its rex agent tab restarts with the summary.'
        }
        onCancel={() => setMode(undefined)}
        placeholder="Summary for pi (optional): what changed, what's next"
        submit={async (text) => {
          await release(row.path, text, row.baton?.ultimate?.conversation)
          setMode(undefined)
          void refetch()
        }}
      />
    )
  return (
    <div className="flex shrink-0 items-center gap-0.5">
      {held && row.baton && (
        <HolderLink baton={row.baton} className="hover:no-underline">
          <Act tabIndex={-1}>
            open #{row.baton.ultimate?.conversation ?? '?'}
            {!local && <ArrowUpRightIcon />}
          </Act>
        </HolderLink>
      )}
      {held ? (
        <Act onClick={() => setMode('release')} primary title="Hand the baton back to pi">
          <Undo2Icon />
          release
        </Act>
      ) : (
        <Act
          disabled={!canPickUp}
          onClick={() => setMode('pickup')}
          primary
          title={
            working
              ? `pi ${working.label ?? working.pid} is working; pick up once it stops`
              : 'Continue in a new Ultimate conversation that holds the baton'
          }
        >
          <HandIcon />
          pick up
        </Act>
      )}
    </div>
  )
}

/** One meta line: path, dirty and ahead counts, and how fresh the session is. */
function Meta({ row, now }: { row: Worktree; now: number }) {
  const home = useSystem()?.machine.home
  return (
    <div className="flex min-w-0 items-baseline gap-2 font-mono text-[11px] text-muted-foreground/75">
      <span className="min-w-0 truncate" title={row.path}>
        {shortenPath(row.path, { home })}
      </span>
      <span className="ml-auto flex shrink-0 gap-2">
        {row.dirty > 0 && (
          <span className="text-warning/90" title={`${row.dirty} uncommitted files`}>
            ±{row.dirty}
          </span>
        )}
        {row.ahead ? <span title={`${row.ahead} commits ahead of main`}>↑{row.ahead}</span> : null}
        {row.sessionAt && (
          <span title={`Session saved ${row.sessionAt}`}>{formatAgo(Date.parse(row.sessionAt), now)}</span>
        )}
      </span>
    </div>
  )
}

/** Its live pis, most urgent first, two at most. */
function Pis({ row, all }: { row: Worktree; all?: boolean }) {
  if (!row.pis.length) return null
  const max = all ? Infinity : 2
  const order = ['working', 'input_needed', 'asking', 'error']
  const pis = row.pis.toSorted(
    (a, b) => (order.indexOf(a.state) + 1 || 9) - (order.indexOf(b.state) + 1 || 9),
  )
  return (
    <ul className="mt-1 flex flex-col gap-0.5">
      {pis.slice(0, max).map((pi) => (
        <li className="flex min-w-0 items-baseline gap-2 text-[12px]" key={pi.sessionId ?? pi.pid}>
          <span className={cn('w-[74px] shrink-0 font-mono text-[11px] text-muted-foreground', stateText[pi.state])}>
            {label(pi.state)}
          </span>
          <span className="min-w-0 truncate text-muted-foreground" title={pi.label}>
            {pi.label ?? `pid ${pi.pid}`}
          </span>
        </li>
      ))}
      {pis.length > max && (
        <li className="pl-[82px] font-mono text-[11px] text-muted-foreground/60">+{pis.length - max} more</li>
      )}
    </ul>
  )
}

function Row({
  row,
  now,
  onOpen,
  refetch,
}: {
  row: Worktree
  now: number
  onOpen: () => void
  refetch: () => unknown
}) {
  const [mode, setMode] = useState<Mode>()
  return (
    <li className="group/row px-3 py-2.5" data-worktree={row.path}>
      <div className="flex min-w-0 items-center gap-2">
        <StateDot state={topState(row.pis)} />
        <button
          className="flex min-w-0 flex-1 items-center gap-2 text-left"
          onClick={onOpen}
          title="Read pi's session"
          type="button"
        >
          <span className="truncate text-[13px] text-foreground group-hover/row:underline">{name(row)}</span>
          {row.branch && row.branch !== name(row) && (
            <span className="min-w-0 truncate font-mono text-[11px] text-muted-foreground/75">{row.branch}</span>
          )}
          <ChevronRightIcon className="size-3 shrink-0 text-muted-foreground/50" />
        </button>
        <BatonChip baton={row.baton} />
      </div>
      <div className="pl-3.5">
        <Meta now={now} row={row} />
        <Pis row={row} />
        <div className={cn(!mode && '-mr-1.5 mt-1 flex justify-end')}>
          <Moves mode={mode} refetch={refetch} row={row} setMode={setMode} />
        </div>
      </div>
    </li>
  )
}

/** A worktree's session brief as Markdown, with the same moves as its row. */
function Session({
  row,
  onBack,
  refetch,
}: {
  row: Worktree
  onBack: () => void
  refetch: () => unknown
}) {
  const brief = useAction(SessionAction, { worktree: row.path }, { onError: () => {} })
  const [mode, setMode] = useState<Mode>()
  const now = useNow(60_000)
  return (
    <div className="flex min-h-0 flex-col">
      <div className="sticky top-0 z-10 border-b border-border/60 bg-background px-3 pt-1.5 pb-2.5">
        <div className="flex min-w-0 items-center gap-1.5">
          <Act className="-ml-1.5" onClick={onBack} title="All worktrees">
            <ArrowLeftIcon />
            worktrees
          </Act>
          <Act
            className="ml-auto"
            disabled={brief.loading}
            onClick={() => void brief.refetch()}
            title="Read the session again"
          >
            <RotateCwIcon className={cn(brief.loading && 'animate-spin')} />
          </Act>
        </div>
        <div className="mt-1 flex min-w-0 items-center gap-2">
          <StateDot state={topState(row.pis)} />
          <span className="truncate text-[14px] font-medium text-foreground">{name(row)}</span>
          {row.branch && row.branch !== name(row) && (
            <span className="min-w-0 truncate font-mono text-[11px] text-muted-foreground/75">{row.branch}</span>
          )}
          <span className="ml-auto" />
          <BatonChip baton={row.baton} />
        </div>
        <div className="pl-3.5">
          <Meta now={now} row={row} />
          <Pis all row={row} />
          <div className={cn(!mode && '-mr-1.5 mt-1 flex justify-end')}>
            <Moves
              mode={mode}
              refetch={() => {
                void refetch()
                void brief.refetch()
              }}
              row={row}
              setMode={setMode}
            />
          </div>
        </div>
      </div>
      <div className="px-3 py-3">
        {/* A failed refresh shows above the last good read, so stale data never passes for current. */}
        {brief.error && (
          <p className="mb-3 font-mono text-[11.5px] break-words text-error">{brief.error.message}</p>
        )}
        {brief.data !== undefined ? (
          <Brief sections={brief.data.sections} />
        ) : (
          !brief.error && <p className="font-mono text-[11.5px] text-muted-foreground">reading pi's session…</p>
        )}
      </div>
    </div>
  )
}

export function PiPanel() {
  const sessions = useAction(SessionsAction, null, { every: 15_000, focus: true, onError: () => {} })
  const [open, setOpen] = useState<string>()
  const now = useNow(60_000)
  const rows = sessions.data
  const refetch = () => sessions.refetch()
  const shown = open ? rows?.find((row) => row.path === open) : undefined
  if (shown) return <Session onBack={() => setOpen(undefined)} refetch={refetch} row={shown} />
  return (
    <div className="pb-4">
      <div className="flex h-8 items-center gap-2 border-b border-border/60 pr-1.5 pl-3">
        <span className="section-label">pi sessions</span>
        {rows && (
          <span className="min-w-0 truncate font-mono text-[11px] text-muted-foreground/70">{summary(rows)}</span>
        )}
        <Act
          className="ml-auto"
          disabled={sessions.loading}
          onClick={() => void refetch()}
          title="Refresh (every 15 s while open)"
        >
          <RotateCwIcon className={cn(sessions.loading && 'animate-spin')} />
        </Act>
      </div>
      {rows && sessions.error && (
        <p className="border-b border-border/60 px-3 py-2 font-mono text-[11.5px] break-words text-error">
          refresh failed, showing the last list: {sessions.error.message}
        </p>
      )}
      {!rows ? (
        <p className="px-3 py-3 font-mono text-[11.5px] break-words text-muted-foreground">
          {sessions.error ? (
            <span className="text-error">{sessions.error.message}</span>
          ) : (
            'looking for pi worktrees…'
          )}
        </p>
      ) : rows.length === 0 ? (
        <p className="px-3 py-6 text-center text-[12.5px] text-muted-foreground">
          No worktree has a pi, a saved session or a baton.
        </p>
      ) : (
        <ul className="divide-y divide-border/50">
          {rows.map((row) => (
            <Row key={row.path} now={now} onOpen={() => setOpen(row.path)} refetch={refetch} row={row} />
          ))}
        </ul>
      )}
    </div>
  )
}
