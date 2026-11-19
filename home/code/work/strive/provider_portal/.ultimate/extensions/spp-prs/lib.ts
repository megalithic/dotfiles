/** Pure parts of My PRs: GitHub's answer shaped into merge order, and the gates ledger. */

export const DOCUMENT = 'spp-prs.gates';
export const JUDGED = 'spp-prs.judged';

export type Ci = 'pass' | 'fail' | 'pending' | 'none';
export type Review = 'approved' | 'changes' | 'commented' | 'required' | 'none';

/** What a review comment asks of Seth: a change, an answer, or nothing. */
export type Kind = 'act' | 'question' | 'none';

/** One review thread, review body or PR comment still waiting on Seth. `by` says who judged it. */
export type Item = { kind: Kind; by: 'rule' | 'model'; author: string; text: string; url: string };

/** Review comments on one pull request: totals, and the items that need Seth (act or question). */
export type Feedback = { threads: number; unresolved: number; items: Item[]; truncated?: true };

/** One open pull request as the panel shows it; `depth` > 0 means it is stacked on the row above its parent. */
export type Row = {
  number: number;
  title: string;
  url: string;
  draft: boolean;
  base: string;
  head: string;
  ci: Ci;
  review: Review;
  /** GitHub's `mergeStateStatus`, lowercased: `clean`, `blocked`, `dirty` (conflicts), `behind`, `unstable`… */
  merge: string;
  depth: number;
  /** Worktrees of the project checked out on this branch or at its head commit. */
  worktrees: string[];
  /** Absent when GitHub's review threads could not be read. */
  feedback?: Feedback;
};

/** The `list` action's answer: rows, or why GitHub could not be asked. */
export type List = { status: 'ok'; at: number; rows: Row[] } | { status: 'setup'; reason: string };

/** The `gh pr list --json` fields `order` reads. */
export type GhPull = {
  number: number;
  title: string;
  url: string;
  isDraft: boolean;
  baseRefName: string;
  headRefName: string;
  headRefOid: string;
  reviewDecision: string | null;
  mergeStateStatus: string | null;
  statusCheckRollup: { status?: string; conclusion?: string | null; state?: string }[] | null;
};

export type Worktree = { path: string; head: string; branch?: string };

const failed = new Set(['FAILURE', 'ERROR', 'TIMED_OUT', 'CANCELLED', 'ACTION_REQUIRED', 'STARTUP_FAILURE']);

const passed = new Set(['SUCCESS', 'NEUTRAL', 'SKIPPED']);

/** One state for all checks: any failure wins; anything not plainly passed (running, stale, queued) is pending. */
export function rollup(checks: GhPull['statusCheckRollup']): Ci {
  if (!checks?.length) return 'none';
  if (checks.some((check) => failed.has(check.conclusion ?? check.state ?? ''))) return 'fail';
  const ok = (check: NonNullable<GhPull['statusCheckRollup']>[number]) =>
    check.status ? check.status === 'COMPLETED' && passed.has(check.conclusion ?? '') : check.state === 'SUCCESS';
  return checks.every(ok) ? 'pass' : 'pending';
}

const reviews: Record<string, Review> = {
  APPROVED: 'approved',
  CHANGES_REQUESTED: 'changes',
  REVIEW_REQUIRED: 'required',
};

/** Judgments by comment id and `updatedAt`, so each comment version goes to the model once. */
export type Judged = { kinds: Record<string, Kind> };

/**
 * Pull requests in merge order. A pull request whose base branch is another one's head is stacked on it and follows
 * it, indented; the rest (on `main` or a branch without a pull request) start stacks, oldest number first.
 */
