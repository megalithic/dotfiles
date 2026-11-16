/**
 * The `session` action's Markdown, which is written for an agent, reshaped for reading on a phone: what pi wants and
 * said first, git next, the long brief and compaction folded. Live is dropped (the header shows it); empty sections too.
 */
import { ChevronRightIcon } from 'lucide-react'
import { MessageResponse } from '@/components/ai/message'
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from '@/components/ui/collapsible'

type Section = { title: string; body: string }

/** Sections in reading order; `fold` ones start closed, `code` ones are shown verbatim. */
const layout: { title: string; label: string; fold?: boolean; code?: boolean }[] = [
  { title: 'Goal', label: 'Goal' },
  { title: 'Open todos', label: 'Open todos' },
  { title: 'Last assistant message', label: 'Last answer' },
  { title: 'git status --short', label: 'git status', code: true },
  { title: 'git diff --stat', label: 'git diff --stat', code: true },
  { title: 'Brief', label: 'Session brief', fold: true },
  { title: 'Last compaction summary', label: 'Compaction summary', fold: true },
]

export function sections(markdown: string): Section[] {
  const parts = markdown.split(/^## /m).slice(1)
  return parts.map((part) => {
    const newline = part.indexOf('\n')
    return {
      title: (newline < 0 ? part : part.slice(0, newline)).trim(),
      body: newline < 0 ? '' : part.slice(newline + 1).trim(),
    }
  })
}

/** The brief nests its own `#`/`##` headings; push them below the section label. */
const demote = (body: string) => body.replace(/^(#{1,3}) /gm, (_, hashes: string) => `${'#'.repeat(hashes.length + 3)} `)

const empty = (body: string) => !body || /^(none|no saved pi session\.?)$/i.test(body)

function Body({ body, code }: { body: string; code?: boolean }) {
  if (code)
    return (
      <pre className="overflow-x-auto rounded-md bg-muted/50 px-2.5 py-2 font-mono text-[11.5px] leading-[1.5] text-foreground/85">
        {body}
      </pre>
    )
  return <MessageResponse className="text-[13px]">{demote(body)}</MessageResponse>
}

export function Brief({ markdown }: { markdown: string }) {
  const found = new Map(sections(markdown).map((section) => [section.title, section.body]))
  const shown = layout.flatMap((item) => {
    const body = found.get(item.title)
    return body === undefined || empty(body) ? [] : [{ ...item, body }]
  })
  // Anything the server adds later still shows, after the known sections.
  const known = new Set(['Live', ...layout.map((item) => item.title)])
  const extra = [...found].filter(([title, body]) => !known.has(title) && !empty(body))
  if (!shown.length && !extra.length)
    return <p className="text-[12.5px] text-muted-foreground">No saved pi session, todos or changes here yet.</p>
  return (
    <div className="flex flex-col gap-4">
      {shown.map((item) =>
        item.fold ? (
          <Collapsible className="group/fold" key={item.title}>
            <CollapsibleTrigger className="flex items-center gap-1 section-label transition-colors hover:text-foreground">
              <ChevronRightIcon className="size-3 transition-transform group-data-[state=open]/fold:rotate-90" />
              {item.label}
            </CollapsibleTrigger>
            <CollapsibleContent className="mt-1.5">
              <Body body={item.body} />
            </CollapsibleContent>
          </Collapsible>
        ) : (
          <section key={item.title}>
            <h3 className="mb-1.5 section-label">{item.label}</h3>
            <Body body={item.body} code={item.code} />
          </section>
        ),
      )}
      {extra.map(([title, body]) => (
        <section key={title}>
          <h3 className="mb-1.5 section-label">{title}</h3>
          <Body body={body} />
        </section>
      ))}
    </div>
  )
}
