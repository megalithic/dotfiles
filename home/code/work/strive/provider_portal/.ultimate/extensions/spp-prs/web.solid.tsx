import {
  ArrowUpRightIcon,
  CheckIcon,
  GitPullRequestIcon,
  PlusIcon,
  RotateCwIcon,
  XIcon,
} from '@lucide/solid'
import { createMemo, createSignal, For, Show, omit } from 'solid-js'
import type { ComponentProps, Accessor } from 'solid-js'
import type { JSX } from '@solidjs/web'
import { Button } from '@/components/ui/button.solid.tsx'
import { Form } from '@/components/ui/form.solid.tsx'
import { Input } from '@/components/ui/input.solid.tsx'
import {
  actionRef,
  api,
  cn,
  defineWebExtension,
  docRef,
  formatAgo,
  ROOT,
  useAction,
  useConversations,
  useDocOf,
  useNow,
  switchConversation,
  closePanel,
  writingAs,
  keepLast,
} from '@/sdk/solid'
import { DOCUMENT } from './lib.ts'
import type { Gate, Gates, List, Row } from './lib.ts'

const PANEL = 'spp-prs'
const ListAction = actionRef<null, List>('spp-prs', 'list')
const AddGateAction = actionRef<{ blocks: number; after?: number; text: string }, Gate>(
  'spp-prs',
  'addGate',
)
const ConfirmGateAction = actionRef<{ id: number }, Gate>('spp-prs', 'confirmGate')
const RemoveGateAction = actionRef<{ id: number }, Gate>('spp-prs', 'removeGate')
const GatesDoc = docRef<Gates>(DOCUMENT)

function httpUrl(value: string) {
  try {
    const url = new URL(value)
    return url.protocol === 'http:' || url.protocol === 'https:' ? url.href : undefined
  } catch {
    return undefined
  }
}

interface ActProps extends ComponentProps<typeof Button> {
  primary?: boolean
}

function Act(props: ActProps) {
  const rest = omit(props, 'primary', 'class', 'children')
  return (
    <Button
      size="xs"
      type="button"
      variant="ghost"
      {...rest}
      class={cn(
        'h-6 gap-1 px-1.5 font-mono text-[11px] font-normal text-muted-foreground pointer-coarse:h-8 pointer-coarse:px-2.5 has-[>svg]:px-1.5 [&_svg]:size-3',
        props.primary && 'text-brand hover:text-brand',
        props.class,
      )}
    >
      {props.children}
    </Button>
  )
}

const ci: Record<Row['ci'], [string, string]> = {
  pass: ['ci pass', 'text-success'],
  fail: ['ci fail', 'text-error'],
  pending: ['ci pending', 'text-warning'],
  none: ['no ci', 'text-muted-foreground/60'],
}
const review: Record<Row['review'], [string, string] | undefined> = {
  approved: ['approved', 'text-success'],
  changes: ['changes requested', 'text-error'],
  commented: ['commented', 'text-muted-foreground'],
  required: ['review required', 'text-muted-foreground'],
  none: undefined,
}
const merge: Record<string, [string, string] | undefined> = {
  dirty: ['conflicts', 'text-error'],
  behind: ['behind base', 'text-warning'],
}

function useWorkingConversation(worktrees: Accessor<string[]>) {
  const conversations = useConversations()
  return createMemo(() => {
    const inTree = conversations().filter((item) => item.cwd && worktrees().includes(item.cwd))
    const top = inTree.filter(
      (item) => !inTree.some((other) => other.id === item.parentConversationId),
    )
    const active = (item: (typeof top)[number]) => Math.max(item.inputAt ?? 0, item.answerAt ?? 0)
    return top.toSorted((a, b) => active(b) - active(a))[0]
  })
}

function ConversationLink(props: { worktrees: string[]; pr: number }) {
  const found = useWorkingConversation(() => props.worktrees)
  return (
    <Show when={found()}>
      {(conversation) => (
        <Button
          class="inline-block h-auto min-w-0 truncate text-left text-[length:inherit] font-normal hover:text-foreground hover:underline"
          size={null}
          variant={null}
          aria-label={`Open working conversation #${conversation().id} for PR #${props.pr}`}
          onClick={() => {
            switchConversation(conversation().id)
            if (window.matchMedia('(max-width: 767px)').matches) closePanel()
          }}
          title={`Open the conversation working on this branch${conversation().title ? `: ${conversation().title}` : ''}`}
        >
          #{conversation().id}
          <Show when={conversation().title}>
            <span class="ml-1 font-sans">{conversation().title}</span>
          </Show>
        </Button>
      )}
    </Show>
  )
}