export function order(pulls: GhPull[], worktrees: Worktree[] = []): Row[] {
  const byHead = new Map(pulls.map((pull) => [pull.headRefName, pull]));
  const children = new Map<string, GhPull[]>();
  const roots: GhPull[] = [];
  for (const pull of pulls) {
    const parent = pull.baseRefName !== pull.headRefName && byHead.get(pull.baseRefName);
    if (parent) children.set(parent.headRefName, [...(children.get(parent.headRefName) ?? []), pull]);
    else roots.push(pull);
  }
  const rows: Row[] = [];
  const seen = new Set<number>();
  const visit = (pull: GhPull, depth: number) => {
    if (seen.has(pull.number)) return;
    seen.add(pull.number);
    rows.push({
      number: pull.number,
      title: pull.title,
      url: pull.url,
      draft: pull.isDraft,
      base: pull.baseRefName,
      head: pull.headRefName,
      ci: rollup(pull.statusCheckRollup),
      review: reviews[pull.reviewDecision ?? ''] ?? 'none',
      merge: (pull.mergeStateStatus ?? 'unknown').toLowerCase(),
      depth,
      worktrees: worktrees
        .filter((tree) => tree.branch === pull.headRefName || tree.head === pull.headRefOid)
        .map((tree) => tree.path),
    });
    for (const child of byNumber(children.get(pull.headRefName) ?? [])) visit(child, depth + 1);
  };
  for (const root of byNumber(roots)) visit(root, 0);
  // A cycle of bases (never in practice) has no root: list what is left flat rather than lose it.
  for (const pull of byNumber(pulls)) visit(pull, 0);
  return rows;
}
const byNumber = (pulls: GhPull[]) => pulls.toSorted((a, b) => a.number - b.number);

type Author = { login: string; __typename: string } | null;
type GqlComment = { id: string; url: string; body: string; createdAt: string; updatedAt: string; author: Author };

/** One pull request from the review-feedback GraphQL query (`server.ts`). */
export type GqlPull = {
  number: number;
  latestReviews: { nodes: (GqlComment & { state: string })[] };
  reviewThreads: {
    totalCount: number;
    nodes: { isResolved: boolean; isOutdated: boolean; comments: { nodes: GqlComment[] } }[];
  };
  comments: { nodes: GqlComment[] };
};

const isBot = (author: Author) => !author || author.__typename === 'Bot' || author.login.endsWith('[bot]');

/** Prose only: quoted replies and code (other than a suggestion) say nothing about what is asked. */
const prose = (body: string) =>
  body
    .replace(/```[\s\S]*?```/g, ' ')
    .replace(/`[^`]*`/g, 'code')
    .split('\n')
    .filter((line) => !line.trimStart().startsWith('>'))
    .join('\n')
    .trim();

// The whole message, not its start: "Thanks, please rename this" still asks for a change.
const chatter =
  /^((thanks?( you)?( so much)?|thx|ty|lgtm|looks (good|great)( to me)?|nice( work| one)?|great( work)?|awesome|cool|ok(ay)?|done|sounds good|ship it|\+1|agreed|makes sense|fair enough)\s*)+$/i;
const request = /\b(can|could|would|will) you\b|\bwhy not\b|\bmind (changing|adding|removing)\b/i;
const nit = /(^|\n)\s*\W*(nit|nitpick|suggestion|todo)\b/i;
// Only a comment's opening sentence: long write-ups ("Looks good. … the missing rate limit is recorded…") use these
// words while asking nothing.
const imperative =
  /\b(please|should(n'?t)?|must|need(s)? to|let'?s|consider|instead of|rename|remove|move|extract|don'?t|avoid|typo)\b/i;
const opening = (text: string) => text.split(/(?<=[.!?])\s|\n/)[0] ?? '';

/**
 * What a comment asks of Seth, decided in code: `act` (a change), `question` (an answer) or `none` (bots, thanks,
 * LGTM, emoji). `undefined` when the wording does not say; the caller asks a model or assumes a question.
 */
export function rule(body: string, author: Author): Kind | undefined {
  if (isBot(author)) return 'none';
  if (/```suggestion\b/.test(body)) return 'act';
  const text = prose(body);
  // Priority-tagged findings from AI review: "[P2] Preserve completion callbacks…".
  if (/^\s*\[P[0-3]\]/.test(text)) return 'act';
  const words = text.replace(/[^\p{L}\p{N}?+]+/gu, ' ').trim();
  if (!words) return 'none';
  if (chatter.test(words)) return 'none';
  if (nit.test(text) || imperative.test(opening(text))) return 'act';
  const asks = /\?(\s|$)/.test(text);
  if (asks && request.test(text)) return 'act';
  if (asks) return 'question';
  return undefined;
}

