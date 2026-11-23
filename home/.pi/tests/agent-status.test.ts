import { afterEach, describe, expect, test } from 'bun:test';
import agentStatus, { askReport } from '../agent/extensions/agent-status.ts';

type Event = { toolName?: string; messages?: { role: string; content: string; stopReason: string }[] };

type Handler = (event: Event, ctx: { hasUI: boolean }) => void;

const harness = () => {
  const handlers = new Map<string, Handler>();

  // SAFETY: agent-status only calls pi.on.
  agentStatus({ on: (name: string, handler: Handler) => handlers.set(name, handler) } as never);

  return (name: string, event: Event = {}) => handlers.get(name)?.(event, { hasUI: true });
};

const original = { write: process.stdout.write, isTTY: process.stdout.isTTY, rex: process.env.REX_BLOCK };

afterEach(() => {
  process.stdout.write = original.write;
  process.stdout.isTTY = original.isTTY;

  if (original.rex === undefined) delete process.env.REX_BLOCK;
  else process.env.REX_BLOCK = original.rex;
});

describe('agent-status in Rex', () => {
  test('ask_user_question reports a blocked child record, and the answer clears it', () => {
    process.env.REX_BLOCK = '1';
    delete process.env.TMUX;
    process.stdout.isTTY = true;
    const written: string[] = [];
    // SAFETY: the extension only writes strings.
    process.stdout.write = ((chunk: string) => written.push(chunk) > 0) as never;
    const emit = harness();
    emit('session_start');
    emit('agent_start');
    emit('tool_call', { toolName: 'ask_user_question' });
    emit('tool_call', { toolName: 'ask_user_question' });
    emit('tool_execution_end', { toolName: 'ask_user_question' });
    emit('agent_end', { messages: [{ role: 'assistant', content: 'Which one?', stopReason: 'stop' }] });
    emit('input');
    expect(written).toEqual([askReport(true), askReport(false), askReport(true), askReport(false)]);
    expect(askReport(true)).toStartWith('\x1b]7501;state=blocked:kind=question:id=ask:app=pi:msg=');
    expect(askReport(false)).toBe('\x1b]7501;state=clear:id=ask\x1b\\');
  });

  test('outside Rex nothing is written to the terminal', () => {
    delete process.env.REX_BLOCK;
    delete process.env.TMUX;
    process.stdout.isTTY = true;
    const written: string[] = [];
    // SAFETY: the extension only writes strings.
    process.stdout.write = ((chunk: string) => written.push(chunk) > 0) as never;
    const emit = harness();
    emit('session_start');
    emit('tool_call', { toolName: 'ask_user_question' });
    expect(written).toEqual([]);
  });
});
