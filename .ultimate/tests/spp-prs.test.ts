import { describe, expect, test } from 'bun:test';
import {
  addGate,
  confirmGate,
  initial,
  order,
  parseWorktrees,
  rollup,
} from '../../home/code/work/strive/provider_portal/.ultimate/extensions/spp-prs/lib.ts';
import type { GhPull } from '../../home/code/work/strive/provider_portal/.ultimate/extensions/spp-prs/lib.ts';

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
