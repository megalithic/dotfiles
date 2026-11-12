import { writeFileSync } from 'node:fs'
import { defineExtension } from '@earendil-works/pi-durable'

type Status = {
  busy: number
  questions: { count: number; first?: { text: string } }
}
type State = { state: 'blocked' | 'working' | 'idle'; msg?: string }
// Only public host capabilities; user extensions cannot import clone-local modules.
type Host = {
  invoke(name: string, action: string, args: unknown, signal: AbortSignal): Promise<unknown>
  onOpen(callback: () => void): void
  onClose(callback: () => void): void
}

export function derive(status: Status): State {
  if (status.questions.count > 0) {
    return {
      state: 'blocked',
      msg: (status.questions.first?.text ?? '').replace(/\s+/g, ' ').trim().slice(0, 120),
    }
  }
  if (status.busy > 0) return { state: 'working', msg: `@ultimate · ${status.busy} busy` }
  return { state: 'idle' }
}

export function osc({ state, msg }: State): string {
  const message = msg === undefined ? '' : `:msg=${Buffer.from(msg).toString('base64')}`
  return `\x1b]7501;state=${state}:app=ultimate${message}\x1b\\`
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
    const poll = async () => {
      if (polling || controller.signal.aborted) return
      polling = true
      try {
        const status = await host.invoke('status', 'status', {}, controller.signal)
        if (!controller.signal.aborted) emit(derive(status as Status))
      } catch {
        // Status may be unavailable during reload; try again on the next tick.
      } finally {
        polling = false
      }
    }
    host.onOpen(() => {
      if (timer) return
      timer = setInterval(() => void poll(), 3000)
      timer.unref()
    })
    host.onClose(() => {
      controller.abort()
      clearInterval(timer)
      // Reset even if the last successful update was already idle.
      previous = undefined
      emit({ state: 'idle' })
    })
  }
  return defineExtension({ name: 'rex-status' })
}