function Tag(props: { value?: [string, string] }) {
  return (
    <Show when={props.value}>
      {(value) => <span class={cn('shrink-0', value()[1])}>{value()[0]}</span>}
    </Show>
  )
}

function NextApprover(props: { row: Row }) {
  const requested = () => props.row.next.requested
  const title = () =>
    [
      `author: ${props.row.author} (cannot approve)`,
      props.row.next.state === 'awaiting'
        ? `awaiting an approval from ${requested().length ? requested().join(', ') : 'any non-author reviewer'}`
        : 'GitHub gives no review decision here (stacked branch or no review rule): who approves is unknown',
      requested().length ? `requested: ${requested().join(', ')}` : 'no reviewers requested',
    ].join('\n')
  return (
    <Show when={props.row.next.state !== 'approved'}>
      <span class="min-w-0 shrink truncate text-muted-foreground" title={title()}>
        {props.row.next.state === 'awaiting'
          ? `next: ${requested().length ? requested().join(', ') : 'non-author'}`
          : 'next: unknown'}
      </span>
    </Show>
  )
}

function FeedbackTags(props: { row: Row }) {
  const feedback = () => props.row.feedback
  const act = () => feedback()?.items.filter((item) => item.kind === 'act').length ?? 0
  const ask = () => (feedback()?.items.length ?? 0) - act()
  const title = () => {
    const value = feedback()
    if (!value) return ''
    return [
      `review threads: ${value.threads}, unresolved: ${value.unresolved}${value.truncated ? ' (first 50 threads read)' : ''}`,
      value.items
        .map(
          (item) =>
            `${item.kind === 'act' ? 'act' : 'answer'}${item.by === 'model' ? '*' : ''} · ${item.author}: ${item.text}`,
        )
        .join('\n'),
      value.items.some((item) => item.by === 'model') ? '* judged by the tiny model' : '',
    ]
      .filter(Boolean)
      .join('\n\n')
  }
  return (
    <Show when={feedback() && (feedback()!.threads || feedback()!.items.length)}>
      <a
        class="flex shrink-0 gap-2 hover:underline"
        href={httpUrl(feedback()!.items[0]?.url ?? `${props.row.url}/files`)}
        rel="noreferrer"
        target="_blank"
        title={title()}
      >
        <span class={act() ? 'text-error' : 'text-muted-foreground/60'}>{act()} to act</span>
        <span class={ask() ? 'text-warning' : 'text-muted-foreground/60'}>{ask()} to answer</span>
        <span class="text-muted-foreground/60">
          {feedback()!.unresolved}
          {feedback()!.truncated && '+'}/{feedback()!.threads} open
        </span>
      </a>
    </Show>
  )
}

function GateLine(props: { gate: Gate; now: number }) {
  const [error, setError] = createSignal<string>()
  const run = (action: typeof ConfirmGateAction) =>
    api.action(action, { id: props.gate.id }).then(
      () => {
        setError(undefined)
      },
      (failure: Error) => {
        setError(failure.message)
      },
    )
  const confirmed = () => props.gate.state === 'confirmed'
  return (
    <li class="flex min-w-0 flex-wrap items-center gap-x-2 text-[12px]">
      <span
        class={cn(
          'shrink-0 rounded-sm px-1 font-mono text-[11px]',
          confirmed() ? 'bg-success/12 text-success' : 'bg-warning/12 text-warning',
        )}
        title={
          confirmed()
            ? `Seth confirmed this ${formatAgo(props.gate.confirmedAt ?? props.gate.at, props.now, { ago: true })}`
            : 'Not confirmed: GitHub cannot tell whether this happened'
        }
      >
        {confirmed() ? 'confirmed' : 'unknown'}
      </span>
      <span class="min-w-0 flex-1 text-muted-foreground">
        <Show when={props.gate.after !== undefined}>
          <span class="font-mono">after #{props.gate.after}: </span>
        </Show>
        {props.gate.text}
      </span>
      <span class="-mr-1.5 flex shrink-0">
        <Show when={!confirmed()}>
          <Act
            aria-label={`Confirm gate ${props.gate.id} for PR #${props.gate.blocks}`}
            onClick={() => run(ConfirmGateAction)}
            primary
            title="I checked: this has happened"
          >
            <CheckIcon />
            confirm
          </Act>
        </Show>
        <Act
          aria-label={`Remove gate ${props.gate.id} for PR #${props.gate.blocks}`}
          onClick={() => run(RemoveGateAction)}
          title="Remove this gate"
        >
          <XIcon />
        </Act>
      </span>
      <Show when={error()}>
        <span class="w-full font-mono text-[11px] text-error">{error()}</span>
      </Show>
    </li>
  )
}

