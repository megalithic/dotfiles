import { BACKGROUND_CONTEXT as context } from '@earendil-works/chord/context';
import { defineDoc, defineExtension, ROOT_CONVERSATION_ID } from '@earendil-works/pi-durable';
import type { Harness } from '@earendil-works/pi-durable';
import {
  addGate,
  confirmGate,
  DOCUMENT,
  feedback,
  initial,
  JUDGE_SYSTEM,
  JUDGED,
  judgeInput,
  order,
  parseWorktrees,
  pending,
  readJudgment,
  record,
  removeGate,
  reviewOf,
} from './lib.ts';
import type { Gates, GhPull, GqlPull, Judged, Kind, List, Open } from './lib.ts';

type Model = { maxTokens?: number };
type ActionContext = {
  host: {
    harness(): Harness;
    projectRoot: string;
    projectSettings(): Promise<Record<string, unknown>>;
    modelRuntime: {
      getModel(provider: string, id: string): Model | undefined;
      completeSimple(
        model: Model,
        context: { systemPrompt: string; messages: { role: 'user'; content: string; timestamp: number }[] },
        options: { maxTokens: number; signal?: AbortSignal; reasoning?: string },
      ): Promise<{ content: { type: string; text?: string }[]; stopReason: string }>;
    };
  };
  signal?: AbortSignal;
  conversationId?: number;
  exec(command: string, args: string[], options?: { cwd?: string; timeout?: number }): Promise<{ stdout: string }>;
};

export const GatesDoc = defineDoc<Gates>({
  kind: DOCUMENT,
  checkpointWhen: () => false,
  version: 1,
  scope: 'conversation',
  history: 'latest',
  fork: 'initial',
  initial,
});
export const JudgedDoc = defineDoc<Judged>({
  kind: JUDGED,
  checkpointWhen: () => false,
  version: 1,
  scope: 'conversation',
  history: 'latest',
  fork: 'initial',
  initial: () => ({ kinds: {} }),
});
export const docs = [GatesDoc, JudgedDoc];

export default defineExtension({ name: 'spp-prs' });

const fields = [
  'number',
  'title',
  'url',
  'isDraft',
  'baseRefName',
  'headRefName',
  'headRefOid',
  'reviewDecision',
  'author',
  'reviewRequests',
  'mergeStateStatus',
  'statusCheckRollup',
].join(',');

const comment = 'id url body createdAt updatedAt author { login __typename }';
const FEEDBACK = `query($q: String!) {
  viewer { login }
  search(query: $q, type: ISSUE, first: 100) { nodes { ... on PullRequest {
    number
    latestReviews(first: 20) { nodes { state ${comment} } }
    reviewThreads(first: 50) { totalCount nodes { isResolved isOutdated comments(last: 1) { nodes { ${comment} } } } }
    comments(last: 30) { nodes { ${comment} } }
  } } }
}`;

/** Review threads, reviews and comments of every open PR of Seth's, in one read-only GraphQL query. */
async function readFeedback(exec: ActionContext['exec'], cwd: string) {
  const { stdout } = await exec(
    'gh',
    ['api', 'graphql', '-F', 'q=repo:{owner}/{repo} is:pr is:open author:@me', '-f', `query=${FEEDBACK}`],
    { cwd },
  );
  const { data } = JSON.parse(stdout) as { data: { viewer: { login: string }; search: { nodes: GqlPull[] } } };
  return { me: data.viewer.login, pulls: new Map(data.search.nodes.map((pull) => [pull.number, pull])) };
}

/** The `tiny` family's model (the project's, else Ultimate's built-in) judges what no rule decided. */
async function tinyModel(host: ActionContext['host']) {
  const settings = (await host.projectSettings()) as { modelFamilies?: { families?: Record<string, { model?: string }> } };
  const ref = settings.modelFamilies?.families?.tiny?.model ?? 'openai-codex/gpt-6-luna';
  const slash = ref.indexOf('/');
  return host.modelRuntime.getModel(ref.slice(0, slash), ref.slice(slash + 1));
}

