/** Pure parts of My PRs: GitHub's answer shaped into merge order, and the gates ledger. */

export const DOCUMENT = 'spp-prs.gates';

export type Ci = 'pass' | 'fail' | 'pending' | 'none';
export type Review = 'approved' | 'changes' | 'required' | 'none';

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
