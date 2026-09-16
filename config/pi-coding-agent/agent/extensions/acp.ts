// @ts-nocheck
/**
 * acp.ts — Tidewave → tmux pi ACP forwarder shim (input-only).
 *
 * Dual role, single file:
 *
 * 1. CLI (spawned by Tidewave IDE as an External Agent, e.g. `bun .../acp.ts`):
 *    Speaks ACP (ndjson JSON-RPC 2.0, protocol v1) on stdio. On
 *    `session/prompt` it reads the Cmd+Shift+C handshake binding for the
 *    session's cwd and forwards the prompt text to the bound interactive tmux
 *    pi via its bridge socket (`pi.control.v1` `message.send`), emits one
 *    `agent_message_chunk` describing the outcome, and returns `end_turn`
 *    immediately. No pi subprocess is spawned; replies are read in tmux.
 *
 * 2. Extension (auto-loaded by pi from extensions/*.ts):
 *    Shows a small "Tidewave bound" indicator widget in interactive pis whose
 *    worktree has an active binding. The CLI entrypoint is guarded by an
 *    argv[1]-is-this-file check, so loading as an extension is side-effect
 *    free.
 *
 * Handshake binding (written by Hammerspoon on Cmd+Shift+C):
 *   ${PI_STATE_DIR}/tidewave/bindings/<worktree-slug>.json
 *   { worktree, cwd, socket, session, window, pane, tabUrl, port, boundAt }
 * Matched by exact cwd first, then by worktree-slug filename.
 */

import net from "node:net";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createInterface } from "node:readline";
import type {
	ExtensionAPI,
	ExtensionContext,
} from "@earendil-works/pi-coding-agent";

// =============================================================================
// Shared: binding lookup + bridge control client
// =============================================================================

const xdgStateHome =
	process.env.XDG_STATE_HOME ||
	(process.env.HOME ? path.join(process.env.HOME, ".local", "state") : "/tmp");
const PI_STATE_DIR = process.env.PI_STATE_DIR || path.join(xdgStateHome, "pi");
const BINDING_DIR = path.join(PI_STATE_DIR, "tidewave", "bindings");

const CONNECT_TIMEOUT_MS = 800;

type Binding = {
	worktree?: string;
	cwd?: string;
	socket?: string;
	session?: string;
	window?: string;
	pane?: string;
	tabUrl?: string;
	port?: number;
	boundAt?: string;
};

/** Slugify a cwd basename the same way .envrc / wt do (lowercase, dash-sep). */
const worktreeSlug = (cwd: string): string =>
	path
		.basename(cwd)
		.toLowerCase()
		.replace(/[^a-z0-9]/g, "-")
		.replace(/-+/g, "-")
		.replace(/^-|-$/g, "");

/** Find the handshake binding for a given cwd. Matches by exact cwd first,
 *  then by worktree slug filename. Returns null when unbound. */
const readBindingForCwd = (cwd: string): Binding | null => {
	try {
		if (!fs.existsSync(BINDING_DIR)) return null;
		const entries = fs
			.readdirSync(BINDING_DIR)
			.filter((f) => f.endsWith(".json"));
		for (const f of entries) {
			try {
				const b = JSON.parse(
					fs.readFileSync(path.join(BINDING_DIR, f), "utf8"),
				) as Binding;
				if (b.cwd && path.resolve(b.cwd) === path.resolve(cwd)) return b;
			} catch {}
		}
		const slugFile = path.join(BINDING_DIR, `${worktreeSlug(cwd)}.json`);
		if (fs.existsSync(slugFile)) {
			return JSON.parse(fs.readFileSync(slugFile, "utf8")) as Binding;
		}
	} catch {}
	return null;
};

