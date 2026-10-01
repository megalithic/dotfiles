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
 *    Registers the trusted worktree's Tidewave MCP endpoint with Pi's native
 *    MCP support (`pi.registerMcpServer`) and pings it with Pi's own MCP client
 *    so the footer and the Cmd+Shift+C gate only see a live endpoint. Also
 *    publishes the bound app URL and local ownership for the custom footer. The
 *    CLI entrypoint is guarded by an argv[1]-is-this-file check, so loading as
 *    an extension is side-effect free, and Pi itself is only imported lazily.
 *
 * Handshake binding (written by Hammerspoon on Cmd+Shift+C):
 *   ${PI_STATE_DIR}/tidewave/bindings/<worktree-slug>.json
 *   { worktree, cwd, socket, session, window, pane, appUrl, targetPrefix, migrationUrl?, port, boundAt }
 * Matched by exact cwd first, then by worktree-slug filename.
 */

import net from "node:net";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { createInterface } from "node:readline";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

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
// Extension role: native Tidewave MCP registration + liveness + binding footer status
// =============================================================================

const ENDPOINT_EVENT = "pidewave:endpoint:v1";

const SERVER_NAME = "tidewave";

const PING_INTERVAL_MS = 10_000;

const PING_TIMEOUT_MS = 3_000;

/** Liveness probe: Pi's own MCP client, connected to the registered URL. */
type Probe = { ping(options?: { timeoutMs?: number }): Promise<void>; close(): Promise<void> };

type Connect = (url: URL) => Promise<Probe>;

