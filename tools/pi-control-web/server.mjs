#!/usr/bin/env node

import { createHmac, randomUUID, timingSafeEqual } from "node:crypto";
import { createReadStream, readdirSync, readFileSync, statSync } from "node:fs";
import { createServer } from "node:http";
import net from "node:net";
import { homedir } from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const HOST = "127.0.0.1";
const DEFAULT_PORT = 8788;
const MAX_JSON_BODY = 20 * 1024;
const MAX_MESSAGE_LENGTH = 8_000;
const MAX_SOCKET_RESPONSE = 1024 * 1024;
const CONTROL_TIMEOUT_MS = 1_500;
const COOKIE_NAME = "pi_control_web_session";
const COOKIE_MAX_AGE = 30 * 24 * 60 * 60;
const HERE = path.dirname(fileURLToPath(import.meta.url));
const DEFAULT_STATIC_DIR = path.join(HERE, "web");
const DEFAULT_STATE_DIR = path.join(
	process.env.XDG_STATE_HOME || path.join(homedir(), ".local", "state"),
	"pi",
);
const DEFAULT_TOKEN_FILE = path.join(
	process.env.XDG_CONFIG_HOME || path.join(homedir(), ".config"),
	"pi-control-web",
	"token",
);

const MIME_TYPES = new Map([
	[".css", "text/css; charset=utf-8"],
	[".html", "text/html; charset=utf-8"],
	[".js", "text/javascript; charset=utf-8"],
	[".json", "application/json; charset=utf-8"],
	[".svg", "image/svg+xml"],
	[".webmanifest", "application/manifest+json; charset=utf-8"],
]);

const securityHeaders = {
	"Content-Security-Policy":
		"default-src 'self'; connect-src 'self'; img-src 'self'; manifest-src 'self'; script-src 'self'; style-src 'self'; worker-src 'self'; base-uri 'none'; form-action 'self'; frame-ancestors 'none'",
	"Referrer-Policy": "no-referrer",
	"X-Content-Type-Options": "nosniff",
	"X-Frame-Options": "DENY",
};

const constantTimeEqual = (left, right) => {
	const leftBuffer = Buffer.from(left || "", "utf8");
	const rightBuffer = Buffer.from(right || "", "utf8");
	return (
		leftBuffer.length === rightBuffer.length &&
		timingSafeEqual(leftBuffer, rightBuffer)
	);
};

const sessionCookieValue = (token) =>
	createHmac("sha256", token)
		.update("pi-control-web-session-v1")
		.digest("base64url");

const opaqueSessionId = (token, socket) =>
	createHmac("sha256", token).update(socket).digest("base64url").slice(0, 24);

const parseCookies = (header = "") =>
	Object.fromEntries(
		header
			.split(";")
			.map((part) => part.trim())
			.filter(Boolean)
			.map((part) => {
				const separator = part.indexOf("=");
				return separator === -1
					? [part, ""]
					: [
							part.slice(0, separator),
							decodeURIComponent(part.slice(separator + 1)),
						];
			}),
	);

const requestIsAuthorized = (request, token) => {
	const authorization = request.headers.authorization || "";
	if (authorization.startsWith("Bearer ")) {
		return constantTimeEqual(authorization.slice(7), token);
	}
	const cookies = parseCookies(request.headers.cookie);
	return constantTimeEqual(cookies[COOKIE_NAME], sessionCookieValue(token));
};

const validMutationOrigin = (request) => {
	const origin = request.headers.origin;
	if (!origin)
		return (request.headers.authorization || "").startsWith("Bearer ");
	try {
		return new URL(origin).host === request.headers.host;
	} catch {
		return false;
	}
};

const sendJson = (response, status, value, headers = {}) => {
	response.writeHead(status, {
		...securityHeaders,
		"Cache-Control": "no-store",
		"Content-Type": "application/json; charset=utf-8",
		...headers,
	});
	response.end(JSON.stringify(value));
};

const readJson = async (request, maximum = MAX_JSON_BODY) => {
	const chunks = [];
	let length = 0;
	for await (const chunk of request) {
		length += chunk.length;
		if (length > maximum) throw new Error("request body too large");
		chunks.push(chunk);
	}
	const raw = Buffer.concat(chunks).toString("utf8");
	if (!raw) return {};
	try {
		return JSON.parse(raw);
	} catch {
		throw new Error("invalid JSON");
	}
};

