import { afterEach, beforeEach, expect, test } from 'bun:test';
import { copyFileSync, mkdirSync, mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import type { ExtensionAPI, ExtensionContext, ToolCallEventResult } from '@earendil-works/pi-coding-agent';
import prodGuard from '../agent/extensions/prod-guard.ts';

type Handler = (
  event: { toolName: string; input: { command: string } },
  ctx: { hasUI: boolean; ui: Pick<ExtensionContext['ui'], 'confirm'> },
) => Promise<ToolCallEventResult | void>;

const originalAgentDir = process.env.PI_CODING_AGENT_DIR;

let agentDir: string;

let handler: Handler;

beforeEach(() => {
  agentDir = mkdtempSync(join(tmpdir(), 'pi-prod-guard-'));
  mkdirSync(join(agentDir, 'pi-warden'));
  copyFileSync(new URL('../agent/pi-warden/config.json', import.meta.url), join(agentDir, 'pi-warden/config.json'));
  process.env.PI_CODING_AGENT_DIR = agentDir;

  const pi = {
    on(name: string, callback: Handler) {
      expect(name).toBe('tool_call');
      handler = callback;
    },
  };

  // SAFETY: this extension only registers a tool_call handler using the context fields above.
  prodGuard(pi as ExtensionAPI);
});

afterEach(() => {
  if (originalAgentDir === undefined) delete process.env.PI_CODING_AGENT_DIR;
  else process.env.PI_CODING_AGENT_DIR = originalAgentDir;
  rmSync(agentDir, { recursive: true });
});

function call(command: string, approved: boolean, hasUI = true) {
  const prompts: string[][] = [];

  const result = handler(
    { toolName: 'interactive_shell', input: { command } },
    {
      hasUI,
      ui: {
        confirm: async (title, body) => {
          prompts.push([title, body]);

          return approved;
        },
      },
    },
  );

  return { result, prompts };
}

test('production command asks with the rule name and command; yes allows it', async () => {
  const command = 'ssh rxv-core-prod-phx-us-central1-b';
  const { result, prompts } = call(command, true);

  expect(await result).toBeUndefined();
  expect(prompts).toEqual([['Allow production access? (production-ssh-host)', command]]);
});

test('no blocks production access', async () => {
  const { result, prompts } = call('ssh rxv-core-prod-phx-us-central1-b', false);

  expect((await result)?.block).toBe(true);
  expect((await result)?.reason).toContain('user declined');
  expect(prompts).toHaveLength(1);
});

test('staging passes without asking', async () => {
  const { result, prompts } = call('ssh rxv-core-staging-bastion', false);

  expect(await result).toBeUndefined();
  expect(prompts).toHaveLength(0);
});

test('production access without a UI is blocked', async () => {
  const { result, prompts } = call('ssh rxv-core-prod-phx-us-central1-b', true, false);

  expect((await result)?.block).toBe(true);
  expect((await result)?.reason).toContain('no UI');
  expect(prompts).toHaveLength(0);
});
