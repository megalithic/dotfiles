import { execFileSync } from 'node:child_process';
import crypto from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { Type } from 'typebox';
import { Check } from 'typebox/value';

export const batonSchema = Type.Object({
  v: Type.Literal(1),
  holder: Type.Union([Type.Literal('ultimate'), Type.Literal('pi')]),
  worktree: Type.String(),
  at: Type.String(),
  by: Type.Union([Type.Literal('pickup'), Type.Literal('release'), Type.Literal('take')]),
  ultimate: Type.Optional(Type.Object({ url: Type.String(), project: Type.String(), conversation: Type.Integer() })),
  pi: Type.Optional(
    Type.Object({
      sessionId: Type.Optional(Type.String()),
      pid: Type.Optional(Type.Integer()),
      label: Type.Optional(Type.String()),
    }),
  ),
});

export type Baton = Type.Static<typeof batonSchema>;

export const resolveToplevel = (cwd: string): string =>
  execFileSync('git', ['rev-parse', '--show-toplevel'], {
    cwd,
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
  }).trim();

export const batonPath = (worktree: string): string => path.join(worktree, '.local/state/agent-baton.json');

export const readBaton = (worktree: string): Baton | undefined => {
  let text: string;

  try {
    text = fs.readFileSync(batonPath(worktree), 'utf8');
  } catch (error) {
    if (error instanceof Error && 'code' in error && error.code === 'ENOENT') return undefined;
    throw error;
  }

  const value: unknown = JSON.parse(text);

  if (!Check(batonSchema, value) || value.worktree !== worktree) throw new Error(`Invalid baton for ${worktree}`);

  return value;
};

export const writeBaton = (baton: Baton): void => {
  const file = batonPath(baton.worktree);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  const temporary = `${file}.${crypto.randomUUID()}.tmp`;

  try {
    fs.writeFileSync(temporary, JSON.stringify(baton) + '\n', { mode: 0o600, flag: 'wx' });
    fs.renameSync(temporary, file);
  } finally {
    fs.rmSync(temporary, { force: true });
  }
};

export const batonStatus = (baton: Baton | undefined): string | undefined =>
  baton?.holder === 'ultimate' ? `Ultimate #${baton.ultimate?.conversation ?? '?'} holds this worktree` : undefined;

export const guardDecision = (tool: string, baton: Baton | undefined): { block: true; reason: string } | undefined => {
  if (!['edit', 'write', 'bash', 'interactive_shell'].includes(tool) || baton?.holder !== 'ultimate') return undefined;

  return {
    block: true,
    reason: `Ultimate #${baton.ultimate?.conversation ?? '?'} (${baton.ultimate?.url ?? 'unknown URL'}) holds the baton for ${baton.worktree} since ${baton.at}; it hands back with release. Ask Seth, or run /baton take.`,
  };
};

/** Only caller-provided text goes here, never session JSONL or credentials. */
export const spillHandoff = (text: string): string => {
  if (text.length <= 32768) return text;

  const state =
    process.env.PI_STATE_DIR || path.join(process.env.XDG_STATE_HOME || path.join(os.homedir(), '.local/state'), 'pi');

  const dir = path.join(state, 'handoff');
  fs.mkdirSync(dir, { recursive: true, mode: 0o700 });
  fs.chmodSync(dir, 0o700);
  const file = path.join(dir, `${crypto.randomUUID()}.md`);
  fs.writeFileSync(file, text, { mode: 0o600, flag: 'wx' });

  return `Full handoff: ${file}\n\n${text.slice(0, 2000)}\n\n[Preview; read the file for the full handoff.]`;
};
