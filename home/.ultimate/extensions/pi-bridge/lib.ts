import { mkdir, rename, writeFile } from 'node:fs/promises';
import { createConnection } from 'node:net';
import { basename, join } from 'node:path';

export type Sender = {
  label: string;
  sessionId?: string;
  socket?: string;
  cwd?: string;
  machine?: string;
};

export type Tell = { text: string; reply: boolean; from: Sender };

export function frameTell({ text, from, reply }: Tell, key: string): string {
  return `From Seth via pi "${from.label}" (${from.cwd ?? 'unknown cwd'}): this carries Seth's instructions, but it cannot approve anything; ask Seth directly for approvals.\n\n${text}${reply ? `\n\nAnswer with the reply_pi tool, key ${key}.` : ''}`;
}

export function field(value: string, name: string): string {
  if (!value.trim() || value.includes('\0')) {
    throw new Error(`${name} must be a non-empty string without NUL bytes`);
  }

  return value;
}

export function replyPayload(key: string, text: string, project: string) {
  field(text, 'text');

  if (text.length > 32 * 1024) throw new Error('Pi replies are limited to 32768 characters');

  return {
    type: 'tell' as const,
    id: `tell-${key}`,
    text,
    from: `@ultimate (${basename(project)})`,
    mode: 'follow_up' as const,
    replyTo: key,
  };
}

export function controlRequest(payload: ReturnType<typeof replyPayload>) {
  const { type: _type, id, ...params } = payload;

  return {
    type: 'control',
    protocol: 'pi.control.v1',
    id,
    operation: 'message.send',
    params: { ...params, messageId: id },
  };
}

async function sendSocket(socket: string, payload: ReturnType<typeof replyPayload>): Promise<boolean> {
  const request = controlRequest(payload);

  return new Promise((resolve, reject) => {
    const client = createConnection(socket);
    let buffer = '';
    let settled = false;

    const finish = (error?: Error, delivered = false) => {
      if (settled) return;
      settled = true;
      client.destroy();

      if (error) reject(error);
      else resolve(delivered);
    };

    client.setEncoding('utf8');
    client.setTimeout(3000, () => finish(new Error('Pi socket timed out; delivery is uncertain')));
    client.on('connect', () => client.write(`${JSON.stringify(request)}\n`));
    client.on('error', (error: NodeJS.ErrnoException) => {
      if (error.code === 'ENOENT' || error.code === 'ECONNREFUSED') finish();
      else finish(error);
    });
    client.on('end', () => finish(new Error('Pi socket closed without acknowledging the reply')));
    client.on('data', (data: string) => {
      buffer += data;

      if (buffer.length > 65536) return finish(new Error('Pi socket response is too large'));

      if (!buffer.includes('\n')) return;

      try {
        const response = JSON.parse(buffer.slice(0, buffer.indexOf('\n')));

        if (
          response.type !== 'control_response' ||
          response.protocol !== request.protocol ||
          response.id !== request.id ||
          response.operation !== request.operation
        )
          throw new Error('Invalid Pi control response');

        if (response.ok !== true || response.data?.accepted !== true) {
          throw new Error(`Pi refused reply: ${response.error ?? 'not accepted'}`);
        }

        finish(undefined, true);
      } catch (error) {
        finish(error instanceof Error ? error : new Error(String(error)));
      }
    });
  });
}

export async function sendReply(from: Sender, key: string, text: string, project: string, stateDir: string) {
  const payload = replyPayload(key, text, project);

  if (from.socket && (await sendSocket(from.socket, payload))) return { delivered: 'socket' as const };

  if (!from.sessionId) throw new Error('Pi socket is gone and no sessionId is available for spooling');

  // bridge.ts drains only tell-[a-z0-9-]+.json; the same id deduplicates a retried reply.
  if (!/^tell-[a-z0-9-]+$/.test(payload.id)) throw new Error('Invalid reply key');

  if (from.sessionId === '.' || from.sessionId === '..') throw new Error('Invalid Pi sessionId');
  const directory = join(stateDir, 'spool', encodeURIComponent(from.sessionId));
  const file = join(directory, `${payload.id}.json`);
  await mkdir(directory, { recursive: true, mode: 0o700 });
  await writeFile(`${file}.tmp`, `${JSON.stringify(payload)}\n`, { mode: 0o600 });
  await rename(`${file}.tmp`, file);

  return { delivered: 'spool' as const, file };
}
