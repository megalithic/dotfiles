import { Show } from 'solid-js'
import {
  actionRef,
  cn,
  defineWebExtension,
  useAction,
  useConversationId,
  useConversationSummary,
  keepLast,
} from '@/sdk/solid'

type Pr = {
  number: number
  url: string
  state: string
  draft: boolean
  review: string | null
  checks: { pass: number; fail: number; pending: number }
  colour: 'yellow' | 'blue' | 'green' | 'red' | 'merged' | 'closed'
  stale: boolean
}

const PrAction = actionRef<null, Pr | null>('pr-status', 'pr')

const COLOUR: Record<Pr['colour'], string> = {
  yellow: 'text-yellow-500',
  blue: 'text-blue-500',
  green: 'text-green-500',
  red: 'text-red-500',
  merged: 'text-purple-500',
  closed: 'text-muted-foreground',
}

const MEANING: Record<Pr['colour'], string> = {
  yellow: 'checks running',
  blue: 'waiting (draft or review)',
  green: 'ready to merge',
  red: 'failed checks or conflicts',
  merged: 'merged',
  closed: 'closed',
}

function PrChip() {
  const id = useConversationId()
  const conversation = useConversationSummary(id)
  // The action runs in this conversation's cwd; refresh after each run and every 2 min.
  const { data: pr } = useAction(PrAction, null, {
    on: () => `${id()}:${conversation()?.busy}`,
    every: 120_000,
    focus: true,
    onError: keepLast,
  })
  const href = () => {
    const value = pr()?.url ?? ''
    try {
      const url = new URL(value)
      return url.protocol === 'http:' || url.protocol === 'https:' ? url.href : undefined
    } catch {
      return undefined
    }
  }
  return (
    <Show when={pr()}>
      {(pull) => (
        <a
          href={href()}
          target="_blank"
          rel="noreferrer"
          class={cn(
            'shrink-0 hover:underline',
            COLOUR[pull().colour],
            pull().stale && 'opacity-50',
          )}
          title={`PR #${pull().number}: ${MEANING[pull().colour]}${pull().draft ? ' · draft' : ''} · checks ${pull().checks.pass}✓ ${pull().checks.fail}✗ ${pull().checks.pending}…${
            pull().review ? ` · ${pull().review!.toLowerCase().replace('_', ' ')}` : ''
          }${pull().stale ? ' · offline, last known' : ''}`}
        >
          #{pull().number}
        </a>
      )}
    </Show>
  )
}

export default defineWebExtension({
  slots: { 'composer.status': [PrChip] },
})
