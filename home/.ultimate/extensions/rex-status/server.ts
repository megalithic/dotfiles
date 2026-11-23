import { writeFileSync } from 'node:fs'
import { BACKGROUND_CONTEXT as context } from '@earendil-works/chord/context'
import { defineExtension } from '@earendil-works/pi-durable'
import type { ConversationDocToken, ConversationId, Harness, JsonObject } from '@earendil-works/pi-durable'

// The project's Inbox lives on the root conversation (pi-durable's ROOT_CONVERSATION_ID).
const ROOT = 1 as ConversationId

type Status = {
  busy: number
  questions: { count: number; first?: { text: string } }
}
type Items = { items?: { done?: unknown }[] }
type State = { state: 'blocked' | 'working' | 'idle'; kind?: 'question'; msg?: string }
// Only public host capabilities; user extensions cannot import clone-local modules.
type Host = {
  invoke(name: string, action: string, args: unknown, signal: AbortSignal): Promise<unknown>
  harness(): Harness
  doc(kind: string): ConversationDocToken<JsonObject> | undefined
  onOpen(callback: () => Promise<void>): void
  onClose(callback: () => Promise<void>): void
}

/** Open Inbox items, as the Inbox and `rtm needs` count them: not yet done. */
export const openItems = (doc: Items | undefined) =>
  (doc?.items ?? []).filter((item) => item.done === undefined || item.done === null || item.done === false).length

/** What waits on the user is open questions plus open Inbox items, the same count as `rtm needs`. */
export function derive(status: Status, items = 0): State {
  const waiting = status.questions.count + items
  if (waiting > 0) {
    const first = (status.questions.first?.text ?? '').replace(/\s+/g, ' ').trim()
    const msg = `${waiting} waiting${first ? ` · ${first}` : ''}`.slice(0, 120)
    return status.questions.count > 0 ? { state: 'blocked', kind: 'question', msg } : { state: 'blocked', msg }
  }
  if (status.busy > 0) return { state: 'working', msg: `@ultimate · ${status.busy} busy` }
  return { state: 'idle' }
}

export function osc({ state, kind, msg }: State): string {
  const kindPair = kind === undefined ? '' : `:kind=${kind}`
  const message = msg === undefined ? '' : `:msg=${Buffer.from(msg).toString('base64')}`
  return `\x1b]7501;state=${state}${kindPair}:app=ultimate${message}\x1b\\`
}

export default function rexStatus(host: Host) {
  if (process.env.REX_BLOCK) {
    const controller = new AbortController()
    let timer: ReturnType<typeof setInterval> | undefined
    let previous: string | undefined
    let polling = false
    const emit = (state: State) => {
      const value = osc(state)
      if (value === previous) return
      try {
        writeFileSync('/dev/tty', value)
        previous = value
      } catch {
        // A detached or closing terminal must not interrupt Ultimate.
      }
    }
    const items = async () => {
      const doc = host.doc('inbox-items.items')
      // Without the inbox-items extension only questions wait.
      if (!doc) return 0
      return openItems((await host.harness().snapshot(doc, ROOT, context)) as Items | undefined)
    }
    const poll = async () => {
      if (polling || controller.signal.aborted) return
      polling = true
      try {
        const [status, open] = await Promise.all([
          host.invoke('status', 'status', {}, controller.signal),
          items(),
        ])
        if (!controller.signal.aborted) emit(derive(status as Status, open))
      } catch {
        // Status may be unavailable during reload; try again on the next tick.
      } finally {
        polling = false
      }
    }
    host.onOpen(async () => {
      if (timer) return
      timer = setInterval(() => void poll(), 3000)
      timer.unref()
    })
    host.onClose(async () => {
      controller.abort()
      clearInterval(timer)
      // Reset even if the last successful update was already idle.
      previous = undefined
      emit({ state: 'idle' })
    })
  }
  return defineExtension({ name: 'rex-status' })
}
