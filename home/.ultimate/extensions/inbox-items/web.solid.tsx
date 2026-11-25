import type { ConversationId } from '@earendil-works/pi-durable'
import type { JSX } from '@solidjs/web'
import { CheckIcon, CopyIcon, ExternalLinkIcon, FolderOpenIcon } from '@lucide/solid'
import { createMemo, createSignal, Show } from 'solid-js'
import { Markdown } from '@/components/markdown/markdown.solid.tsx'
import { Button } from '@/components/ui/button.solid.tsx'
import {
  actionRef,
  api,
  definePoint,
  defineWebExtension,
  docRef,
  provide,
  ROOT,
  useDocOf,
} from '@/sdk/solid'
import { DOCUMENT } from './lib.ts'
import type { Item, State } from './lib.ts'

type InboxItem = {
  key: string
  at: number
  conversation?: ConversationId
  tag: string
  title: string
  gist?: string
  text?: string
  pane: JSX.Element
}
const InboxItems = definePoint<null, InboxItem[]>('inbox.items')
const ItemsDoc = docRef<State>(DOCUMENT)
const Done = actionRef<{ id: number }, Item>('inbox-items', 'done')
const Open = actionRef<{ id: number }, { id: number }>('inbox-items', 'open')
const Reveal = actionRef<{ id: number }, { id: number }>('inbox-items', 'reveal')

function webLink(value?: string) {
  try {
    const url = new URL(value ?? '')
    return /^https?:$/.test(url.protocol) ? url.href : undefined
  } catch {
    return undefined
  }
}

function Pane(props: { item: Item }) {
  const [busy, setBusy] = createSignal(false)
  const [error, setError] = createSignal('')
  const [copied, setCopied] = createSignal(false)
  async function act(work: Promise<unknown>) {
    setBusy(true)
    setError('')
    try {
      await work
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : String(cause))
    } finally {
      setBusy(false)
    }
  }
  return (
    <div class="flex min-w-0 flex-col gap-4">
      <Markdown class="text-[15px] leading-6" text={props.item.text} />
      <Show when={props.item.kind === 'link' && props.item.url}>
        <div class="flex min-w-0 flex-col gap-2">
          <p class="font-mono text-xs break-all text-muted-foreground">{props.item.url}</p>
          <div class="flex flex-wrap items-center gap-2">
            <Show when={webLink(props.item.url)}>
              {(url) => (
                <Button
                  aria-label={`Open link: ${props.item.title} (#${props.item.id})`}
                  render={(link) => (
                    <a
                      {...link}
                      aria-label={`Open link: ${props.item.title} (#${props.item.id})`}
                      href={url()}
                      rel="noreferrer"
                      target="_blank"
                    />
                  )}
                  size="sm"
                  variant="outline"
                >
                  <ExternalLinkIcon class="size-3.5" />
                  Open link
                </Button>
              )}
            </Show>
          </div>
        </div>
      </Show>
      <Show when={props.item.kind === 'artifact' && props.item.path}>
        <div class="flex flex-col gap-2">
          <p class="break-all font-mono text-xs text-muted-foreground">{props.item.path}</p>
          <div class="flex flex-wrap items-center gap-2">
            <Button
              aria-label={`Open: ${props.item.title} (#${props.item.id})`}
              disabled={busy()}
              onClick={() => act(api.action(Open, { id: props.item.id }))}
              size="sm"
              variant="outline"
            >
              <ExternalLinkIcon class="size-3.5" />
              Open
            </Button>
            <Button
              aria-label={`Reveal in Finder: ${props.item.title} (#${props.item.id})`}
              disabled={busy()}
              onClick={() => act(api.action(Reveal, { id: props.item.id }))}
              size="sm"
              variant="outline"
            >
              <FolderOpenIcon class="size-3.5" />
              Reveal in Finder
            </Button>
            <Button
              aria-label={`Copy path: ${props.item.title} (#${props.item.id})`}
              disabled={busy()}
              onClick={() =>
                act(
                  navigator.clipboard.writeText(props.item.path!).then(() => {
                    setCopied(true)
                  }),
                )
              }
              size="sm"
              variant="outline"
            >
              <Show when={copied()} fallback={<CopyIcon class="size-3.5" />}>
                <CheckIcon class="size-3.5" />
              </Show>
              {copied() ? 'Copied' : 'Copy path'}
            </Button>
          </div>
        </div>
      </Show>
      <Show when={error()}>
        <p class="text-sm text-destructive" role="alert">
          {error()}
        </p>
      </Show>
      <Button
        aria-label={`Done: ${props.item.title} (#${props.item.id})`}
        class="self-start"
        disabled={busy()}
        onClick={() => act(api.action(Done, { id: props.item.id }))}
        size="sm"
      >
        <CheckIcon class="size-3.5" />
        Done
      </Button>
    </div>
  )
}

export default defineWebExtension({
  provides: [
    provide(InboxItems, () => {
      const state = useDocOf(() => ROOT, ItemsDoc)
      return createMemo(() =>
        (state()?.items ?? [])
          .filter((item) => item.done === undefined)
          .map((item) => ({
            key: `inbox-items:${item.id}`,
            at: item.at,
            conversation: item.conversation as ConversationId,
            tag: item.kind,
            title: item.title,
            gist: item.text.split(/\r?\n/, 1)[0],
            text: item.text,
            pane: <Pane item={item} />,
          })),
      )
    }),
  ],
})
