import { createSignal, Show } from 'solid-js'
import { HandIcon, PiIcon, Undo2Icon } from '@lucide/solid'
import { Button } from '@/components/ui/button.solid.tsx'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover.solid.tsx'
import {
  cn,
  defineWebExtension,
  formatAgo,
  useAction,
  useConversation,
  useNow,
  openPanel,
  writingAs,
  keepLast,
} from '@/sdk/solid'
import { PiPanel } from './panel.solid.tsx'
import { Act, BatonAction, Confirm, PANEL, release } from './parts.solid.tsx'

/** The baton of the shown conversation's worktree, read only once the conversation has an id. */
function BatonBadge() {
  const conversation = useConversation()
  return <Show when={conversation().id}>{(id) => <Baton id={id()} />}</Show>
}
function Baton(props: { id: number }) {
  const conversation = useConversation()
  const now = useNow(60_000)
  const baton = useAction(
    BatonAction,
    {
      get conversation() {
        return props.id
      },
    },
    { every: 30_000, focus: true, on: () => conversation().busy, onError: keepLast },
  )
  const [open, setOpen] = createSignal(false)
  const [releasing, setReleasing] = createSignal(false)
  const data = () => (baton.error() ? undefined : baton.data())
  const pi = () => data()?.holder === 'pi'
  const mine = () => !pi() && data()?.ultimate?.conversation === conversation().id
  const who = () => (pi() ? 'pi' : mine() ? 'you' : `#${data()?.ultimate?.conversation ?? '?'}`)
  const piName = () => data()?.pi?.label ?? (data()?.pi?.pid ? `pid ${data()?.pi?.pid}` : undefined)
  return (
    <Show when={data()}>
      {(held) => (
        <Popover
          open={open()}
          onOpenChange={(value) => {
            setOpen(value)
            if (!value) setReleasing(false)
          }}
        >
          <PopoverTrigger
            render={(trigger) => <Button {...trigger} size={null} variant={null} />}
            aria-label="Worktree baton details"
            class={cn(
              'flex h-6 shrink-0 items-center gap-1.5 rounded border px-1.5 font-mono text-[11px] font-normal transition-colors',
              pi()
                ? 'border-warning/35 text-warning hover:bg-warning/10'
                : 'border-brand/35 text-brand hover:bg-brand/10',
            )}
            title={
              pi()
                ? 'pi holds the baton: edits here are blocked'
                : 'Ultimate holds the baton: pi cannot edit'
            }
          >
            {pi() ? <PiIcon class="size-3" /> : <HandIcon class="size-3" />}
            <span>
              {who()} {who() === 'you' ? 'hold' : 'holds'} baton
            </span>
          </PopoverTrigger>
          <PopoverContent align="end" class="w-80 max-w-[calc(100vw-1rem)] p-3 text-[12.5px]">
            <p class="leading-snug text-foreground">
              {pi()
                ? 'pi holds this worktree. This conversation can only read and talk until pi hands it over.'
                : mine()
                  ? 'This conversation holds this worktree. pi cannot edit until you hand it back.'
                  : `Conversation #${held().ultimate?.conversation ?? '?'} holds this worktree; pi cannot edit until it hands it back.`}
            </p>
            <p
              class="mt-1.5 truncate font-mono text-[11px] text-muted-foreground"
              title={held().worktree}
            >
              {held().worktree}
            </p>
            <p class="font-mono text-[11px] text-muted-foreground">
              {held().by} {formatAgo(Date.parse(held().at), now(), { ago: true })}
              {piName() && <> · pi {piName()}</>}
            </p>
            <Show
              when={releasing()}
              fallback={
                <div class="-mr-1.5 mt-2 flex justify-end gap-0.5">
                  <Act
                    onClick={() => {
                      setOpen(false)
                      openPanel(PANEL)
                    }}
                  >
                    all worktrees
                  </Act>
                  {!pi() && (
                    <Act
                      aria-label="Release shown worktree to pi"
                      onClick={() => setReleasing(true)}
                      primary
                    >
                      <Undo2Icon />
                      release to pi
                    </Act>
                  )}
                </div>
              }
            >
              <Confirm
                name="shown worktree"
                action="Hand back to pi"
                busyLabel="Handing back…"
                onCancel={() => setReleasing(false)}
                placeholder="Summary for pi (optional): what changed, what's next"
                onConfirm={(text, source) =>
                  release(held().worktree, text, conversation().id).then(() =>
                    writingAs(source, () => {
                      setOpen(false)
                      setReleasing(false)
                      void baton.refetch()
                    }),
                  )
                }
              />
            </Show>
          </PopoverContent>
        </Popover>
      )}
    </Show>
  )
}
export default defineWebExtension({
  panels: [{ id: PANEL, title: 'pi', icon: PiIcon, component: PiPanel, order: 20 }],
  slots: { 'header.right': [BatonBadge] },
  commands: [
    {
      id: 'pi-sessions.open',
      title: 'pi sessions: worktrees and batons',
      run: () => openPanel(PANEL),
    },
  ],
})
