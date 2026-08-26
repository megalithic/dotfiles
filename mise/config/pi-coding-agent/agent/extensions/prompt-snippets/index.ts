/**
 * Prompt Snippets — mix-and-match single-purpose prompt rules.
 *
 * Each snippet is a markdown file with frontmatter (name, description,
 * placement, order) stored in the `snippets/` directory next to this file.
 *
 * - Press alt+s or run /snippets to open the toggle menu (space: toggle,
 *   tab: preview, enter: apply, esc: cancel). The menu is a bordered,
 *   scrollable view.
 * - Active snippets appear as a widget above the editor, with prepend and
 *   append groups visually distinguished.
 * - When a message is sent, active snippet bodies are prepended/appended to
 *   the message text in order (prepend group sorted by `order` first, then
 *   the typed text, then the append group sorted by `order`).
 * - Toggles reset to all-off after each send and at session start.
 */

import { existsSync, mkdirSync, readFileSync, readdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Key, matchesKey, truncateToWidth, wrapTextWithAnsi } from "@earendil-works/pi-tui";

interface Snippet {
	/** Filename, e.g. "concise.md" */
	id: string;
	name: string;
	description: string;
	placement: "prepend" | "append";
	order: number;
	body: string;
}

const extensionDir = dirname(fileURLToPath(import.meta.url));
const snippetsDir = join(extensionDir, "snippets");
const WIDGET_ID = "prompt-snippets";

