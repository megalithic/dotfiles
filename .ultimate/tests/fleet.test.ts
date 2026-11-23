import { describe, expect, mock, test } from 'bun:test';
import { mkdir, mkdtemp, rm, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { readRegistry } from '../../home/.pi/agent/lib/registry.ts';
import { arrange, row, state, unreachable } from '../extensions/fleet/lib.ts';
import type { Status, Target } from '../extensions/fleet/lib.ts';

// rex-status's server facet imports Ultimate's packages for its host wiring only; derive needs none of it.
mock.module('@earendil-works/pi-durable', () => ({ defineExtension: (value: unknown) => value }));
mock.module('@earendil-works/chord/context', () => ({ BACKGROUND_CONTEXT: {} }));
const { derive, openItems, osc } = await import('../../home/.ultimate/extensions/rex-status/server.ts');

const target = (root: string, machine = 'here'): Target => ({
  name: root.split('/').at(-1)!,
  root,
  url: 'http://127.0.0.1:4747',
  machine,
  current: false,
});
const quiet: Status = { busy: 0, questions: { count: 0 } };

describe('fleet', () => {
  test('hub roles and memberships match the agent registry', async () => {
    const home = await mkdtemp('/tmp/fleet-');
    const roots = [
      '/work/strive',
      '/work/strive/portal',
      '/work/strive/devops',
      '/work/strive/devops/charts',
      '/home/dotfiles',
      '/code/swifties',
    ];
    try {
      for (const [index, root] of roots.entries()) {
        await mkdir(join(home, 'projects', String(index)), { recursive: true });
        await writeFile(
          join(home, 'projects', String(index), 'ultimate.lock'),
          JSON.stringify({ pid: process.pid, port: 4747 + index, project: root }),
        );
      }
      // Unnormalized on purpose: both resolve it before comparing.
      const primary = '/home/./dotfiles/';
      await writeFile(join(home, 'settings.json'), JSON.stringify({ fleet: { primary } }));
      const previous = { user: process.env.ULTIMATE_USER_HOME, state: process.env.PI_STATE_DIR };
      process.env.ULTIMATE_USER_HOME = home;
      process.env.PI_STATE_DIR = join(home, 'pi');
      const registry = readRegistry();
      process.env.ULTIMATE_USER_HOME = previous.user;
      process.env.PI_STATE_DIR = previous.state;

      const rows = arrange(
        roots.map((root) => row(target(root), quiet, [])),
        'here',
        primary,
      );
      const fleetRoles = Object.fromEntries(rows.flatMap((item) => (item.role ? [[item.root, item.role]] : [])));
      const registryRoles = Object.fromEntries(
        registry.ultimates.flatMap((item) => (item.hub ? [[item.project, item.hub]] : [])),
      );
      expect(fleetRoles).toEqual(registryRoles);
      expect(fleetRoles).toEqual({
        '/home/dotfiles': 'primary',
        '/work/strive': 'secondary',
        '/work/strive/devops': 'secondary',
      });
      expect(Object.fromEntries(rows.map((item) => [item.root, item.hub]))).toEqual({
        '/work/strive': undefined,
        '/work/strive/portal': '/work/strive',
        '/work/strive/devops': '/work/strive',
        '/work/strive/devops/charts': '/work/strive/devops',
        '/home/dotfiles': undefined,
        '/code/swifties': undefined,
      });
    } finally {
      await rm(home, { recursive: true, force: true });
    }
  });

  test('states match the Rex tab states', () => {
    const cases: Status[] = [
      quiet,
      { busy: 2, questions: { count: 0 } },
      { busy: 2, questions: { count: 1, first: { text: 'Ship it?', conversation: 4 } } },
    ];
    for (const status of cases) expect(state(status)).toBe(derive(status).state);
  });

  test('rex-status counts open questions plus open Inbox items, as rtm needs does', () => {
    const items = openItems({ items: [{}, { done: 5 }, { done: null }, { done: false }] });
    expect(items).toBe(3);
    expect(openItems(undefined)).toBe(0);
    const asked = derive({ busy: 1, questions: { count: 1, first: { text: 'Ship\n it?' } } }, items);
    expect(asked).toEqual({ state: 'blocked', kind: 'question', msg: '4 waiting · Ship it?' });
    expect(osc(asked)).toBe(
      `\x1b]7501;state=blocked:kind=question:app=ultimate:msg=${Buffer.from('4 waiting · Ship it?').toString('base64')}\x1b\\`,
    );
    // Items alone wait too, without claiming a question.
    expect(derive(quiet, 2)).toEqual({ state: 'blocked', msg: '2 waiting' });
    expect(derive({ busy: 2, questions: { count: 0 } }, 0).state).toBe('working');
  });

  test('a row carries the question, busy titles, failures and failing providers', () => {
    const result = row(
      target('/code/swifties'),
      {
        busy: 2,
        questions: { count: 2, first: { text: 'questions 1. Ship\n it?', conversation: 57 } },
        failures: [
          { conversation: 42, title: 'Fix the build', error: '429' },
          { conversation: 9, error: 'x' },
        ],
        providers: [
          { provider: 'anthropic', state: 'ok' },
          { provider: 'openai-codex', state: 'failing' },
        ],
        head: { behind: 3 },
      },
      [
        { id: 1, title: '@ultimate', busy: true },
        { id: 2, title: 'idle', busy: false },
        { id: 3, busy: true },
      ],
    );
    expect(result).toMatchObject({
      state: 'blocked',
      question: { text: 'questions 1. Ship it?', conversation: 57, more: 1 },
      working: [{ id: 1, title: '@ultimate' }],
      failures: { count: 2, last: { conversation: 42, title: 'Fix the build', error: '429' } },
      providers: ['openai-codex'],
      behind: 3,
    });
  });

  test('malformed answers from another instance never reach the UI', () => {
    expect(() => row(target('/x'), { busy: '2', questions: {} }, [])).toThrow('answered without a status');
    const result = row(
      target('/x'),
      {
        busy: 1,
        questions: { count: 1, first: { text: { bad: 'object' }, conversation: 4 } },
        failures: [{ conversation: 'x', error: 'e' }, { conversation: 2, error: ['e'] }, 'junk'],
        providers: [{ provider: 7, state: 'failing' }],
        head: { behind: -1 },
      },
      [{ id: 1, title: { bad: 'object' }, busy: true }, { id: '2', title: 't', busy: true }, null],
    );
    expect(result).toMatchObject({ state: 'blocked', working: [], failures: { count: 0 }, providers: [] });
    expect(result.question).toBeUndefined();
    expect(result.behind).toBeUndefined();
  });

  test('remote rows get no hub, and an unreachable local instance still makes its parent a hub', () => {
    const rows = arrange(
      [
        row(target('/work/strive'), quiet, []),
        unreachable(target('/work/strive/portal'), 'no answer in 3 s'),
        row(target('/work/strive/devops', 'megabookpro'), quiet, []),
      ],
      'here',
    );
    expect(rows.map((item) => [item.role, item.hub, item.state])).toEqual([
      ['secondary', undefined, 'idle'],
      [undefined, '/work/strive', 'unreachable'],
      [undefined, undefined, 'idle'],
    ]);
  });
});