async function judge(host: ActionContext['host'], items: Open[], signal?: AbortSignal): Promise<Record<string, Kind>> {
  const model = await tinyModel(host);
  if (!model || !items.length) return {};
  const answer = await host.modelRuntime.completeSimple(
    model,
    { systemPrompt: JUDGE_SYSTEM, messages: [{ role: 'user', content: judgeInput(items), timestamp: Date.now() }] },
    { maxTokens: Math.min(2048, model.maxTokens || 2048), reasoning: 'low', ...(signal ? { signal } : {}) },
  );
  if (answer.stopReason !== 'stop') return {};
  const kinds = readJudgment(items, answer.content.map((part) => part.text ?? '').join(''));
  // The model answered but skipped or garbled some: keep those as questions so they are not asked again.
  for (const item of items) kinds[item.key] ??= 'question';
  return kinds;
}

/**
 * Cached judgments, plus the model's for comments not seen before. A failed or aborted call caches nothing (an outage
 * must not pin labels): those count as questions until the next refresh asks again.
 */
async function judged(host: ActionContext['host'], items: Open[], signal?: AbortSignal) {
  const cached = (await host.harness().snapshot(JudgedDoc, ROOT_CONVERSATION_ID, context))?.kinds ?? {};
  const fresh = items.filter((item) => !item.kind && !Object.hasOwn(cached, item.key)).slice(0, 40);
  if (!fresh.length) return cached;
  const kinds = await judge(host, fresh, signal).catch(() => ({}));
  if (!Object.keys(kinds).length) return cached;
  await host.harness().commit(async (tx) => Object.assign((await tx.doc(JudgedDoc, ROOT_CONVERSATION_ID)).kinds, kinds), context);
  return { ...cached, ...kinds };
}

/**
 * Read-only on GitHub: `gh pr list`, one GraphQL query for review feedback and `git worktree list`; nothing on GitHub
 * or in the checkout changes. Comments no rule decides go to the `tiny` model once each.
 */
async function list(_args: unknown, { exec, host, signal }: ActionContext): Promise<List> {
  let pulls: GhPull[];
  try {
    const { stdout } = await exec(
      'gh',
      ['pr', 'list', '--author', '@me', '--state', 'open', '--limit', '100', '--json', fields],
      {
        cwd: host.projectRoot,
      },
    );
    pulls = JSON.parse(stdout) as GhPull[];
  } catch (error) {
    const { code, stderr } = error as { code?: string; stderr?: string };
    if (code === 'ENOENT') return { status: 'setup', reason: 'gh is not on the PATH of this Ultimate.' };
    if (stderr?.includes('auth login')) return { status: 'setup', reason: 'gh is signed out: run `gh auth login`.' };
    throw error;
  }
  const trees = await exec('git', ['worktree', 'list', '--porcelain'], { cwd: host.projectRoot }).then(
    ({ stdout }) => parseWorktrees(stdout),
    // Rows without conversation links beat no rows.
    () => [],
  );
  const rows = order(pulls, trees);
  // Rows without review feedback beat no rows.
  const review = await readFeedback(exec, host.projectRoot).catch(() => undefined);
  if (!review) return { status: 'ok', at: Date.now(), rows };
  const open = new Map(rows.map((row) => [row.number, pending(review.pulls.get(row.number) ?? none, review.me)]));
  const kinds = await judged(host, [...open.values()].flat(), signal);
  for (const row of rows) {
    const pull = review.pulls.get(row.number);
    row.review = reviewOf(row.review, pull, review.me);
    if (pull) row.feedback = feedback(pull, open.get(row.number) ?? [], kinds);
  }
  return { status: 'ok', at: Date.now(), rows };
}

const none: GqlPull = {
  number: 0,
  latestReviews: { nodes: [] },
  reviewThreads: { totalCount: 0, nodes: [] },
  comments: { nodes: [] },
};

const change = <T>(host: ActionContext['host'], edit: (state: Gates) => T) =>
  host.harness().commit(async (tx) => edit(await tx.doc(GatesDoc, ROOT_CONVERSATION_ID)), context);

/** Only the panel confirms or removes a gate; agents may add them. */
export const userActions = ['confirmGate', 'removeGate'];
export const actions = {
  list,
  addGate: (args: unknown, { host, conversationId }: ActionContext) =>
    change(host, (state) => addGate(state, args, conversationId, Date.now())),
  confirmGate: (args: unknown, { host }: ActionContext) =>
    change(host, (state) => confirmGate(state, record(args).id, Date.now())),
  removeGate: (args: unknown, { host }: ActionContext) => change(host, (state) => removeGate(state, record(args).id)),
};