/** Send one line-delimited JSON control request to a bridge socket. */
const sendControl = (
	socketPath: string,
	payload: unknown,
): Promise<Record<string, unknown> | null> =>
	new Promise((resolve) => {
		const socket = net.createConnection(socketPath);
		let buffer = "";
		let settled = false;
		const finish = (result: Record<string, unknown> | null): void => {
			if (settled) return;
			settled = true;
			socket.destroy();
			resolve(result);
		};
		socket.setTimeout(CONNECT_TIMEOUT_MS, () => finish(null));
		socket.on("error", () => finish(null));
		socket.on("connect", () => {
			socket.write(`${JSON.stringify(payload)}\n`);
		});
		socket.on("data", (chunk) => {
			buffer += chunk.toString();
			const idx = buffer.indexOf("\n");
			if (idx === -1) return;
			const line = buffer.slice(0, idx).trim();
			if (!line) return;
			try {
				finish(JSON.parse(line));
			} catch {
				finish(null);
			}
		});
		socket.on("close", () => finish(null));
	});

/** Forward a prompt to the handshaken tmux pi. Returns a status. */
const forwardToBoundPi = async (
	cwd: string,
	text: string,
): Promise<{ ok: boolean; detail: string }> => {
	const binding = readBindingForCwd(cwd);
	if (!binding?.socket) {
		return {
			ok: false,
			detail:
				"No Tidewave↔pi handshake for this worktree. Press Cmd+Shift+C in the pi you want bound.",
		};
	}
	if (!fs.existsSync(binding.socket)) {
		return {
			ok: false,
			detail: `Bound pi socket is gone (${path.basename(binding.socket)}). Re-handshake with Cmd+Shift+C.`,
		};
	}
	const request = {
		type: "control",
		protocol: "pi.control.v1",
		id: `pidewave-${Date.now().toString(36)}`,
		operation: "message.send",
		params: {
			text,
			mode: "follow_up",
			from: "tidewave",
		},
	};
	const res = await sendControl(binding.socket, request);
	if (res && res.ok === true) {
		const target = `${binding.session ?? "pi"}${binding.pane ? ` ${binding.pane}` : ""}`;
		return { ok: true, detail: `Forwarded to ${target}. Reply lands in tmux.` };
	}
	return {
		ok: false,
		detail:
			(res && typeof res.error === "string" && res.error) ||
			"Bound pi did not accept the message (control.v1 message.send failed).",
	};
};

// =============================================================================
// CLI role: ACP agent (stdio ndjson JSON-RPC 2.0)
// =============================================================================

const PROTOCOL_VERSION = 1;

const log = (msg: string): void => {
	try {
		process.stderr.write(`[pidewave-acp] ${msg}\n`);
	} catch {}
};

