/** My PRs: Seth's open pull requests in merge order, what GitHub says about each, and the gates only he can confirm. */
import { useState } from 'react';
import type { ReactNode } from 'react';
import { ArrowUpRightIcon, CheckIcon, GitPullRequestIcon, PlusIcon, RotateCwIcon, XIcon } from 'lucide-react';
import { Button } from '@/components/ui/button';
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
  useUltimate,
} from '@/sdk';
import { DOCUMENT } from './lib.ts';
import type { Gate, Gates, List, Row } from './lib.ts';

const PANEL = 'spp-prs';
const ListAction = actionRef<null, List>('spp-prs', 'list');
const AddGateAction = actionRef<{ blocks: number; after?: number; text: string }, Gate>('spp-prs', 'addGate');
const ConfirmGateAction = actionRef<{ id: number }, Gate>('spp-prs', 'confirmGate');
const RemoveGateAction = actionRef<{ id: number }, Gate>('spp-prs', 'removeGate');
const GatesDoc = docRef<Gates>(DOCUMENT);

function Act({ children, primary, className, ...props }: React.ComponentProps<'button'> & { primary?: boolean }) {
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
  );
}

const ci: Record<Row['ci'], [string, string]> = {
  pass: ['ci pass', 'text-success'],
  fail: ['ci fail', 'text-error'],
  pending: ['ci pending', 'text-warning'],
  none: ['no ci', 'text-muted-foreground/60'],
};
const review: Record<Row['review'], [string, string] | undefined> = {
  approved: ['approved', 'text-success'],
  changes: ['changes requested', 'text-error'],
  commented: ['commented', 'text-muted-foreground'],
  required: ['review required', 'text-muted-foreground'],
  // Stacked branches have no review rule until they are retargeted to main.
  none: undefined,
};
const merge: Record<string, [string, string] | undefined> = {
  dirty: ['conflicts', 'text-error'],
  behind: ['behind base', 'text-warning'],
};

/** The conversation working in one of these worktrees: the topmost there, most recently active. */
function useWorkingConversation(worktrees: string[]) {
  const conversations = useConversations();
  const inTree = conversations.filter((item) => item.cwd && worktrees.includes(item.cwd));
  const top = inTree.filter((item) => !inTree.some((other) => other.id === item.parentConversationId));
  const active = (item: (typeof top)[number]) => Math.max(item.inputAt ?? 0, item.answerAt ?? 0);
  return top.toSorted((a, b) => active(b) - active(a))[0];
}

function ConversationLink({ worktrees }: { worktrees: string[] }) {
  const { switchConversation, closePanel } = useUltimate();
  const found = useWorkingConversation(worktrees);
  if (!found) return null;
  return (
    <button
      className="min-w-0 truncate hover:text-foreground hover:underline"
      onClick={() => {
        switchConversation(found.id);
        if (window.matchMedia('(max-width: 767px)').matches) closePanel();
      }}
      title={`Open the conversation working on this branch${found.title ? `: ${found.title}` : ''}`}
      type="button"
    >
      #{found.id}
      {found.title && <span className="ml-1 font-sans">{found.title}</span>}
    </button>
  );
}

function Tag({ value }: { value?: [string, string] }) {
  return value ? <span className={cn('shrink-0', value[1])}>{value[0]}</span> : null;
}

/** How many review comments need a change or an answer from Seth; hovering lists them. */
function FeedbackTags({ row }: { row: Row }) {
  const feedback = row.feedback;
  // A PR nobody has commented on stays quiet; once there is review, zero counts say "nothing waiting".
  if (!feedback || (!feedback.threads && !feedback.items.length)) return null;
  const act = feedback.items.filter((item) => item.kind === 'act').length;
  const ask = feedback.items.length - act;
  const list = feedback.items
    .map((item) => `${item.kind === 'act' ? 'act' : 'answer'}${item.by === 'model' ? '*' : ''} · ${item.author}: ${item.text}`)
    .join('\n');
  const title = [
    `review threads: ${feedback.threads}, unresolved: ${feedback.unresolved}${feedback.truncated ? ' (first 50 threads read)' : ''}`,
    list,
    feedback.items.some((item) => item.by === 'model') ? '* judged by the tiny model' : '',
  ]
    .filter(Boolean)
    .join('\n\n');
  return (
    <a
      className="flex shrink-0 gap-2 hover:underline"
      href={feedback.items[0]?.url ?? `${row.url}/files`}
      rel="noreferrer"
      target="_blank"
      title={title}
    >
      <span className={act ? 'text-error' : 'text-muted-foreground/60'}>{act} to act</span>
      <span className={ask ? 'text-warning' : 'text-muted-foreground/60'}>{ask} to answer</span>
      <span className="text-muted-foreground/60">
        {feedback.unresolved}
        {feedback.truncated && '+'}/{feedback.threads} open
      </span>
    </a>
  );
}

