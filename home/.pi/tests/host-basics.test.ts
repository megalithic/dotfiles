import { expect, test } from 'bun:test';
import fs from 'node:fs';
import path from 'node:path';

const home = path.join(import.meta.dir, '../..');

// The host rules pi and Ultimate both carry, word for word: neither can include a shared file into its AGENTS.md.
const shared = ['Host basics', 'Time-sensitive handoffs'];

function section(file: string, heading: string) {
  const text = fs.readFileSync(path.join(home, file), 'utf8');
  // Up to the next heading or the end of the file; `$` would stop at the first line end under the m flag.
  const match = text.match(new RegExp(`^## ${heading}\\n[\\s\\S]*?(?=\\n## |(?![\\s\\S]))`, 'm'));
  expect(match).not.toBeNull();

  // SAFETY: the preceding assertion verifies the match exists.
  return match![0].trim();
}

test.each(shared)('pi and Ultimate carry the same %s section', (heading) => {
  expect(section('.pi/agent/AGENTS.md', heading)).toBe(section('.ultimate/AGENTS.md', heading));
});
