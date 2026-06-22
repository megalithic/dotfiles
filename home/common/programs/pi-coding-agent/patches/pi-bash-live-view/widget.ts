import type { ExtensionContext } from "@mariozechner/pi-coding-agent";
import { snapshotToAnsiContentLines } from "./terminal-emulator.ts";
import type { PtyTerminalSession } from "./pty-session.ts";

export const WIDGET_PREFIX = "pi-bash-live-view/live/";
const DEFAULT_TITLE = "Live terminal";
const DEFAULT_ACCENT_COLOR = "77;163;255";

export type LiveSession = {
  id: string;
  startedAt: number;
  rows: number;
  visible: boolean;
  disposed: boolean;
  timer?: NodeJS.Timeout;
  session: PtyTerminalSession;
  requestRender?: () => void;
};

export function formatElapsed(ms: number): string {
  const totalSeconds = Math.max(0, ms / 1000);
  if (totalSeconds < 60) return `${totalSeconds.toFixed(1)}s`;
  const wholeSeconds = Math.floor(totalSeconds);
  const hours = Math.floor(wholeSeconds / 3600);
  const minutes = Math.floor((wholeSeconds % 3600) / 60);
  const seconds = wholeSeconds % 60;
  if (hours > 0)
    return `${hours}:${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
  return `${minutes}:${String(seconds).padStart(2, "0")}`;
}

export function buildTopBorder(
  title: string,
  innerWidth: number,
  elapsedMs: number,
): string {
  const timer = ` ${formatElapsed(elapsedMs)} `;
  const rawTitle = title ? ` ${title} ` : "";
  const titleText = rawTitle.slice(0, Math.max(0, innerWidth - timer.length));
  const fill = "─".repeat(
    Math.max(0, innerWidth - titleText.length - timer.length),
  );
  return `${titleText}${fill}${timer}`
    .padEnd(innerWidth, "─")
    .slice(0, innerWidth);
}

function isWideCodePoint(codePoint: number): boolean {
  return (
    codePoint >= 0x1100 &&
    (codePoint <= 0x115f ||
      codePoint === 0x2329 ||
      codePoint === 0x232a ||
      (codePoint >= 0x2e80 && codePoint <= 0xa4cf && codePoint !== 0x303f) ||
      (codePoint >= 0xac00 && codePoint <= 0xd7a3) ||
      (codePoint >= 0xf900 && codePoint <= 0xfaff) ||
      (codePoint >= 0xfe10 && codePoint <= 0xfe19) ||
      (codePoint >= 0xfe30 && codePoint <= 0xfe6f) ||
      (codePoint >= 0xff00 && codePoint <= 0xff60) ||
      (codePoint >= 0xffe0 && codePoint <= 0xffe6) ||
      (codePoint >= 0x1f300 && codePoint <= 0x1faff) ||
      (codePoint >= 0x20000 && codePoint <= 0x3fffd))
  );
}

function charWidth(char: string): number {
  const codePoint = char.codePointAt(0) ?? 0;
  if (codePoint === 0) return 0;
  if (codePoint < 32 || (codePoint >= 0x7f && codePoint < 0xa0)) return 0;
  if (codePoint >= 0x300 && codePoint <= 0x36f) return 0;
  if (codePoint >= 0xfe00 && codePoint <= 0xfe0f) return 0;
  if (codePoint === 0x200d) return 0;
  return isWideCodePoint(codePoint) ? 2 : 1;
}

function fitAnsiLine(line: string, width: number): string {
  let out = "";
  let visible = 0;
  let i = 0;
  while (i < line.length && visible < width) {
    const rest = line.slice(i);
    const ansiMatch = rest.match(
      /^\x1b(?:\[[0-?]*[ -/]*[@-~]|\][^\x07]*(?:\x07|\x1b\\)|[PX^_].*?(?:\x1b\\)|[()][A-Za-z0-9])/,
    );
    if (ansiMatch) {
      out += ansiMatch[0];
      i += ansiMatch[0].length;
      continue;
    }

    const codePoint = line.codePointAt(i);
    if (codePoint === undefined) break;
    const char = String.fromCodePoint(codePoint);
    const charCells = charWidth(char);
    if (visible + charCells > width) break;
    out += char;
    visible += charCells;
    i += char.length;
  }
  return `${out}\x1b[0m${" ".repeat(Math.max(0, width - visible))}`;
}

export function buildWidgetAnsiLines({
  title = DEFAULT_TITLE,
  snapshot,
  width,
  rows,
  elapsedMs = 0,
  accentColor = DEFAULT_ACCENT_COLOR,
}: {
  title?: string;
  snapshot: ReturnType<PtyTerminalSession["getViewportSnapshot"]>;
  width: number;
  rows: number;
  elapsedMs?: number;
  accentColor?: string;
}): string[] {
  const accent = `\x1b[38;2;${accentColor}m`;
  const reset = "\x1b[0m";
  const innerWidth = Math.max(10, width - 2);
  const top = `${accent}╭${buildTopBorder(title, innerWidth, elapsedMs)}╮${reset}`;
  const bottom = `${accent}╰${"─".repeat(innerWidth)}╯${reset}`;
  const bodySource = snapshotToAnsiContentLines(snapshot).slice(-rows);
  const body = [];
  for (let i = 0; i < rows; i += 1) {
    const line = fitAnsiLine(bodySource[i] ?? "", innerWidth);
    body.push(`${accent}│${reset}${line}${accent}│${reset}`);
  }
  return [top, ...body, bottom];
}

function makeWidgetFactory(session: LiveSession) {
  return (tui: any) => {
    session.requestRender = () => tui.requestRender();
    return {
      invalidate() {},
      render(width: number) {
        return buildWidgetAnsiLines({
          snapshot: session.session.getViewportSnapshot(),
          width,
          rows: session.rows,
          elapsedMs: Date.now() - session.startedAt,
        });
      },
    };
  };
}

export function showWidget(ctx: ExtensionContext, session: LiveSession) {
  if (!ctx.hasUI || session.visible || session.disposed) return;
  session.visible = true;
  ctx.ui.setWidget(`${WIDGET_PREFIX}${session.id}`, makeWidgetFactory(session));
}

export function hideWidget(ctx: ExtensionContext | null, session: LiveSession) {
  if (!ctx || !ctx.hasUI) return;
  ctx.ui.setWidget(`${WIDGET_PREFIX}${session.id}`, undefined);
}
