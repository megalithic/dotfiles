/**
 * Pidewave helpers shared by the extension, the ACP agent, and the lease readers.
 * Paths are read from the environment at call time so tests can point them anywhere.
 */

import net from 'node:net';
import os from 'node:os';
import path from 'node:path';

export type JsonValue = null | boolean | number | string | JsonValue[] | { [key: string]: JsonValue };

// These predicates are only for untouched JSON.parse results. JSON cannot
// contain boxed primitives, proxies, or Symbol.toStringTag overrides.
export const isJsonString = (value: JsonValue | undefined): value is string =>
  Object.prototype.toString.call(value) === '[object String]';

export const isJsonObject = (value: JsonValue | undefined): value is { [key: string]: JsonValue } =>
  Object.prototype.toString.call(value) === '[object Object]';

export const isJsonNumber = (value: JsonValue | undefined): value is number => Number.isFinite(value);

export const piStateDir = (env: NodeJS.ProcessEnv = process.env): string =>
  env.PI_STATE_DIR ||
  path.join(env.XDG_STATE_HOME || (env.HOME ? path.join(env.HOME, '.local', 'state') : '/tmp'), 'pi');

/** Same machine name and target grammar as tell.ts (`pi:<machine>:<sessionId>`). */
export const tellId = (sessionId: string, env: NodeJS.ProcessEnv = process.env): string => {
  const machine = (env.HOSTNAME || os.hostname()).split('.')[0]?.trim() || 'localhost';

  return `pi:${machine}:${encodeURIComponent(sessionId)}`;
};

export type ControlOperation = 'message.send' | 'pidewave.inspect';

export type ControlRequest = {
  type: 'control';
  protocol: 'pi.control.v1';
  id: string;
  operation: ControlOperation;
  params?: { text: string; mode: 'follow_up'; from: 'tidewave' };
};

export type ControlResponse = { ok: boolean; error?: string };

const CONNECT_TIMEOUT_MS = 800;

const parseControlResponse = (text: string): ControlResponse | null => {
  const value: JsonValue = JSON.parse(text);

  if (!isJsonObject(value) || (value.ok !== true && value.ok !== false)) return null;

  return { ok: value.ok, error: isJsonString(value.error) ? value.error : undefined };
};

/** Send one line-delimited `pi.control.v1` request to a bridge socket; null when it never answers. */
export const sendControl = (socketPath: string, payload: ControlRequest): Promise<ControlResponse | null> =>
  new Promise((resolve) => {
    const socket = net.createConnection(socketPath);
    let buffer = '';
    let settled = false;

    const finish = (result: ControlResponse | null): void => {
      if (settled) return;
      settled = true;
      socket.destroy();
      resolve(result);
    };

    socket.setTimeout(CONNECT_TIMEOUT_MS, () => finish(null));
    socket.on('error', () => finish(null));
    socket.on('connect', () => {
      socket.write(`${JSON.stringify(payload)}\n`);
    });
    socket.on('data', (chunk) => {
      buffer += chunk.toString();
      const idx = buffer.indexOf('\n');

      if (idx === -1) return;
      const line = buffer.slice(0, idx).trim();

      if (!line) return;

      try {
        finish(parseControlResponse(line));
      } catch {
        finish(null);
      }
    });
    socket.on('close', () => finish(null));
  });

export const controlId = (): string => `pidewave-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 6)}`;

/** Prompt delivery over a bridge socket, with the Tidewave source label bridge.ts renders. */
export const promptRequest = (text: string): ControlRequest => ({
  type: 'control',
  protocol: 'pi.control.v1',
  id: controlId(),
  operation: 'message.send',
  params: { text, mode: 'follow_up', from: 'tidewave' },
});
