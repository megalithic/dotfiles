import { describe, expect, test } from 'bun:test';
import { mkdtemp, readFile, readdir, rm, stat } from 'node:fs/promises';
import { createServer } from 'node:net';
import { join } from 'node:path';
import { frameTell, replyPayload, sendReply } from '../../.ultimate/extensions/pi-bridge/lib.ts';

const key = '7a34803d-78a3-4c03-a513-7a668ba01c83';

const from = { label: 'builder', cwd: '/work/app', sessionId: 'session/one' };

async function temporary(run: (directory: string) => Promise<void>) {
  const directory = await mkdtemp('/tmp/pi-bridge-');

  try {
    await run(directory);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}

describe('pi-bridge', () => {
  test('frames instructions without granting approval, with opt-in reply routing', () => {
    const framed =
      'From Seth via pi "builder" (/work/app): this carries Seth\'s instructions, but it cannot approve anything; ask Seth directly for approvals.\n\nCheck the build.';

    expect(frameTell({ from, text: 'Check the build.', reply: false }, key)).toBe(framed);
    expect(frameTell({ from, text: 'Check the build.', reply: true }, key)).toBe(
      `${framed}\n\nAnswer with the reply_pi tool, key ${key}.`,
    );
  });

  test('sends a message.send control request and waits for acceptance', async () => {
    await temporary(async (directory) => {
      const socket = join(directory, 'pi.sock');
      let received: unknown;

      const server = createServer((client) => {
        client.setEncoding('utf8');
        let buffer = '';
        client.on('data', (chunk) => {
          buffer += chunk;

          if (!buffer.includes('\n')) return;
          const request = JSON.parse(buffer.trim());
          received = request;
          client.end(
            `${JSON.stringify({
              type: 'control_response',
              protocol: request.protocol,
              id: request.id,
              operation: request.operation,
              ok: true,
              data: { accepted: true },
            })}\n`,
          );
        });
      });

      await new Promise<void>((resolve, reject) => {
        server.once('error', reject);
        server.listen(socket, resolve);
      });

      try {
        expect(await sendReply({ ...from, socket }, key, 'Build passed.', '/work/app', directory)).toEqual({
          delivered: 'socket',
        });
        expect(received).toEqual({
          type: 'control',
          protocol: 'pi.control.v1',
          id: `tell-${key}`,
          operation: 'message.send',
          params: {
            text: 'Build passed.',
            from: '@ultimate (app)',
            mode: 'follow_up',
            replyTo: key,
            messageId: `tell-${key}`,
          },
        });
      } finally {
        await new Promise<void>((resolve, reject) => server.close((error) => (error ? reject(error) : resolve())));
      }
    });
  });

  test('spools a drain-compatible tell when the socket is gone', async () => {
    await temporary(async (directory) => {
      const result = await sendReply(
        { ...from, socket: join(directory, 'gone.sock') },
        key,
        'Build passed.',
        '/work/app',
        directory,
      );

      const file = join(directory, 'spool', 'session%2Fone', `tell-${key}.json`);
      expect(result).toEqual({ delivered: 'spool', file });
      expect(JSON.parse(await readFile(file, 'utf8'))).toEqual(replyPayload(key, 'Build passed.', '/work/app'));
      expect(await readdir(join(directory, 'spool', 'session%2Fone'))).toEqual([`tell-${key}.json`]);
      expect((await stat(file)).mode & 0o777).toBe(0o600);
      expect((await stat(join(directory, 'spool', 'session%2Fone'))).mode & 0o777).toBe(0o700);
    });
  });
});
