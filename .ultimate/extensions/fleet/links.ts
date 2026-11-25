import type { Row } from './lib.ts'

type Page = { hostname: string; protocol: string }

/** Local links stay on the page's network; remote instances keep their configured URL. */
export function href(
  row: Pick<Row, 'url' | 'tailnetPort'>,
  local: boolean,
  page: Page,
  conversation?: number,
) {
  const loopback = /^(127\.0\.0\.1|localhost|\[::1\])$|\.localhost$/.test(page.hostname)
  const base =
    local && !loopback
      ? row.tailnetPort
        ? `${page.protocol}//${page.hostname}:${row.tailnetPort}`
        : undefined
      : row.url
  if (!base) return undefined
  try {
    if (!/^https?:$/.test(new URL(base).protocol)) return undefined
  } catch {
    return undefined
  }
  return conversation === undefined
    ? base
    : `${base.replace(/\/$/, '')}/?conversation=${conversation}`
}