const loadToken = (tokenFile = DEFAULT_TOKEN_FILE) => {
	const stats = statSync(tokenFile);
	if (!stats.isFile()) throw new Error(`token is not a file: ${tokenFile}`);
	if ((stats.mode & 0o077) !== 0) {
		throw new Error(`token must have mode 0600: ${tokenFile}`);
	}
	const token = readFileSync(tokenFile, "utf8").trim();
	if (token.length < 32) throw new Error(`token is too short: ${tokenFile}`);
	return token;
};

const discoverBridgeSockets = (stateDir) => {
	const manifestDir = path.join(stateDir, "manifests");
	const sockets = [];
	try {
		for (const name of readdirSync(manifestDir)) {
			if (!name.endsWith(".info")) continue;
			try {
				const manifest = JSON.parse(
					readFileSync(path.join(manifestDir, name), "utf8"),
				);
				if (
					manifest?.ephemeral === true ||
					typeof manifest?.socket !== "string" ||
					!statSync(manifest.socket).isSocket()
				)
					continue;
				sockets.push(manifest.socket);
			} catch {}
		}
	} catch {}
	return [...new Set(sockets)].sort();
};

const controlRequest = (
	socketPath,
	operation,
	params = {},
	timeoutMs = CONTROL_TIMEOUT_MS,
) =>
	new Promise((resolve, reject) => {
		const id = randomUUID();
		const request = {
			type: "control",
			protocol: "pi.control.v1",
			id,
			operation,
			params,
		};
		const socket = net.createConnection({ path: socketPath });
		let buffer = "";
		let settled = false;

		const finish = (error, value) => {
			if (settled) return;
			settled = true;
			clearTimeout(timer);
			socket.destroy();
			if (error) reject(error);
			else resolve(value);
		};

		const timer = setTimeout(
			() => finish(new Error(`bridge timeout: ${operation}`)),
			timeoutMs,
		);
		timer.unref?.();

		socket.once("connect", () => {
			socket.write(`${JSON.stringify(request)}\n`);
		});
		socket.on("data", (chunk) => {
			buffer += chunk.toString("utf8");
			if (buffer.length > MAX_SOCKET_RESPONSE) {
				finish(new Error("bridge response too large"));
				return;
			}
			const newline = buffer.indexOf("\n");
			if (newline === -1) return;
			try {
				const response = JSON.parse(buffer.slice(0, newline));
				if (
					response?.type !== "control_response" ||
					response?.protocol !== "pi.control.v1" ||
					response?.id !== id ||
					response?.operation !== operation ||
					typeof response?.ok !== "boolean"
				) {
					finish(new Error("invalid bridge response"));
					return;
				}
				if (!response.ok) {
					finish(new Error(response.error || `bridge rejected ${operation}`));
					return;
				}
				finish(null, response.data);
			} catch {
				finish(new Error("invalid bridge JSON"));
			}
		});
		socket.once("error", (error) => finish(error));
	});

const listInternalSessions = async (stateDir, token) => {
	const sockets = discoverBridgeSockets(stateDir);
	const allowedSockets = new Set(sockets);
	for (const socket of sockets) {
		try {
			const data = await controlRequest(socket, "sessions.list");
			if (!Array.isArray(data?.sessions)) continue;
			return data.sessions
				.filter(
					(session) =>
						session?.reachable === true &&
						typeof session.socket === "string" &&
						allowedSockets.has(session.socket),
				)
				.map((session) => ({
					...session,
					id: opaqueSessionId(token, session.socket),
				}));
		} catch {}
	}
	return [];
};

const publicSession = (session) => ({
	id: session.id,
	sessionName: session.sessionName || null,
	project:
		typeof session.cwd === "string"
			? path.basename(session.cwd) || "home"
			: null,
	tmux: [
		session.session,
		session.windowIndex ?? session.window,
		session.paneIndex,
	]
		.filter((part) => part !== undefined && part !== null && part !== "")
		.join(":"),
	state: session.state || "idle",
	statusUpdatedAt: session.statusUpdatedAt || session.heartbeatAt || null,
	heartbeatAt: session.heartbeatAt || null,
});

