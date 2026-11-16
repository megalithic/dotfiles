/** Refs, types and the small pieces the panel and the header badge share. */
import { useState } from 'react'
import type { ReactNode } from 'react'
import { Button } from '@/components/ui/button'
import { actionRef, api, cn, errorMessage, useSystem, useUltimate } from '@/sdk'
import type { Baton, Pi, Worktree } from './lib.ts'

export type { Baton, Pi, Worktree }

/** Every worktree of this project with a pi, a saved session or a baton. */
export const SessionsAction = actionRef<null, Worktree[]>('pi-sessions', 'sessions')
/** A worktree's pi session as titled sections: live state, brief, todos, goal, last answer, git status. */
export const SessionAction = actionRef<{ worktree: string }, { sections: { title: string; body: string }[] }>(
  'pi-sessions',
  'session',
)
/** Pick a worktree up into a new conversation that holds its baton. */
export const PickupAction = actionRef<
  { cwd: string; goal?: string },
  { conversation: number; url: string; worktree: string; baton: Baton }
>('pi-sessions', 'pickup')
/** Hand a worktree's baton back to pi, with an optional summary for it. */
export const ReleaseAction = actionRef<{ worktree?: string; text?: string }, unknown>(
  'pi-sessions',
  'release',
)
/** The baton of a conversation's worktree; throws when its cwd is not one of this project's worktrees. */
export const BatonAction = actionRef<{ conversation: number }, Baton | null>('pi-sessions', 'baton')

export const PANEL = 'pi-sessions'

/** Show a conversation; on a phone the panel covers it, so close the panel too. */
export function useShow() {
  const { switchConversation, closePanel } = useUltimate()
  return (id: number) => {
    switchConversation(id as never)
    if (window.matchMedia('(max-width: 767px)').matches) closePanel()
  }
}

/** Most urgent first: what a worktree's dot shows when several pis live in it. */
const urgency = ['working', 'input_needed', 'asking', 'error', 'idle', 'done']

export function topState(pis: Pi[]): string | undefined {
  return pis.map((pi) => pi.state).toSorted((a, b) => rank(a) - rank(b))[0]
}
const rank = (state: string) => {
  const index = urgency.indexOf(state)
  return index < 0 ? urgency.length : index
}

const dots: Record<string, string> = {
  working: 'animate-pulse-dot bg-brand',
  input_needed: 'bg-warning',
  asking: 'bg-warning',
  error: 'bg-error',
}
/** The sidebar's data-status vocabulary, for themes. */
const statuses: Record<string, string> = {
  working: 'working',
  input_needed: 'waiting',
  asking: 'waiting',
  error: 'failed',
  done: 'done',
}

/** A pi's state as the sidebar draws an agent's: pulsing brand while working, amber while it waits on Seth. */
export function StateDot({ state, className }: { state?: string; className?: string }) {
  return (
    <span
      className={cn(
        'size-1.5 shrink-0 rounded-full',
        state ? (dots[state] ?? 'bg-muted-foreground/45') : 'border border-muted-foreground/40',
        className,
      )}
      data-status={state ? (statuses[state] ?? 'idle') : 'idle'}
      title={state ? `pi ${label(state)}` : 'no live pi'}
    />
  )
}

/** `input_needed` → `needs input`. */
export const label = (state: string) => (state === 'input_needed' ? 'needs input' : state)

export const stateText: Record<string, string> = {
  working: 'text-brand',
  input_needed: 'text-warning',
  asking: 'text-warning',
  error: 'text-error',
}

/** Whether a baton held by Ultimate belongs to this instance (same project), so its conversation opens here. */
export function useLocalBaton(baton: Baton | null) {
  const root = useSystem()?.project.root
  return baton?.holder === 'ultimate' && !!baton.ultimate && baton.ultimate.project === root
}

/** A link to the conversation an Ultimate baton names: here it switches, elsewhere it opens that instance on this page's host. */
export function HolderLink({
  baton,
  className,
  children,
}: {
  baton: Baton
  className?: string
  children: ReactNode
}) {
  const show = useShow()
  const local = useLocalBaton(baton)
  const holder = baton.ultimate
  if (!holder) return <span className={className}>{children}</span>
  if (local)
    return (
      <button
        className={cn('hover:underline', className)}
        onClick={() => show(holder.conversation)}
        type="button"
      >
        {children}
      </button>
    )
  // The baton is a file on disk: a malformed URL shows the text without a link instead of breaking the panel.
  let port: string
  try {
    port = new URL(holder.url).port
  } catch {
    return <span className={className}>{children}</span>
  }
  const href = `${window.location.protocol}//${window.location.hostname}${port ? `:${port}` : ''}/?conversation=${holder.conversation}`
  return (
    <a className={cn('hover:underline', className)} href={href} rel="noreferrer" target="_blank">
      {children}
    </a>
  )
}

