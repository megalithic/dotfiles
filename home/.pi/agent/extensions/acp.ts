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
 *    Registers the trusted worktree's Tidewave MCP endpoint and publishes
 *    its verified runtime identity. Also publishes the bound app URL and
 *    local ownership for the custom footer. The CLI entrypoint is guarded by an
 *    argv[1]-is-this-file check, so loading as an extension is side-effect
 *    free.
 *
 * Handshake binding (written by Hammerspoon on Cmd+Shift+C):
 *   ${PI_STATE_DIR}/tidewave/bindings/<worktree-slug>.json
 *   { worktree, cwd, socket, session, window, pane, appUrl, targetPrefix, migrationUrl?, port, boundAt }
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
	cwd?: string;
	socket?: string;
	session?: string;
	pane?: string;
	appUrl?: string;
	port?: number;
};

type JsonValue = null | boolean | number | string | JsonValue[] | { [key: string]: JsonValue };

// These predicates are only for untouched JSON.parse results. JSON cannot
// contain boxed primitives, proxies, or Symbol.toStringTag overrides.
const isJsonString = (value: JsonValue | undefined): value is string =>
	Object.prototype.toString.call(value) === "[object String]";

const isJsonObject = (value: JsonValue | undefined): value is { [key: string]: JsonValue } =>
	Object.prototype.toString.call(value) === "[object Object]";

const isJsonNumber = (value: JsonValue | undefined): value is number =>
	Number.isFinite(value);

const parseBinding = (text: string): Binding | null => {
	const value: JsonValue = JSON.parse(text);

	if (!isJsonObject(value)) return null;

	const { cwd, socket, session, pane, appUrl, port } = value;

	if (
		(cwd !== undefined && !isJsonString(cwd)) ||
		(socket !== undefined && !isJsonString(socket)) ||
		(session !== undefined && !isJsonString(session)) ||
		(pane !== undefined && !isJsonString(pane)) ||
		(appUrl !== undefined && !isJsonString(appUrl))
	) return null;

	return {
		cwd, socket, session, pane, appUrl,
		port: isJsonNumber(port) && Number.isInteger(port) && port > 0 && port <= 65535
			? port : undefined,
	};
};

type ControlRequest = {
	type: "control";
	protocol: "pi.control.v1";
	id: string;
	operation: "message.send";
	params: { text: string; mode: "follow_up"; from: "tidewave" };
};

type ControlResponse = { ok: boolean; error?: string };

const parseControlResponse = (text: string): ControlResponse | null => {
	const value: JsonValue = JSON.parse(text);

	if (!isJsonObject(value) || (value.ok !== true && value.ok !== false)) return null;

	return { ok: value.ok, error: isJsonString(value.error) ? value.error : undefined };
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
				const text = fs.readFileSync(path.join(BINDING_DIR, f), "utf8");
				const b: JsonValue = JSON.parse(text);

				if (isJsonObject(b) && isJsonString(b.cwd) && b.cwd && path.resolve(b.cwd) === path.resolve(cwd)) {
					return parseBinding(text);
				}
			} catch {}
		}

		const slugFile = path.join(BINDING_DIR, `${worktreeSlug(cwd)}.json`);

		if (fs.existsSync(slugFile)) {
			return parseBinding(fs.readFileSync(slugFile, "utf8"));
		}
	} catch {}

	return null;
};

