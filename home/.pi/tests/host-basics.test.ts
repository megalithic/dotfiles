import { expect, test } from 'bun:test';
import fs from 'node:fs';
import path from 'node:path';

const home = path.join(import.meta.dir, '../..');

function hostBasics(file: string) {
  const text = fs.readFileSync(path.join(home, file), 'utf8');
  const section = text.match(/^## Host basics\n[\s\S]*?(?=\n## |$)/m);
  expect(section).not.toBeNull();

  // SAFETY: the preceding assertion verifies the match exists.
  return section![0].trim();
}

test('pi and Ultimate carry the same host basics', () => {
  expect(hostBasics('.pi/agent/AGENTS.md')).toBe(hostBasics('.ultimate/AGENTS.md'));
});