const resolveSession = async (stateDir, token, id) => {
	const sessions = await listInternalSessions(stateDir, token);
	return sessions.find((session) => constantTimeEqual(session.id, id)) || null;
};

const routeParts = (pathname) =>
	pathname
		.split("/")
		.filter(Boolean)
		.map((part) => decodeURIComponent(part));

const serveStatic = (request, response, staticDir, pathname) => {
	const relative = pathname === "/" ? "index.html" : pathname.slice(1);
	const target = path.resolve(staticDir, relative);
	const root = `${path.resolve(staticDir)}${path.sep}`;
	if (!target.startsWith(root)) {
		sendJson(response, 404, { error: "not found" });
		return;
	}

	try {
		const stats = statSync(target);
		if (!stats.isFile()) throw new Error("not a file");
		response.writeHead(200, {
			...securityHeaders,
			"Cache-Control": "no-cache",
			"Content-Length": stats.size,
			"Content-Type":
				MIME_TYPES.get(path.extname(target)) || "application/octet-stream",
		});
		if (request.method === "HEAD") response.end();
		else createReadStream(target).pipe(response);
	} catch {
		sendJson(response, 404, { error: "not found" });
	}
};

const openEventStream = (request, response, listSessions, onClose) => {
	response.writeHead(200, {
		...securityHeaders,
		"Cache-Control": "no-cache, no-transform",
		Connection: "keep-alive",
		"Content-Type": "text/event-stream; charset=utf-8",
		"X-Accel-Buffering": "no",
	});
	response.write("retry: 3000\n\n");

	let closed = false;
	let polling = false;
	let lastSnapshot = "";
	let eventId = 0;
	const poll = async () => {
		if (closed || polling) return;
		polling = true;
		try {
			const snapshot = JSON.stringify(await listSessions());
			if (snapshot !== lastSnapshot) {
				lastSnapshot = snapshot;
				eventId += 1;
				response.write(
					`id: ${eventId}\nevent: snapshot\ndata: ${snapshot}\n\n`,
				);
			}
		} catch {
			response.write("event: unavailable\ndata: {}\n\n");
		} finally {
			polling = false;
		}
	};

	void poll();
	const reconcile = setInterval(poll, 2_000);
	const heartbeat = setInterval(() => {
		if (!closed) response.write(": heartbeat\n\n");
	}, 15_000);
	reconcile.unref?.();
	heartbeat.unref?.();

	request.once("close", () => {
		closed = true;
		clearInterval(reconcile);
		clearInterval(heartbeat);
		onClose();
	});
};

