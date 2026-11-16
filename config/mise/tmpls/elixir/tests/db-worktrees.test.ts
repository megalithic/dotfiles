import { afterAll, describe, expect, test } from 'bun:test';
import fs from 'node:fs';
import path from 'node:path';

const script = path.join(import.meta.dir, '../scripts/db-worktrees.sh');

// Stub psql: logs each SQL to PSQL_LOG, answers SHOW data_directory with
// PG_DATADIR and the database list with DBS (name<TAB>bytes lines).
const psql = `#!/bin/bash
while [ $# -gt 0 ]; do [ "$1" = -c ] && sql="$2"; shift; done
echo "$sql" >>"$PSQL_LOG"
case "$sql" in
  SHOW*) echo "$PG_DATADIR" ;;
  SELECT*) printf '%s\\n' "$DBS" ;;
esac
`;

const git = (cwd: string, ...args: string[]) => {
  const r = Bun.spawnSync(['git', '-c', 'user.email=t@t', '-c', 'user.name=t', ...args], { cwd });
  if (r.exitCode !== 0) throw new Error(r.stderr.toString());
};

// A provider_portal checkout with two live worktrees: one with a long name
// whose database names get truncated, one Ultimate-style worktree whose .env
// pins GIT_WORKTREE=ult_7.
const tmp = fs.realpathSync(fs.mkdtempSync('/tmp/db-worktrees-test-'));
const main = path.join(tmp, 'provider_portal');
fs.mkdirSync(path.join(main, 'tmp/pg/data'), { recursive: true });
fs.mkdirSync(path.join(tmp, 'bin'));
fs.writeFileSync(path.join(tmp, 'bin/psql'), psql, { mode: 0o755 });
fs.writeFileSync(path.join(tmp, 'bin/pg_isready'), '#!/bin/sh\nexit "${PG_UP:-0}"\n', { mode: 0o755 });
git(tmp, 'init', '-q', '-b', 'main', main);
fs.writeFileSync(path.join(main, '.gitignore'), 'tmp/\n.worktrees/\n');
git(main, 'add', '.');
git(main, 'commit', '-qm', 'init');
const long = 'sm-onboarding-provider-npi-concerns-post-149';
git(main, 'worktree', 'add', '-q', '-b', long, `.worktrees/${long}`);
git(main, 'worktree', 'add', '-q', '--detach', path.join(tmp, '7'));
fs.writeFileSync(path.join(tmp, '7/.env'), 'PORT=20070\nGIT_WORKTREE=ult_7\n');
afterAll(() => fs.rmSync(tmp, { recursive: true, force: true }));

const gone = 'provider_portal-sm-gone-with-a-rather-long-name';
const t63 = (s: string) => s.slice(0, 63);
const databases = [
  'postgres',
  'rx_dev',
  'rx_test',
  'rx_catalog_test',
  `rx_dev_${gone}`,
  `rx_test_${gone}`,
  t63(`rx_catalog_test_${gone}`),
  `rx_dev_${gone}-2`,
  t63(`rx_dev_provider_portal-${long}`),
  t63(`rx_catalog_test_provider_portal-${long}`),
  'rx_dev_ult_7',
  'rx_test_ult_9',
];

const shells = [...new Set(['/bin/bash', Bun.which('bash')].filter((s): s is string => !!s && fs.existsSync(s)))];

for (const bash of shells) {
  const run = (args: string[], opts: { up?: boolean; datadir?: string } = {}) => {
    const log = path.join(tmp, 'psql.log');
    fs.rmSync(log, { force: true });
    const r = Bun.spawnSync([bash, script, ...args], {
      cwd: main,
      env: {
        PATH: `${tmp}/bin:/usr/bin:/bin:${path.dirname(Bun.which('git') ?? '/usr/bin/git')}`,
        HOME: tmp,
        PGPORT: '5999',
        PG_UP: opts.up === false ? '1' : '0',
        PG_DATADIR: opts.datadir ?? path.join(main, 'tmp/pg/data'),
        PSQL_LOG: log,
        DBS: databases.map((d, i) => `${d}\t${(i + 1) * 1024 * 1024}`).join('\n'),
      },
    });
    const sql = fs.existsSync(log) ? fs.readFileSync(log, 'utf8').trim().split('\n') : [];
    const dropped = sql.filter((s) => s.startsWith('DROP')).map((s) => s.match(/"(.*)"/)![1]);
    return { code: r.exitCode, out: r.stdout.toString(), err: r.stderr.toString(), sql, dropped };
  };

  describe(`db-worktrees.sh (${bash})`, () => {
    test("drop removes exactly the worktree's databases, truncated names included", () => {
      const r = run(['drop', gone]);
      expect(r.code).toBe(0);
      expect(r.dropped.sort()).toEqual([t63(`rx_catalog_test_${gone}`), `rx_dev_${gone}`, `rx_test_${gone}`].sort());
      expect(t63(`rx_catalog_test_${gone}`).length).toBe(63);
      expect(r.out).toContain(`dropped rx_dev_${gone}`);
    });

    test('drop keeps a truncated name a live worktree shares', () => {
      // post-150 and the live post-149 both truncate to the same rx_dev name.
      const r = run(['drop', `provider_portal-${long.replace('149', '150')}`]);
      expect(r.code).toBe(0);
      expect(r.dropped).toEqual([]);
      expect(r.out).toContain(`kept ${t63(`rx_dev_provider_portal-${long}`)}`);
    });

    test('drop refuses a live worktree and the main checkout', () => {
      for (const id of [`provider_portal-${long}`, 'ult_7', '']) {
        const r = run(['drop', id]);
        expect(r.code).toBe(2);
        expect(r.dropped).toEqual([]);
      }
    });

    test('leaves the databases when the server is down', () => {
      const r = run(['drop', gone], { up: false });
      expect(r.code).toBe(0);
      expect(r.out).toContain('not running');
      expect(r.sql).toEqual([]);
    });

    test('refuses a server serving another data directory', () => {
      const r = run(['orphans', '--drop'], { datadir: '/var/db/postgres' });
      expect(r.code).toBe(2);
      expect(r.dropped).toEqual([]);
    });

    test('orphans lists only databases of no live worktree, and drops them only with --drop', () => {
      const orphans = [
        `rx_dev_${gone}`,
        `rx_dev_${gone}-2`,
        `rx_test_${gone}`,
        t63(`rx_catalog_test_${gone}`),
        'rx_test_ult_9',
      ];
      const dry = run(['orphans']);
      expect(dry.code).toBe(0);
      expect(dry.dropped).toEqual([]);
      const listed = dry.out
        .split('\n')
        .filter((l) => /^ *[\d.]+ [KMG]?B  /.test(l))
        .map((l) => l.trim().split(/\s+/)[2]);
      expect(listed.sort()).toEqual(orphans.sort());
      expect(dry.out).toContain('5 orphaned database(s), 38.0 MB');
      expect(run(['orphans', '--drop']).dropped.sort()).toEqual(orphans.sort());
    });
  });
}