function PullRow(props: { row: Row; gates: Gate[]; now: number }) {
  return (
    <li class="py-2 pr-3" style={{ 'padding-left': `${0.75 + props.row.depth}rem` }}>
      <div class={cn('min-w-0', props.row.depth > 0 && 'border-l border-border/70 pl-2.5')}>
        <div class="flex min-w-0 items-baseline gap-2">
          <a
            class="shrink-0 font-mono text-[12px] text-foreground hover:underline"
            href={httpUrl(props.row.url)}
            rel="noreferrer"
            target="_blank"
            title="Open on GitHub"
          >
            #{props.row.number}
            <ArrowUpRightIcon class="ml-0.5 inline size-3 opacity-60" />
          </a>
          <span class="min-w-0 truncate text-[13px] text-foreground" title={props.row.title}>
            {props.row.title}
          </span>
        </div>
        <div class="mt-0.5 flex min-w-0 items-baseline gap-2 font-mono text-[11px] text-muted-foreground/75">
          <Show when={props.row.draft}>
            <span class="shrink-0 text-muted-foreground">draft</span>
          </Show>
          <a
            class={cn('shrink-0 hover:underline', ci[props.row.ci][1])}
            href={httpUrl(`${props.row.url}/checks`)}
            rel="noreferrer"
            target="_blank"
          >
            {ci[props.row.ci][0]}
          </a>
          <Tag value={review[props.row.review]} />
          <NextApprover row={props.row} />
          <FeedbackTags row={props.row} />
          <Tag value={merge[props.row.merge]} />
          <span class="ml-auto flex min-w-0 justify-end">
            <ConversationLink pr={props.row.number} worktrees={props.row.worktrees} />
          </span>
        </div>
        <Show when={props.gates.length > 0}>
          <ul class="mt-1 flex flex-col gap-0.5">
            <For each={props.gates} keyed={(gate) => gate.id}>
              {(gate) => <GateLine gate={gate()} now={props.now} />}
            </For>
          </ul>
        </Show>
      </div>
    </li>
  )
}

function AddGate(props: { onDone: () => void }) {
  const [blocks, setBlocks] = createSignal('')
  const [after, setAfter] = createSignal('')
  const [text, setText] = createSignal('')
  const [error, setError] = createSignal<string>()
  const field =
    'h-7 rounded border border-border/70 bg-background px-2 font-mono text-[12px] outline-none focus:border-brand/60'
  const submit = async (source: Parameters<typeof writingAs>[0]) => {
    try {
      await api.action(AddGateAction, {
        blocks: Number(blocks()),
        ...(after().trim() ? { after: Number(after()) } : {}),
        text: text(),
      })
      const done = props.onDone
      writingAs(source, done)
    } catch (failure) {
      setError((failure as Error).message)
    }
  }
  return (
    <Form class="flex flex-col gap-1.5 border-b border-border/60 px-3 py-2.5">
      <div class="flex gap-1.5">
        <Input
          aria-label="Blocked PR"
          class={cn(field, 'w-24')}
          inputmode="numeric"
          onValueChange={setBlocks}
          placeholder="blocks #"
          value={blocks()}
        />
        <Input
          aria-label="After PR"
          class={cn(field, 'w-24')}
          inputmode="numeric"
          onValueChange={setAfter}
          placeholder="after # (opt)"
          value={after()}
        />
      </div>
      <Input
        aria-label="What must happen"
        class={field}
        onValueChange={setText}
        placeholder="run the migration"
        value={text()}
      />
      <Show when={error()}>
        <p class="font-mono text-[11px] text-error">{error()}</p>
      </Show>
      <div class="-mr-1.5 flex justify-end gap-0.5">
        <Act onClick={() => props.onDone()}>cancel</Act>
        <Act
          disabled={!blocks().trim() || !text().trim()}
          onClick={(_, details) => submit(details.source)}
          primary
          type="submit"
        >
          add gate
        </Act>
      </div>
    </Form>
  )
}