const runAcpShim = (): void => {
	const sessions = new Map<string, { cwd: string }>();
	let counter = 0;

	const send = (msg: Record<string, unknown>): void => {
		try {
			process.stdout.write(`${JSON.stringify({ jsonrpc: "2.0", ...msg })}\n`);
		} catch {}
	};
	const reply = (id: unknown, result: unknown): void => send({ id, result });
	const replyError = (id: unknown, code: number, message: string): void =>
		send({ id, error: { code, message } });
	const sessionChunk = (sessionId: string, text: string): void =>
		send({
			method: "session/update",
			params: {
				sessionId,
				update: {
					sessionUpdate: "agent_message_chunk",
					content: { type: "text", text },
				},
			},
		});

	/** Flatten prompt content blocks to plain text. */
	const textFromBlocks = (blocks: unknown): string => {
		if (!Array.isArray(blocks)) return "";
		return blocks
			.map((b: any) => {
				if (!b || typeof b !== "object") return "";
				if (b.type === "text" && typeof b.text === "string") return b.text;
				if (b.type === "resource_link" && typeof b.uri === "string")
					return b.uri;
				if (b.type === "resource")
					return b.resource?.text ?? b.resource?.uri ?? "";
				return "";
			})
			.filter(Boolean)
			.join("\n")
			.trim();
	};

	const handlers: Record<string, (params: any) => Promise<unknown>> = {
		initialize: async (params) => ({
			protocolVersion:
				params?.protocolVersion === PROTOCOL_VERSION
					? params.protocolVersion
					: PROTOCOL_VERSION,
			agentInfo: {
				name: "pidewave-acp",
				title: "pi tmux forwarder",
				version: "1.0.0",
			},
			authMethods: [],
			agentCapabilities: {
				loadSession: false,
				mcpCapabilities: { http: false, sse: false },
				promptCapabilities: {
					image: false,
					audio: false,
					embeddedContext: false,
				},
			},
		}),

		authenticate: async () => ({}),

		"session/new": async (params) => {
			const cwd = typeof params?.cwd === "string" ? params.cwd : process.cwd();
			counter += 1;
			const sessionId = `pidewave-${Date.now().toString(36)}-${counter}`;
			sessions.set(sessionId, { cwd });
			log(`session/new ${sessionId} cwd=${cwd}`);
			return { sessionId };
		},

		"session/prompt": async (params) => {
			const sessionId = params?.sessionId as string;
			const session = sessionId ? sessions.get(sessionId) : undefined;
			if (!session) {
				throw { code: -32602, message: `unknown sessionId: ${sessionId}` };
			}
			const text = textFromBlocks(params?.prompt);
			if (!text) {
				sessionChunk(sessionId, "Empty prompt; nothing forwarded.");
				return { stopReason: "end_turn" };
			}
			const { ok, detail } = await forwardToBoundPi(session.cwd, text);
			log(`session/prompt ${sessionId} ok=${ok} ${detail}`);
			sessionChunk(sessionId, ok ? `✓ ${detail}` : `✗ ${detail}`);
			return { stopReason: "end_turn" };
		},
	};

	const rl = createInterface({ input: process.stdin, crlfDelay: Infinity });
	rl.on("line", (line) => {
		const trimmed = line.trim();
		if (!trimmed) return;
		let msg: any;
		try {
			msg = JSON.parse(trimmed);
		} catch {
			log(`ignoring non-JSON line: ${trimmed.slice(0, 120)}`);
			return;
		}
		const { id, method, params } = msg;
		if (typeof method !== "string") return; // response to us; we never ask.
		const isNotification = id === undefined || id === null;
		if (method === "session/cancel" || method.startsWith("$/")) return; // nothing in flight to cancel.
		const handler = handlers[method];
		if (!handler) {
			if (!isNotification)
				replyError(id, -32601, `method not supported: ${method}`);
			return;
		}
		void handler(params)
			.then((result) => {
				if (!isNotification) reply(id, result);
			})
			.catch((err) => {
				if (isNotification) return;
				if (err && typeof err.code === "number") {
					replyError(id, err.code, String(err.message ?? "error"));
				} else {
					replyError(id, -32603, String(err?.message ?? err));
				}
			});
	});

	const shutdown = (): void => {
		try {
			process.exit(0);
		} catch {}
	};
	rl.on("close", shutdown);
	process.on("SIGINT", shutdown);
	process.on("SIGTERM", shutdown);
	process.stdout.on("error", shutdown);
	log(`ready (bindings: ${BINDING_DIR})`);
};

// Run the ACP shim only when executed directly (bun/node acp.ts), never when
// pi auto-loads this file as an extension (argv[1] is then pi's own entry).
const isMain = (() => {
	try {
		return (
			typeof process.argv[1] === "string" &&
			path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)
		);
	} catch {
		return false;
	}
})();

if (isMain) runAcpShim();

// =============================================================================
// Extension role: Tidewave-binding indicator widget (interactive tmux pis)
// =============================================================================

export default function (pi: ExtensionAPI): void {
	if (isMain) return; // defensive: never register hooks in CLI mode.

	const showBindingWidget = (ctx: ExtensionContext): void => {
		if (!ctx.hasUI) return;
		try {
			const b = readBindingForCwd(ctx.cwd);
			if (!b) {
				ctx.ui.setWidget?.("pidewave", undefined);
				return;
			}
			const mySocket = process.env.PI_SOCKET;
			const boundHere = mySocket && b.socket === mySocket;
			ctx.ui.setWidget?.("pidewave", [
				ctx.ui.theme.fg(
					boundHere ? "accent" : "muted",
					boundHere
						? "◉ Tidewave bound here"
						: "○ Tidewave bound (this worktree)",
				),
				...(b.tabUrl ? [ctx.ui.theme.fg("muted", b.tabUrl)] : []),
			]);
		} catch {}
	};

	pi.on("session_start", (_e, ctx) => showBindingWidget(ctx));
	pi.on("before_agent_start", (_e, ctx) => {
		showBindingWidget(ctx);
		return undefined;
	});
}