export const createGateway = ({
	token,
	tokenFile = DEFAULT_TOKEN_FILE,
	stateDir = process.env.PI_STATE_DIR || DEFAULT_STATE_DIR,
	staticDir = DEFAULT_STATIC_DIR,
	port = Number(process.env.PI_CONTROL_WEB_PORT || DEFAULT_PORT),
	host = HOST,
} = {}) => {
	if (host !== HOST) throw new Error("pi-control-web must bind to 127.0.0.1");
	const secret = token || loadToken(tokenFile);
	const eventStreams = new Set();
	const listSessions = async () =>
		(await listInternalSessions(stateDir, secret)).map(publicSession);

	const server = createServer((request, response) => {
		const dispatch = async () => {
			const method = request.method || "GET";
			const url = new URL(
				request.url || "/",
				`http://${request.headers.host || HOST}`,
			);

			if (url.pathname === "/healthz" && method === "GET") {
				sendJson(response, 200, { ok: true });
				return;
			}

			if (url.pathname === "/api/login" && method === "POST") {
				if (!validMutationOrigin(request)) {
					sendJson(response, 403, { error: "invalid origin" });
					return;
				}
				try {
					const body = await readJson(request, 4_096);
					if (!constantTimeEqual(body?.token, secret)) {
						sendJson(response, 401, { error: "invalid token" });
						return;
					}
					sendJson(
						response,
						200,
						{ ok: true },
						{
							"Set-Cookie": `${COOKIE_NAME}=${encodeURIComponent(sessionCookieValue(secret))}; HttpOnly; Secure; SameSite=Strict; Path=/; Max-Age=${COOKIE_MAX_AGE}`,
						},
					);
				} catch (error) {
					sendJson(response, 400, { error: error.message });
				}
				return;
			}

			if (!url.pathname.startsWith("/api/")) {
				if (method !== "GET" && method !== "HEAD") {
					sendJson(response, 405, { error: "method not allowed" });
					return;
				}
				serveStatic(request, response, staticDir, url.pathname);
				return;
			}

			if (!requestIsAuthorized(request, secret)) {
				sendJson(response, 401, { error: "authentication required" });
				return;
			}

			if (url.pathname === "/api/logout" && method === "POST") {
				if (!validMutationOrigin(request)) {
					sendJson(response, 403, { error: "invalid origin" });
					return;
				}
				sendJson(
					response,
					200,
					{ ok: true },
					{
						"Set-Cookie": `${COOKIE_NAME}=; HttpOnly; Secure; SameSite=Strict; Path=/; Max-Age=0`,
					},
				);
				return;
			}

			if (url.pathname === "/api/sessions" && method === "GET") {
				sendJson(response, 200, { sessions: await listSessions() });
				return;
			}

			if (url.pathname === "/api/events" && method === "GET") {
				if (eventStreams.size >= 8) {
					sendJson(response, 429, { error: "too many event streams" });
					return;
				}
				eventStreams.add(response);
				openEventStream(request, response, listSessions, () => {
					eventStreams.delete(response);
				});
				return;
			}

			const parts = routeParts(url.pathname);
			if (parts[0] === "api" && parts[1] === "sessions" && parts[2]) {
				const session = await resolveSession(stateDir, secret, parts[2]);
				if (!session) {
					sendJson(response, 404, { error: "session not found" });
					return;
				}

				if (parts[3] === "last" && method === "GET") {
					try {
						const data = await controlRequest(session.socket, "message.last");
						sendJson(response, 200, {
							session: publicSession(session),
							message: data?.message || null,
						});
					} catch {
						sendJson(response, 502, { error: "Pi session unavailable" });
					}
					return;
				}

				if (parts[3] === "messages" && method === "POST") {
					if (!validMutationOrigin(request)) {
						sendJson(response, 403, { error: "invalid origin" });
						return;
					}
					try {
						const body = await readJson(request);
						const text = typeof body?.text === "string" ? body.text.trim() : "";
						const mode = body?.mode;
						if (!text) throw new Error("message text is required");
						if (text.length > MAX_MESSAGE_LENGTH)
							throw new Error(
								`message exceeds ${MAX_MESSAGE_LENGTH} characters`,
							);
						if (mode !== "steer" && mode !== "follow_up")
							throw new Error("mode must be steer or follow_up");
						const data = await controlRequest(session.socket, "message.send", {
							text,
							mode,
							from: "pi-control-web",
						});
						sendJson(response, 202, data);
					} catch (error) {
						const status = /bridge|socket|connect|timeout/i.test(error.message)
							? 502
							: 400;
						sendJson(response, status, {
							error: status === 502 ? "Pi session unavailable" : error.message,
						});
					}
					return;
				}
			}

			sendJson(response, 404, { error: "not found" });
		};

		void dispatch().catch((error) => {
			if (!response.headersSent) {
				sendJson(response, 500, { error: "internal server error" });
			} else {
				response.destroy(error);
			}
		});
	});

	server.on("clientError", (_error, socket) => {
		socket.end("HTTP/1.1 400 Bad Request\r\nConnection: close\r\n\r\n");
	});

	return {
		server,
		listen: () =>
			new Promise((resolve, reject) => {
				server.once("error", reject);
				server.listen(port, host, () => {
					server.off("error", reject);
					resolve(server.address());
				});
			}),
		close: () =>
			new Promise((resolve, reject) => {
				for (const response of eventStreams) response.end();
				eventStreams.clear();
				server.close((error) => (error ? reject(error) : resolve()));
			}),
	};
};

const isMain =
	process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href;

if (isMain) {
	const gateway = createGateway();
	const address = await gateway.listen();
	console.log(
		`pi-control-web listening on http://${address.address}:${address.port}`,
	);
	const shutdown = async () => {
		await gateway.close();
		process.exit(0);
	};
	process.once("SIGINT", shutdown);
	process.once("SIGTERM", shutdown);
}