/** A comment still waiting on Seth, with the cache key its judgment is kept under. */
export type Open = { key: string; author: string; body: string; url: string; kind?: Kind };

/** An approval's write-up needs nothing unless a rule finds a request or a question in it. */
const open = (comment: GqlComment & { state?: string }): Open => ({
  key: `${comment.id}@${comment.updatedAt}`,
  author: comment.author?.login ?? 'ghost',
  body: comment.body,
  url: comment.url,
  kind: rule(comment.body, comment.author) ?? (comment.state === 'APPROVED' ? 'none' : undefined),
});

/**
 * The comments on a pull request still waiting on `me`: the last comment of each unresolved, current thread unless it
 * is Seth's (then it is answered), and review bodies and conversation comments by others since Seth last commented.
 * Outdated threads are on code that has changed since: they need nothing.
 */
export function pending(pull: GqlPull, me: string): Open[] {
  const mine = (comment: GqlComment) => comment.author?.login === me;
  const threads = pull.reviewThreads.nodes
    .filter((thread) => !thread.isResolved && !thread.isOutdated)
    .map((thread) => thread.comments.nodes.at(-1))
    .filter((last): last is GqlComment => !!last && !mine(last));
  const spoke = Math.max(0, ...pull.comments.nodes.filter(mine).map((comment) => Date.parse(comment.createdAt)));
  const since = [...pull.latestReviews.nodes, ...pull.comments.nodes].filter(
    (comment) => comment.body.trim() && !mine(comment) && Date.parse(comment.createdAt) > spoke,
  );
  return [...threads, ...since].map(open);
}

/** Totals, and the open items judged `act` or `question`; one no rule or model decided counts as a question. */
export function feedback(pull: GqlPull, items: Open[], judged: Record<string, Kind>): Feedback {
  return {
    threads: pull.reviewThreads.totalCount,
    unresolved: pull.reviewThreads.nodes.filter((thread) => !thread.isResolved).length,
    // Only the first 50 threads are read: counts and items are a lower bound.
    ...(pull.reviewThreads.totalCount > pull.reviewThreads.nodes.length ? { truncated: true as const } : {}),
    items: items.flatMap((item): Item[] => {
      const kind = item.kind ?? judged[item.key] ?? 'question';
      if (kind === 'none') return [];
      const text = prose(item.body).split('\n')[0]?.slice(0, 140) || item.body.slice(0, 140);
      return [{ kind, by: item.kind ? 'rule' : 'model', author: item.author, text, url: item.url }];
    }),
  };
}

/** On a stacked branch GitHub gives no review decision: the latest reviews by others still say what they think. */
export function reviewOf(decision: Review, pull: GqlPull | undefined, me: string): Review {
  if (decision !== 'none' && decision !== 'required') return decision;
  const states = new Set(
    pull?.latestReviews.nodes.filter((review) => review.author?.login !== me).map((review) => review.state),
  );
  if (states.has('CHANGES_REQUESTED')) return 'changes';
  if (states.has('APPROVED')) return 'approved';
  if (states.has('COMMENTED')) return 'commented';
  return decision;
}

/** The cheap model's prompt for comments no rule decided, and its answer read back; anything unreadable is skipped. */
export const JUDGE_SYSTEM =
  'You triage GitHub pull request review comments for the PR author. For each comment answer "act" when it asks for a code change, "question" when it asks the author something that needs a reply, or "none" when it needs neither (thanks, praise, FYI, agreement). Answer with one JSON object mapping each id to its label, nothing else.';

