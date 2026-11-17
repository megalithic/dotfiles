export type Item = {
  id: number;
  kind: 'action' | 'artifact' | 'link';
  title: string;
  text: string;
  url?: string;
  path?: string;
  conversation: number;
  key?: string;
  at: number;
  done?: number;
};
export type State = { next: number; items: Item[] };

export const DOCUMENT = 'inbox-items.items';
export const initial = (): State => ({ next: 1, items: [] });

export function record(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error('Expected an argument object');
  return value as Record<string, unknown>;
}

function string(value: unknown, name: string): string {
  if (typeof value !== 'string' || !value.trim() || value.includes('\0'))
    throw new Error(`${name} must be a nonempty string without NUL bytes`);
  return value;
}

/** Mutate a document overlay; return a detached item that remains usable after the commit. */
export function add(state: State, value: unknown, conversation: number, at: number): Item {
  const input = record(value);
  const key = input.key === undefined ? undefined : string(input.key, 'key');
  if (key !== undefined) {
    const known = state.items.find((item) => item.key === key);
    if (known) return { ...known };
  }
  const kind = input.kind;
  if (kind !== 'action' && kind !== 'artifact' && kind !== 'link')
    throw new Error('kind must be action, artifact or link');
  const title = string(input.title, 'title').trim();
  const text = string(input.text, 'text').trim();
  if (title.length > 120) throw new Error('title must be at most 120 characters');
  if (text.length > 8000) throw new Error('text must be at most 8000 characters');
  const url = input.url === undefined ? undefined : string(input.url, 'url');
  const path = input.path === undefined ? undefined : string(input.path, 'path');
  if (kind === 'link' && !url) throw new Error('A link needs a url');
  if (kind === 'artifact' && !path) throw new Error('An artifact needs a path');
  if (url && !['http:', 'https:'].includes(new URL(url).protocol)) throw new Error('url must be an http or https URL');
  if (path && path !== '~' && !path.startsWith('~/') && !path.startsWith('/'))
    throw new Error('path must be absolute or start with ~/');
  const item: Item = {
    id: state.next++,
    kind,
    title,
    text,
    conversation,
    at,
    ...(url === undefined ? {} : { url }),
    ...(path === undefined ? {} : { path }),
    ...(key === undefined ? {} : { key }),
  };
  state.items.push(item);
  return { ...item };
}

export function find(state: State, id: unknown): Item {
  if (typeof id !== 'number' || !Number.isSafeInteger(id) || id < 1) throw new Error('id must be a positive integer');
  const item = state.items.find((item) => item.id === id);
  if (!item) throw new Error(`No inbox item ${id}`);
  return item;
}

/** Keep all open items and the 50 most recently completed, not merely most recently added. */
export function done(state: State, id: unknown, at: number): Item {
  const item = find(state, id);
  item.done ??= at;
  const drop = new Set(
    state.items
      .filter((entry) => entry.done !== undefined)
      .sort((a, b) => b.done! - a.done! || b.id - a.id)
      .slice(50)
      .map((entry) => entry.id),
  );
  state.items = state.items.filter((entry) => !drop.has(entry.id));
  return { ...item };
}
