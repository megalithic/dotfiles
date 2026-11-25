import { createSignal, omit, Show } from 'solid-js'
import { ArrowUpRightIcon } from '@lucide/solid'
import type { Accessor, ComponentProps } from 'solid-js'
import { Button } from '@/components/ui/button.solid.tsx'
import { Form } from '@/components/ui/form.solid.tsx'
import { Textarea } from '@/components/ui/input.solid.tsx'
import {
  actionRef,
  api,
  cn,
  errorMessage,
  useSystem,
  switchConversation,
  closePanel,
} from '@/sdk/solid'
import type { Baton, Pi, Worktree } from './lib.ts'

export type { Baton, Pi, Worktree }
export const SessionsAction = actionRef<null, Worktree[]>('pi-sessions', 'sessions')
export const SessionAction = actionRef<
  { worktree: string },
  { sections: { title: string; body: string }[] }
>('pi-sessions', 'session')
export const PickupAction = actionRef<
  { cwd: string; goal?: string },
  { conversation: number; url: string; worktree: string; baton: Baton }
>('pi-sessions', 'pickup')
export const ReleaseAction = actionRef<{ worktree?: string; text?: string }, unknown>(
  'pi-sessions',
  'release',
)
export const BatonAction = actionRef<{ conversation: number }, Baton | null>('pi-sessions', 'baton')
export const PANEL = 'pi-sessions'

export function useShow() {
  return (id: number) => {
    switchConversation(id as never)
    if (window.matchMedia('(max-width: 767px)').matches) closePanel()
  }
}
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
const statuses: Record<string, string> = {
  working: 'working',
  input_needed: 'waiting',
  asking: 'waiting',
  error: 'failed',
  done: 'done',
}
export function StateDot(props: { state?: string; class?: string }) {
  return (
    <span
      class={cn(
        'size-1.5 shrink-0 rounded-full',
        props.state
          ? (dots[props.state] ?? 'bg-muted-foreground/45')
          : 'border border-muted-foreground/40',
        props.class,
      )}
      data-status={props.state ? (statuses[props.state] ?? 'idle') : 'idle'}
      title={props.state ? `pi ${label(props.state)}` : 'no live pi'}
    />
  )
}
export const label = (state: string) => (state === 'input_needed' ? 'needs input' : state)
export const stateText: Record<string, string> = {
  working: 'text-brand',
  input_needed: 'text-warning',
  asking: 'text-warning',
  error: 'text-error',
}
export function useLocalBaton(baton: Accessor<Baton | null>) {
  const system = useSystem()
  return () =>
    baton()?.holder === 'ultimate' &&
    !!baton()?.ultimate &&
    baton()?.ultimate?.project === system()?.project.root
}

