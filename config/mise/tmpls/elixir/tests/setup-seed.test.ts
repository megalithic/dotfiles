import { describe, expect, test } from 'bun:test';
import fs from 'node:fs';
import path from 'node:path';

const script = path.join(import.meta.dir, '../scripts/setup.sh');
const fresh = 'The database for App.Repo has been created';
const existing = 'The database for App.Repo has already been created';

// Stub mix: logs each call as "<MIX_ENV> <args>", prints CREATE_OUT for the dev
// ecto.create, and exits SEED_RC for ecto.seed. The test database always exists.
const stub = `#!/bin/bash
echo "\${MIX_ENV:-dev} $*" >>"$MIX_LOG"
case "$*" in
  ecto.create) if [ "\${MIX_ENV:-dev}" = test ]; then echo '${existing}'; else printf '%s\\n' "$CREATE_OUT"; fi ;;
  ecto.seed) exit "\${SEED_RC:-0}" ;;
esac
exit 0
`;

// mise tasks run whichever `bash` is on PATH; macOS /bin/bash is 3.2.
const shells = [...new Set(['/bin/bash', Bun.which('bash')].filter((s): s is string => !!s && fs.existsSync(s)))];

for (const bash of shells) {
  const run = (createOut: string, seedRc = 0) => {
    const cwd = fs.mkdtempSync('/tmp/setup-seed-test-');
    fs.mkdirSync(path.join(cwd, 'bin'));
    fs.writeFileSync(path.join(cwd, 'bin/mix'), stub, { mode: 0o755 });
    const log = path.join(cwd, 'mix.log');
    const result = Bun.spawnSync([bash, script], {
      cwd,
      env: {
        PATH: `${cwd}/bin:/usr/bin:/bin`,
        MIX_LOG: log,
        CREATE_OUT: createOut,
        SEED_RC: String(seedRc),
      },
    });
    return {
      code: result.exitCode,
      stderr: result.stderr.toString(),
      calls: fs.readFileSync(log, 'utf8').trim().split('\n'),
    };
  };

  describe(`setup.sh seeding (${bash})`, () => {
    test('seeds when every dev database is new', () => {
      const r = run(fresh);
      expect(r.code).toBe(0);
      expect(r.calls).toContain('dev ecto.seed');
      expect(r.calls).not.toContain('test ecto.seed');
    });

    test('skips seeding when the dev databases already exist', () => {
      const r = run(existing);
      expect(r.code).toBe(0);
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
      const r = run(fresh, 1);
      expect(r.code).toBe(1);
      expect(r.calls.slice(-2)).toEqual(['dev ecto.seed', 'dev ecto.drop']);
      expect(r.stderr).toContain('seeding failed');
    });
  });
}
