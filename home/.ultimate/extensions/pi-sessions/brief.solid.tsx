import { createMemo, For, Show } from 'solid-js'
import { ChevronRightIcon } from '@lucide/solid'
import { Markdown } from '@/components/markdown/markdown.solid.tsx'
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from '@/components/ui/collapsible.solid.tsx'
type Section = { title: string; body: string }
const layout: { title: string; label: string; fold?: boolean; code?: boolean }[] = [
  { title: 'Goal', label: 'Goal' },
  { title: 'Open todos', label: 'Open todos' },
  { title: 'Last assistant message', label: 'Last answer' },
  { title: 'git status --short', label: 'git status', code: true },
  { title: 'git diff --stat', label: 'git diff --stat', code: true },
  { title: 'Brief', label: 'Session brief', fold: true },
  { title: 'Last compaction summary', label: 'Compaction summary', fold: true },
]
const demote = (body: string) =>
  body.replace(/^(#{1,3}) /gm, (_, hashes: string) => `${'#'.repeat(hashes.length + 3)} `)
const empty = (body: string) => !body || /^(none|no saved pi session\.?)$/i.test(body)
function Body(props: { body: string; code?: boolean }) {
  return (
    <Show when={props.code} fallback={<Markdown class="text-[13px]" text={demote(props.body)} />}>
      <pre class="overflow-x-auto rounded-md bg-muted/50 px-2.5 py-2 font-mono text-[11.5px] leading-[1.5] text-foreground/85">
        {props.body}
      </pre>
    </Show>
  )
}
export function Brief(props: { sections: Section[] }) {
  const found = createMemo(
    () => new Map(props.sections.map((section) => [section.title, section.body.trim()])),
  )
  const shown = createMemo(() =>
    layout.flatMap((item) => {
      const body = found().get(item.title)
      return body === undefined || empty(body) ? [] : [{ ...item, body }]
    }),
  )
  const known = new Set(['Live', ...layout.map((item) => item.title)])
  const extra = createMemo(() =>
    [...found()].filter(([title, body]) => !known.has(title) && !empty(body)),
  )
  return (
    <Show
      when={shown().length || extra().length}
      fallback={
        <p class="text-[12.5px] text-muted-foreground">
          No saved pi session, todos or changes here yet.
        </p>
      }
    >
      <div class="flex flex-col gap-4">
        <For each={shown()} keyed={(item) => item.title}>
          {(item) => (
            <Show
              when={item().fold}
              fallback={
                <section>
                  <h3 class="mb-1.5 section-label">{item().label}</h3>
                  <Body body={item().body} code={item().code} />
                </section>
              }
            >
              <Collapsible>
                <CollapsibleTrigger class="group/fold flex items-center gap-1 section-label transition-colors hover:text-foreground">
                  <ChevronRightIcon class="size-3 transition-transform group-data-open/fold:rotate-90" />
                  {item().label}
                </CollapsibleTrigger>
                <CollapsibleContent class="mt-1.5">
                  <Body body={item().body} />
                </CollapsibleContent>
              </Collapsible>
            </Show>
          )}
        </For>
        <For each={extra()} keyed={(item) => item[0]}>
          {(item) => (
            <section>
              <h3 class="mb-1.5 section-label">{item()[0]}</h3>
              <Body body={item()[1]} />
            </section>
          )}
        </For>
      </div>
    </Show>
  )
}
