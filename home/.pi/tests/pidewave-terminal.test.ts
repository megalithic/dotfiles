import { describe, expect, test } from 'bun:test';
import { ancestors, appFor, focusTerminal, type Run } from '../agent/extensions/pidewave/terminal.ts';

const REX_SERVER =
  '/Users/me/Library/Application Support/com.superlogical.rex/RexServer/Versions/1/Rex Server.app/Contents/MacOS/rex';

// pid ppid command, like `ps -axo pid=,ppid=,comm=`.
const table = [
  `  50     1 ${REX_SERVER}`,
  '  51    50 /usr/bin/login',
  '  52    51 -fish',
  '  60    52 tmux',
  '  70     1 /Applications/Ghostty.app/Contents/MacOS/ghostty',
  '  71    70 -fish',
  '  72    71 node',
].join('\n');

const recorder = (answers: { [command: string]: string | undefined }) => {
  const calls: string[] = [];

  const exec: Run = async (command, args) => {
    const line = [command, ...args].join(' ');
    calls.push(line);
    const key = Object.keys(answers).find((prefix) => line.startsWith(prefix));

    return key === undefined ? '' : answers[key];
  };

  return { calls, exec };
};

describe('process ancestry', () => {
  test('walks parents to the owning app; Rex terminals map to the Rex app', () => {
    expect(ancestors(60, table).map((entry) => entry.pid)).toEqual([60, 52, 51, 50]);
    expect(appFor(ancestors(60, table))).toEqual({ bundle: 'com.superlogical.rex' });
    expect(appFor(ancestors(72, table))).toEqual({ path: '/Applications/Ghostty.app' });
    expect(appFor(ancestors(999, table))).toBeUndefined();
  });
});

describe('focus', () => {
  test('Rex: select the session, focus the block, raise Rex', async () => {
    const { calls, exec } = recorder({});
    const error = await focusTerminal({ kind: 'rex', rex: { session: 'session:1', block: 'block:2' } }, exec);
    expect(error).toBeUndefined();
    expect(calls).toEqual([
      'rex do session.select session_id=session:1',
      'rex focus -s session:1 block:2',
      'open -b com.superlogical.rex',
    ]);
  });

  test('Rex: a failed focus is reported', async () => {
    const { exec } = recorder({ 'rex focus': undefined });
    expect(await focusTerminal({ kind: 'rex', rex: { session: 's', block: 'b' } }, exec)).toContain('could not focus');
  });

  test('tmux inside Rex: switch the pane, then focus the Rex block that runs the latest tmux client', async () => {
    const { calls, exec } = recorder({
      'tmux display-message': 'work\t3\n',
      'tmux list-clients': '100\t70\t/dev/ttys001\n200\t60\t/dev/ttys002\n',
      ps: table,
      'rex ls': JSON.stringify({ sessions: [{ session_id: 'session:a' }] }),
      'rex session inspect': JSON.stringify({
        windows: [{ layout: { block_id: 'block:x' } }, { block_id: 'block:y' }],
      }),
      'rex block call -s session:a -b block:x': JSON.stringify({ child: { pid: 999 } }),
      'rex block call -s session:a -b block:y': JSON.stringify({ child: { pid: 51 } }),
    });

    expect(await focusTerminal({ kind: 'tmux', tmux: { pane: '%7' } }, exec)).toBeUndefined();
    expect(calls).toContain(
      'tmux switch-client -c /dev/ttys002 -t =work ; select-window -t =work:3 ; select-pane -t %7',
    );
    expect(calls.slice(-3)).toEqual([
      'rex do session.select session_id=session:a',
      'rex focus -s session:a block:y',
      'open -b com.superlogical.rex',
    ]);
  });

  test('tmux: a vanished pane is reported', async () => {
    const { exec } = recorder({ 'tmux display-message': undefined });
    expect(await focusTerminal({ kind: 'tmux', tmux: { pane: '%7' } }, exec)).toBe('tmux pane %7 is gone.');
  });

  test('plain: raise the app that started this process', async () => {
    const { calls, exec } = recorder({ ps: table });
    expect(await focusTerminal({ kind: 'plain' }, exec, 72)).toBeUndefined();
    expect(calls.at(-1)).toBe('open -a /Applications/Ghostty.app');
  });
});