function parseSnippet(filename: string, raw: string): Snippet | null {
	const match = raw.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n?([\s\S]*)$/);
	if (!match) return null;

	const meta: Record<string, string> = {};
	for (const line of match[1].split(/\r?\n/)) {
		const kv = line.match(/^([A-Za-z][\w-]*)\s*:\s*(.*)$/);
		if (kv) meta[kv[1].toLowerCase()] = kv[2].trim().replace(/^["']|["']$/g, "");
	}

	const body = match[2].trim();
	if (!body) return null;

	const parsedOrder = Number.parseInt(meta.order ?? "", 10);
	return {
		id: filename,
		name: meta.name || filename.replace(/\.md$/i, ""),
		description: meta.description ?? "",
		placement: meta.placement === "prepend" ? "prepend" : "append",
		order: Number.isFinite(parsedOrder) ? parsedOrder : 9999,
		body,
	};
}

/** Load all snippets, sorted: prepend group first, append group last, each by (order, name). */
function loadSnippets(): Snippet[] {
	if (!existsSync(snippetsDir)) return [];
	const snippets: Snippet[] = [];
	for (const file of readdirSync(snippetsDir)) {
		if (!file.toLowerCase().endsWith(".md")) continue;
		try {
			const snippet = parseSnippet(file, readFileSync(join(snippetsDir, file), "utf8"));
			if (snippet) snippets.push(snippet);
		} catch {
			// Skip unreadable files
		}
	}
	const byOrder = (a: Snippet, b: Snippet) => a.order - b.order || a.name.localeCompare(b.name);
	return [
		...snippets.filter((s) => s.placement === "prepend").sort(byOrder),
		...snippets.filter((s) => s.placement === "append").sort(byOrder),
	];
}

export default function (pi: ExtensionAPI) {
	// Snippets last seen on disk (sorted). Refreshed whenever the menu opens or a message is sent.
	let snippets: Snippet[] = [];
	// Ids of currently toggled snippets. Resets to empty after each send and at session start.
	let enabled = new Set<string>();

	function updateWidget(ctx: ExtensionContext) {
		if (!ctx.hasUI || ctx.mode !== "tui") return;
		const active = snippets.filter((s) => enabled.has(s.id));
		const prepends = active.filter((s) => s.placement === "prepend");
		const appends = active.filter((s) => s.placement === "append");

		if (prepends.length === 0 && appends.length === 0) {
			ctx.ui.setWidget(WIDGET_ID, undefined);
			return;
		}

		const theme = ctx.ui.theme;
		const lines: string[] = [];
		if (prepends.length > 0) {
			lines.push(theme.fg("accent", `↑ prepend: ${prepends.map((s) => s.name).join(" · ")}`));
		}
		if (appends.length > 0) {
			lines.push(theme.fg("warning", `↓ append: ${appends.map((s) => s.name).join(" · ")}`));
		}
		ctx.ui.setWidget(WIDGET_ID, lines);
	}

	async function openMenu(ctx: ExtensionContext) {
		if (ctx.mode !== "tui") {
			ctx.ui.notify("Snippet menu requires interactive mode", "warning");
			return;
		}

		snippets = loadSnippets();
		// Drop toggles for snippets that no longer exist on disk.
		enabled = new Set([...enabled].filter((id) => snippets.some((s) => s.id === id)));

		if (snippets.length === 0) {
			ctx.ui.notify(`No snippets found in ${snippetsDir}`, "warning");
			updateWidget(ctx);
			return;
		}

		// Working copy; only committed to `enabled` on confirm.
		const working = new Set(enabled);

		const confirmed = await ctx.ui.custom<boolean>((tui, theme, _keybindings, done) => {
			const prepends = snippets.filter((s) => s.placement === "prepend");
			const appends = snippets.filter((s) => s.placement === "append");
			const items = [...prepends, ...appends];

			let mode: "list" | "preview" = "list";
			let cursor = 0;
			let listScroll = 0;
			let previewScroll = 0;

			const itemRow = (snippet: Snippet, idx: number, width: number): string => {
				const pointer = idx === cursor ? theme.fg("accent", "> ") : "  ";
				const checkbox = working.has(snippet.id) ? theme.fg("success", "[x]") : theme.fg("dim", "[ ]");
				const desc = snippet.description ? theme.fg("dim", ` — ${snippet.description}`) : "";
				return truncateToWidth(`${pointer}${checkbox} ${theme.bold(snippet.name)}${desc}`, width);
			};

			/** List rows with the item index each row corresponds to (null for headers/blanks). */
			const buildListRows = (width: number): { text: string; itemIndex: number | null }[] => {
				const rows: { text: string; itemIndex: number | null }[] = [];
				rows.push({ text: theme.fg("dim", "↑ PREPEND — added before your message"), itemIndex: null });
				prepends.forEach((s, i) => rows.push({ text: itemRow(s, i, width), itemIndex: i }));
				rows.push({ text: "", itemIndex: null });
				rows.push({ text: theme.fg("dim", "↓ APPEND — added after your message"), itemIndex: null });
				appends.forEach((s, i) => rows.push({ text: itemRow(s, prepends.length + i, width), itemIndex: prepends.length + i }));
				return rows;
			};

			const buildPreviewRows = (snippet: Snippet, width: number): string[] => {
				const rows: string[] = [];
				rows.push(truncateToWidth(theme.bold(snippet.name), width));
				rows.push(truncateToWidth(theme.fg("dim", `${snippet.placement} · order ${snippet.order} · ${snippet.id}`), width));
				rows.push(theme.fg("dim", "─".repeat(Math.min(width, 40))));
				for (const line of snippet.body.split("\n")) {
					for (const wrapped of wrapTextWithAnsi(line, width)) {
						rows.push(truncateToWidth(wrapped, width));
					}
				}
				return rows;
			};

			/**
			 * Slice `lines` to a scrollable viewport of at most `maxView` lines,
			 * reserving indicator slots when clipped. Returns the visible lines
			 * plus the clamped scroll position. When `focusRow` is given, scrolls
			 * so it stays visible.
			 */
			const viewport = (
				lines: string[],
				scroll: number,
				maxView: number,
				focusRow?: number,
			): { out: string[]; scroll: number } => {
				const clipped = lines.length > maxView;
				const view = clipped ? Math.max(1, maxView - 2) : maxView;

				let s = Math.min(Math.max(0, scroll), Math.max(0, lines.length - view));
				if (focusRow !== undefined) {
					if (focusRow < s) s = focusRow;
					else if (focusRow >= s + view) s = focusRow - view + 1;
				}

				const visible = lines.slice(s, s + view);
				if (!clipped) return { out: visible, scroll: s };

				const above = s;
				const below = lines.length - (s + view);
				return {
					out: [
						above > 0 ? theme.fg("dim", `  ↑ ${above} more`) : "",
						...visible,
						below > 0 ? theme.fg("dim", `  ↓ ${below} more`) : "",
					],
					scroll: s,
				};
			};

			return {
				render(width: number): string[] {
					// Reserve lines for: top border, title, blank, blank, hints, bottom border.
					const maxView = Math.max(5, tui.terminal.rows - 10);

					let content: string[];
					let title: string;
					let hints: string;
					if (mode === "list") {
						const rows = buildListRows(width);
						const cursorRow = rows.findIndex((r) => r.itemIndex === cursor);
						const v = viewport(rows.map((r) => r.text), listScroll, maxView, cursorRow);
						content = v.out;
						listScroll = v.scroll;
						title = "Prompt snippets";
						hints = "↑↓ navigate • Space toggle • Tab preview • Enter apply • Esc cancel";
					} else {
						const snippet = items[cursor];
						const rows = buildPreviewRows(snippet, width);
						const v = viewport(rows, previewScroll, maxView);
						content = v.out;
						previewScroll = v.scroll;
						title = `Preview: ${snippet.name}`;
						hints = "↑↓ scroll • Tab/Esc back";
					}

					return [
						theme.fg("accent", "─".repeat(width)),
						truncateToWidth(` ${theme.fg("accent", theme.bold(title))}`, width),
						"",
						...content,
						"",
						truncateToWidth(theme.fg("dim", ` ${hints}`), width),
						theme.fg("accent", "─".repeat(width)),
					];
				},
				invalidate() {},
				handleInput(data: string) {
					if (mode === "list") {
						if (matchesKey(data, Key.up)) {
							cursor = (cursor - 1 + items.length) % items.length;
							tui.requestRender();
						} else if (matchesKey(data, Key.down)) {
							cursor = (cursor + 1) % items.length;
							tui.requestRender();
						} else if (matchesKey(data, Key.space)) {
							const id = items[cursor].id;
							if (working.has(id)) working.delete(id);
							else working.add(id);
							tui.requestRender();
						} else if (matchesKey(data, Key.tab)) {
							mode = "preview";
							previewScroll = 0;
							tui.requestRender();
						} else if (matchesKey(data, Key.enter)) {
							done(true);
						} else if (matchesKey(data, Key.escape)) {
							done(false);
						}
					} else {
						if (matchesKey(data, Key.up)) {
							previewScroll--;
							tui.requestRender();
						} else if (matchesKey(data, Key.down)) {
							previewScroll++;
							tui.requestRender();
						} else if (matchesKey(data, Key.tab) || matchesKey(data, Key.escape)) {
							mode = "list";
							tui.requestRender();
						}
					}
				},
			};
		});

		if (confirmed) {
			enabled = working;
		}
		updateWidget(ctx);
	}

	pi.on("session_start", (_event, ctx) => {
		enabled = new Set();
		snippets = loadSnippets();
		if (!existsSync(snippetsDir)) mkdirSync(snippetsDir, { recursive: true });
		updateWidget(ctx);
	});

	pi.on("input", async (event, ctx) => {
		if (enabled.size === 0) return; // continue unchanged

		snippets = loadSnippets();
		const active = snippets.filter((s) => enabled.has(s.id));
		enabled = new Set();
		updateWidget(ctx);

		if (active.length === 0) return; // all toggled snippets vanished from disk

		const prependBodies = active.filter((s) => s.placement === "prepend").map((s) => s.body);
		const appendBodies = active.filter((s) => s.placement === "append").map((s) => s.body);
		return {
			action: "transform",
			text: [...prependBodies, event.text, ...appendBodies].join("\n\n"),
		};
	});

	pi.registerShortcut("alt+s", {
		description: "Toggle prompt snippets",
		handler: async (ctx) => {
			await openMenu(ctx);
		},
	});

	pi.registerCommand("snippets", {
		description: "Open the prompt snippet toggle menu",
		handler: async (_args, ctx) => {
			await openMenu(ctx);
		},
	});
}
