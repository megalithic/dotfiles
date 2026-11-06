/**
 * Port lease: `${PI_STATE_DIR}/pidewave/ports/<port>.json` names the one Pi that
 * receives browser prompts for a Phoenix port. A Pi claims it at start when it is
 * free or its holder is dead; Inspect and `/pidewave claim` take it over. Readers
 * (rwt, the ACP agent, the pidewave CLI) only read the file.
 */

import { Type } from 'typebox';
import { Value } from 'typebox/value';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { piStateDir } from './shared.ts';

const terminalSchema = Type.Object({
  kind: Type.Union([Type.Literal('rex'), Type.Literal('tmux'), Type.Literal('plain')]),
  rex: Type.Optional(
    Type.Object({ server: Type.Optional(Type.String()), session: Type.String(), block: Type.String() }),
  ),
  tmux: Type.Optional(Type.Object({ pane: Type.String() })),
});

const tabSchema = Type.Object({
  targetId: Type.String(),
  url: Type.String(),
  title: Type.String(),
  kind: Type.Union([Type.Literal('app'), Type.Literal('connect')]),
  lastActiveAt: Type.Optional(Type.String()),
});

const leaseSchema = Type.Object({
  v: Type.Literal(1),
  port: Type.Integer({ minimum: 1, maximum: 65535 }),
  origin: Type.String(),
  root: Type.String(),
  cwd: Type.String(),
  pid: Type.Integer({ minimum: 1 }),
  sessionId: Type.Union([Type.String(), Type.Null()]),
  sessionName: Type.Union([Type.String(), Type.Null()]),
  tellId: Type.Union([Type.String(), Type.Null()]),
  socket: Type.Union([Type.String(), Type.Null()]),
  terminal: terminalSchema,
  claimedAt: Type.String(),
  browser: Type.Object({
    cdp: Type.Union([Type.Literal('up'), Type.Literal('down'), Type.Literal('off')]),
    tabs: Type.Array(tabSchema),
  }),
  lastPromptAt: Type.Union([Type.String(), Type.Null()]),
});

export type Terminal = Type.Static<typeof terminalSchema>;

export type Tab = Type.Static<typeof tabSchema>;

export type Lease = Type.Static<typeof leaseSchema>;

export const leaseDir = (env: NodeJS.ProcessEnv = process.env): string =>
  path.join(piStateDir(env), 'pidewave', 'ports');

export const leaseFile = (port: number, dir = leaseDir()): string => path.join(dir, `${port}.json`);

export const readLease = (port: number, dir = leaseDir()): Lease | null => {
  try {
    const value = JSON.parse(fs.readFileSync(leaseFile(port, dir), 'utf8'));

    return Value.Check(leaseSchema, value) ? value : null;
  } catch {
    return null;
  }
};

export const listLeases = (dir = leaseDir()): Lease[] => {
  let names: string[] = [];

  try {
    names = fs.readdirSync(dir);
  } catch {
    return [];
  }

  return names.flatMap((name) => {
    const port = /^(\d+)\.json$/.exec(name)?.[1];
    const lease = port ? readLease(Number(port), dir) : null;

    return lease ? [lease] : [];
  });
};

/** A lease from before the last boot names a pid that may since belong to anything. */
export const holderAlive = (lease: Lease, now = Date.now(), uptimeSeconds = os.uptime()): boolean => {
  const claimed = Date.parse(lease.claimedAt);

  if (!Number.isFinite(claimed) || claimed < now - uptimeSeconds * 1000) return false;

  try {
    process.kill(lease.pid, 0);

    return true;
  } catch (error) {
    return error instanceof Error && 'code' in error && error.code === 'EPERM';
  }
};

const writeTemp = (lease: Lease, file: string): string => {
  fs.mkdirSync(path.dirname(file), { recursive: true, mode: 0o700 });
  const tmp = `${file}.${process.pid}.${Date.now()}.tmp`;
  fs.writeFileSync(tmp, `${JSON.stringify(lease, null, 2)}\n`, { mode: 0o600 });

  return tmp;
};

export type ClaimResult = { held: true } | { held: false; holder: Lease };

/**
 * Claim the port. `link` creates the file only when absent; a dead or forced
 * takeover renames over it. Two followers racing for a dead holder both rename,
 * so the result is read back: the loser sees the winner as holder.
 */
export const claimLease = (lease: Lease, force = false, dir = leaseDir()): ClaimResult => {
  const file = leaseFile(lease.port, dir);
  const tmp = writeTemp(lease, file);

  try {
    fs.linkSync(tmp, file);
    fs.unlinkSync(tmp);

    return { held: true };
  } catch (error) {
    if (!(error instanceof Error && 'code' in error && error.code === 'EEXIST')) {
      fs.rmSync(tmp, { force: true });
      throw error;
    }
  }

  const current = readLease(lease.port, dir);

  if (current && current.pid !== lease.pid && !force && holderAlive(current)) {
    fs.rmSync(tmp, { force: true });

    return { held: false, holder: current };
  }

  fs.renameSync(tmp, file);
  const after = readLease(lease.port, dir);

  return after && after.pid !== lease.pid ? { held: false, holder: after } : { held: true };
};

/** Rewrite the lease while this pid still holds it. Returns whether it does. */
export const updateLease = (lease: Lease, dir = leaseDir()): boolean => {
  const file = leaseFile(lease.port, dir);

  if (readLease(lease.port, dir)?.pid !== lease.pid) return false;
  fs.renameSync(writeTemp(lease, file), file);

  return true;
};

export const releaseLease = (port: number, pid: number, dir = leaseDir()): void => {
  if (readLease(port, dir)?.pid === pid) fs.rmSync(leaseFile(port, dir), { force: true });
};

/**
 * Where this Pi runs. Inside tmux, REX_* variables are whatever the tmux server
 * inherited when it started, so tmux wins and Rex ids are ignored.
 */
export const terminalFromEnv = (env: NodeJS.ProcessEnv = process.env): Terminal => {
  if (env.TMUX && env.TMUX_PANE) return { kind: 'tmux', tmux: { pane: env.TMUX_PANE } };

  if (env.REX_SESSION && env.REX_BLOCK) {
    const rex: NonNullable<Terminal['rex']> = { session: env.REX_SESSION, block: env.REX_BLOCK };

    if (env.REX_SERVER) rex.server = env.REX_SERVER;

    return { kind: 'rex', rex };
  }

  return { kind: 'plain' };
};