export const judgeInput = (items: Open[]) =>
  JSON.stringify(items.map((item, index) => ({ id: String(index), comment: prose(item.body).slice(0, 800) })));

export function readJudgment(items: Open[], answer: string): Record<string, Kind> {
  const json = answer.slice(answer.indexOf('{'), answer.lastIndexOf('}') + 1);
  let parsed: unknown;
  try {
    parsed = JSON.parse(json);
  } catch {
    return {};
  }
  const labels = parsed && typeof parsed === 'object' ? (parsed as Record<string, unknown>) : {};
  return Object.fromEntries(
    items.flatMap((item, index) => {
      const label = labels[String(index)];
      return label === 'act' || label === 'question' || label === 'none' ? [[item.key, label]] : [];
    }),
  );
}

/** `git worktree list --porcelain` as path, head commit and branch. */
export function parseWorktrees(porcelain: string): Worktree[] {
  return porcelain
    .split('\n\n')
    .map((block) => {
      const field = (key: string) =>
        block
          .split('\n')
          .find((line) => line.startsWith(`${key} `))
          ?.slice(key.length + 1);
      const branch = field('branch');
      return {
        path: field('worktree') ?? '',
        head: field('HEAD') ?? '',
        ...(branch ? { branch: branch.replace(/^refs\/heads\//, '') } : {}),
      };
    })
    .filter((tree) => tree.path);
}

/**
 * A manual gate: something outside GitHub (a deploy, a backfill) that must happen before `blocks` merges. It stays
 * `unknown` until Seth confirms it in the panel; agents can add gates but never confirm them.
 */
export type Gate = {
  id: number;
  blocks: number;
  /** The pull request the gate is about, such as the one to deploy first. */
  after?: number;
  text: string;
  state: 'unknown' | 'confirmed';
  at: number;
  /** The conversation that added it. */
  by?: number;
  confirmedAt?: number;
};
export type Gates = { next: number; gates: Gate[] };

export const initial = (): Gates => ({ next: 1, gates: [] });

const pr = (value: unknown, name: string) => {
  if (typeof value !== 'number' || !Number.isSafeInteger(value) || value < 1)
    throw new Error(`${name} must be a pull request number`);
  return value;
};

export function record(args: unknown): Record<string, unknown> {
  if (!args || typeof args !== 'object' || Array.isArray(args)) throw new Error('Arguments must be an object');
  return args as Record<string, unknown>;
}

/** Adds a gate as `unknown`, or returns the same open gate when one with this `blocks`, `after` and text exists. */
export function addGate(state: Gates, args: unknown, by: number | undefined, now: number): Gate {
  const input = record(args);
  const blocks = pr(input.blocks, 'blocks');
  const after = input.after === undefined || input.after === null ? undefined : pr(input.after, 'after');
  const text = typeof input.text === 'string' ? input.text.trim() : '';
  if (!text || text.length > 200) throw new Error('text must be 1 to 200 characters');
  const same = state.gates.find((gate) => gate.blocks === blocks && gate.after === after && gate.text === text);
  if (same) return { ...same };
  const gate: Gate = {
    id: state.next++,
    blocks,
    ...(after === undefined ? {} : { after }),
    text,
    state: 'unknown',
    at: now,
    ...(by === undefined ? {} : { by }),
  };
  state.gates.push(gate);
  return { ...gate };
}

function find(state: Gates, id: unknown) {
  const gate = state.gates.find((item) => item.id === id);
  if (!gate) throw new Error(`No gate ${String(id)}`);
  return gate;
}

/** Seth's confirmation; repeating it keeps the first time. */
export function confirmGate(state: Gates, id: unknown, now: number): Gate {
  const gate = find(state, id);
  gate.state = 'confirmed';
  gate.confirmedAt ??= now;
  return { ...gate };
}

export function removeGate(state: Gates, id: unknown): Gate {
  const gate = find(state, id);
  state.gates.splice(state.gates.indexOf(gate), 1);
  return { ...gate };
}
