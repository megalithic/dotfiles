import { describe, expect, test } from 'bun:test';
import fs from 'node:fs';
import path from 'node:path';

const script = path.join(import.meta.dir, '../scripts/db-ensure.sh');
const fresh = 'The database for App.Repo has been created';
const existing = 'The database for App.Repo has already been created';

// Stub mix: logs each call as "<MIX_ENV> <args>", prints CREATE_OUT for the dev
// ecto.create, exits SEED_RC for ecto.seed and MIGRATE_RC for the dev
// ecto.migrate. The test database always exists.
const stub = `#!/bin/bash
echo "\${MIX_ENV:-dev} $*" >>"$MIX_LOG"
case "$*" in
  ecto.create) if [ "\${MIX_ENV:-dev}" = test ]; then echo '${existing}'; else printf '%s\\n' "$CREATE_OUT"; fi ;;
  ecto.migrate) [ "\${MIX_ENV:-dev}" = test ] || exit "\${MIGRATE_RC:-0}" ;;
  ecto.seed) exit "\${SEED_RC:-0}" ;;
esac
exit 0
`;

// mise tasks run whichever `bash` is on PATH; macOS /bin/bash is 3.2.
const shells = [...new Set(['/bin/bash', Bun.which('bash')].filter((s): s is string => !!s && fs.existsSync(s)))];

for (const bash of shells) {
  const checkout = () => {
    const cwd = fs.mkdtempSync('/tmp/setup-seed-test-');
    fs.mkdirSync(path.join(cwd, 'bin'));
    fs.writeFileSync(path.join(cwd, 'bin/mix'), stub, { mode: 0o755 });
    return cwd;
  };
  const run = (
    createOut: string,
    opts: { seedRc?: number; migrateRc?: number; cwd?: string; mixEnv?: string } = {},
  ) => {
    const cwd = opts.cwd ?? checkout();
    const log = path.join(cwd, 'mix.log');
    fs.rmSync(log, { force: true });
    const result = Bun.spawnSync([bash, script], {
      cwd,
      env: {
        PATH: `${cwd}/bin:/usr/bin:/bin`,
        MIX_LOG: log,
        CREATE_OUT: createOut,
        SEED_RC: String(opts.seedRc ?? 0),
        MIGRATE_RC: String(opts.migrateRc ?? 0),
        ...(opts.mixEnv ? { MIX_ENV: opts.mixEnv } : {}),
      },
    });
    return {
      cwd,
      code: result.exitCode,
      stderr: result.stderr.toString(),
      calls: fs.existsSync(log) ? fs.readFileSync(log, 'utf8').trim().split('\n') : [],
    };
  };

  describe(`db-ensure.sh seeding (${bash})`, () => {
    test('seeds when every dev database is new', () => {
      const r = run(fresh);
      expect(r.code).toBe(0);
      expect(r.calls).toContain('dev ecto.seed');
      expect(r.calls).not.toContain('test ecto.seed');
      expect(fs.existsSync(path.join(r.cwd, '.local/state/seed-pending'))).toBe(false);
    });

    test('skips seeding when the dev databases already exist', () => {
      const r = run(existing);
      expect(r.code).toBe(0);
      expect(r.calls).toContain('dev ecto.migrate');
      expect(r.calls).not.toContain('dev ecto.seed');
      expect(r.stderr).toBe('');
    });

    test('skips seeding and warns when only some dev databases are new', () => {
      const r = run(`${fresh}\n${existing}`);
      expect(r.code).toBe(0);
      expect(r.calls).not.toContain('dev ecto.seed');
      expect(r.stderr).toContain('skipped seeding');
    });

    test('drops the new dev databases when seeding fails', () => {
      const r = run(fresh, { seedRc: 1 });
      expect(r.code).toBe(1);
      expect(r.calls.slice(-2)).toEqual(['dev ecto.seed', 'dev ecto.drop']);
      expect(r.stderr).toContain('seeding failed');
    });

    test('seeds on the rerun after a failed migration left new databases unseeded', () => {
      const first = run(fresh, { migrateRc: 1 });
      expect(first.code).not.toBe(0);
      expect(first.calls).not.toContain('dev ecto.seed');
      const rerun = run(existing, { cwd: first.cwd });
      expect(rerun.code).toBe(0);
      expect(rerun.calls).toContain('dev ecto.seed');
      expect(fs.existsSync(path.join(first.cwd, '.local/state/seed-pending'))).toBe(false);
    });

    test('an inherited MIX_ENV=test still creates, seeds and drops only dev databases', () => {
      const r = run(fresh, { mixEnv: 'test', seedRc: 1 });
      expect(r.code).toBe(1);
      expect(r.calls).toContain('dev ecto.seed');
      expect(r.calls).toContain('dev ecto.drop');
      expect(r.calls).not.toContain('test ecto.seed');
      expect(r.calls).not.toContain('test ecto.drop');
    });

    test('refuses a non-dev MIX_ENV before touching any database', () => {
      const r = run(fresh, { mixEnv: 'prod' });
      expect(r.code).toBe(2);
      expect(r.calls).toEqual([]);
    });
  });
}