export function HolderLink(props: { baton: Baton; class?: string; name: string }) {
  const show = useShow()
  const local = useLocalBaton(() => props.baton)
  const holder = () => props.baton.ultimate
  const href = () => {
    try {
      const url = new URL(holder()!.url)
      if (!['http:', 'https:'].includes(url.protocol)) return undefined
      return `${window.location.protocol}//${window.location.hostname}${url.port ? `:${url.port}` : ''}/?conversation=${holder()!.conversation}`
    } catch {
      return undefined
    }
  }
  const text = () => `open #${holder()?.conversation ?? '?'}`
  return (
    <Show when={holder()} fallback={<span class={props.class}>{text()}</span>}>
      <Show
        when={local()}
        fallback={
          <Show when={href()} fallback={<span class={props.class}>{text()}</span>}>
            <Act
              aria-label={props.name}
              class={props.class}
              render={(button) => (
                <a {...button} href={href()} rel="noreferrer" target="_blank">
                  {button.children}
                </a>
              )}
            >
              {text()} <ArrowUpRightIcon />
            </Act>
          </Show>
        }
      >
        <Act aria-label={props.name} onClick={() => show(holder()!.conversation)}>
          {text()}
        </Act>
      </Show>
    </Show>
  )
}
export function BatonChip(props: { baton: Baton | null; here?: number }) {
  return (
    <Show when={props.baton}>
      {(baton) => (
        <span
          class={cn(
            'shrink-0 rounded border px-1.5 font-mono text-[10.5px] leading-[18px]',
            baton().holder === 'pi'
              ? 'border-warning/35 text-warning'
              : 'border-brand/35 text-brand',
          )}
          title={`${baton().holder === 'pi' ? 'pi' : 'Ultimate'} holds the baton since ${baton().at}: ${baton().holder === 'pi' ? 'Ultimate' : 'pi'} cannot edit here`}
        >
          {baton().holder === 'pi'
            ? 'pi holds baton'
            : props.here !== undefined && baton().ultimate?.conversation === props.here
              ? 'you hold baton'
              : `#${baton().ultimate?.conversation ?? '?'} holds baton`}
        </span>
      )}
    </Show>
  )
}
export function Act(props: ComponentProps<typeof Button> & { primary?: boolean }) {
  const rest = omit(props, 'primary', 'class', 'children')
  return (
    <Button
      {...rest}
      class={cn(
        'h-6 gap-1 px-1.5 font-mono text-[11px] font-normal text-muted-foreground pointer-coarse:h-8 pointer-coarse:px-2.5 has-[>svg]:px-1.5 [&_svg]:size-3',
        props.primary && 'text-brand hover:text-brand',
        props.class,
      )}
      size="xs"
      type="button"
      variant="ghost"
    >
      {props.children}
    </Button>
  )
}
export function Confirm(props: {
  name: string
  placeholder: string
  action: string
  busyLabel: string
  hint?: string
  onCancel: () => void
  onConfirm: (note: string | undefined, source: string) => Promise<void>
}) {
  const [note, setNote] = createSignal('')
  const [busy, setBusy] = createSignal(false)
  const [error, setError] = createSignal<string>()
  const run = async (source: string) => {
    setBusy(true)
    setError(undefined)
    try {
      await props.onConfirm(note().trim() || undefined, source)
    } catch (caught) {
      setError(errorMessage(caught))
      setBusy(false)
    }
  }
  return (
    <Form class="mt-2 flex flex-col gap-1.5">
      <Textarea
        aria-label={`${props.placeholder}: ${props.name}`}
        autofocus
        class="min-h-14 w-full resize-y rounded-md border border-border/70 bg-background px-2 py-1.5 text-[13px] leading-snug outline-none placeholder:text-muted-foreground/60 focus-visible:border-ring"
        disabled={busy()}
        onValueChange={setNote}
        onKeyDown={(event) => {
          if (event.key === 'Escape') props.onCancel()
        }}
        submitShortcut="mod+enter"
        placeholder={props.placeholder}
        rows={2}
        value={note()}
      />
      <Show when={props.hint}>
        <p class="font-mono text-[11px] text-muted-foreground">{props.hint}</p>
      </Show>
      <Show when={error()}>
        <p class="font-mono text-[11px] break-words text-error">{error()}</p>
      </Show>
      <div class="flex items-center justify-end gap-1">
        <Button
          aria-label={`Cancel ${props.name}`}
          class="h-7 px-2.5 text-[12px]"
          disabled={busy()}
          onClick={props.onCancel}
          size="sm"
          type="button"
          variant="ghost"
        >
          Cancel
        </Button>
        <Button
          aria-label={`${props.action}: ${props.name}`}
          class="h-7 px-2.5 text-[12px]"
          disabled={busy()}
          onClick={(_, details) => run(details.source)}
          size="sm"
          type="submit"
        >
          {busy() ? props.busyLabel : props.action}
        </Button>
      </div>
    </Form>
  )
}
export async function release(worktree: string, text: string | undefined, conversationId?: number) {
  await api.action(
    ReleaseAction,
    { worktree, ...(text ? { text } : {}) },
    conversationId === undefined ? undefined : { conversationId: conversationId as never },
  )
}
