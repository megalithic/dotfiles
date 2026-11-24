import { afterEach, expect, spyOn, test } from 'bun:test';
import { run } from '../agent/lib/beam.ts';

const stderr = spyOn(process.stderr, 'write').mockImplementation(() => true);

afterEach(() => stderr.mockClear());

test('a missing binary logs one line and resolves empty', async () => {
  expect(await run('/nonexistent/lsof', ['-v'])).toBe('');
  expect(stderr.mock.calls).toEqual([['run: /nonexistent/lsof failed: ENOENT\n']]);
});

test('a non-zero exit still resolves stdout, without logging', async () => {
  expect(await run('/bin/sh', ['-c', 'echo found; exit 1'])).toBe('found\n');
  expect(stderr).not.toHaveBeenCalled();
});
