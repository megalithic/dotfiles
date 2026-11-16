import { describe, expect, test } from 'bun:test';
import fs from 'node:fs';
import path from 'node:path';

const script = path.join(import.meta.dir, '../scripts/pg-guard.sh');

// Stub ps prints PS_OUT; stub sleep and lsof keep the run instant and offline.
const run = (psLines: string[], owner?: string) => {
  const dir = fs.mkdtempSync('/tmp/pg-guard-test-');
  const pgdata = path.join(dir, 'tmp/pg/data');
  fs.mkdirSync(pgdata, { recursive: true });
  if (owner) fs.writeFileSync(path.join(pgdata, 'postmaster.pid'), `${owner}\n${pgdata}\n`);
  fs.mkdirSync(path.join(dir, 'bin'));
  fs.writeFileSync(path.join(dir, 'bin/ps'), '#!/bin/sh\nprintf "%s\\n" "$PS_OUT"\n', { mode: 0o755 });
  for (const cmd of ['sleep', 'lsof']) fs.writeFileSync(path.join(dir, 'bin', cmd), '#!/bin/sh\n', { mode: 0o755 });
  const result = Bun.spawnSync(['bash', script], {
    env: {
      PATH: `${dir}/bin:/usr/bin:/bin`,
      PGDATA: pgdata,
      PS_OUT: psLines.map((l) => l.replaceAll('$PGDATA', pgdata)).join('\n'),
    },
  });
  return { code: result.exitCode, stderr: result.stderr.toString() };
};

describe('pg-guard.sh', () => {
  test('passes with no server for this data dir', () => {
    const r = run(['  123 /opt/pg/bin/postgres -D /elsewhere/tmp/pg/data', '  124 postgres: checkpointer']);
    expect(r.code).toBe(0);
  });

  test('passes for the server that owns postmaster.pid', () => {
    expect(run(['  200 /opt/pg/bin/postgres -D $PGDATA'], '200').code).toBe(0);
  });

  test('refuses while a server whose data dir was moved still claims the path', () => {
    // rx: tmp/ went to the Trash with pid 97174 running; a new cluster was
    // initialized and started beside it (pid 74263 owns postmaster.pid).
    const r = run(['74263 /opt/pg/bin/postgres -D $PGDATA', '97174 /opt/pg/bin/postgres -D $PGDATA'], '74263');
    expect(r.code).toBe(1);
    expect(r.stderr).toContain('pid 97174');
    expect(r.stderr).not.toContain('pid 74263');
  });

  test('refuses when no postmaster.pid exists but a server claims the path', () => {
    const r = run(['  300 /opt/pg/bin/postgres -D $PGDATA']);
    expect(r.code).toBe(1);
    expect(r.stderr).toContain('pid 300');
  });

  test('ignores data dirs that only share a prefix', () => {
    expect(run(['  400 /opt/pg/bin/postgres -D $PGDATA-old']).code).toBe(0);
  });
});
