import { truncateToWidth } from "@earendil-works/pi-tui";
import type { ExtensionContext } from "@mariozechner/pi-coding-agent";
import type { PtyTerminalSession } from "./pty-session.ts";
import { snapshotToAnsiContentLines } from "./terminal-emulator.ts";

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

function fitAnsiLine(line: string, width: number): string {
	// Delegate to pi-tui's own grapheme + RGI-emoji + ANSI aware width logic so
	// this widget measures cells exactly like the renderer does. A per-codepoint
	// count drifts on emoji/ZWJ clusters (renderer counts the cluster as 2, a
	// naive sum gets 1), which pads the line one column short and overflows the
	// terminal width -> "Rendered line exceeds terminal width" TUI crash.
	// Append a reset first so trailing padding never inherits prior styling.
	return truncateToWidth(`${line}\x1b[0m`, width, "", true);
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
