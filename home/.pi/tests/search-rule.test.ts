import { expect, test } from 'bun:test';
import { readFileSync } from 'node:fs';

// The warden rule that steers find/grep to fd/rg: `find / -maxdepth 6` from an agent walked ~/Music and
// raised four macOS privacy prompts on 2026-11-18.
const config = JSON.parse(readFileSync(new URL('../agent/pi-warden/config.json', import.meta.url), 'utf8'));

const rule = config.action.commandRules.find((r: { id: string }) => r.id === 'search-with-fd-rg');

const matches = (command: string) => new RegExp(rule.pattern, 'i').test(command);

test('warns on find and grep commands', () => {
  for (const command of [
    'find / -maxdepth 6 -name browsers.json',
    'cd /tmp; find . -name x',
    'ls | grep foo',
    'grep -rn foo src',
    'xargs grep x',
    '/usr/bin/find ~',
    'echo $(find . -type f)',
  ]) {
    expect(matches(command)).toBe(true);
  }

  expect(rule.severity).toBe('warn');
});

test('leaves fd, rg, ast-grep and git grep alone', () => {
  for (const command of [
    'rg find',
    'fd grep',
    'git grep foo',
    'rg -n "find /" x',
    'cat findings.txt',
    'ast-grep -p x',
  ]) {
    expect(matches(command)).toBe(false);
  }
});
