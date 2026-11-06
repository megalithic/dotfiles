/**
 * Minimal ACP agent for the Tidewave IDE ("External Agent": `bun ~/.pi/agent/extensions/pidewave/acp.ts`).
 *
 * Speaks ACP (ndjson JSON-RPC 2.0, protocol v1) on stdio. On `session/prompt`
 * it finds the Pi holding the pidewave lease for the session's worktree and
 * forwards the prompt text with `pi.control.v1 message.send`, emits one
 * `agent_message_chunk` describing the outcome, and returns `end_turn`. No
 * streaming or cancel: replies are read in that Pi's terminal.
 *
 * Not an extension: Pi only loads `pidewave/index.ts`.
 */

import fs from 'node:fs';
import path from 'node:path';
import { createInterface } from 'node:readline';
import { fileURLToPath } from 'node:url';
import { holderAlive, leaseDir, listLeases } from './lease.ts';
import { isJsonNumber, isJsonObject, isJsonString, type JsonValue, promptRequest, sendControl } from './shared.ts';

const inside = (child: string, parent: string): boolean => {
  const rel = path.relative(path.resolve(parent), path.resolve(child));

  return rel === '' || (!rel.startsWith('..') && !path.isAbsolute(rel));
};

/** Forward a prompt to the lease holder whose worktree contains `cwd`. */
export const forwardToHolder = async (
  cwd: string,
  text: string,
  dir = leaseDir(),
): Promise<{ ok: boolean; detail: string }> => {
  const holders = listLeases(dir).filter((lease) => inside(cwd, lease.root) && holderAlive(lease));
  // The deepest root wins when worktrees nest under the main checkout.
  const lease = holders.sort((a, b) => b.root.length - a.root.length)[0];

  if (!lease) {
    return {
      ok: false,
      detail: 'No Pi holds the Tidewave link for this worktree. Start Pi there, or run /pidewave claim.',
    };
  }

  if (!lease.socket || !fs.existsSync(lease.socket)) {
    return { ok: false, detail: `The Pi holding ${lease.origin} has no bridge socket.` };
  }

  const res = await sendControl(lease.socket, promptRequest(text));

  if (res?.ok === true) return { ok: true, detail: `Forwarded to ${lease.sessionName ?? lease.tellId ?? 'Pi'}.` };

  return { ok: false, detail: res?.error || 'The Pi did not accept the message (control.v1 message.send failed).' };
};

const PROTOCOL_VERSION = 1;

type RpcId = string | number;

type AcpParams = { cwd?: string; sessionId?: string; prompt: string };

type AcpRequest = { id?: RpcId | null; method: string; params: AcpParams };

class AcpError extends Error {
  readonly code: number;

  constructor(code: number, message: string) {
    super(message);
    this.code = code;
  }
}

/** Decode only text-bearing ACP blocks; unsupported or malformed blocks are ignored. */
const textFromBlocks = (blocks: JsonValue | undefined): string => {
  if (!Array.isArray(blocks)) return '';

  return blocks
    .map((block) => {
      if (!isJsonObject(block)) return '';

      if (block.type === 'text' && isJsonString(block.text)) return block.text;

      if (block.type === 'resource_link' && isJsonString(block.uri)) return block.uri;

      if (block.type !== 'resource' || !isJsonObject(block.resource)) return '';

      const resource = block.resource;

      if (isJsonString(resource.text)) return resource.text;

      if (isJsonString(resource.uri)) return resource.uri;

      return '';
    })
    .filter(Boolean)
    .join('\n')
    .trim();
};

const parseAcpRequest = (text: string): AcpRequest | null => {
  const value: JsonValue = JSON.parse(text);

  if (!isJsonObject(value) || !isJsonString(value.method)) return null;

  const { id, method } = value;

  if (id !== undefined && id !== null && !isJsonString(id) && !isJsonNumber(id)) return null;

  const params = isJsonObject(value.params) ? value.params : {};

  return {
    id,
    method,
    params: {
      cwd: isJsonString(params.cwd) ? params.cwd : undefined,
      sessionId: isJsonString(params.sessionId) ? params.sessionId : undefined,
      prompt: textFromBlocks(params.prompt),
    },
  };
};

const log = (msg: string): void => {
  try {
    process.stderr.write(`[pidewave-acp] ${msg}\n`);
  } catch {}
};

