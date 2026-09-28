// @ts-nocheck
/**
 * /tell extension - async Pi-to-Pi guidance messages.
 *
 * This replaces the shell-script tell skill for Pi instance targeting. It sends
 * line-delimited JSON to the existing Pi/pinvim socket for a selected running Pi
 * instance. New peers use pi.control.v1 and fall back to pi.tell.v1 only when an
 * older peer explicitly rejects the control envelope. The receiver injects the
 * message as a user prompt and can reply with /tell or tell_pi.
 */

import { execFile } from "node:child_process";
import crypto from "node:crypto";
import fsp from "node:fs/promises";
import { readFileSync } from "node:fs";
import net from "node:net";
import os from "node:os";
import path from "node:path";
import { stripVTControlCharacters } from "node:util";
import type {
	ExtensionAPI,
	ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { StringEnum } from "@earendil-works/pi-ai";
import { SelectList, truncateToWidth, wrapTextWithAnsi } from "@earendil-works/pi-tui";
import { Type, type Static } from "typebox";
import { Check } from "typebox/value";

const xdgStateHome =
	process.env.XDG_STATE_HOME ||
	(process.env.HOME ? path.join(process.env.HOME, ".local", "state") : "/tmp");

const PI_STATE_DIR = process.env.PI_STATE_DIR || path.join(xdgStateHome, "pi");

const SOCKET_DIR = path.join(PI_STATE_DIR, "sockets");

const MANIFEST_DIR = path.join(PI_STATE_DIR, "manifests");

const SOCKET_PREFIX = "pi";

// macOS sun_path limit is 104 bytes (incl. NUL). Must match bridge.ts scheme.
const MAX_SOCKET_PATH_BYTES = 103;

const CONNECT_TIMEOUT_MS = 800;

const PING_TIMEOUT_MS = 1000;

const PING_ATTEMPTS = 2;

const MAX_RESPONSE_BYTES = 1024 * 1024;

const SSH_TIMEOUT_MS = 5000;

const KNOWN_MACHINE_ALIASES = new Set(["megabookpro", "workbookpro"]);

const CONTROL_PROTOCOL = "pi.control.v1";

type DeliveryMode = "steer" | "follow_up";

type ControlOperation = "sessions.list" | "message.last" | "message.send";

type TmuxInfo = {
	session: string;
	window: string;
	windowIndex?: string;
	pane?: string;
	paneIndex?: string;
};

const RuntimeIdentitySchema = Type.Object({
	version: Type.String(),
	loadedAt: Type.String(),
	sourceHash: Type.Union([Type.String(), Type.Null()]),
});

const tellRuntime: Static<typeof RuntimeIdentitySchema> = {
	version: "tell.v2",
	loadedAt: new Date().toISOString(),
	sourceHash: crypto.createHash("sha256").update(readFileSync(new URL(import.meta.url))).digest("hex"),
};

const ManifestSchema = Type.Object({
	socket: Type.Optional(Type.String({ minLength: 1 })),
	cwd: Type.Optional(Type.String()),
	root: Type.Optional(Type.String()),
	pid: Type.Optional(Type.Integer({ minimum: 1 })),
	session: Type.Optional(Type.String()),
	sessionId: Type.Optional(Type.Union([Type.String(), Type.Null()])),
	sessionName: Type.Optional(Type.Union([Type.String(), Type.Null()])),
	window: Type.Optional(Type.String()),
	windowIndex: Type.Optional(Type.String()),
	windowName: Type.Optional(Type.String()),
	pane: Type.Optional(Type.String()),
	paneIndex: Type.Optional(Type.String()),
	paneTitle: Type.Optional(Type.String()),
	owner: Type.Optional(Type.String()),
	role: Type.Optional(Type.String()),
	linkMode: Type.Optional(Type.String()),
	ephemeral: Type.Optional(Type.Boolean()),
	startedAt: Type.Optional(Type.Union([Type.String(), Type.Number()])),
	heartbeatAt: Type.Optional(Type.Union([Type.Number(), Type.String()])),
	state: Type.Optional(Type.String()),
	statusUpdatedAt: Type.Optional(Type.String()),
	bridge: Type.Optional(RuntimeIdentitySchema),
	tell: Type.Optional(Type.Union([RuntimeIdentitySchema, Type.Null()])),
});

type PiManifest = Static<typeof ManifestSchema>;

const RemoteManifestSchema = Type.Intersect([ManifestSchema, Type.Object({
	socket: Type.String({ minLength: 1 }),
	reachable: Type.Boolean(),
	registration: Type.Optional(Type.Object({
		session: Type.Optional(Type.String()),
		window: Type.Optional(Type.String()),
		pane: Type.Optional(Type.String()),
		pid: Type.Optional(Type.Integer({ minimum: 1 })),
	})),
})]);

const MessageSchema = Type.Object({
	content: Type.String(),
	timestamp: Type.Optional(Type.Number()),
});

const WireResponseSchema = Type.Object({
	ok: Type.Boolean(),
	type: Type.Optional(Type.String()),
	protocol: Type.Optional(Type.String()),
	id: Type.Optional(Type.String()),
	operation: Type.Optional(Type.String()),
	error: Type.Optional(Type.String()),
	data: Type.Optional(Type.Object({
		message: Type.Optional(Type.Union([MessageSchema, Type.Null()])),
		sessions: Type.Optional(Type.Array(ManifestSchema)),
	})),
});

type WireResponse = Static<typeof WireResponseSchema>;

const parseWireResponse = (text: string): WireResponse => {
	const value: unknown = JSON.parse(text);

	if (!Check(WireResponseSchema, value)) throw new Error("Invalid Pi response");

	return value;
};

type Candidate = {
	socket: string;
	id: string;
	label: string;
	searchText: string;
	machine?: string;
	windowIndex?: string;
	windowName?: string;
	displayTitle?: string;
	paneTitle?: string;
	paneIndex?: string;
	state?: string;
	statusUpdatedAt?: string;
	session?: string;
	sessionId?: string | null;
	sessionName?: string | null;
	window?: string;
	pane?: string;
	cwd?: string;
	root?: string;
	pid?: number;
	current: boolean;
	reachable: boolean;
	manifest?: PiManifest;
};

type SendResult = {
	ok: boolean;
	candidates?: Candidate[];
	target?: Candidate;
	id?: string;
	response?: WireResponse;
	error?: string;
};

type RemoteSendResult = {
	ok: boolean;
	target?: string;
	socket?: string;
	response?: WireResponse;
	error?: string;
};

type TellRoute = {
	machine?: string;
	target?: string;
	message: string;
	mode?: DeliveryMode;
};

type OriginInfo = {
	display: string;
	replyTarget: string;
};

type TellPayloadOptions = {
	includeMachineReply: boolean;
	includeFromSocket: boolean;
	mode?: DeliveryMode;
};

type TellPayload = {
	type: "tell";
	protocol: "pi.tell.v1";
	id: string;
	text: string;
	from: string;
	fromSocket?: string | null;
	sessionId: string;
	sessionName?: string;
	timestamp: number;
	mode?: DeliveryMode;
};

type ControlSendParams = Omit<TellPayload, "type" | "protocol" | "id"> & {
	messageId: string;
	tellProtocol: "pi.tell.v1";
};

type ControlRequest = {
	type: "control";
	protocol: "pi.control.v1";
	id: string;
	operation: ControlOperation;
	params: Partial<ControlSendParams>;
};

type ControlResponse = {
	ok: boolean;
	type: "control_response";
	protocol: "pi.control.v1";
	id: string;
	operation: ControlOperation;
	data?: WireResponse["data"];
	error?: string;
};

type SelectionResult =
	| { ok: true; candidate: Candidate }
	| { ok: false; error: string; candidates: Candidate[] };

const fileExists = async (file: string): Promise<boolean> => {
	try {
		await fsp.access(file);

		return true;
	} catch {
		return false;
	}
};

const isSocket = async (file: string): Promise<boolean> => {
	try {
		const stat = await fsp.stat(file);

		return stat.isSocket();
	} catch {
		return false;
	}
};

const parseSocketName = (socket: string): Partial<Candidate> => {
	const base = path.basename(socket).replace(/\.sock$/, "");
	const prefix = `${SOCKET_PREFIX}-`;

	if (!base.startsWith(prefix)) return { id: base };

	const rest = base.slice(prefix.length);
	const eph = rest.match(/^(.+)-(.+)-eph-[^-]+-[^-]+$/);

	if (eph) {
		return { id: rest, session: eph[1], window: eph[2] };
	}

	const firstDash = rest.indexOf("-");

	if (firstDash === -1) return { id: rest, session: rest };

	return {
		id: rest,
		session: rest.slice(0, firstDash),
		window: rest.slice(firstDash + 1),
	};
};

const detectTmux = (): Promise<TmuxInfo | null> =>
	new Promise((resolve) => {
		if (!process.env.TMUX) {
			resolve(null);

			return;
		}

		// Target our own pane explicitly: without -t, display-message reports
		// the client's ACTIVE window, not the window this process runs in.
		execFile(
			"tmux",
			[
				"display-message",
				"-p",
				...(process.env.TMUX_PANE ? ["-t", process.env.TMUX_PANE] : []),
				"#{session_name}\t#{window_name}\t#{window_index}\t#{pane_id}\t#{pane_index}",
			],
			{ encoding: "utf-8", timeout: 2000 },
			(err, stdout) => {
				if (err) {
					resolve(null);

					return;
				}

				const [session, windowName, windowIndex, pane, paneIndex] = stdout
					.trim()
					.split("\t");

				const window =
					windowName && /^[a-zA-Z0-9_-]+$/.test(windowName)
						? windowName
						: windowIndex;

				resolve(
					session && window
						? { session, window, windowIndex, pane, paneIndex }
						: null,
				);
			},
		);
	});

const currentMachineName = (): string | undefined => {
	const raw = process.env.HOSTNAME || process.env.HOST || os.hostname();
	const name = raw.split(".")[0]?.trim();

	return name || undefined;
};

const looksLikeMachineTarget = (token: string | undefined): boolean => {
	if (!token) return false;
	const normalized = token.toLowerCase();

	return (
		KNOWN_MACHINE_ALIASES.has(normalized) ||
		normalized.includes("@") ||
		normalized.includes(".")
	);
};

const utf8Bytes = (value: string): number =>
	new TextEncoder().encode(value).length;

/**
 * Build the socket path for a tmux pane. Mirrors bridge.ts: when the full path
 * exceeds the sun_path limit, truncate the name and append a deterministic
 * 8-char sha256 suffix.
 */
const buildSocketPath = (
	session: string,
	window: string,
	paneId?: string,
): string => {
	const name = [session, window, paneId].filter(Boolean).join("-");
	const full = `${SOCKET_DIR}/${SOCKET_PREFIX}-${name}.sock`;

	if (utf8Bytes(full) <= MAX_SOCKET_PATH_BYTES) return full;
	const fixed = utf8Bytes(`${SOCKET_DIR}/${SOCKET_PREFIX}-.sock`) + 9; // "-" + 8 hex
	const budget = MAX_SOCKET_PATH_BYTES - fixed;

	if (budget < 0) throw new Error(`Pi socket directory exceeds the Unix socket path limit: ${SOCKET_DIR}`);

	let prefix = "";

	for (const character of name) {
		if (utf8Bytes(prefix + character) > budget) break;
		prefix += character;
	}

	const hash = crypto
		.createHash("sha256")
		.update(name)
		.digest("hex")
		.slice(0, 8);

	return `${SOCKET_DIR}/${SOCKET_PREFIX}-${prefix}-${hash}.sock`;
};

const currentSocketPath = async (): Promise<string | null> => {
	if (process.env.PI_SOCKET && (!process.env.PI_SOCKET_OWNER_PID || process.env.PI_SOCKET_OWNER_PID === String(process.pid))) return process.env.PI_SOCKET;
	const tmux = await detectTmux();

	if (tmux) {
		return buildSocketPath(tmux.session, tmux.window, tmux.pane);
	}

	return buildSocketPath("process", String(process.pid));
};

const readManifest = async (file: string): Promise<PiManifest | null> => {
	try {
		const raw = await fsp.readFile(file, "utf-8");
		const value: unknown = JSON.parse(raw.trim());

		return Check(ManifestSchema, value) ? value : null;
	} catch {
		return null;
	}
};

const pingSocketOnce = (socketPath: string): Promise<boolean> =>
	new Promise((resolve) => {
		const socket = net.createConnection(socketPath);
		let buffer = "";
		let receivedBytes = 0;
		let settled = false;

		socket.setEncoding("utf8");

		const finish = (ok: boolean): void => {
			if (settled) return;
			settled = true;
			clearTimeout(timer);
			socket.destroy();
			resolve(ok);
		};

		const timer = setTimeout(() => finish(false), PING_TIMEOUT_MS);
		socket.on("error", () => finish(false));
		socket.on("connect", () => {
			socket.write(`${JSON.stringify({ type: "ping" })}\n`);
		});
		socket.on("data", (chunk) => {
			receivedBytes += Buffer.byteLength(chunk);

			if (receivedBytes > MAX_RESPONSE_BYTES) return finish(false);
			buffer += chunk;
			const newline = buffer.indexOf("\n");

			if (newline === -1) return;

			try {
				finish(parseWireResponse(buffer.slice(0, newline)).ok);
			} catch {
				finish(false);
			}
		});
		socket.on("close", () => finish(false));
	});

const socketRespondsToPing = async (socketPath: string): Promise<boolean> => {
	for (let attempt = 0; attempt < PING_ATTEMPTS; attempt += 1) {
		if (await pingSocketOnce(socketPath)) return true;
	}

	return false;
};

const compactPath = (value: string | undefined): string => {
	if (!value) return "?";
	const home = process.env.HOME;

	return home && value.startsWith(home) ? `~${value.slice(home.length)}` : value;
};

const labelFor = (
	candidate: Omit<Candidate, "label" | "searchText">,
): string => {
	const session = candidate.session || "?";
	const window = candidate.window || "?";

	const address =
		candidate.windowIndex && candidate.paneIndex
			? `${session}:${candidate.windowIndex}.${candidate.paneIndex}`
			: `${session}:${window}`;

	const cwd = compactPath(candidate.cwd || candidate.root);
	const pane = candidate.pane ? ` ${candidate.pane}` : "";
	const current = candidate.current ? " current" : "";
	const status = candidate.reachable ? "" : " busy/unreachable";
	const title = candidate.displayTitle || candidate.paneTitle;
	const machine = candidate.machine ? `${candidate.machine} ` : "";
	const logicalName = candidate.sessionName ? ` {${candidate.sessionName}}` : "";
	const logicalId = candidate.sessionId ? ` <${candidate.sessionId}>` : "";
	const id = candidate.id ? ` [${candidate.id}]` : "";

	return `${machine}${address}${pane}${title ? ` ${title}` : ""}${logicalName}${logicalId} — ${cwd}${current}${status}${id}`;
};

const buildCandidate = (
	socket: string,
	manifest: PiManifest | undefined,
	currentSocket: string | null,
	reachable: boolean,
): Candidate => {
	const parsed = parseSocketName(socket);
	const base = path.basename(socket).replace(/\.sock$/, "");

	const stableId = [
		currentMachineName() || "local",
		manifest?.session || parsed.session || "?",
		manifest?.window || parsed.window || "?",
		manifest?.pane || manifest?.pid || base,
	].join(":");

	const partial = {
		socket,
		id: stableId,
		session: manifest?.session || parsed.session,
		sessionId: manifest?.sessionId,
		sessionName: manifest?.sessionName,
		window: manifest?.window || parsed.window,
		pane: manifest?.pane,
		paneIndex: manifest?.paneIndex,
		cwd: manifest?.cwd,
		machine: currentMachineName(),
		state: reachable ? manifest?.state || "reachable" : "orphaned/unreachable",
		statusUpdatedAt: manifest?.statusUpdatedAt,
		windowIndex: manifest?.windowIndex,
		windowName: manifest?.windowName || manifest?.window,
		paneTitle: manifest?.paneTitle,
		root: manifest?.root,
		pid: manifest?.pid,
		current: socket === currentSocket || manifest?.pid === process.pid,
		reachable,
		manifest,
	};

	const label = labelFor(partial);

	const searchText = [
		partial.id,
		partial.session,
		partial.sessionId,
		partial.sessionName,
		partial.window,
		partial.pane,
		partial.paneIndex,
		partial.windowIndex,
		partial.cwd,
		partial.root,
		path.basename(socket),
		label,
	]
		.filter(Boolean)
		.join(" ")
		.toLowerCase();

	return { ...partial, label, searchText };
};

const listTmuxPanes = (run: typeof execFile = execFile): Promise<
	Array<{
		session: string;
		window: string;
		windowIndex: string;
		windowName: string;
		pane: string;
		paneIndex: string;
		title: string;
		cwd?: string;
		pid?: number;
	}>
> =>
	new Promise((resolve) => {
		run(
			"tmux",
			[
				"list-panes",
				"-a",
				"-F",
				"#{session_name}\t#{window_index}\t#{window_name}\t#{pane_id}\t#{pane_index}\t#{pane_title}\t#{pane_pid}\t#{pane_current_path}",
			],
			{ encoding: "utf8", timeout: 2000 },
			(err, stdout) => {
				if (err) return resolve([]);

				const rows = stdout
					.trim()
					.split(/\r?\n/)
					.filter(Boolean)
					.map((line) => {
						const [
							session,
							windowIndex,
							windowName,
							pane,
							paneIndex,
							title,
							pid,
							cwd,
						] = line.split("\t");

						return {
							session,
							window: /^[a-zA-Z0-9_-]+$/.test(windowName || "")
								? windowName
								: windowIndex,
							windowIndex,
							windowName,
							pane,
							paneIndex,
							title,
							cwd,
							panePid: Number(pid) || undefined,
						};
					});

				run(
					"ps",
					["-axo", "pid=,ppid=,comm="],
					{ encoding: "utf8", timeout: 2000 },
					(psErr, psOut) => {
						if (psErr) return resolve([]);
						const commands = new Map<number, string>();
						const children = new Map<number, number[]>();

						for (const line of psOut.trim().split(/\r?\n/)) {
							const match = line.trim().match(/^(\d+)\s+(\d+)\s+(.*)$/);

							if (!match) continue;

							const pid = Number(match[1]),
								ppid = Number(match[2]);

							commands.set(pid, match[3]);
							children.set(ppid, [...(children.get(ppid) || []), pid]);
						}

						const piDescendant = (root: number | undefined): number | undefined => {
							const queue = root ? [root] : [];
							const seen = new Set<number>();

							while (queue.length) {
								const pid = queue.shift()!;

								if (seen.has(pid)) continue;
								seen.add(pid);

								if (path.basename(commands.get(pid) || "") === "pi") return pid;
								queue.push(...(children.get(pid) || []));
							}

							return undefined;
						};

						resolve(
							rows.flatMap(({ panePid, ...row }) => {
								if (
									/eph|ephemeral/i.test(
										`${row.title || ""} ${row.session || ""} ${row.windowName || ""}`,
									)
								)
									return [];
								const pid = piDescendant(panePid);

								return pid ? [{ ...row, pid }] : [];
							}),
						);
					},
				);
			},
		);
	});

const discoverCandidates = async (listPanes = listTmuxPanes): Promise<Candidate[]> => {
	const currentSocket = await currentSocketPath();
	const bySocket = new Map<string, PiManifest | undefined>();
	const ignoredSockets = new Set<string>();
	const ignoredPids = new Set<number>();
	const ignoredPanes = new Set<string>();

	if (await fileExists(MANIFEST_DIR)) {
		const entries = (await fsp.readdir(MANIFEST_DIR)).sort();

		for (const entry of entries) {
			if (!entry.endsWith(".info")) continue;
			const manifest = await readManifest(path.join(MANIFEST_DIR, entry));

			if (!manifest?.socket) continue;

			if (manifest.ephemeral) {
				ignoredSockets.add(manifest.socket);

				if (await socketRespondsToPing(manifest.socket)) {
					if (manifest.pid) ignoredPids.add(manifest.pid);
					else if (manifest.pane) ignoredPanes.add(manifest.pane);
				}

				continue;
			}

			bySocket.set(manifest.socket, manifest);
		}
	}

	if (await fileExists(SOCKET_DIR)) {
		const entries = await fsp.readdir(SOCKET_DIR);

		for (const entry of entries) {
			if (!entry.startsWith(`${SOCKET_PREFIX}-`) || !entry.endsWith(".sock")) {
				continue;
			}

			if (entry.includes("-eph-")) continue;
			const socket = path.join(SOCKET_DIR, entry);

			if (ignoredSockets.has(socket) || !(await isSocket(socket))) continue;

			if (!bySocket.has(socket) && (await socketRespondsToPing(socket))) {
				bySocket.set(socket, undefined);
			}
		}
	}

	for (const socket of ignoredSockets) bySocket.delete(socket);

	const candidates = await Promise.all(
		[...bySocket.entries()].map(async ([socket, manifest]) =>
			buildCandidate(
				socket,
				manifest,
				currentSocket,
				(await isSocket(socket)) && (await socketRespondsToPing(socket)),
			),
		),
	);

	const panes = await listPanes();
	const seenPanes = new Set<string>();

	for (const row of panes) {
		if (seenPanes.has(row.pane) || ignoredPanes.has(row.pane) || ignoredPids.has(row.pid)) continue;

		seenPanes.add(row.pane);

		for (let index = candidates.length - 1; index >= 0; index--) {
			const candidate = candidates[index];

			if (!candidate.reachable && candidate.manifest?.pane === row.pane && candidate.pid && candidate.pid !== row.pid) candidates.splice(index, 1);
		}

		const owners = candidates.filter((candidate) => (row.pid && candidate.manifest?.pid === row.pid) || (!candidate.manifest?.pid && candidate.manifest?.pane === row.pane));
		const manifestCandidate = owners.sort((a, b) => Number(b.pid === row.pid) - Number(a.pid === row.pid) || compareCandidates(a, b))[0];
		const linkedPanes = panes.filter((entry) => entry.pane === row.pane);
		let pane = linkedPanes.find((entry) => entry.session === manifestCandidate?.session) || row;
		let existing = manifestCandidate;

		if (!existing?.reachable) {
			for (const linked of linkedPanes) {
				const socket = buildSocketPath(linked.session, linked.window, linked.pane);
				const candidate = candidates.find((entry) => entry.socket === socket && (!entry.pid || entry.pid === row.pid));

				if (candidate?.reachable) {
					existing = candidate;
					pane = linked;
					break;
				}
			}
		}

		if (existing) {
			for (const owner of owners) {
				if (owner !== existing && !owner.reachable) candidates.splice(candidates.indexOf(owner), 1);
			}

			existing.session = pane.session;
			existing.window = pane.window;
			existing.pane = pane.pane;
			existing.pid = existing.pid || pane.pid;
			existing.current = existing.socket === currentSocket || existing.pid === process.pid;
			existing.cwd = existing.cwd || pane.cwd;
			existing.windowIndex = pane.windowIndex;
			existing.windowName = pane.windowName;
			existing.paneIndex = pane.paneIndex;
			existing.paneTitle = pane.title;
			existing.displayTitle = pane.windowName;
			existing.searchText = [
				existing.id,
				existing.session,
				existing.sessionId,
				existing.sessionName,
				existing.window,
				existing.pane,
				existing.paneIndex,
				existing.windowIndex,
				existing.cwd,
				existing.paneTitle,
				existing.displayTitle,
				existing.socket,
			]
				.filter(Boolean)
				.join(" ")
				.toLowerCase();
			existing.label = labelFor(existing);
			continue;
		}

		const socket = buildSocketPath(pane.session, pane.window, pane.pane);

		if (candidates.some((candidate) => candidate.socket === socket)) continue;

		const orphan = buildCandidate(
			socket,
			{
				session: pane.session,
				window: pane.window,
				pane: pane.pane,
				paneIndex: pane.paneIndex,
				pid: pane.pid,
				cwd: pane.cwd,
			},
			currentSocket,
			false,
		);

		orphan.windowIndex = pane.windowIndex;
		orphan.windowName = pane.windowName;
		orphan.paneIndex = pane.paneIndex;
		orphan.paneTitle = pane.title;
		orphan.displayTitle = pane.windowName;
		orphan.state = "orphaned/unreachable";
		orphan.label = labelFor(orphan);
		orphan.searchText += ` ${pane.windowIndex} ${pane.windowName} ${pane.title}`.toLowerCase();
		candidates.push(orphan);
	}

	return candidates.sort(compareCandidates);
};

const activityTime = (candidate: Candidate): number => {
	const time = Date.parse(candidate.statusUpdatedAt || "");

	return Number.isFinite(time) ? time : 0;
};

const compareCandidates = (a: Candidate, b: Candidate): number => {
	if (a.reachable !== b.reachable) return a.reachable ? -1 : 1;

	if (a.current !== b.current) return a.current ? 1 : -1;

	return activityTime(b) - activityTime(a) || a.id.localeCompare(b.id) || a.socket.localeCompare(b.socket);
};

const pickerText = (text: string): string =>
	stripVTControlCharacters(text).replace(/\p{Cc}/gu, " ");

const pickerItem = (candidate: Candidate, now = Date.now()) => {
	const address = candidate.windowIndex !== undefined && candidate.paneIndex !== undefined
		? `${candidate.session || "?"}:${candidate.windowIndex}.${candidate.paneIndex}`
		: `${candidate.session || "?"}:${candidate.window || "?"}`;

	const timestamp = activityTime(candidate);
	const seconds = Math.max(0, Math.floor((now - timestamp) / 1000));

	const age = !timestamp ? "activity unknown"
		: seconds < 60 ? "just now"
		: seconds < 3600 ? `${Math.floor(seconds / 60)}m ago`
		: seconds < 86400 ? `${Math.floor(seconds / 3600)}h ago`
		: `${Math.floor(seconds / 86400)}d ago`;

	const name = candidate.sessionName || candidate.displayTitle || candidate.windowName || candidate.window || "unnamed";
	const state = candidate.state === "input_needed" ? "needs input" : candidate.state || "unknown";

	return {
		value: candidate.socket,
		label: pickerText(`${address}${candidate.pane ? ` ${candidate.pane}` : ""}`),
		description: pickerText(`${state.padEnd(12)} ${age.padEnd(16)} ${name}`),
	};
};

const previewText = (text: string): string => {
	const bounded = text.slice(0, 4000);

	const clean = stripVTControlCharacters(bounded)
		.replace(/\r\n?/g, "\n")
		.replace(/[\p{Cc}\p{Cf}]/gu, (char) => char === "\n" ? char : " ")
		.trim();

	return clean + (text.length > bounded.length ? "\n[Preview truncated]" : "");
};

const pickCandidate = async (
	choices: Candidate[],
	ctx: ExtensionContext,
	title: string,
): Promise<Candidate | undefined> => {
	if (ctx.mode !== "tui") {
		const options = new Map(choices.map((candidate) => [candidate.label, candidate]));
		const selected = await ctx.ui.select(title, [...options.keys()]);

		return options.get(selected);
	}

	const bySocket = new Map(choices.map((candidate) => [candidate.socket, candidate]));

	const selected = await ctx.ui.custom<string | undefined>((tui, theme, keybindings, done) => {
		const items = choices.map((candidate) => pickerItem(candidate));

		const makeList = (maxVisible: number) => new SelectList(items, maxVisible, {
			selectedPrefix: (text) => theme.fg("accent", text),
			selectedText: (text) => theme.fg("accent", text),
			description: (text) => theme.fg("muted", text),
			scrollInfo: (text) => theme.fg("dim", text),
			noMatch: (text) => theme.fg("warning", text),
		}, { minPrimaryColumnWidth: 24, maxPrimaryColumnWidth: 48 });

		let list = makeList(1);

		const detail = {
			render(width: number) {
				const item = list.getSelectedItem();
				const candidate = item && bySocket.get(item.value);

				if (!candidate) return [];

				return [
					...[
						`${candidate.machine || "local"} / ${item.label}`,
						candidate.sessionName || candidate.displayTitle || candidate.windowName || candidate.window || "unnamed",
						item.description || "",
						compactPath(candidate.cwd || candidate.root),
					].map((line) => truncateToWidth(pickerText(line), width)),
					...wrapTextWithAnsi(pickerText(`Session ID: ${candidate.sessionId?.trim() || "unknown"}`), Math.max(1, width)),
				].map((line) => theme.fg("muted", line));
			},
			invalidate() {},
		};

		let closed = false;
		let revision = 0;
		let previewSocket: string | undefined;
		let preview = "Loading...";

		const close = (value: string | undefined) => {
			if (closed) return;
			closed = true;
			done(value);
		};

		const updatePreview = () => {
			const socket = list.getSelectedItem()?.value;

			if (closed || socket === previewSocket) return;
			previewSocket = socket;
			const candidate = socket && bySocket.get(socket);
			const currentRevision = ++revision;
			preview = "Loading...";

			if (!candidate) return;

			void requestCandidateControl(candidate, "message.last").then((result) => {
				if (closed || currentRevision !== revision) return;
				preview = result.ok
					? previewText(controlLastMessage(result.response)?.content || "") || "No assistant message yet."
					: isUnsupportedControlResponse(result.response)
						? "Preview unavailable: target needs pi.control.v1 reload."
						: "Preview unavailable.";
				tui.requestRender();
			});
		};

		const messagePreview = {
			render(width: number) {
				const available = tui.terminal.rows - list.render(width).length - detail.render(width).length - 5;
				const maxLines = Math.max(1, Math.min(6, available));
				const lines = wrapTextWithAnsi(preview, Math.max(1, width));
				const shown = lines.slice(0, maxLines);

				if (lines.length > maxLines) {
					shown[maxLines - 1] = maxLines === 1
						? `${truncateToWidth(shown[0], Math.max(0, width - 3), "")}...`
						: "[Preview truncated]";
				}

				return [
					theme.fg("accent", truncateToWidth("Latest assistant message", width)),
					...shown.map((line) => theme.fg("muted", truncateToWidth(line, width))),
				];
			},
			invalidate() {},
		};

		const bindList = () => {
			list.onSelect = (item) => close(item.value);
			list.onCancel = () => close(undefined);
		};

		bindList();
		updatePreview();

		return {
			render(width: number) {
				const index = items.findIndex((item) => item.value === list.getSelectedItem()?.value);
				const available = tui.terminal.rows - detail.render(width).length - 8;
				list = makeList(Math.max(1, Math.min(8, choices.length, available)));
				list.setSelectedIndex(index);
				bindList();

				return [
					theme.fg("accent", truncateToWidth(title, width)),
					...list.render(width),
					...detail.render(width),
					...messagePreview.render(width),
					theme.fg("dim", truncateToWidth("Up/down: choose | Enter: select | Esc: cancel", width)),
				];
			},
			invalidate: () => list.invalidate(),
			dispose() { closed = true; },
			handleInput(data: string) {
				if (closed) return;

				if (keybindings.matches(data, "tui.select.confirm")) close(list.getSelectedItem()?.value);
				else if (keybindings.matches(data, "tui.select.cancel")) close(undefined);
				else if (data === "j" || data === "k") {
					const index = items.findIndex((item) => item.value === list.getSelectedItem()?.value);

					list.setSelectedIndex((index + (data === "j" ? 1 : -1) + items.length) % items.length);
				} else list.handleInput(data);

				if (!closed) {
					updatePreview();
					tui.requestRender();
				}
			},
		};
	});

	return selected ? bySocket.get(selected) : undefined;
};

const STOPWORDS = new Set(["pi", "agent", "instance", "the", "a", "an", "to"]);

const normalizeTarget = (target: string): string =>
	target
		.trim()
		.replace(/[“”]/g, '"')
		.replace(/[‘’]/g, "'")
		.replace(/[^\p{L}\p{N}:@._-]+/gu, " ")
		.replace(/\s+/g, " ")
		.toLowerCase();

const tokenizeHint = (input: string): string[] => {
	const tokens: string[] = [];
	const re = /"((?:\\.|[^"\\])*)"|'((?:\\.|[^'\\])*)'|(\S+)/g;
	let match: RegExpExecArray | null;

	while ((match = re.exec(input)))
		tokens.push((match[1] ?? match[2] ?? match[3]).replace(/\\(["'])/g, "$1"));

	return tokens;
};

const isExactSelfTarget = (candidate: Candidate, target: string): boolean => {
	const t = normalizeTarget(target);

	const exacts = [
		candidate.id,
		candidate.socket,
		path.basename(candidate.socket),
		candidate.sessionId,
		candidate.sessionName,
		candidate.session && candidate.window
			? `${candidate.session}:${candidate.window}`
			: undefined,
		candidate.session && candidate.window && candidate.pane
			? `${candidate.session}:${candidate.window} ${candidate.pane}`
			: undefined,
		candidate.session && candidate.windowIndex && candidate.paneIndex
			? `${candidate.session}:${candidate.windowIndex}.${candidate.paneIndex}`
			: undefined,
	].flatMap((value) => (value ? [normalizeTarget(String(value))] : []));

	return exacts.includes(t);
};

const scoreCandidate = (candidate: Candidate, target: string): number => {
	if (candidate.socket === target || candidate.id === target) return 200;

	const t = normalizeTarget(target);

	if (!t) return 0;

	const exactSessionWindow =
		candidate.session && candidate.window
			? normalizeTarget(`${candidate.session}:${candidate.window}`)
			: undefined;

	const exactSessionWindowPane =
		candidate.session && candidate.window && candidate.pane
			? normalizeTarget(
					`${candidate.session}:${candidate.window} ${candidate.pane}`,
				)
			: undefined;

	const exactTmuxAddress =
		candidate.session && candidate.windowIndex && candidate.paneIndex
			? normalizeTarget(
					`${candidate.session}:${candidate.windowIndex}.${candidate.paneIndex}`,
				)
			: undefined;

	if (candidate.sessionId && normalizeTarget(candidate.sessionId) === t)
		return 155;

	if (exactTmuxAddress && exactTmuxAddress === t) return 160;

	if (exactSessionWindowPane && exactSessionWindowPane === t) return 140;

	if (exactSessionWindow && exactSessionWindow === t) return 120;

	if (candidate.sessionName && normalizeTarget(candidate.sessionName) === t)
		return 110;

	const exacts = [
		candidate.id,
		candidate.session,
		candidate.sessionId,
		candidate.sessionName,
		candidate.window,
		candidate.pane,
		candidate.paneIndex,
		candidate.socket,
		path.basename(candidate.socket),
	].flatMap((value) => (value ? [normalizeTarget(String(value))] : []));

	if (exacts.includes(t)) return 100;

	if (candidate.searchText.includes(t)) return 50;

	const words = tokenizeHint(t)
		.map((word) => word.replace(/[^\p{L}\p{N}:@._-]/gu, "").toLowerCase())
		.filter((word) => word && !STOPWORDS.has(word));

	if (
		words.length > 0 &&
		words.every((word) => candidate.searchText.includes(word))
	) {
		return 25 + words.length;
	}

	return 0;
};

const formatCandidateList = (candidates: Candidate[]): string =>
	candidates
		.flatMap((candidate) =>
			candidate.reachable && !candidate.current ? [`- ${candidate.label}`] : [],
		)
		.join("\n") || "(none)";

const selectCandidate = async (
	target: string | undefined,
	ctx: ExtensionContext,
	inventory?: Candidate[],
): Promise<SelectionResult> => {
	const candidates = inventory || (await discoverCandidates());

	const nonCurrentReachable = candidates.filter(
		(candidate) => candidate.reachable && !candidate.current,
	).sort(compareCandidates);

	if (candidates.length === 0) {
		return {
			ok: false,
			error: "No running Pi sockets found",
			candidates,
		};
	}

	if (target?.trim()) {
		const scored = candidates
			.map((candidate) => ({
				candidate,
				score: scoreCandidate(candidate, target),
			}))
			.filter((entry) => entry.score > 0)
			.sort(
				(a, b) =>
					b.score - a.score ||
					a.candidate.id.localeCompare(b.candidate.id) ||
					a.candidate.socket.localeCompare(b.candidate.socket),
			);

		const bestOverall = scored[0];

		if (!bestOverall) {
			return {
				ok: false,
				error: `Target "${target.trim()}" not found.\nReachable candidates:\n${formatCandidateList(candidates)}`,
				candidates,
			};
		}

		const topMatches = scored.filter(
			(entry) => entry.score === bestOverall.score,
		);

		const unreachableTop = topMatches.find((entry) => !entry.candidate.reachable);

		if (unreachableTop) {
			return {
				ok: false,
				error: `Target "${target.trim()}" found but socket is not reachable or target is busy: ${unreachableTop.candidate.label}\nReachable candidates:\n${formatCandidateList(candidates)}`,
				candidates,
			};
		}

		const looseCurrentTop = topMatches.find(
			(entry) =>
				entry.candidate.current && !isExactSelfTarget(entry.candidate, target),
		);

		if (looseCurrentTop) {
			return {
				ok: false,
				error: `Target "${target.trim()}" only matched the current Pi instance loosely; refusing loopback.\nReachable candidates:\n${formatCandidateList(candidates)}`,
				candidates,
			};
		}

		const reachableScored = topMatches.filter(
			(entry) =>
				entry.candidate.reachable &&
				(!entry.candidate.current || isExactSelfTarget(entry.candidate, target)),
		);

		const best = reachableScored[0];
		const next = reachableScored[1];

		if (best && best.score >= 100 && (!next || next.score < best.score)) {
			return { ok: true, candidate: best.candidate };
		}

		const choices = scored
			.filter((entry) => entry.candidate.reachable && !entry.candidate.current)
			.map((entry) => entry.candidate);

		if (ctx.hasUI && choices.length > 0) {
			try {
				const candidate = await pickCandidate(choices, ctx, "Select matching Pi instance");

				if (candidate) return { ok: true, candidate };
			} catch (err) {
				return {
					ok: false,
					error: `Selection unavailable (${err instanceof Error ? err.message : String(err)}). Retry with an exact target; candidates:\n${formatCandidateList(candidates)}`,
					candidates,
				};
			}
		}

		return {
			ok: false,
			error: `Target "${target.trim()}" ambiguous. Retry with an exact target.\nReachable candidates:\n${formatCandidateList(candidates)}`,
			candidates,
		};
	}

	if (!ctx.hasUI || nonCurrentReachable.length === 0) {
		const prefix =
			nonCurrentReachable.length === 0
				? "No reachable non-current Pi sockets found."
				: "No target provided.";

		return {
			ok: false,
			error: `${prefix} Reachable candidates:\n${formatCandidateList(candidates)}`,
			candidates,
		};
	}

	try {
		const candidate = await pickCandidate(nonCurrentReachable, ctx, "Select Pi instance - latest activity first");

		if (!candidate)
			return {
				ok: false,
				error: "No Pi instance selected; retry with an exact target.",
				candidates,
			};

		return { ok: true, candidate };
	} catch (err) {
		return {
			ok: false,
			error: `Selection unavailable (${err instanceof Error ? err.message : String(err)}). Retry with an exact target; candidates:\n${formatCandidateList(candidates)}`,
			candidates,
		};
	}
};

const sendJsonLine = (socketPath: string, payload: ControlRequest | TellPayload): Promise<WireResponse> =>
	new Promise((resolve, reject) => {
		const socket = net.createConnection(socketPath);
		let buffer = "";
		let receivedBytes = 0;
		let settled = false;

		socket.setEncoding("utf8");

		const finish = (err: Error | null, result?: WireResponse): void => {
			if (settled) return;
			settled = true;
			clearTimeout(timer);
			socket.destroy();

			if (err) reject(err);
			else if (result) resolve(result);
			else reject(new Error(`socket closed without response: ${socketPath}`));
		};

		const timer = setTimeout(() => {
			finish(new Error(`timed out waiting for ${socketPath}`));
		}, CONNECT_TIMEOUT_MS);

		socket.on("error", (err) => finish(err));
		socket.on("connect", () => {
			socket.write(`${JSON.stringify(payload)}\n`);
		});
		socket.on("data", (chunk) => {
			receivedBytes += Buffer.byteLength(chunk);

			if (receivedBytes > MAX_RESPONSE_BYTES) return finish(new Error(`response exceeds ${MAX_RESPONSE_BYTES} bytes from ${socketPath}`));
			buffer += chunk;
			const idx = buffer.indexOf("\n");

			if (idx === -1) return;
			const line = buffer.slice(0, idx).trim();

			if (!line) return;

			try {
				finish(null, parseWireResponse(line));
			} catch {
				finish(new Error(`invalid JSON response from ${socketPath}`));
			}
		});
		socket.on("close", () => {
			if (!settled) finish(new Error(`socket closed without a complete response: ${socketPath}`));
		});
	});

const shellQuote = (value: string): string =>
	`'${value.replace(/'/g, `'\\''`)}'`;

const REMOTE_INVENTORY_SCRIPT = `
set -euo pipefail
state_dir="\${PI_STATE_DIR:-\${XDG_STATE_HOME:-$HOME/.local/state}/pi}"
STATE_DIR="$state_dir" node - <<'NODE'
const fs=require("node:fs"), path=require("node:path"), cp=require("node:child_process"), crypto=require("node:crypto"), net=require("node:net");
const state=process.env.STATE_DIR, sockets=path.join(state,"sockets"), manifests=path.join(state,"manifests"), out=new Map(), ignored=new Set(), ignoredPids=new Set(), ignoredPanes=new Set(), ephemeral=[], manifestSockets=new Set();
const runtime=m=>m&&typeof m==="object"&&["version","loadedAt"].every(k=>typeof m[k]==="string")&&(m.sourceHash===null||typeof m.sourceHash==="string");
const validManifest=m=>m&&typeof m==="object"&&!Array.isArray(m)&&["socket","cwd","root","session","window","windowIndex","windowName","pane","paneIndex","paneTitle","owner","role","linkMode","state","statusUpdatedAt"].every(k=>m[k]===undefined||typeof m[k]==="string")&&["sessionId","sessionName"].every(k=>m[k]==null||typeof m[k]==="string")&&(m.pid===undefined||(Number.isInteger(m.pid)&&m.pid>0))&&(m.ephemeral===undefined||typeof m.ephemeral==="boolean")&&["startedAt","heartbeatAt"].every(k=>m[k]===undefined||typeof m[k]==="string"||Number.isFinite(m[k]))&&(m.bridge===undefined||runtime(m.bridge))&&(m.tell==null||runtime(m.tell));
const socketFor=(session,window,paneId)=>{const name=[session,window,paneId].filter(Boolean).join("-"),full=path.join(sockets,"pi-"+name+".sock");if(Buffer.byteLength(full)<=${MAX_SOCKET_PATH_BYTES})return full;const fixed=Buffer.byteLength(path.join(sockets,"pi-.sock"))+9,budget=${MAX_SOCKET_PATH_BYTES}-fixed,hash=crypto.createHash("sha256").update(name).digest("hex").slice(0,8);if(budget<0)throw new Error("Pi socket directory exceeds the Unix socket path limit: "+sockets);let prefix="";for(const character of name){if(Buffer.byteLength(prefix+character)>budget)break;prefix+=character}return path.join(sockets,"pi-"+prefix+"-"+hash+".sock")};
const add=(m,s,replaceRegistration=false)=>{if(typeof s!=="string"||!s)return;const previous=replaceRegistration?undefined:out.get(s),registration=previous?.registration||{session:m.session,window:m.window,pane:m.pane,pid:m.pid};out.set(s,{...previous,...m,socket:s,registration})};
try {
  for(const f of fs.readdirSync(manifests).filter(x=>x.endsWith(".info")).sort()) {
    try {
      const m=JSON.parse(fs.readFileSync(path.join(manifests,f),"utf8"));
      if(!validManifest(m)||!m.socket)continue;
      if(m.ephemeral){ignored.add(m.socket);ephemeral.push(m)}else{add(m,m.socket,true);manifestSockets.add(m.socket)}
    } catch {}
  }
} catch {}
try {
  for(const f of fs.readdirSync(sockets).filter(x=>x.startsWith("pi-")&&x.endsWith(".sock"))) {
    const socket=path.join(sockets,f);
    try{if(!f.includes("-eph-")&&!ignored.has(socket)&&fs.statSync(socket).isSocket())add({},socket)}catch{}
  }
} catch {}
for(const socket of ignored)out.delete(socket);
const ping=(socket)=>new Promise(resolve=>{
  const client=net.createConnection(socket);let done=false,buffer="",receivedBytes=0;
  const finish=ok=>{if(done)return;done=true;clearTimeout(timer);client.destroy();resolve(ok)};
  const timer=setTimeout(()=>finish(false),${PING_TIMEOUT_MS});
  client.setEncoding("utf8");
  client.once("error",()=>finish(false));
  client.once("close",()=>finish(false));
  client.once("connect",()=>client.write('{"type":"ping"}\\n'));
  client.on("data",data=>{receivedBytes+=Buffer.byteLength(data);if(receivedBytes>${MAX_RESPONSE_BYTES})return finish(false);buffer+=data;const newline=buffer.indexOf("\\n");if(newline<0)return;try{finish(JSON.parse(buffer.slice(0,newline))?.ok===true)}catch{finish(false)}});
});
(async()=>{
  await Promise.all(ephemeral.map(async m=>{if(await ping(m.socket)){if(m.pid)ignoredPids.add(m.pid);else if(m.pane)ignoredPanes.add(m.pane)}}));
  await Promise.all([...out.values()].map(async row=>{row.reachable=false;for(let i=0;i<${PING_ATTEMPTS};i++){if(await ping(row.socket)){row.reachable=true;break}}if(!row.reachable&&!manifestSockets.has(row.socket))out.delete(row.socket)}));
  let panes=[];
  try {
    const ps=cp.execFileSync("ps",["-axo","pid=,ppid=,comm="],{encoding:"utf8",timeout:2000}),commands=new Map(),children=new Map();
    for(const l of ps.trim().split(/\\r?\\n/)){
      const m=l.trim().match(/^(\\d+)\\s+(\\d+)\\s+(.*)$/);if(!m)continue;
      const pid=+m[1],ppid=+m[2];commands.set(pid,m[3]);children.set(ppid,[...(children.get(ppid)||[]),pid]);
    }
    const pi=root=>{const queue=[root],seen=new Set();while(queue.length){const pid=queue.shift();if(!pid||seen.has(pid))continue;seen.add(pid);if(path.basename(commands.get(pid)||"")==="pi")return pid;queue.push(...(children.get(pid)||[]))}};
    const paneText=cp.execFileSync("tmux",["list-panes","-a","-F","#{session_name}\\t#{window_index}\\t#{window_name}\\t#{pane_id}\\t#{pane_index}\\t#{pane_title}\\t#{pane_pid}\\t#{pane_current_path}"],{encoding:"utf8",timeout:2000});
    panes=paneText.trim().split(/\\r?\\n/).map(l=>{const [session,windowIndex,windowName,pane,paneIndex,paneTitle,panePid,cwd]=l.split("\\t");return {session,windowIndex,windowName,pane,paneIndex,paneTitle,pid:pi(+panePid),cwd}});
  } catch {}
    const seen=new Set();
    for(const row of panes){
      if(!row.pid||seen.has(row.pane)||ignoredPids.has(row.pid)||ignoredPanes.has(row.pane)||/eph|ephemeral/i.test(row.paneTitle+" "+row.session+" "+row.windowName))continue;
      seen.add(row.pane);
      for(const stale of out.values()){if(!stale.reachable&&stale.pane===row.pane&&stale.pid&&stale.pid!==row.pid)out.delete(stale.socket)}
      const owners=[...out.values()].filter(m=>m.pid===row.pid||(!m.pid&&m.pane===row.pane)).sort((a,b)=>Number(b.pid===row.pid)-Number(a.pid===row.pid)||Number(b.reachable)-Number(a.reachable));
      const owner=owners[0],linkedPanes=panes.filter(p=>p.pane===row.pane);
      let pane=linkedPanes.find(p=>p.session===owner?.session)||row,existing=owner;
      if(!existing?.reachable){for(const linked of linkedPanes){const window=/^[a-zA-Z0-9_-]+$/.test(linked.windowName||"")?linked.windowName:linked.windowIndex;const candidate=out.get(socketFor(linked.session,window,linked.pane));if(candidate?.reachable&&(!candidate.pid||candidate.pid===row.pid)){existing=candidate;pane=linked;break}}}
      const window=/^[a-zA-Z0-9_-]+$/.test(pane.windowName||"")?pane.windowName:pane.windowIndex;
      if(existing){for(const stale of owners){if(stale!==existing&&!stale.reachable)out.delete(stale.socket)}Object.assign(existing,{session:pane.session,window,pane:pane.pane,pid:existing.pid||pane.pid,cwd:existing.cwd||pane.cwd,windowIndex:pane.windowIndex,windowName:pane.windowName,paneIndex:pane.paneIndex,paneTitle:pane.paneTitle});continue}
      const socket=socketFor(pane.session,window,pane.pane);
      if(!out.has(socket))add({...pane,window,state:"orphaned/unreachable",reachable:false},socket);
    }
  process.stdout.write(JSON.stringify([...out.values()]));
})().catch(error=>{console.error(error);process.exit(1)});
NODE
`;

const REMOTE_TELL_NODE = `
const net = require("node:net");
const socketPath = process.env.PI_TELL_SOCKET;
const payload = Buffer.from(process.env.PI_TELL_PAYLOAD_B64 || "", "base64").toString("utf8");
if (!socketPath || !payload) {
  console.error("missing remote tell socket or payload");
  process.exit(2);
}
const socket = net.createConnection(socketPath);
let buffer = "";
let receivedBytes = 0;
let settled = false;
const finish = (code, text) => {
  if (settled) return;
  settled = true;
  clearTimeout(timer);
  socket.destroy();
  process.exitCode = code;
  if (text) process.stdout.write(text.endsWith("\\n") ? text : text + "\\n");
};
socket.setEncoding("utf8");
const timer = setTimeout(() => finish(3, "remote tell timed out"), ${CONNECT_TIMEOUT_MS});
socket.on("error", (err) => finish(4, err.message));
socket.on("connect", () => socket.write(payload.endsWith("\\n") ? payload : payload + "\\n"));
socket.on("data", (chunk) => {
  receivedBytes += Buffer.byteLength(chunk);
  if (receivedBytes > ${MAX_RESPONSE_BYTES}) return finish(6, "remote Pi response exceeds ${MAX_RESPONSE_BYTES} bytes");
  buffer += chunk;
  if (buffer.includes("\\n")) finish(0, buffer.trim());
});
socket.on("close", () => finish(buffer.trim() ? 0 : 5, buffer.trim() || "remote tell socket closed without response"));
`;

const remoteTellScript = (socketPath: string, payloadB64: string): string => `
set -euo pipefail
socket_path=${shellQuote(socketPath)}
payload_b64=${shellQuote(payloadB64)}
if [[ ! -S "$socket_path" ]]; then
  echo "Selected Pi socket is unavailable: $socket_path" >&2
  exit 3
fi
printf '__TELL_SOCKET__ %s\n' "$socket_path"
PI_TELL_SOCKET="$socket_path" PI_TELL_PAYLOAD_B64="$payload_b64" node -e ${shellQuote(REMOTE_TELL_NODE)}
`;

const fetchRemoteInventory = (machine: string, run: typeof execFile = execFile): Promise<Candidate[]> =>
	new Promise((resolve, reject) => {
		if (!machine.trim() || machine.trim().startsWith("-")) return reject(new Error(`Invalid SSH machine: ${JSON.stringify(machine)}`));

		run(
			"ssh",
			[
				"-o",
				"BatchMode=yes",
				"-o",
				`ConnectTimeout=${Math.ceil(SSH_TIMEOUT_MS / 1000)}`,
				"--",
				machine,
				`bash -lc ${shellQuote(REMOTE_INVENTORY_SCRIPT)}`,
			],
			{ encoding: "utf8", timeout: SSH_TIMEOUT_MS, maxBuffer: MAX_RESPONSE_BYTES },
			(err, stdout, stderr) => {
				if (err) return reject(new Error(`Cannot discover Pi sessions on ${machine}: ${stderr.trim() || err.message}`));

				try {
					const rows: unknown = JSON.parse(stdout.trim());

					if (!Array.isArray(rows)) throw new Error("expected an inventory array");

					resolve(
						rows.map((row) => {
							if (!Check(RemoteManifestSchema, row)) throw new Error("invalid inventory row");

							const m = row;
							const c = buildCandidate(m.socket, m, null, Boolean(m.reachable));
							c.machine = machine;
							c.current = false;
							const registered = m.registration || m;
							const parsed = parseSocketName(m.socket);
							c.id = [
								machine,
								registered.session || parsed.session || "?",
								registered.window || parsed.window || "?",
								registered.pane || registered.pid || path.basename(m.socket).replace(/\.sock$/, ""),
							].join(":");
							c.state = c.reachable ? m.state || "reachable" : "orphaned/unreachable";
							c.label = labelFor(c);
							c.searchText = [
								c.id,
								c.session,
								c.sessionId,
								c.sessionName,
								c.window,
								c.pane,
								c.paneIndex,
								c.windowIndex,
								c.windowName,
								c.cwd,
								c.paneTitle,
								c.displayTitle,
								c.socket,
							]
								.filter(Boolean)
								.join(" ")
								.toLowerCase();

							return c;
						}).sort(compareCandidates),
					);
				} catch {
					reject(new Error(`Invalid Pi inventory from ${machine}`));
				}
			},
		);
	});

const sendRemoteJsonLine = (
	machine: string,
	target: string,
	payload: ControlRequest | TellPayload,
	run: typeof execFile = execFile,
): Promise<RemoteSendResult> =>
	new Promise((resolve) => {
		if (!machine.trim() || machine.trim().startsWith("-")) return resolve({ ok: false, error: `Invalid SSH machine: ${JSON.stringify(machine)}` });

		const payloadB64 = Buffer.from(JSON.stringify(payload), "utf8").toString(
			"base64",
		);

		const command = `bash -lc ${shellQuote(remoteTellScript(target, payloadB64))}`;
		run(
			"ssh",
			[
				"-o",
				"BatchMode=yes",
				"-o",
				`ConnectTimeout=${Math.ceil(SSH_TIMEOUT_MS / 1000)}`,
				"--",
				machine,
				command,
			],
			{ encoding: "utf-8", timeout: SSH_TIMEOUT_MS, maxBuffer: MAX_RESPONSE_BYTES },
			(err, stdout, stderr) => {
				const stderrText = stderr.trim();

				if (err) {
					resolve({
						ok: false,
						error: stderrText || err.message,
					});

					return;
				}

				const lines = stdout.trim().split(/\r?\n/).filter(Boolean);

				const socketLine = lines.find((line) =>
					line.startsWith("__TELL_SOCKET__ "),
				);

				const socket = socketLine?.replace("__TELL_SOCKET__ ", "");

				const responseText = lines
					.filter((line) => !line.startsWith("__TELL_SOCKET__ "))
					.join("\n")
					.trim();

				try {
					resolve({ ok: true, target, socket, response: parseWireResponse(responseText) });
				} catch {
					resolve({ ok: false, target, socket, error: "Invalid remote Pi response" });
				}
			},
		);
	});

const makeMessageId = (): string =>
	`tell-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;

const buildControlRequest = (
	operation: ControlOperation,
	params: Partial<ControlSendParams> = {},
	id = `control-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`,
): ControlRequest => ({
	type: "control",
	protocol: CONTROL_PROTOCOL,
	id,
	operation,
	params,
});

const isOkResponse = (response: WireResponse | undefined): boolean => response?.ok === true;

const isUnsupportedControlResponse = (response: WireResponse | undefined): boolean =>
	response?.ok === false && /unsupported (?:payload type: control|control protocol)/i.test(response.error || "");

const parseControlResponse = (
	request: ControlRequest,
	response: WireResponse | undefined,
): { ok: true; response: ControlResponse } | { ok: false; error: string } => {
	if (!response) {
		return { ok: false, error: "Target returned no control response" };
	}

	const value = response;

	if (
		value.type !== "control_response" ||
		value.protocol !== CONTROL_PROTOCOL ||
		value.id !== request.id ||
		value.operation !== request.operation
	) {
		return {
			ok: false,
			error: `Target returned an invalid control response: ${JSON.stringify(response)}`,
		};
	}

	if (!value.ok) {
		return {
			ok: false,
			error: value.error || `Control operation ${request.operation} failed`,
		};
	}

	return { ok: true, response: { ...value, type: "control_response", protocol: CONTROL_PROTOCOL, id: request.id, operation: request.operation } };
};

const controlSendParams = (
	payload: TellPayload,
	mode: DeliveryMode | undefined,
): ControlSendParams => {
	const { type: _type, protocol, id, ...params } = payload;
	const result = { ...params, messageId: id, tellProtocol: protocol };

	if (mode) result.mode = mode;

	return result;
};

const tellResponseError = (
	request: ControlRequest,
	response: WireResponse | undefined,
	legacy: boolean,
): string | undefined => {
	if (legacy) {
		return isOkResponse(response)
			? undefined
			: `Target rejected legacy tell payload: ${JSON.stringify(response)}`;
	}

	const parsed = parseControlResponse(request, response);

	return parsed.ok ? undefined : parsed.error;
};

const isLocalMachine = (machine: string | undefined): boolean => {
	if (!machine) return false;
	const normalized = machine.toLowerCase();
	const current = currentMachineName()?.toLowerCase();

	return (
		normalized === "localhost" ||
		normalized === "127.0.0.1" ||
		(current !== undefined && normalized === current)
	);
};

const originInfo = async (
	ctx: ExtensionContext,
	includeMachineReply: boolean,
): Promise<OriginInfo> => {
	const currentSocket = await currentSocketPath();
	const candidates = await discoverCandidates();

	const currentCandidate = candidates.find(
		(candidate) => candidate.current || candidate.socket === currentSocket,
	);

	const tmux = await detectTmux();
	const parsed = currentSocket ? parseSocketName(currentSocket) : {};
	const cwd = compactPath(ctx.cwd);

	const session =
		currentCandidate?.session ||
		tmux?.session ||
		parsed.session ||
		process.env.PI_SESSION ||
		"unknown";

	const window =
		currentCandidate?.window ||
		tmux?.window ||
		parsed.window ||
		process.env.PI_WINDOW ||
		"?";

	const windowIndex = currentCandidate?.windowIndex || tmux?.windowIndex;
	const paneIndex = currentCandidate?.paneIndex || tmux?.paneIndex;

	const localTarget =
		windowIndex && paneIndex
			? `${session}:${windowIndex}.${paneIndex}`
			: `${session}:${window}`;

	const machine = currentMachineName();

	const replyTarget =
		includeMachineReply && machine ? `${machine} ${localTarget}` : localTarget;

	const display =
		includeMachineReply && machine
			? `${machine} ${localTarget} (${cwd})`
			: `${localTarget} (${cwd})`;

	return { display, replyTarget };
};

const wrapGuidance = async (
	ctx: ExtensionContext,
	message: string,
	id: string,
	includeMachineReply: boolean,
): Promise<{ text: string; from: string }> => {
	const origin = await originInfo(ctx, includeMachineReply);

	return {
		from: origin.display,
		text: `[TELL:${id} from ${origin.display}]\n${message.trim()}\n\nReply asynchronously with /tell ${origin.replyTarget} <message>, or use the tell_pi tool with target ${JSON.stringify(origin.replyTarget)}.`,
	};
};

const buildTellPayload = async (
	ctx: ExtensionContext,
	message: string,
	id: string,
	options: TellPayloadOptions,
): Promise<TellPayload> => {
	const wrapped = await wrapGuidance(
		ctx,
		message,
		id,
		options.includeMachineReply,
	);

	const payload: TellPayload = {
		type: "tell",
		protocol: "pi.tell.v1",
		id,
		text: wrapped.text,
		from: wrapped.from,
		sessionId: ctx.sessionManager.getSessionId(),
		sessionName: ctx.sessionManager.getSessionName() || undefined,
		timestamp: Math.floor(Date.now() / 1000),
	};

	if (options.mode) payload.mode = options.mode;

	if (options.includeFromSocket) payload.fromSocket = await currentSocketPath();

	return payload;
};

const normalizeRoute = (route: TellRoute): TellRoute => {
	if (route.machine && isLocalMachine(route.machine)) {
		return {
			target: route.target,
			message: route.message,
			mode: route.mode,
		};
	}

	return route;
};

const routeFromTargetHint = (
	targetText: string | undefined,
	message: string,
	machine?: string,
	mode?: DeliveryMode,
): TellRoute => {
	const trimmedTarget = targetText?.trim();

	if (!trimmedTarget) return normalizeRoute({ machine, message, mode });

	const stableMachine = trimmedTarget.match(/^([^:\s]+):/);

	if (!machine && stableMachine && looksLikeMachineTarget(stableMachine[1])) {
		return normalizeRoute({
			machine: stableMachine[1],
			target: trimmedTarget,
			message,
			mode,
		});
	}

	const words = trimmedTarget.split(/\s+/).filter(Boolean);

	if (!machine && words.length >= 2 && looksLikeMachineTarget(words[0])) {
		return normalizeRoute({
			machine: words[0],
			target: words.slice(1).join(" "),
			message,
			mode,
		});
	}

	return normalizeRoute({ machine, target: trimmedTarget, message, mode });
};

const sendTell = async (
	ctx: ExtensionContext,
	rawRoute: TellRoute,
	selectedSocket?: string,
): Promise<SendResult> => {
	const route = normalizeRoute(rawRoute);

	if (!route.target?.trim() && route.machine) {
		return {
			ok: false,
			error: `Remote tell target missing for ${route.machine}. Usage: /tell ${route.machine} <tmux-session[:window]> <message>`,
		};
	}

	let inventory: Candidate[];

	try {
		inventory = await listSessions(route.machine);
	} catch (error) {
		return { ok: false, error: error instanceof Error ? error.message : String(error) };
	}

	const selection = await selectCandidate(route.target, ctx,
		selectedSocket ? inventory.filter((candidate) => candidate.socket === selectedSocket) : inventory,
	);

	if (!selection.ok) {
		return {
			ok: false,
			candidates: selection.candidates,
			error: `${selection.error}\nUse ask_user_question with these candidates, then retry tell_pi using the selected stable candidate id.`,
		};
	}

	const id = makeMessageId();

	const legacyPayload = await buildTellPayload(ctx, route.message, id, {
		includeMachineReply: Boolean(route.machine),
		includeFromSocket: !route.machine,
		mode: route.mode,
	});

	const controlRequest = buildControlRequest(
		"message.send",
		controlSendParams(legacyPayload, route.mode),
		id,
	);

	const target = selection.candidate;

	try {
		if (route.machine) {
			let remoteResponse = await sendRemoteJsonLine(
				route.machine,
				target.socket,
				controlRequest,
			);

			let usedLegacy = false;

			if (
				remoteResponse.ok &&
				isUnsupportedControlResponse(remoteResponse.response)
			) {
				usedLegacy = true;
				remoteResponse = await sendRemoteJsonLine(
					route.machine,
					target.socket,
					legacyPayload,
				);
			}

			const resolvedTarget: Candidate = {
				...target,
				socket: remoteResponse.socket || target.socket,
				reachable: remoteResponse.ok,
			};

			const responseError = remoteResponse.ok
				? tellResponseError(controlRequest, remoteResponse.response, usedLegacy)
				: remoteResponse.error || "Remote tell transport failed";

			if (responseError) {
				return {
					ok: false,
					target: resolvedTarget,
					id,
					response: remoteResponse.response,
					error: responseError,
				};
			}

			return {
				ok: true,
				target: resolvedTarget,
				id,
				response: remoteResponse.response,
			};
		}

		let response = await sendJsonLine(target.socket, controlRequest);
		let usedLegacy = false;

		if (isUnsupportedControlResponse(response)) {
			usedLegacy = true;
			response = await sendJsonLine(target.socket, legacyPayload);
		}

		const responseError = tellResponseError(controlRequest, response, usedLegacy);

		if (responseError) {
			return {
				ok: false,
				target,
				id,
				response,
				error: responseError,
			};
		}

		return { ok: true, target, id, response };
	} catch (err) {
		return {
			ok: false,
			target,
			id,
			error: err instanceof Error ? err.message : String(err),
		};
	}
};

const requestControl = async (
	ctx: ExtensionContext,
	rawRoute: TellRoute,
	operation: Exclude<ControlOperation, "message.send">,
): Promise<SendResult> => {
	const route = normalizeRoute(rawRoute);

	if (!route.target?.trim()) {
		return { ok: false, error: `${operation} requires a target` };
	}

	let inventory: Candidate[];

	try {
		inventory = await listSessions(route.machine);
	} catch (error) {
		return { ok: false, error: error instanceof Error ? error.message : String(error) };
	}

	const selection = await selectCandidate(route.target, ctx, inventory);

	if (!selection.ok) {
		return {
			ok: false,
			candidates: selection.candidates,
			error: selection.error,
		};
	}

	return requestCandidateControl(selection.candidate, operation);
};

const requestCandidateControl = async (
	target: Candidate,
	operation: Exclude<ControlOperation, "message.send">,
): Promise<SendResult> => {
	const request = buildControlRequest(operation);

	try {
		let response: WireResponse | undefined;

		if (target.machine && !isLocalMachine(target.machine)) {
			const remote = await sendRemoteJsonLine(
				target.machine,
				target.socket,
				request,
			);

			if (!remote.ok) {
				return { ok: false, target, id: request.id, error: remote.error };
			}

			response = remote.response;
		} else {
			response = await sendJsonLine(target.socket, request);
		}

		if (isUnsupportedControlResponse(response)) {
			return {
				ok: false,
				target,
				id: request.id,
				response,
				error: `${target.label} has not reloaded pi.control.v1`,
			};
		}

		const parsed = parseControlResponse(request, response);

		if (!parsed.ok) {
			return {
				ok: false,
				target,
				id: request.id,
				response,
				error: parsed.error,
			};
		}

		return {
			ok: true,
			target,
			id: request.id,
			response: parsed.response,
		};
	} catch (error) {
		return {
			ok: false,
			target,
			id: request.id,
			error: error instanceof Error ? error.message : String(error),
		};
	}
};

const splitCommandArgs = (args: string): Partial<TellRoute> => {
	const normalized = args.trim().replace(/^to\s+/i, "");
	const tokens = tokenizeHint(normalized);

	if (!tokens.length) return {};
	let mode: DeliveryMode | undefined;

	if (tokens[0] === "--steer") {
		mode = "steer";
		tokens.shift();
	} else if (tokens[0] === "--follow-up" || tokens[0] === "--follow_up") {
		mode = "follow_up";
		tokens.shift();
	}

	if (!tokens.length) return { mode };

	if (looksLikeMachineTarget(tokens[0]) && tokens[1]) {
		return {
			machine: tokens[0],
			target: tokens[1],
			message: tokens.slice(2).join(" "),
			mode,
		};
	}

	return {
		target: tokens[0],
		message: tokens.slice(1).join(" "),
		mode,
	};
};

const listSessions = async (
	machine: string | undefined,
): Promise<Candidate[]> => {
	if (machine && !isLocalMachine(machine)) return fetchRemoteInventory(machine);

	return discoverCandidates();
};

const formatSessionList = (candidates: Candidate[]): string => {
	if (!candidates.length) return "No Pi sessions found.";

	return candidates.map((candidate) => `- ${candidate.label}`).join("\n");
};

const controlLastMessage = (
	response: WireResponse | undefined,
): Static<typeof MessageSchema> | null => response?.data?.message?.content ? response.data.message : null;

const ReceivedTellSchema = Type.Object({
	direction: Type.Literal("received"),
	from: Type.Optional(Type.String()),
	text: Type.String({ minLength: 1 }),
	timestamp: Type.Optional(Type.Number()),
});

const restoreRecentTellWidget = (ctx: ExtensionContext): void => {
	if (!ctx.hasUI) return;
	const entries = ctx.sessionManager.getEntries();

	for (let i = entries.length - 1; i >= 0; i--) {
		const entry = entries[i];

		if (entry.type !== "custom" || entry.customType !== "tell-message") {
			continue;
		}

		const data = entry.data;

		if (!Check(ReceivedTellSchema, data)) continue;
		const ageMs = Date.now() - (data.timestamp || 0) * 1000;

		if (ageMs > 60 * 60 * 1000) return;
		const from = data.from || "unknown";
		ctx.ui.setWidget("tell", [
			ctx.ui.theme.fg("accent", `Recent tell from ${from}`),
			data.text.replace(/\s+/g, " ").slice(0, 160),
			ctx.ui.theme.fg("muted", "Persisted in session history"),
		]);

		return;
	}
};

export const _test = {
	REMOTE_INVENTORY_SCRIPT,
	REMOTE_TELL_NODE,
	buildCandidate,
	compareCandidates,
	pickerItem,
	pickCandidate,
	requestCandidateControl,
	currentSocketPath,
	readManifest,
	pingSocketOnce,
	sendJsonLine,
	sendRemoteJsonLine,
	MAX_RESPONSE_BYTES,
	parseWireResponse,
	tellRuntime,
	buildControlRequest,
	buildSocketPath,
	controlLastMessage,
	discoverCandidates,
	fetchRemoteInventory,
	formatSessionList,
	isUnsupportedControlResponse,
	labelFor,
	listTmuxPanes,
	normalizeTarget,
	parseControlResponse,
	tellResponseError,
	routeFromTargetHint,
	scoreCandidate,
	selectCandidate,
	splitCommandArgs,
	tokenizeHint,
};

export default function (pi: ExtensionAPI): void {
	pi.on("session_start", (_event, ctx) => {
		pi.events.emit("tell:runtime", tellRuntime);
		restoreRecentTellWidget(ctx);
	});

	// @lat: [[pi-coding-agent#Session and routing extensions]]
	pi.registerCommand("tell", {
		description: "Send async guidance to another running Pi instance",
		handler: async (args, ctx) => {
			const parsed = splitCommandArgs(args);
			const machine = parsed.machine;
			const mode = parsed.mode;
			let target = parsed.target;
			let message = parsed.message;
			let selectedSocket: string | undefined;

			if (!message?.trim()) {
				if (!ctx.hasUI) {
					ctx.ui.notify(
						"Usage: /tell [--steer|--follow-up] [machine] <target> <message>",
						"error",
					);

					return;
				}

				if (machine && !target) {
					ctx.ui.notify(
						`Usage: /tell ${machine} <tmux-session[:window]> <message>`,
						"error",
					);

					return;
				}

				if (!target) {
					const selected = await selectCandidate(undefined, ctx);

					if (selected.ok === false) {
						ctx.ui.notify(selected.error, "error");

						return;
					}

					selectedSocket = selected.candidate.socket;
					target = selectedSocket;
				}

				message = await ctx.ui.editor("Tell Pi", "");

				if (message === undefined || !message.trim()) {
					ctx.ui.notify("Cancelled", "info");

					return;
				}
			}

			const result = await sendTell(ctx, {
				machine,
				target,
				message,
				mode,
			}, selectedSocket);

			if (!result.ok) {
				ctx.ui.notify(`Tell failed: ${result.error || "unknown error"}`, "error");

				return;
			}

			pi.appendEntry("tell-message", {
				id: result.id,
				direction: "sent",
				target: result.target?.label,
				socket: result.target?.socket,
				message,
				mode: mode || "follow_up",
				timestamp: Date.now(),
			});
			ctx.ui.notify(`Told ${result.target?.label}`, "info");
		},
	});

	pi.registerCommand("tell-sessions", {
		description: "List discoverable local or remote Pi sessions",
		handler: async (args, ctx) => {
			const machine = args.trim() || undefined;

			try {
				const candidates = await listSessions(machine);
				ctx.ui.notify(formatSessionList(candidates), "info");
			} catch (error) {
				ctx.ui.notify(error instanceof Error ? error.message : String(error), "error");
			}
		},
	});

	pi.registerCommand("tell-last", {
		description: "Show the last assistant message from another Pi session",
		handler: async (args, ctx) => {
			if (!ctx.hasUI) {
				ctx.ui.notify("tell-last requires interactive mode", "error");

				return;
			}

			const parsed = splitCommandArgs(args);

			if (!parsed.target) {
				ctx.ui.notify("Usage: /tell-last [machine] <target>", "error");

				return;
			}

			const result = await requestControl(
				ctx,
				routeFromTargetHint(parsed.target, "", parsed.machine),
				"message.last",
			);

			if (!result.ok) {
				ctx.ui.notify(
					`Last-message lookup failed: ${result.error || "unknown error"}`,
					"error",
				);

				return;
			}

			const message = controlLastMessage(result.response);

			if (!message) {
				ctx.ui.notify("Target has no assistant message", "info");

				return;
			}

			await ctx.ui.editor(
				`Last assistant message from ${result.target?.label || parsed.target}`,
				message.content,
			);
		},
	});

	pi.registerTool({
		name: "tell_pi",
		label: "Tell Pi",
		description:
			"Send asynchronous guidance to another running Pi instance by machine and target name/session/window.",
		promptSnippet:
			"Send async guidance to another running Pi instance selected by machine, target name, or fuzzy selector.",
		promptGuidelines: [
			"Use tell_pi when the user asks to tell, notify, guide, or hand work to another running Pi instance.",
			"tell_pi is Pi-only; do not use it for external agents like Claude Code, opencode, aider, or codex.",
		],
		parameters: Type.Object({
			machine: Type.Optional(
				Type.String({
					description: "Optional machine/SSH host, e.g. megabookpro or workbookpro.",
				}),
			),
			target: Type.Optional(
				Type.String({
					description:
						"Pi target hint such as machine + session, session, session:window, cwd basename, pane, or loose description.",
				}),
			),
			message: Type.String({ description: "Guidance/prompt to send." }),
			mode: Type.Optional(
				StringEnum(["steer", "follow_up"] as const, {
					description:
						"Delivery mode while the target is busy. Defaults to follow_up.",
				}),
			),
		}),
		async execute(...args) {
			const [, params, , , ctx] = args;

			const result = await sendTell(
				ctx,
				routeFromTargetHint(
					params.target,
					params.message,
					params.machine,
					params.mode,
				),
			);

			if (!result.ok) {
				return {
					isError: true,
					content: [{ type: "text", text: result.error || "Tell failed" }],
					details: result,
				};
			}

			pi.appendEntry("tell-message", {
				id: result.id,
				direction: "sent",
				target: result.target?.label,
				socket: result.target?.socket,
				message: params.message,
				mode: params.mode || "follow_up",
				timestamp: Date.now(),
			});

			return {
				content: [
					{
						type: "text",
						text: `Sent ${result.id} to ${result.target?.label}`,
					},
				],
				details: {
					id: result.id,
					target: result.target?.label,
					socket: result.target?.socket,
					response: result.response,
				},
			};
		},
	});

	pi.registerTool({
		name: "list_pi_sessions",
		label: "List Pi Sessions",
		description:
			"List discoverable Pi sessions locally or on an SSH-accessible machine.",
		parameters: Type.Object({
			machine: Type.Optional(
				Type.String({
					description: "Optional machine/SSH host to inspect.",
				}),
			),
		}),
		async execute(...args) {
			const [, params] = args;
			const candidates = await listSessions(params.machine);

			return {
				content: [{ type: "text", text: formatSessionList(candidates) }],
				details: { candidates },
			};
		},
	});

	pi.registerTool({
		name: "get_pi_last_message",
		label: "Get Pi Last Message",
		description:
			"Retrieve the last assistant message from a selected running Pi session.",
		parameters: Type.Object({
			machine: Type.Optional(
				Type.String({
					description: "Optional machine/SSH host.",
				}),
			),
			target: Type.String({
				description:
					"Exact or fuzzy Pi target using the same selection rules as tell_pi.",
			}),
		}),
		async execute(...args) {
			const [, params, , , ctx] = args;
			const route = routeFromTargetHint(params.target, "", params.machine);
			const result = await requestControl(ctx, route, "message.last");

			if (!result.ok) {
				return {
					isError: true,
					content: [
						{
							type: "text",
							text: result.error || "Last-message lookup failed",
						},
					],
					details: result,
				};
			}

			const message = controlLastMessage(result.response);

			if (!message) {
				return {
					content: [{ type: "text", text: "Target has no assistant message." }],
					details: result,
				};
			}

			const maxLength = 30_000;

			const content =
				message.content.length > maxLength
					? `${message.content.slice(0, maxLength)}\n\n[Message truncated at ${maxLength} characters]`
					: message.content;

			return {
				content: [{ type: "text", text: content }],
				details: {
					target: result.target,
					message,
				},
			};
		},
	});
}
