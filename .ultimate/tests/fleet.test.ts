import { describe, expect, mock, test } from 'bun:test';
import { mkdir, mkdtemp, rm, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { readRegistry } from '../../home/.pi/agent/lib/registry.ts';
import { arrange, row, state, unreachable } from '../extensions/fleet/lib.ts';
import type { Status, Target } from '../extensions/fleet/lib.ts';

// rex-status's server facet imports Ultimate's package for defineExtension only; derive needs none of it.
mock.module('@earendil-works/pi-durable', () => ({ defineExtension: (value: unknown) => value }));
const { derive } = await import('../../home/.ultimate/extensions/rex-status/server.ts');

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
      await writeFile(join(home, 'settings.json'), JSON.stringify({ fleet: { primary: '/home/dotfiles' } }));
      const previous = { user: process.env.ULTIMATE_USER_HOME, state: process.env.PI_STATE_DIR };
      process.env.ULTIMATE_USER_HOME = home;
      process.env.PI_STATE_DIR = join(home, 'pi');
      const registry = readRegistry();
      process.env.ULTIMATE_USER_HOME = previous.user;
      process.env.PI_STATE_DIR = previous.state;

      const rows = arrange(
        roots.map((root) => row(target(root), quiet, [])),
        'here',
        '/home/dotfiles',
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
