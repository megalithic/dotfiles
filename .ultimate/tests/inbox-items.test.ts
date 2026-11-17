import { describe, expect, test } from 'bun:test';
import { add, done, initial } from '../../home/.ultimate/extensions/inbox-items/lib.ts';

const action = { kind: 'action', title: 'Sign in', text: 'Sign in to finish setup.' };

describe('inbox-items', () => {
  test('adds each kind, deduplicates keys, and completes items without changing their origin', () => {
    const state = initial();
    const first = add(state, { ...action, key: 'setup' }, 42, 100);
    const artifact = add(
      state,
      { kind: 'artifact', title: 'Page', text: 'A generated page.', path: '~/Desktop/page.html' },
      7,
      101,
    );
    const link = add(
      state,
      { kind: 'link', title: 'Share', text: 'The published page.', url: 'https://example.com/page' },
      8,
      102,
    );
    expect(first).toEqual({ id: 1, ...action, key: 'setup', conversation: 42, at: 100 });
    expect(artifact.path).toBe('~/Desktop/page.html');
    expect(link.url).toBe('https://example.com/page');
    expect(state.items).toHaveLength(3);
    expect(add(state, { ...action, title: 'Duplicate', key: 'setup' }, 99, 103)).toEqual(first);
    expect(state.next).toBe(4);
    expect(state.items).toHaveLength(3);

    const completed = done(state, first.id, 200);
    expect(completed).toEqual({ ...first, done: 200 });
    expect(done(state, first.id, 300)).toEqual(completed);
    expect(add(state, { ...action, key: 'setup' }, 99, 400)).toEqual(completed);
    // Returned values must survive the transaction, not expose its mutable document overlay.
    first.title = 'Changed outside the document';
    completed.text = 'Changed outside the document';
    expect(state.items[0].title).toBe(action.title);
    expect(state.items[0].text).toBe(action.text);
  });

  test('keeps every open item and only the 50 newest completions', () => {
    const state = initial();
    const oldest = add(state, action, 1, 0);
    const open = Array.from({ length: 55 }, (_, index) => add(state, action, 2, index + 1));
    const completed = Array.from({ length: 51 }, (_, index) => {
      const item = add(state, action, 3, index + 100);
      done(state, item.id, index + 1000);
      return item;
    });
    // Completing the oldest-created item last must retain it, not the oldest completion.
    done(state, oldest.id, 2000);
    expect(state.items.filter((item) => item.done === undefined)).toEqual(open);
    expect(state.items.filter((item) => item.done !== undefined).map((item) => item.id)).toEqual([
      oldest.id,
      ...completed.slice(2).map((item) => item.id),
    ]);
    expect(state.items).toHaveLength(105);
  });

  test('enforces title and text limits before consuming an id', () => {
    const state = initial();
    const boundary = { ...action, title: 't'.repeat(120), text: 'x'.repeat(8000) };
    expect(add(state, boundary, 1, 0)).toMatchObject(boundary);
    expect(() => add(state, { ...boundary, title: 't'.repeat(121) }, 1, 1)).toThrow('120');
    expect(() => add(state, { ...boundary, text: 'x'.repeat(8001) }, 1, 1)).toThrow('8000');
    expect(state.next).toBe(2);
    expect(state.items).toHaveLength(1);
  });
});
