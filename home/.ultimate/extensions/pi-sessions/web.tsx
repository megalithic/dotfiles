import { useState } from 'react'
import { HandIcon, PiIcon, Undo2Icon } from 'lucide-react'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'
import { cn, defineWebExtension, formatAgo, useAction, useConversation, useNow, useUltimate } from '@/sdk'
import { PiPanel } from './panel.tsx'
import { Act, BatonAction, Confirm, PANEL, release } from './parts.tsx'

/**
 * Who holds the baton of the shown conversation's worktree, in its header. Nothing outside this project's worktrees
 * (the action throws there) or while nobody holds it. Its popover says what that means and hands the baton back.
 */
function BatonBadge() {
  const { id, busy } = useConversation()
  const { openPanel } = useUltimate()
  const now = useNow(60_000)
  const baton = useAction(
    BatonAction,
    { conversation: id ?? 0 },
    { enabled: id !== undefined, every: 30_000, focus: true, on: busy, onError: () => {} },
  )
  const [open, setOpen] = useState(false)
  const [releasing, setReleasing] = useState(false)
  const data = baton.error ? undefined : baton.data
  if (!data) return null
  const pi = data.holder === 'pi'
  const mine = !pi && data.ultimate?.conversation === id
  const who = pi ? 'pi' : mine ? 'you' : `#${data.ultimate?.conversation ?? '?'}`
  const piName = data.pi?.label ?? (data.pi?.pid ? `pid ${data.pi.pid}` : undefined)
  return (
    <Popover
      onOpenChange={(value) => {
        setOpen(value)
        if (!value) setReleasing(false)
      }}
      open={open}
    >
      <PopoverTrigger asChild>
        <button
          className={cn(
            'flex h-6 shrink-0 items-center gap-1.5 rounded border px-1.5 font-mono text-[11px] transition-colors',
            pi
              ? 'border-warning/35 text-warning hover:bg-warning/10'
              : 'border-brand/35 text-brand hover:bg-brand/10',
          )}
          title={pi ? 'pi holds the baton: edits here are blocked' : 'Ultimate holds the baton: pi cannot edit'}
          type="button"
        >
          {pi ? <PiIcon className="size-3" /> : <HandIcon className="size-3" />}
          <span>{who} {who === 'you' ? 'hold' : 'holds'} baton</span>
        </button>
      </PopoverTrigger>
      <PopoverContent align="end" className="w-80 max-w-[calc(100vw-1rem)] p-3 text-[12.5px]">
        <p className="leading-snug text-foreground">
          {pi
            ? 'pi holds this worktree. Edit, write and bash are blocked here until pi hands it over.'
            : mine
              ? 'This conversation holds this worktree. pi cannot edit until you hand it back.'
              : `Conversation #${data.ultimate?.conversation ?? '?'} holds this worktree; pi cannot edit until it hands it back.`}
        </p>
        <p className="mt-1.5 truncate font-mono text-[11px] text-muted-foreground" title={data.worktree}>
          {data.worktree}
        </p>
        <p className="font-mono text-[11px] text-muted-foreground">
          {data.by} {formatAgo(Date.parse(data.at), now, { ago: true })}
          {piName && <> · pi {piName}</>}
        </p>
        {releasing ? (
          <Confirm
            action="Hand back to pi"
            busyLabel="Handing back…"
            onCancel={() => setReleasing(false)}
            placeholder="Summary for pi (optional): what changed, what's next"
            submit={async (text) => {
              await release(data.worktree, text, id)
              setOpen(false)
              setReleasing(false)
              void baton.refetch()
            }}
          />
        ) : (
          <div className="-mr-1.5 mt-2 flex justify-end gap-0.5">
            <Act
              onClick={() => {
                setOpen(false)
                openPanel(PANEL)
              }}
            >
              all worktrees
            </Act>
            {!pi && (
              <Act onClick={() => setReleasing(true)} primary>
                <Undo2Icon />
                release to pi
              </Act>
            )}
          </div>
        )}
      </PopoverContent>
    </Popover>
  )
}

export default defineWebExtension({
  panels: [{ id: PANEL, title: 'pi', icon: PiIcon, component: PiPanel, order: 20 }],
  slots: { 'header.right': [BatonBadge] },
  commands: [
    {
      id: 'pi-sessions.open',
      title: 'pi sessions: worktrees and batons',
      run: ({ openPanel }) => openPanel(PANEL),
    },
  ],
})