/** Send one line-delimited JSON control request to a bridge socket. */
const sendControl = (
	socketPath: string,
	payload: ControlRequest,
): Promise<ControlResponse | null> =>
	new Promise((resolve) => {
		const socket = net.createConnection(socketPath);
		let buffer = "";
		let settled = false;

		const finish = (result: ControlResponse | null): void => {
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
				finish(parseControlResponse(line));
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
	} satisfies ControlRequest;

	const res = await sendControl(binding.socket, request);

	if (res && res.ok === true) {
		const target = `${binding.session ?? "pi"}${binding.pane ? ` ${binding.pane}` : ""}`;

		return { ok: true, detail: `Forwarded to ${target}. Reply lands in tmux.` };
	}

	return {
		ok: false,
		detail:
			res?.error ||
			"Bound pi did not accept the message (control.v1 message.send failed).",
	};
};

// =============================================================================
// CLI role: ACP agent (stdio ndjson JSON-RPC 2.0)
// =============================================================================

const PROTOCOL_VERSION = 1;

type RpcId = string | number;

type AcpParams = { cwd?: string; sessionId?: string; prompt: string };

type AcpRequest = { id?: RpcId | null; method: string; params: AcpParams };

class AcpError extends Error {
	readonly code: number;

	constructor(code: number, message: string) {
		super(message);
		this.code = code;
	}
}

/** Decode only text-bearing ACP blocks; unsupported or malformed blocks are ignored. */
const textFromBlocks = (blocks: JsonValue | undefined): string => {
	if (!Array.isArray(blocks)) return "";

	return blocks.map((block) => {
		if (!isJsonObject(block)) return "";

		if (block.type === "text" && isJsonString(block.text)) return block.text;

		if (block.type === "resource_link" && isJsonString(block.uri)) return block.uri;

		if (block.type !== "resource" || !isJsonObject(block.resource)) return "";

		const resource = block.resource;

		if (isJsonString(resource.text)) return resource.text;

		if (isJsonString(resource.uri)) return resource.uri;

		return "";
	}).filter(Boolean).join("\n").trim();
};

const parseAcpRequest = (text: string): AcpRequest | null => {
	const value: JsonValue = JSON.parse(text);

	if (!isJsonObject(value) || !isJsonString(value.method)) return null;

	const { id, method } = value;

	if (id !== undefined && id !== null && !isJsonString(id) && !isJsonNumber(id)) return null;

	const params = isJsonObject(value.params) ? value.params : {};

	return {
		id, method,
		params: {
			cwd: isJsonString(params.cwd) ? params.cwd : undefined,
			sessionId: isJsonString(params.sessionId) ? params.sessionId : undefined,
			prompt: textFromBlocks(params.prompt),
		},
	};
};

const log = (msg: string): void => {
	try {
		process.stderr.write(`[pidewave-acp] ${msg}\n`);
	} catch {}
};

const runAcpShim = (): void => {
	const sessions = new Map<string, { cwd: string }>();
	let counter = 0;

	type AcpResult = Awaited<ReturnType<(typeof handlers)[keyof typeof handlers]>>;

	type AcpMessage =
		| { id: RpcId; result: AcpResult }
		| { id: RpcId; error: { code: number; message: string } }
		| { method: "session/update"; params: {
			sessionId: string;
			update: { sessionUpdate: "agent_message_chunk"; content: { type: "text"; text: string } };
		} };

	const send = (msg: AcpMessage): void => {
		try {
			process.stdout.write(`${JSON.stringify({ jsonrpc: "2.0", ...msg })}\n`);
		} catch {}
	};

	const reply = (id: RpcId, result: AcpResult): void => send({ id, result });

	const replyError = (id: RpcId, code: number, message: string): void =>
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

	const handlers = {
		initialize: async (_params: AcpParams) => ({
			protocolVersion: PROTOCOL_VERSION,
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

		authenticate: async (_params: AcpParams) => ({}),

		"session/new": async (params: AcpParams) => {
			const cwd = params.cwd ?? process.cwd();
			counter += 1;
			const sessionId = `pidewave-${Date.now().toString(36)}-${counter}`;
			sessions.set(sessionId, { cwd });
			log(`session/new ${sessionId} cwd=${cwd}`);

			return { sessionId };
		},

		"session/prompt": async (params: AcpParams) => {
			const sessionId = params.sessionId;
			const session = sessionId ? sessions.get(sessionId) : undefined;

			if (!session || !sessionId) {
				throw new AcpError(-32602, `unknown sessionId: ${sessionId}`);
			}

			const text = params.prompt;

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
		let msg: AcpRequest | null;

		try {
			msg = parseAcpRequest(trimmed);
		} catch {
			log(`ignoring non-JSON line: ${trimmed.slice(0, 120)}`);

			return;
		}

		if (!msg) return; // malformed input or a response; we never ask.

		const { id, method, params } = msg;
		const isNotification = id === undefined || id === null;

		if (method === "session/cancel" || method.startsWith("$/")) return; // nothing in flight to cancel.
		// Own entries only: arbitrary RPC methods must not call Object.prototype.
		const handler = Object.entries(handlers).find(([name]) => name === method)?.[1];

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

				if (err instanceof AcpError) {
					replyError(id, err.code, err.message);
				} else {
					replyError(id, -32603, err instanceof Error ? err.message : String(err));
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
			process.argv[1] !== undefined &&
			path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)
		);
	} catch {
		return false;
	}
})();

if (isMain) runAcpShim();

// =============================================================================
// Extension role: runtime Tidewave endpoint + binding footer status
// =============================================================================

const ENDPOINT_EVENT = "pidewave:endpoint:v1";

const MCP_STATUS_EVENT = "pi-mcp-adapter/status/v1";

const MCP_REGISTER_EVENT = "pi-mcp-adapter:runtime-register:v1";

const MCP_SNAPSHOT_EVENT = "pi-mcp-adapter:runtime-snapshot:v1";

// /pidewave hands off across /reload: the old runtime opens the handoff, the
// reloaded runtime attaches its own reconnect callback.
type ReloadHandoff = { reconnect?: () => Promise<void> };

// SAFETY: Only this file reads or writes this dotfiles-owned global slot.
const shared = globalThis as typeof globalThis & { __dotfilesPidewaveHandoff?: ReloadHandoff };

type RuntimeRegistration = { dispose(): Promise<void> };

type RegistrationRequest = {
	version: 1;
	name: "tidewave";
	definition: { httpTransport: "streamable-http"; url: string; lifecycle: "keep-alive" };
	result?: { ok: true; registration: RuntimeRegistration } | { ok: false };
};

type SnapshotRequest = {
	version: 1;
	name: "tidewave";
	result?: { ok: true; snapshot: {
		name: string;
		definition: { url?: string };
		runtime: boolean;
		persisted: boolean;
	} } | { ok: false };
};

const readEndpoint = (ctx: ExtensionContext): URL | undefined => {
	if (ctx.isProjectTrusted?.() !== true) return;
	const file = path.join(ctx.cwd, ".pi", "mcp.json");

	if (!fs.existsSync(file)) return;
	const config: JsonValue = JSON.parse(fs.readFileSync(file, "utf8"));

	if (!isJsonObject(config) || config.pidewave === undefined) return;

	if (!isJsonObject(config.pidewave) || !isJsonString(config.pidewave.url)) {
		throw new Error("Invalid Pidewave configuration");
	}

	const env = (_match: string, name: string): string => {
		const value = process.env[name];

		if (!value) throw new Error("Missing Pidewave environment variable");

		return value;
	};

	const literal = config.pidewave.url
		.replace(/\$\{(\w+)\}/g, env)
		.replace(/\$env:(\w+)/g, env)
		.replace(/\{env:(\w+)\}/g, env);

	if (!/^https?:\/\/(?:localhost|127\.0\.0\.1)(?::[1-9]\d{0,4})?\/tidewave\/mcp$/.test(literal)) {
		throw new Error("Unsafe Pidewave endpoint");
	}

	const url = new URL(literal);
	const port = Number(url.port || (url.protocol === "https:" ? 443 : 80));

	if (url.href !== literal || port < 1 || port > 65535 || port === 9832) {
		throw new Error("Unsafe Pidewave endpoint");
	}

	return url;
};

export default function (pi: ExtensionAPI): void {
	if (isMain) return; // defensive: never register hooks in CLI mode.

	let poll: ReturnType<typeof setInterval> | undefined;
	let lastStatus: string | undefined;
	let started = false;
	let stopped = false;
	let registration: RuntimeRegistration | undefined;
	let registeredUrl: URL | undefined;
	let unsubscribeStatus: (() => void) | undefined;
	// Latest adapter status for tidewave and whether our runtime registration owns it.
	let tidewaveStatus: string | undefined;
	let owned = false;
	let onTidewaveStatus: (() => void) | undefined;

	const revokeEndpoint = (): void => pi.events.emit(ENDPOINT_EVENT, { version: 1 });

	const publishEndpoint = (): void => {
		owned = false;

		if (stopped || !registration || !registeredUrl) return;
		const request: SnapshotRequest = { version: 1, name: "tidewave" };

		try {
			pi.events.emit(MCP_SNAPSHOT_EVENT, request);
			const snapshot = request.result?.ok === true ? request.result.snapshot : undefined;

			// Acceptance can precede startup; a configured server may still shadow us.
			if (snapshot?.name === "tidewave" && snapshot.runtime === true && snapshot.persisted === false &&
				snapshot.definition?.url === registeredUrl.href) {
				owned = true;
				pi.events.emit(ENDPOINT_EVENT, {
					version: 1,
					endpoint: { origin: registeredUrl.origin, pathname: registeredUrl.pathname },
				});

				return;
			}
		} catch {}

		revokeEndpoint();
	};

	const startEndpoint = (ctx: ExtensionContext): void => {
		if (started || stopped) return;
		started = true;
		revokeEndpoint();

		try {
			const url = readEndpoint(ctx);

			if (!url) return;

			const request: RegistrationRequest = {
				version: 1, name: "tidewave",
				definition: { httpTransport: "streamable-http", url: url.href, lifecycle: "keep-alive" },
			};

			pi.events.emit(MCP_REGISTER_EVENT, request);

			if (request.result?.ok !== true) throw new Error("Registration unavailable");
			registration = request.result.registration;
			registeredUrl = url;
			unsubscribeStatus = pi.events.on(MCP_STATUS_EVENT, (data: JsonValue) => {
				const servers = isJsonObject(data) && Array.isArray(data.servers)
					? data.servers.filter((server) => isJsonObject(server) && server.name === "tidewave")
					: [];

				const server = servers.length === 1 && isJsonObject(servers[0]) ? servers[0] : undefined;
				tidewaveStatus = server?.disabled === true ? "disabled" : isJsonString(server?.status) ? server.status : undefined;
				publishEndpoint();
				onTidewaveStatus?.();
			});
			publishEndpoint();
		} catch {
			revokeEndpoint();

			if (ctx.hasUI) ctx.ui.notify("Pidewave endpoint unavailable; check project configuration and MCP registration.", "warning");
		}
	};

	const updateBindingStatus = (ctx: ExtensionContext): void => {
		if (!ctx.hasUI) return;

		let status: string | undefined;
		const connected = owned && tidewaveStatus === "connected";

		try {
			const b = readBindingForCwd(ctx.cwd);

			if (b?.socket) {
				const appUrl = b.appUrl ?? (b.port ? `http://localhost:${b.port}` : undefined);

				if (appUrl) {
					status = JSON.stringify({
						url: appUrl,
						boundHere: Boolean(process.env.PI_SOCKET && b.socket === process.env.PI_SOCKET),
						connected,
					});
				}
			}
		} catch {}

		// A live Tidewave MCP connection is worth showing even without a browser binding.
		if (!status && connected && registeredUrl) {
			status = JSON.stringify({ url: registeredUrl.origin, boundHere: false, connected });
		}

		if (status !== lastStatus) {
			ctx.ui.setStatus("pidewave", status);
			lastStatus = status;
		}
	};

	// Runs in the reloaded runtime, after /reload has fully finished.
	const reconnectTidewave = async (ctx: ExtensionContext): Promise<void> => {
		if (stopped) return;

		if (!registration) {
			ctx.ui.notify("Pidewave: reloaded, but no Tidewave endpoint is registered for this project.", "warning");

			return;
		}

		// Without the adapter's command the text would reach the model as chat.
		if (!pi.getCommands().some((command) => command.name === "mcp")) {
			ctx.ui.notify("Pidewave: reloaded, but the /mcp command is unavailable.", "error");

			return;
		}

		// The adapter publishes status before its reconnect command returns;
		// wait briefly only if no tidewave status arrived meanwhile.
		tidewaveStatus = undefined;
		await pi.sendUserMessage("/mcp reconnect tidewave", { expandPromptTemplates: true });

		if (tidewaveStatus === undefined) {
			await new Promise<void>((resolve) => {
				const timer = setTimeout(done, 3000);

				function done(): void {
					clearTimeout(timer);
					onTidewaveStatus = undefined;
					resolve();
				}

				onTidewaveStatus = done;
			});
		}

		if (stopped) return;
		const origin = registeredUrl?.origin;

		if (owned && tidewaveStatus === "connected") {
			ctx.ui.notify(`Pidewave: Tidewave connected at ${origin}.`, "info");

			return;
		}

		const reason = !owned
			? "the runtime registration is not active; a configured tidewave server may shadow it"
			: `adapter status: ${tidewaveStatus ?? "no status reported"}; check that Phoenix is running there`;

		ctx.ui.notify(`Pidewave: Tidewave did not connect at ${origin} (${reason}).`, "error");
	};

	pi.registerCommand("pidewave", {
		description: "Reload Pi, then reconnect the project's Tidewave MCP server",
		handler: async (_args, ctx) => {
			const handoff: ReloadHandoff = {};
			shared.__dotfilesPidewaveHandoff = handoff;

			try {
				await ctx.reload();
			} finally {
				delete shared.__dotfilesPidewaveHandoff;
			}

			// Unset when reload refused (streaming or compacting); it already said why.
			await handoff.reconnect?.();
		},
	});

	pi.on("session_start", (e, ctx) => {
		clearInterval(poll);
		poll = undefined;
		lastStatus = undefined;
		startEndpoint(ctx);

		const handoff = shared.__dotfilesPidewaveHandoff;

		if (e.reason === "reload" && handoff) handoff.reconnect = () => reconnectTidewave(ctx);

		if (!ctx.hasUI) return;

		ctx.ui.setWidget("pidewave", undefined);
		ctx.ui.setStatus("pidewave", undefined);
		updateBindingStatus(ctx);
		// Hammerspoon can rebind while Pi is idle, without an agent event.
		poll = setInterval(() => updateBindingStatus(ctx), 1000);
		poll.unref();
	});
	pi.on("before_agent_start", (_e, ctx) => updateBindingStatus(ctx));
	pi.on("session_shutdown", async (_e, ctx) => {
		stopped = true;
		revokeEndpoint();
		unsubscribeStatus?.();
		unsubscribeStatus = undefined;
		const current = registration;
		registration = undefined;
		registeredUrl = undefined;
		clearInterval(poll);
		poll = undefined;
		lastStatus = undefined;

		if (ctx.hasUI) ctx.ui.setStatus("pidewave", undefined);

		try {
			await current?.dispose();
		} catch {} // The adapter may already have shut down.
	});
}