/** The baton as one short chip: who may write in the worktree. */
export function BatonChip({ baton, here }: { baton: Baton | null; here?: number }) {
  if (!baton) return null
  if (baton.holder === 'pi')
    return (
      <span
        className="shrink-0 rounded border border-warning/35 px-1.5 font-mono text-[10.5px] leading-[18px] text-warning"
        title={`pi holds the baton since ${baton.at}: Ultimate cannot edit here`}
      >
        pi holds baton
      </span>
    )
  const conversation = baton.ultimate?.conversation
  return (
    <span
      className="shrink-0 rounded border border-brand/35 px-1.5 font-mono text-[10.5px] leading-[18px] text-brand"
      title={`Ultimate holds the baton since ${baton.at}: pi cannot edit here`}
    >
      {here !== undefined && conversation === here
        ? 'you hold baton'
        : `#${conversation ?? '?'} holds baton`}
    </span>
  )
}

/** A small text action: quiet by default, `primary` in brand. */
export function Act({
  children,
  primary,
  className,
  ...props
}: React.ComponentProps<'button'> & { primary?: boolean }) {
  return (
    <Button
      className={cn(
        'h-6 gap-1 px-1.5 font-mono text-[11px] font-normal text-muted-foreground pointer-coarse:h-8 pointer-coarse:px-2.5 has-[>svg]:px-1.5 [&_svg]:size-3',
        primary && 'text-brand hover:text-brand',
        className,
      )}
      size="xs"
      type="button"
      variant="ghost"
      {...props}
    >
      {children}
    </Button>
  )
}

/**
 * An inline confirmation with one optional note: the pickup goal or the summary for pi. It runs `submit` with the
 * trimmed note and shows a failure in place, keeping the note.
 */
export function Confirm({
  placeholder,
  action,
  busyLabel,
  hint,
  onCancel,
  submit,
}: {
  placeholder: string
  action: string
  busyLabel: string
  hint?: ReactNode
  onCancel: () => void
  submit: (note: string | undefined) => Promise<void>
}) {
  const [note, setNote] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string>()
  const run = async () => {
    setBusy(true)
    setError(undefined)
    try {
      await submit(note.trim() || undefined)
    } catch (caught) {
      setError(errorMessage(caught))
      setBusy(false)
    }
  }
  return (
    <div className="mt-2 flex flex-col gap-1.5">
      <textarea
        autoFocus
        className="min-h-14 w-full resize-y rounded-md border border-border/70 bg-background px-2 py-1.5 text-[13px] leading-snug outline-none placeholder:text-muted-foreground/60 focus-visible:border-ring"
        disabled={busy}
        onChange={(event) => setNote(event.target.value)}
        onKeyDown={(event) => {
          if (event.key === 'Enter' && (event.metaKey || event.ctrlKey)) void run()
          if (event.key === 'Escape') onCancel()
        }}
        placeholder={placeholder}
        rows={2}
        value={note}
      />
      {hint && <p className="font-mono text-[11px] text-muted-foreground">{hint}</p>}
      {error && <p className="font-mono text-[11px] break-words text-error">{error}</p>}
      <div className="flex items-center justify-end gap-1">
        <Button
          className="h-7 px-2.5 text-[12px]"
          disabled={busy}
          onClick={onCancel}
          size="sm"
          type="button"
          variant="ghost"
        >
          Cancel
        </Button>
        <Button
          className="h-7 px-2.5 text-[12px]"
          disabled={busy}
          onClick={() => void run()}
          size="sm"
          type="button"
        >
          {busy ? busyLabel : action}
        </Button>
      </div>
    </div>
  )
}

/** Release a worktree to pi; `conversationId` lets the server default the worktree to that conversation's cwd. */
export async function release(worktree: string, text: string | undefined, conversationId?: number) {
  await api.action(
    ReleaseAction,
    { worktree, ...(text ? { text } : {}) },
    conversationId === undefined ? undefined : { conversationId: conversationId as never },
  )
}
