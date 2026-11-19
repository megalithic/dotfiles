import { describe, expect, test } from 'bun:test';
import {
  addGate,
  confirmGate,
  feedback,
  initial,
  order,
  parseWorktrees,
  pending,
  readJudgment,
  reviewOf,
  rollup,
  rule,
} from '../../home/code/work/strive/provider_portal/.ultimate/extensions/spp-prs/lib.ts';
import type { GhPull, GqlPull } from '../../home/code/work/strive/provider_portal/.ultimate/extensions/spp-prs/lib.ts';

const user = { login: 'reviewer', __typename: 'User' };
const at = (minute: number) => `2026-11-19T10:${String(minute).padStart(2, '0')}:00Z`;
const note = (id: string, body: string, login = 'reviewer', minute = 1) => ({
  id,
  url: `https://github.com/o/r/pull/1#${id}`,
  body,
  createdAt: at(minute),
  updatedAt: at(minute),
  author: { login, __typename: login.endsWith('[bot]') ? 'Bot' : 'User' },
});

const pull = (number: number, head: string, base = 'main', extra: Partial<GhPull> = {}): GhPull => ({
  number,
  title: `PR ${number}`,
  url: `https://github.com/o/r/pull/${number}`,
  isDraft: false,
  baseRefName: base,
  headRefName: head,
  headRefOid: `sha${number}`,
  reviewDecision: null,
  mergeStateStatus: 'CLEAN',
  statusCheckRollup: [],
  ...extra,
});