const runAcpShim = (): void => {
  const sessions = new Map<string, { cwd: string }>();
  let counter = 0;

  type AcpResult = Awaited<ReturnType<(typeof handlers)[keyof typeof handlers]>>;

  type AcpMessage =
    | { id: RpcId; result: AcpResult }
    | { id: RpcId; error: { code: number; message: string } }
    | {
        method: 'session/update';
        params: {
          sessionId: string;
          update: { sessionUpdate: 'agent_message_chunk'; content: { type: 'text'; text: string } };
        };
      };

  const send = (msg: AcpMessage): void => {
    try {
      process.stdout.write(`${JSON.stringify({ jsonrpc: '2.0', ...msg })}\n`);
    } catch {}
  };

  const reply = (id: RpcId, result: AcpResult): void => send({ id, result });

  const replyError = (id: RpcId, code: number, message: string): void => send({ id, error: { code, message } });

  const sessionChunk = (sessionId: string, text: string): void =>
    send({
      method: 'session/update',
      params: {
        sessionId,
        update: {
          sessionUpdate: 'agent_message_chunk',
          content: { type: 'text', text },
        },
      },
    });

  const handlers = {
    initialize: async (_params: AcpParams) => ({
      protocolVersion: PROTOCOL_VERSION,
      agentInfo: {
        name: 'pidewave-acp',
        title: 'Pi forwarder',
        version: '1.0.0',
      },
      authMethods: [],
      agentCapabilities: {
        loadSession: false,
        mcpCapabilities: { http: false, sse: false },
        promptCapabilities: {
          image: false,
          audio: false,
          embeddedContext: false,
        },
      },
    }),

    authenticate: async (_params: AcpParams) => ({}),

    'session/new': async (params: AcpParams) => {
      const cwd = params.cwd ?? process.cwd();
      counter += 1;
      const sessionId = `pidewave-${Date.now().toString(36)}-${counter}`;
      sessions.set(sessionId, { cwd });
      log(`session/new ${sessionId} cwd=${cwd}`);

      return { sessionId };
    },

    'session/prompt': async (params: AcpParams) => {
      const sessionId = params.sessionId;
      const session = sessionId ? sessions.get(sessionId) : undefined;

      if (!session || !sessionId) {
        throw new AcpError(-32602, `unknown sessionId: ${sessionId}`);
      }

      const text = params.prompt;

      if (!text) {
        sessionChunk(sessionId, 'Empty prompt; nothing forwarded.');

        return { stopReason: 'end_turn' };
      }

      const { ok, detail } = await forwardToHolder(session.cwd, text);
      log(`session/prompt ${sessionId} ok=${ok} ${detail}`);
      sessionChunk(sessionId, ok ? `✓ ${detail}` : `✗ ${detail}`);

      return { stopReason: 'end_turn' };
    },
  };

  const rl = createInterface({ input: process.stdin, crlfDelay: Infinity });
  rl.on('line', (line) => {
    const trimmed = line.trim();

    if (!trimmed) return;
    let msg: AcpRequest | null;

    try {
      msg = parseAcpRequest(trimmed);
    } catch {
      log(`ignoring non-JSON line: ${trimmed.slice(0, 120)}`);

      return;
    }

    if (!msg) return; // malformed input or a response; we never ask.

    const { id, method, params } = msg;
    const isNotification = id === undefined || id === null;

    if (method === 'session/cancel' || method.startsWith('$/')) return; // nothing in flight to cancel.
    // Own entries only: arbitrary RPC methods must not call Object.prototype.
    const handler = Object.entries(handlers).find(([name]) => name === method)?.[1];

    if (!handler) {
      if (!isNotification) replyError(id, -32601, `method not supported: ${method}`);

      return;
    }

    void handler(params)
      .then((result) => {
        if (!isNotification) reply(id, result);
      })
      .catch((err) => {
        if (isNotification) return;

        if (err instanceof AcpError) {
          replyError(id, err.code, err.message);
        } else {
          replyError(id, -32603, err instanceof Error ? err.message : String(err));
        }
      });
  });

  const shutdown = (): void => {
    try {
      process.exit(0);
    } catch {}
  };

  rl.on('close', shutdown);
  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
  process.stdout.on('error', shutdown);
  log(`ready (leases: ${leaseDir()})`);
};

// Run the ACP agent only when executed directly (bun acp.ts), never when imported.
const isMain = (() => {
  try {
    return process.argv[1] !== undefined && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);
  } catch {
    return false;
  }
})();

if (isMain) runAcpShim();