// `@earendil-works/pi-mcp` is ESM-only and not jiti-aliased for extensions, so
// resolve its manifest from the running Pi install (node >= 22.14). Loaded
// lazily so the ACP CLI role never imports Pi.
const connectTidewave: Connect = async (url) => {
	const [{ getPackageDir }, { findPackageJSON }] = await Promise.all([
		import("@earendil-works/pi-coding-agent"),
		import("node:module"),
	]);

	const manifest = findPackageJSON("@earendil-works/pi-mcp", pathToFileURL(path.join(getPackageDir(), "package.json")).href);

	if (!manifest) throw new Error("@earendil-works/pi-mcp is not installed next to Pi");
	const pkg: JsonValue = JSON.parse(fs.readFileSync(manifest, "utf8"));
	const main = isJsonObject(pkg) && isJsonString(pkg.main) ? pkg.main : "dist/index.js";
	const { McpClient, StreamableHttpTransport } = await import(pathToFileURL(path.join(path.dirname(manifest), main)).href);
	const client = new McpClient({ name: "pidewave", version: "1.0.0", requestTimeoutMs: PING_TIMEOUT_MS });

	await client.connect(new StreamableHttpTransport({ url, openGetStream: false }));

	return client;
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

	// A configured server of the same name takes precedence over our registration.
	if (isJsonObject(config.mcpServers) && config.mcpServers[SERVER_NAME] !== undefined) {
		throw new Error("Configured tidewave server shadows Pidewave");
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

// Only acp's own messages reach the UI; JSON, URL, and Pi error text could echo file contents.
const OWN_FAILURES = [
	"Invalid Pidewave configuration",
	"Missing Pidewave environment variable",
	"Unsafe Pidewave endpoint",
	"Configured tidewave server shadows Pidewave",
	"MCP registration refused",
];

const endpointFailureReason = (error: Error): string =>
	OWN_FAILURES.includes(error.message) ? error.message : "unreadable .pi/mcp.json or endpoint URL";

const asError = (thrown: Error | string | undefined): Error => thrown instanceof Error ? thrown : new Error();

type PidewaveRecord = { event: string; at: string; [key: string]: string | boolean | undefined };

// Durable trace of endpoint state, kept out of model context (docs/extensions.md:
// "Persist non-context session data → pi.appendEntry()"). Grep the session JSONL
// for "pidewave" or ask vcc_recall. appendEntry is unavailable before a session
// exists, so a failure to record never breaks the endpoint itself.
const record = (pi: ExtensionAPI, event: string, data: Omit<PidewaveRecord, "event" | "at"> = {}): void => {
	try {
		pi.appendEntry<PidewaveRecord>("pidewave", { event, at: new Date().toISOString(), ...data });
	} catch {}
};

export default function (pi: ExtensionAPI, connect: Connect = connectTidewave): void {
	if (isMain) return; // defensive: never register hooks in CLI mode.

	let ctxRef: ExtensionContext | undefined;
	let poll: ReturnType<typeof setInterval> | undefined;
	let monitor: ReturnType<typeof setInterval> | undefined;
	let lastStatus: string | undefined;
	let registeredUrl: URL | undefined;
	let probe: Probe | undefined;
	let checking: Promise<void> | undefined;
	let live = false;

	const publish = (): void => {
		pi.events.emit(ENDPOINT_EVENT, live && registeredUrl
			? { version: 1, endpoint: { origin: registeredUrl.origin, pathname: registeredUrl.pathname } }
			: { version: 1 });
	};

	const setLive = (next: boolean): void => {
		if (next === live) return;
		live = next;
		record(pi, "status", { status: next ? "connected" : "unreachable", url: registeredUrl?.origin });
		publish();

		if (ctxRef) updateBindingStatus(ctxRef);
	};

	// One MCP session per registration; a failed ping drops it and the next tick reconnects.
	const run = async (): Promise<void> => {
		const url = registeredUrl;

		if (!url) return;

		try {
			const current = probe ?? await connect(url);

			// Stopped or re-registered while connecting.
			if (registeredUrl !== url) {
				await current.close().catch(() => {});

				return;
			}

			probe = current;
			await current.ping({ timeoutMs: PING_TIMEOUT_MS });

			if (registeredUrl === url) setLive(true);
		} catch {
			const dead = probe;
			probe = undefined;

			if (registeredUrl === url) setLive(false);
			await dead?.close().catch(() => {});
		}
	};

	const check = (): Promise<void> => {
		checking ??= run().finally(() => { checking = undefined; });

		return checking;
	};

	const startEndpoint = (ctx: ExtensionContext): void => {
		if (registeredUrl) return;
		publish(); // Revoked until the first successful ping.

		try {
			const url = readEndpoint(ctx);

			if (!url) return;

			try {
				pi.registerMcpServer(SERVER_NAME, { url: url.href, exposure: "direct" });
			} catch {
				throw new Error("MCP registration refused");
			}

			registeredUrl = url;
			record(pi, "registered", { url: url.origin });
			monitor = setInterval(() => void check(), PING_INTERVAL_MS);
			monitor.unref();
			void check();
		} catch (error) {
			const reason = endpointFailureReason(asError(error));
			record(pi, "unavailable", { reason, trusted: ctx.isProjectTrusted?.() === true });

			if (ctx.hasUI) ctx.ui.notify(`Pidewave endpoint unavailable: ${reason}.`, "warning");
		}
	};

	const stopEndpoint = async (): Promise<void> => {
		clearInterval(monitor);
		monitor = undefined;
		const url = registeredUrl;
		registeredUrl = undefined;
		const dead = probe;
		probe = undefined;
		setLive(false);

		if (url) {
			try {
				pi.unregisterMcpServer(SERVER_NAME);
			} catch {} // The runtime may already be shutting down.
		}

		await dead?.close().catch(() => {});
	};

	const updateBindingStatus = (ctx: ExtensionContext): void => {
		if (!ctx.hasUI) return;

		let status: string | undefined;

		try {
			const b = readBindingForCwd(ctx.cwd);

			if (b?.socket) {
				const appUrl = b.appUrl ?? (b.port ? `http://localhost:${b.port}` : undefined);

				if (appUrl) {
					status = JSON.stringify({
						url: appUrl,
						boundHere: Boolean(process.env.PI_SOCKET && b.socket === process.env.PI_SOCKET),
						connected: live,
					});
				}
			}
		} catch {}

		// A live Tidewave MCP connection is worth showing even without a browser binding.
		if (!status && live && registeredUrl) {
			status = JSON.stringify({ url: registeredUrl.origin, boundHere: false, connected: live });
		}

		if (status !== lastStatus) {
			ctx.ui.setStatus("pidewave", status);
			lastStatus = status;
		}
	};

	// Pi resolves project trust once at startup; a reload keeps the old state.
	// Saving the decision here still needs a restart before readEndpoint sees it.
	const ensureTrusted = async (ctx: ExtensionContext): Promise<boolean> => {
		if (ctx.isProjectTrusted?.() === true) return true;

		const cwd = path.resolve(ctx.cwd);
		const parent = path.dirname(cwd);
		const options = ["Trust this folder", `Trust parent folder (${parent})`, "Cancel"];
		const selected = await ctx.ui.select(`Pidewave needs project trust to read .pi/mcp.json.\n${cwd}`, options);
		const target = selected === options[0] ? cwd : selected === options[1] ? parent : undefined;

		if (!target) {
			record(pi, "trust-declined", { cwd });
			ctx.ui.notify("Pidewave: project is not trusted, so no Tidewave endpoint can be registered.", "warning");

			return false;
		}

		const { getAgentDir, ProjectTrustStore } = await import("@earendil-works/pi-coding-agent");
		new ProjectTrustStore(getAgentDir()).set(target, true);
		record(pi, "trust-saved", { path: target });
		ctx.ui.notify(`Pidewave: trusted ${target}. Restart Pi, then run /pidewave again.`, "info");

		return false;
	};

	pi.registerCommand("pidewave", {
		description: "Check project trust and config, then re-register and ping the project's Tidewave MCP server",
		handler: async (_args, ctx) => {
			if (!(await ensureTrusted(ctx))) return;

			let url: URL | undefined;

			try {
				url = readEndpoint(ctx);
			} catch (error) {
				ctx.ui.notify(`Pidewave: ${endpointFailureReason(asError(error))}.`, "error");

				return;
			}

			if (!url) {
				ctx.ui.notify("Pidewave: no pidewave.url in .pi/mcp.json; run `mise run bootstrap` to generate it.", "warning");

				return;
			}

			// Re-registering forces Pi's MCP connection to reconnect, not only our probe.
			await stopEndpoint();
			startEndpoint(ctx);

			if (!registeredUrl) return; // startEndpoint already said why.
			await check();
			const origin = registeredUrl.origin;

			if (live) {
				record(pi, "reconnected", { url: origin });
				ctx.ui.notify(`Pidewave: Tidewave connected at ${origin}.`, "info");

				return;
			}

			record(pi, "reconnect-failed", { url: origin });
			ctx.ui.notify(`Pidewave: Tidewave did not answer at ${origin}; start Phoenix there with \`mise run start:server\`.`, "error");
		},
	});

	pi.on("session_start", (_e, ctx) => {
		ctxRef = ctx;
		clearInterval(poll);
		poll = undefined;
		lastStatus = undefined;
		startEndpoint(ctx);

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
		ctxRef = undefined;
		clearInterval(poll);
		poll = undefined;
		lastStatus = undefined;

		if (ctx.hasUI) ctx.ui.setStatus("pidewave", undefined);
		await stopEndpoint();
	});
}
