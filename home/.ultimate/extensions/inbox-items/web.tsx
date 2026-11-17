import type { ConversationId } from '@earendil-works/pi-durable';
import { useState } from 'react';
import type { ReactNode } from 'react';
import { MessageResponse } from '@/components/ai/message';
import { Button } from '@/components/ui/button';
import { actionRef, api, definePoint, defineWebExtension, docRef, provide, ROOT, useDocOf } from '@/sdk';
import { DOCUMENT } from './lib.ts';
import type { Item, State } from './lib.ts';

type InboxItem = {
  key: string;
  at: number;
  conversation?: ConversationId;
  tag: string;
  title: string;
  gist?: string;
  pane: ReactNode;
};
const InboxItems = definePoint<null, InboxItem[]>('inbox.items');
const ItemsDoc = docRef<State>(DOCUMENT);
const Done = actionRef<{ id: number }, Item>('inbox-items', 'done');
const Open = actionRef<{ id: number }, { id: number }>('inbox-items', 'open');
const Reveal = actionRef<{ id: number }, { id: number }>('inbox-items', 'reveal');

function Pane({ item }: { item: Item }) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [copied, setCopied] = useState(false);
  async function act(work: () => Promise<unknown>) {
    setBusy(true);
    setError('');
    try {
      await work();
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : String(cause));
    } finally {
      setBusy(false);
    }
  }
  return (
    <div className="flex min-w-0 flex-col gap-4">
      <MessageResponse isAnimating={false}>{item.text}</MessageResponse>
      {item.kind === 'link' && item.url && (
        <div className="flex flex-wrap items-center gap-2">
          <Button asChild size="sm" variant="outline">
            <a href={item.url} rel="noreferrer" target="_blank">
              Open link
            </a>
          </Button>
        </div>
      )}
      {item.kind === 'artifact' && item.path && (
        <div className="flex flex-col gap-2">
          <p className="break-all font-mono text-xs text-muted-foreground">{item.path}</p>
          <div className="flex flex-wrap items-center gap-2">
            <Button
              disabled={busy}
              onClick={() => act(() => api.action(Open, { id: item.id }))}
              size="sm"
              variant="outline"
            >
              Open
            </Button>
            <Button
              disabled={busy}
              onClick={() => act(() => api.action(Reveal, { id: item.id }))}
              size="sm"
              variant="outline"
            >
              Reveal in Finder
            </Button>
            <Button
              disabled={busy}
              onClick={() =>
                act(async () => {
                  await navigator.clipboard.writeText(item.path!);
                  setCopied(true);
                })
              }
              size="sm"
              variant="outline"
            >
              {copied ? 'Copied' : 'Copy path'}
            </Button>
          </div>
        </div>
      )}
      {error && (
        <p className="text-sm text-destructive" role="alert">
          {error}
        </p>
      )}
      <Button
        className="self-start"
        disabled={busy}
        onClick={() => act(() => api.action(Done, { id: item.id }))}
        size="sm"
      >
        Done
      </Button>
    </div>
  );
}

export default defineWebExtension({
  provides: [
    provide(InboxItems, () => {
      const state = useDocOf(ROOT, ItemsDoc);
      return (state?.items ?? [])
        .filter((item) => item.done === undefined)
        .map((item) => ({
          key: `inbox-items:${item.id}`,
          at: item.at,
          conversation: item.conversation as ConversationId,
          tag: item.kind,
          title: item.title,
          gist: item.text.split(/\r?\n/, 1)[0],
          pane: <Pane key={item.id} item={item} />,
        }));
    }),
  ],
});
