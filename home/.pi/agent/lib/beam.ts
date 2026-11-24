import { execFile } from 'node:child_process';

/**
 * Runs a command and resolves its stdout, whatever its exit code (lsof exits 1 when it finds nothing).
 * A command that cannot start (missing, not executable) or is killed (timeout) logs one line to stderr.
 */
export type Run = (command: string, args: string[]) => Promise<string>;

export const run: Run = (command, args) =>
  new Promise((resolve) => {
    execFile(command, args, { timeout: 5_000 }, (error, stdout) => {
      const failed = error && (error.code === 'ENOENT' || error.code === 'EACCES' || error.signal);

      if (failed) process.stderr.write(`run: ${command} failed: ${error.signal ?? error.code}\n`);
      resolve(String(stdout ?? ''));
    });
  });

/** beam.smp pids and working directories from lsof's `-Fpn` output. */
export const beamCwds = (out: string): { pid: string; cwd: string }[] => {
  const found: { pid: string; cwd: string }[] = [];
  let pid = '';

  for (const line of out.split('\n')) {
    if (line.startsWith('p')) pid = line.slice(1);
    else if (line.startsWith('n') && /^\d+$/.test(pid)) found.push({ pid, cwd: line.slice(1) });
  }

  return found;
};

export type Listener = { pid: string; port: number; address: string };

/** TCP listeners, retaining the bind address, from lsof's `-Fpn` output. */
export const listeners = (out: string): Listener[] => {
  const found: Listener[] = [];
  let pid = '';

  for (const line of out.split('\n')) {
    if (line.startsWith('p')) pid = line.slice(1);
    const match = /^n(.*):(\d+)$/.exec(line);

    if (match && pid) found.push({ pid, port: Number(match[2]), address: match[1]! });
  }

  return found;
};

/** Exclude ports also bound by any other pid, regardless of address; return lowest first. */
export const ownedPorts = (all: Listener[], own: Set<string>): number[] => {
  const ports = new Set(all.flatMap(({ pid, port }) => (own.has(pid) ? [port] : [])));

  for (const { pid, port } of all) if (!own.has(pid)) ports.delete(port);

  return [...ports].toSorted((a, b) => a - b);
};