function Message(props: { children: JSX.Element; error?: boolean }) {
  return (
    <p
      class={cn(
        'px-3 py-3 font-mono text-[11.5px] break-words',
        props.error ? 'text-error' : 'text-muted-foreground',
      )}
    >
      {props.children}
    </p>
  )
}

function MyPrs() {
  const pulls = useAction(ListAction, null, { onError: keepLast })
  const doc = useDocOf(() => ROOT, GatesDoc)
  const [adding, setAdding] = createSignal(false)
  const now = useNow(60_000)
  const data = pulls.data
  const rows = createMemo(() => {
    const value = data()
    return value?.status === 'ok' ? value.rows : undefined
  })
  const gates = createMemo(() => {
    const open = new Set(rows()?.map((row) => row.number))
    return (doc()?.gates ?? []).filter((gate) => open.has(gate.blocks))
  })
  const stacked = () => rows()?.filter((row) => row.depth > 0).length ?? 0
  return (
    <div class="pb-4">
      <div class="flex h-8 items-center gap-2 border-b border-border/60 pr-1.5 pl-3">
        <span class="section-label">my prs</span>
        <Show when={rows()}>
          {(list) => (
            <span class="min-w-0 truncate font-mono text-[11px] text-muted-foreground/70">
              {list().length} open{stacked() > 0 && <> · {stacked()} stacked</>}
              <Show when={data()?.status === 'ok'}>
                {' '}
                · {formatAgo((data() as Extract<List, { status: 'ok' }>).at, now(), { ago: true })}
              </Show>
            </span>
          )}
        </Show>
        <Act
          class="ml-auto"
          onClick={() => setAdding(!adding())}
          title="Add a gate GitHub cannot see"
        >
          <PlusIcon />
          gate
        </Act>
        <Act
          aria-label="Refresh My PRs"
          disabled={pulls.loading()}
          onClick={() => pulls.refetch()}
          title="Ask GitHub again"
        >
          <RotateCwIcon class={cn(pulls.loading() && 'animate-spin')} />
        </Act>
      </div>
      <Show when={adding()}>
        <AddGate onDone={() => setAdding(false)} />
      </Show>
      <Show when={data() && pulls.error()}>
        <Message error>refresh failed, showing the last list: {pulls.error()?.message}</Message>
      </Show>
      <Show
        when={data()}
        fallback={
          <Message error={!!pulls.error()}>{pulls.error()?.message ?? 'asking GitHub…'}</Message>
        }
      >
        {(value) => (
          <Show
            when={value().status === 'ok'}
            fallback={
              <Message error>{(value() as Extract<List, { status: 'setup' }>).reason}</Message>
            }
          >
            <Show
              when={rows()?.length}
              fallback={
                <p class="px-3 py-6 text-center text-[12.5px] text-muted-foreground">
                  No open pull requests.
                </p>
              }
            >
              <ul class="divide-y divide-border/50">
                <For each={rows()} keyed={(row) => row.number}>
                  {(row) => (
                    <PullRow
                      gates={gates().filter((gate) => gate.blocks === row().number)}
                      now={now()}
                      row={row()}
                    />
                  )}
                </For>
              </ul>
            </Show>
          </Show>
        )}
      </Show>
    </div>
  )
}

export default defineWebExtension({
  panels: [{ id: PANEL, title: 'My PRs', icon: GitPullRequestIcon, component: MyPrs, order: 25 }],
  commands: [
    {
      id: 'spp-prs.open',
      title: 'My PRs: open pull requests in merge order',
      run: (context) => context.openPanel(PANEL),
    },
  ],
})