function GateLine({ gate, now }: { gate: Gate; now: number }) {
  const [error, setError] = useState<string>();
  const run = (action: typeof ConfirmGateAction) =>
    void api.action(action, { id: gate.id }).then(
      () => setError(undefined),
      (failure: Error) => setError(failure.message),
    );
  const confirmed = gate.state === 'confirmed';
  return (
    <li className="flex min-w-0 flex-wrap items-center gap-x-2 text-[12px]">
      <span
        className={cn(
          'shrink-0 rounded-sm px-1 font-mono text-[11px]',
          confirmed ? 'bg-success/12 text-success' : 'bg-warning/12 text-warning',
        )}
        title={
          confirmed
            ? `Seth confirmed this ${formatAgo(gate.confirmedAt ?? gate.at, now, { ago: true })}`
            : 'Not confirmed: GitHub cannot tell whether this happened'
        }
      >
        {confirmed ? 'confirmed' : 'unknown'}
      </span>
      <span className="min-w-0 flex-1 text-muted-foreground">
        {gate.after !== undefined && <span className="font-mono">after #{gate.after}: </span>}
        {gate.text}
      </span>
      <span className="-mr-1.5 flex shrink-0">
        {!confirmed && (
          <Act onClick={() => run(ConfirmGateAction)} primary title="I checked: this has happened">
            <CheckIcon />
            confirm
          </Act>
        )}
        <Act onClick={() => run(RemoveGateAction)} title="Remove this gate">
          <XIcon />
        </Act>
      </span>
      {error && <span className="w-full font-mono text-[11px] text-error">{error}</span>}
    </li>
  );
}

function PullRow({ row, gates, now }: { row: Row; gates: Gate[]; now: number }) {
  return (
    <li className="py-2 pr-3" style={{ paddingLeft: `${0.75 + row.depth * 1}rem` }}>
      <div className={cn('min-w-0', row.depth > 0 && 'border-l border-border/70 pl-2.5')}>
        <div className="flex min-w-0 items-baseline gap-2">
          <a
            className="shrink-0 font-mono text-[12px] text-foreground hover:underline"
            href={row.url}
            rel="noreferrer"
            target="_blank"
            title="Open on GitHub"
          >
            #{row.number}
            <ArrowUpRightIcon className="ml-0.5 inline size-3 opacity-60" />
          </a>
          <span className="min-w-0 truncate text-[13px] text-foreground" title={row.title}>
            {row.title}
          </span>
        </div>
        <div className="mt-0.5 flex min-w-0 items-baseline gap-2 font-mono text-[11px] text-muted-foreground/75">
          {row.draft && <span className="shrink-0 text-muted-foreground">draft</span>}
          <a
            className={cn('shrink-0 hover:underline', ci[row.ci][1])}
            href={`${row.url}/checks`}
            rel="noreferrer"
            target="_blank"
          >
            {ci[row.ci][0]}
          </a>
          <Tag value={review[row.review]} />
          <FeedbackTags row={row} />
          <Tag value={merge[row.merge]} />
          <span className="ml-auto flex min-w-0 justify-end">
            <ConversationLink worktrees={row.worktrees} />
          </span>
        </div>
        {gates.length > 0 && (
          <ul className="mt-1 flex flex-col gap-0.5">
            {gates.map((gate) => (
              <GateLine gate={gate} key={gate.id} now={now} />
            ))}
          </ul>
        )}
      </div>
    </li>
  );
}

/** Blocked PR, the PR it waits on, and what must happen; added as unknown. */
function AddGate({ onDone }: { onDone: () => void }) {
  const [blocks, setBlocks] = useState('');
  const [after, setAfter] = useState('');
  const [text, setText] = useState('');
  const [error, setError] = useState<string>();
  const field =
    'h-7 rounded border border-border/70 bg-background px-2 font-mono text-[12px] outline-none focus:border-brand/60';
  const submit = async () => {
    try {
      await api.action(AddGateAction, {
        blocks: Number(blocks),
        ...(after.trim() ? { after: Number(after) } : {}),
        text,
      });
      onDone();
    } catch (failure) {
      setError((failure as Error).message);
    }
  };
  return (
    <form
      className="flex flex-col gap-1.5 border-b border-border/60 px-3 py-2.5"
      onSubmit={(event) => {
        event.preventDefault();
        void submit();
      }}
    >
      <div className="flex gap-1.5">
        <input
          aria-label="Blocked PR"
          className={cn(field, 'w-24')}
          inputMode="numeric"
          onChange={(event) => setBlocks(event.target.value)}
          placeholder="blocks #"
          value={blocks}
        />
        <input
          aria-label="After PR"
          className={cn(field, 'w-24')}
          inputMode="numeric"
          onChange={(event) => setAfter(event.target.value)}
          placeholder="after # (opt)"
          value={after}
        />
      </div>
      <input
        aria-label="What must happen"
        className={field}
        onChange={(event) => setText(event.target.value)}
        placeholder="run the migration"
        value={text}
      />
      {error && <p className="font-mono text-[11px] text-error">{error}</p>}
      <div className="-mr-1.5 flex justify-end gap-0.5">
        <Act onClick={onDone}>cancel</Act>
        <Act disabled={!blocks.trim() || !text.trim()} primary type="submit">
          add gate
        </Act>
      </div>
    </form>
  );
}

function Message({ children, error }: { children: ReactNode; error?: boolean }) {
  return (
    <p className={cn('px-3 py-3 font-mono text-[11.5px] break-words', error ? 'text-error' : 'text-muted-foreground')}>
      {children}
    </p>
  );
}

function MyPrs() {
  const pulls = useAction(ListAction, null, { onError: () => {} });
  const doc = useDocOf(ROOT, GatesDoc);
  const [adding, setAdding] = useState(false);
  const now = useNow(60_000);
  const data = pulls.data;
  const rows = data?.status === 'ok' ? data.rows : undefined;
  const open = new Set(rows?.map((row) => row.number));
  // A gate goes once the PR it holds back is merged or closed.
  const gates = (doc?.gates ?? []).filter((gate) => open.has(gate.blocks));
  const stacked = rows?.filter((row) => row.depth > 0).length ?? 0;
  return (
    <div className="pb-4">
      <div className="flex h-8 items-center gap-2 border-b border-border/60 pr-1.5 pl-3">
        <span className="section-label">my prs</span>
        {rows && (
          <span className="min-w-0 truncate font-mono text-[11px] text-muted-foreground/70">
            {rows.length} open{stacked > 0 && <> · {stacked} stacked</>}
            {data?.status === 'ok' && <> · {formatAgo(data.at, now, { ago: true })}</>}
          </span>
        )}
        <Act className="ml-auto" onClick={() => setAdding(!adding)} title="Add a gate GitHub cannot see">
          <PlusIcon />
          gate
        </Act>
        <Act disabled={pulls.loading} onClick={() => void pulls.refetch()} title="Ask GitHub again">
          <RotateCwIcon className={cn(pulls.loading && 'animate-spin')} />
        </Act>
      </div>
      {adding && <AddGate onDone={() => setAdding(false)} />}
      {data && pulls.error && <Message error>refresh failed, showing the last list: {pulls.error.message}</Message>}
      {!data ? (
        <Message error={!!pulls.error}>{pulls.error ? pulls.error.message : 'asking GitHub…'}</Message>
      ) : data.status === 'setup' ? (
        <Message error>{data.reason}</Message>
      ) : data.rows.length === 0 ? (
        <p className="px-3 py-6 text-center text-[12.5px] text-muted-foreground">No open pull requests.</p>
      ) : (
        <ul className="divide-y divide-border/50">
          {data.rows.map((row) => (
            <PullRow gates={gates.filter((gate) => gate.blocks === row.number)} key={row.number} now={now} row={row} />
          ))}
        </ul>
      )}
    </div>
  );
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
});