describe('spp-prs', () => {
  test('orders stacks by base branch, parents first, independents by number', () => {
    // A stack as GitHub returns it (newest first): 20 <- 21 <- 23 <- {25 <- 29, 27 <- 28}.
    const pulls = [
      pull(34, 'solo'),
      pull(29, 's7', 's4'),
      pull(28, 's6', 's5'),
      pull(27, 's5', 's3'),
      pull(25, 's4', 's3'),
      pull(23, 's3', 's2'),
      pull(21, 's2', 's1'),
      pull(20, 's1'),
      pull(16, 'other'),
    ];
    const rows = order(
      pulls,
      parseWorktrees(
        'worktree /p\nHEAD abc\nbranch refs/heads/main\n\nworktree /p/.worktrees/x\nHEAD sha21\ndetached\n',
      ),
    );
    expect(rows.map((row) => `${row.number}:${row.depth}`)).toEqual([
      '16:0',
      '20:0',
      '21:1',
      '23:2',
      '25:3',
      '29:4',
      '27:3',
      '28:4',
      '34:0',
    ]);
    expect(rows.find((row) => row.number === 21)?.worktrees).toEqual(['/p/.worktrees/x']);
  });

  test('rolls up checks: a failure wins, then anything unfinished', () => {
    expect(rollup([])).toBe('none');
    expect(rollup([{ status: 'COMPLETED', conclusion: 'SUCCESS' }, { state: 'SUCCESS' }])).toBe('pass');
    expect(
      rollup([
        { status: 'IN_PROGRESS', conclusion: null },
        { status: 'COMPLETED', conclusion: 'SUCCESS' },
      ]),
    ).toBe('pending');
    expect(rollup([{ status: 'IN_PROGRESS' }, { status: 'COMPLETED', conclusion: 'FAILURE' }])).toBe('fail');
    // A stale check needs a rerun: never shown as passing.
    expect(
      rollup([
        { status: 'COMPLETED', conclusion: 'SUCCESS' },
        { status: 'COMPLETED', conclusion: 'STALE' },
      ]),
    ).toBe('pending');
    expect(
      rollup([
        { status: 'COMPLETED', conclusion: 'SKIPPED' },
        { status: 'COMPLETED', conclusion: 'NEUTRAL' },
      ]),
    ).toBe('pass');
  });

  test('rules: bots, thanks and emoji need nothing; suggestions and requests are changes; "?" asks', () => {
    expect(rule('Deploy preview ready', { login: 'github-actions', __typename: 'Bot' })).toBe('none');
    expect(rule('Please rename this', { login: 'coderabbitai[bot]', __typename: 'User' })).toBe('none');
    for (const chat of ['LGTM', 'Thanks!', '👍', 'Looks good to me 🚀', 'nice work', '+1'])
      expect(rule(chat, user)).toBe('none');
    // Courtesy around a request does not hide it; a nit with a "?" is still a change.
    expect(rule('Thanks, please rename this', user)).toBe('act');
    expect(rule('nit: rename this?', user)).toBe('act');
    expect(rule('```suggestion\nconst x = 1\n```', user)).toBe('act');
    expect(rule('[P2] Keep the fallback when the header is missing', user)).toBe('act');
    expect(rule('nit: trailing comma', user)).toBe('act');
    expect(rule('This should use `Repo.preload/2`.', user)).toBe('act');
    expect(rule('Can you split this into two functions?', user)).toBe('act');
    expect(rule('Why is this async? Is the order guaranteed?', user)).toBe('question');
    // A question mark inside code or a quote is not a question.
    expect(rule('> did you mean x?\nYes, fixed in abc123.', user)).toBeUndefined();
    expect(rule('Interesting approach with the GenServer here.', user)).toBeUndefined();
  });

  test('pending: unresolved current threads not last answered by Seth, and what others said since he spoke', () => {
    const pull: GqlPull = {
      number: 1,
      latestReviews: { nodes: [{ ...note('r1', 'Overall fine, see comments', 'reviewer', 5), state: 'CHANGES_REQUESTED' }] },
      reviewThreads: {
        totalCount: 5,
        nodes: [
          { isResolved: false, isOutdated: false, comments: { nodes: [note('t1', 'nit: rename to `total`')] } },
          { isResolved: false, isOutdated: false, comments: { nodes: [note('t2', 'Why not a Map?')] } },
          { isResolved: false, isOutdated: false, comments: { nodes: [note('t3', 'Done in abc', 'me')] } },
          { isResolved: true, isOutdated: false, comments: { nodes: [note('t4', 'Please fix')] } },
          { isResolved: false, isOutdated: true, comments: { nodes: [note('t5', 'Please fix')] } },
        ],
      },
      comments: {
        nodes: [note('c1', 'Can you rebase?', 'reviewer', 0), note('c2', 'Rebased.', 'me', 3), note('c3', '🎉', 'reviewer', 4)],
      },
    };
    const open = pending(pull, 'me');
    expect(open.map((item) => item.url.split('#')[1])).toEqual(['t1', 't2', 'r1', 'c3']);
    expect(open[0].key).toBe(`t1@${at(1)}`);
    // "Overall fine, see comments" is undecided: the model said none; c3 is an emoji.
    const result = feedback(pull, open, { [`r1@${at(5)}`]: 'none' });
    expect(result).toMatchObject({ threads: 5, unresolved: 4 });
    expect(result.items.map((item) => `${item.kind}:${item.by}`)).toEqual(['act:rule', 'act:rule']);
    // Without a judgment an undecided comment counts as a question.
    expect(feedback(pull, open, {}).items.map((item) => `${item.kind}:${item.by}`)).toEqual([
      'act:rule',
      'act:rule',
      'question:model',
    ]);
    expect(reviewOf('none', pull, 'me')).toBe('changes');
    expect(reviewOf('approved', pull, 'me')).toBe('approved');
  });

  test('reads the model answer by index and drops anything else', () => {
    const open = [{ key: 'a@1', author: 'r', body: 'x', url: '' }, { key: 'b@1', author: 'r', body: 'y', url: '' }];
    expect(readJudgment(open, 'Sure: {"0": "question", "1": "maybe", "7": "act"}')).toEqual({ 'a@1': 'question' });
    expect(readJudgment(open, 'no json')).toEqual({});
  });

  test('gates start unknown, dedupe, and keep the first confirmation', () => {
    const state = initial();
    const gate = addGate(state, { blocks: 23, after: 21, text: ' run the migration ' }, 17961, 100);
    expect(gate).toMatchObject({
      id: 1,
      blocks: 23,
      after: 21,
      text: 'run the migration',
      state: 'unknown',
      by: 17961,
    });
    expect(addGate(state, { blocks: 23, after: 21, text: 'run the migration' }, 5, 200).id).toBe(1);
    expect(() => addGate(state, { blocks: 'x', text: 't' }, undefined, 1)).toThrow('blocks');
    expect(confirmGate(state, 1, 300).confirmedAt).toBe(300);
    expect(confirmGate(state, 1, 400).confirmedAt).toBe(300);
  });
});
