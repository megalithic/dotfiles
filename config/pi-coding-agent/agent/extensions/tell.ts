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
import net from "node:net";
import os from "node:os";
import path from "node:path";
import type {
	ExtensionAPI,
	ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { StringEnum } from "@earendil-works/pi-ai";
import { Type } from "typebox";

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

type PiManifest = {
	socket?: string;
	cwd?: string;
	root?: string;
	pid?: number;
	session?: string;
	sessionId?: string | null;
	sessionName?: string | null;
	window?: string;
	windowIndex?: string;
	pane?: string;
	paneIndex?: string;
	owner?: string;
	role?: string;
	linkMode?: string;
	ephemeral?: boolean;
	startedAt?: string;
	heartbeatAt?: number | string;
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
	response?: unknown;
	error?: string;
};

type RemoteSendResult = {
	ok: boolean;
	target?: string;
	socket?: string;
	response?: unknown;
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

type ControlRequest = {
	type: "control";
	protocol: "pi.control.v1";
	id: string;
	operation: ControlOperation;
	params: Record<string, unknown>;
};

type ControlResponse = {
	ok: boolean;
	type: "control_response";
	protocol: "pi.control.v1";
	id: string;
	operation: ControlOperation;
	data?: unknown;
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

const pidAlive = (pid: number | undefined): boolean => {
	if (!pid || !Number.isFinite(pid)) return true;
	try {
		process.kill(pid, 0);
		return true;
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
	const budget = Math.max(MAX_SOCKET_PATH_BYTES - fixed, 8);
	const hash = crypto
		.createHash("sha256")
		.update(name)
		.digest("hex")
		.slice(0, 8);
	return `${SOCKET_DIR}/${SOCKET_PREFIX}-${name.slice(0, budget)}-${hash}.sock`;
};

const currentSocketPath = async (): Promise<string | null> => {
	if (process.env.PI_SOCKET) return process.env.PI_SOCKET;
	const tmux = await detectTmux();
	if (tmux) {
		return buildSocketPath(tmux.session, tmux.window, tmux.pane);
	}
	return path.join(SOCKET_DIR, `${SOCKET_PREFIX}-default-0.sock`);
};

const readManifest = async (file: string): Promise<PiManifest | null> => {
	try {
		const raw = await fsp.readFile(file, "utf-8");
		return JSON.parse(raw.trim()) as PiManifest;
	} catch {
		return null;
	}
};

const pingSocketOnce = (socketPath: string): Promise<boolean> =>
	new Promise((resolve) => {
		const socket = net.createConnection(socketPath);
		let settled = false;

		const finish = (ok: boolean): void => {
			if (settled) return;
			settled = true;
			socket.destroy();
			resolve(ok);
		};

		socket.setTimeout(PING_TIMEOUT_MS, () => finish(false));
		socket.on("error", () => finish(false));
		socket.on("connect", () => {
			socket.write(`${JSON.stringify({ type: "ping" })}\n`);
		});
		socket.on("data", (chunk) => {
			try {
				const line = chunk.toString().split("\n")[0]?.trim();
				const response = line ? JSON.parse(line) : null;
				finish(Boolean(response) && response.ok === true);
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
		state: reachable ? "reachable" : "orphaned/unreachable",
		windowIndex: manifest?.windowIndex,
		windowName: manifest?.window,
		root: manifest?.root,
		pid: manifest?.pid,
		current: socket === currentSocket,
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

const listTmuxPanes = (): Promise<
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
		execFile(
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
				execFile(
					"ps",
					["-axo", "pid=,ppid=,command="],
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
								if (/(?:^|[/\s])pi(?:\s|$)/i.test(commands.get(pid) || "")) return pid;
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

const discoverCandidates = async (): Promise<Candidate[]> => {
	const currentSocket = await currentSocketPath();
	const bySocket = new Map<string, PiManifest | undefined>();
	const ignoredSockets = new Set<string>();

	if (await fileExists(MANIFEST_DIR)) {
		const entries = await fsp.readdir(MANIFEST_DIR);
		for (const entry of entries) {
			if (!entry.endsWith(".info")) continue;
			const manifest = await readManifest(path.join(MANIFEST_DIR, entry));
			if (!manifest?.socket) continue;
			if (manifest.ephemeral) {
				ignoredSockets.add(manifest.socket);
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
	const seenPanes = new Set<string>();
	for (const pane of await listTmuxPanes()) {
		const manifestCandidate = candidates.find(
			(candidate) => candidate.manifest?.pane === pane.pane,
		);
		if (manifestCandidate?.session && manifestCandidate.session !== pane.session)
			continue;
		if (seenPanes.has(pane.pane)) continue;
		seenPanes.add(pane.pane);

		const socket = buildSocketPath(pane.session, pane.window, pane.pane);
		const existing =
			candidates.find((candidate) => candidate.socket === socket) ||
			manifestCandidate;
		if (existing) {
			existing.pane = existing.pane || pane.pane;
			existing.pid = existing.pid || pane.pid;
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
		candidates.push(orphan);
	}

	return candidates.sort((a, b) => {
		if (a.reachable !== b.reachable) return a.reachable ? -1 : 1;
		if (a.current !== b.current) return a.current ? 1 : -1;
		return a.label.localeCompare(b.label);
	});
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
	);

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
				const options = new Map(choices.map((entry) => [entry.label, entry]));
				const selected = await ctx.ui.select("Select matching Pi instance", [
					...options.keys(),
				]);
				const candidate = options.get(selected);
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

	const options = new Map(
		nonCurrentReachable.map((candidate) => [candidate.label, candidate]),
	);
	try {
		const selected = await ctx.ui.select("Select Pi instance", [
			...options.keys(),
		]);
		const candidate = options.get(selected);
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

const sendJsonLine = (socketPath: string, payload: unknown): Promise<unknown> =>
	new Promise((resolve, reject) => {
		const socket = net.createConnection(socketPath);
		let buffer = "";
		let settled = false;

		const finish = (err: Error | null, result?: unknown): void => {
			if (settled) return;
			settled = true;
			socket.destroy();
			if (err) reject(err);
			else resolve(result);
		};

		socket.setTimeout(CONNECT_TIMEOUT_MS, () => {
			finish(new Error(`timed out connecting to ${socketPath}`));
		});
		socket.on("error", (err) => finish(err));
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
				finish(null, JSON.parse(line));
			} catch {
				finish(new Error(`invalid JSON response from ${socketPath}`));
			}
		});
		socket.on("close", () => {
			if (!settled) finish(null, buffer.trim() || null);
		});
	});

const shellQuote = (value: string): string =>
	`'${value.replace(/'/g, `'\\''`)}'`;

const REMOTE_INVENTORY_SCRIPT = `
set -euo pipefail
state_dir="\${PI_STATE_DIR:-\${XDG_STATE_HOME:-$HOME/.local/state}/pi}"
STATE_DIR="$state_dir" node - <<'NODE'
const fs=require("node:fs"),path=require("node:path"),cp=require("node:child_process"),crypto=require("node:crypto"),net=require("node:net");
const state=process.env.STATE_DIR, sockets=path.join(state,"sockets"), manifests=path.join(state,"manifests"), out=new Map(), ignored=new Set();
const socketFor=(session,window,paneId)=>{const name=[session,window,paneId].filter(Boolean).join("-"),full=path.join(sockets,"pi-"+name+".sock");if(Buffer.byteLength(full)<=${MAX_SOCKET_PATH_BYTES})return full;const fixed=Buffer.byteLength(path.join(sockets,"pi-.sock"))+9,budget=Math.max(${MAX_SOCKET_PATH_BYTES}-fixed,8),hash=crypto.createHash("sha256").update(name).digest("hex").slice(0,8);return path.join(sockets,"pi-"+name.slice(0,budget)+"-"+hash+".sock")};
const add=(m,s)=>{if(!s)return;const merged={...(out.get(s)||{}),...m,socket:s};merged.alive=!merged.pid||(()=>{try{process.kill(merged.pid,0);return true}catch{return false}})();out.set(s,merged)};
try{for(const f of fs.readdirSync(manifests).filter(x=>x.endsWith(".info"))){try{const m=JSON.parse(fs.readFileSync(path.join(manifests,f)));if(m.ephemeral){if(m.socket)ignored.add(m.socket)}else add(m,m.socket)}catch{}}}catch{}
try{for(const f of fs.readdirSync(sockets).filter(x=>x.startsWith("pi-")&&x.endsWith(".sock"))){const socket=path.join(sockets,f);if(!f.includes("-eph-")&&!ignored.has(socket))add({},socket)}}catch{}
try{const ps=cp.execFileSync("ps",["-axo","pid=,ppid=,command="],{encoding:"utf8"}),commands=new Map(),children=new Map();for(const l of ps.trim().split(/\\r?\\n/)){const m=l.trim().match(/^(\\d+)\\s+(\\d+)\\s+(.*)$/);if(!m)continue;const pid=+m[1],ppid=+m[2];commands.set(pid,m[3]);children.set(ppid,[...(children.get(ppid)||[]),pid])}const pi=(root)=>{const queue=[root],seen=new Set();while(queue.length){const pid=queue.shift();if(!pid||seen.has(pid))continue;seen.add(pid);if(/(?:^|[\\/\\s])pi(?:\\s|$)/i.test(commands.get(pid)||""))return pid;queue.push(...(children.get(pid)||[]))}};const panes=cp.execFileSync("tmux",["list-panes","-a","-F","#{session_name}\\t#{window_index}\\t#{window_name}\\t#{pane_id}\\t#{pane_index}\\t#{pane_title}\\t#{pane_pid}\\t#{pane_current_path}"],{encoding:"utf8"});for(const l of panes.trim().split(/\\r?\\n/)){const [session,wi,wn,pane,paneIndex,title,panePid,cwd]=l.split("\\t"),pid=pi(+panePid);if(pid&&!/eph|ephemeral/i.test((title||"")+" "+(session||"")+" "+(wn||""))){const window=/^[a-zA-Z0-9_-]+$/.test(wn||"")?wn:wi,paneOwner=[...out.values()].find(row=>row.pane===pane);if(paneOwner?.session&&paneOwner.session!==session)continue;if(paneOwner){Object.assign(paneOwner,{windowIndex:wi,windowName:wn,paneIndex,paneTitle:title});continue}add({session,window,windowIndex:wi,windowName:wn,pane,paneIndex,paneTitle:title,pid,cwd,state:"orphaned"},socketFor(session,window,pane))}}}catch{}
const ping=(socket)=>new Promise(resolve=>{if(!fs.existsSync(socket))return resolve(false);const client=net.createConnection(socket);let done=false;const finish=ok=>{if(done)return;done=true;clearTimeout(timer);client.destroy();resolve(ok)};const timer=setTimeout(()=>finish(false),500);client.once("error",()=>finish(false));client.once("connect",()=>client.write('{"type":"ping"}\\n'));client.once("data",data=>{try{finish(JSON.parse(String(data).split("\\n")[0]).ok===true)}catch{finish(false)}})});
(async()=>{const rows=await Promise.all([...out.values()].map(async row=>({...row,reachable:Boolean(row.alive)&&await ping(row.socket)})));process.stdout.write(JSON.stringify(rows))})().catch(error=>{console.error(error);process.exit(1)});
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
let settled = false;
const finish = (code, text) => {
  if (settled) return;
  settled = true;
  socket.destroy();
  if (text) process.stdout.write(text.endsWith("\\n") ? text : text + "\\n");
  process.exit(code);
};
socket.setTimeout(${CONNECT_TIMEOUT_MS}, () => finish(3, "remote tell timed out"));
socket.on("error", (err) => finish(4, err.message));
socket.on("connect", () => socket.write(payload.endsWith("\\n") ? payload : payload + "\\n"));
socket.on("data", (chunk) => {
  buffer += chunk.toString();
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

const fetchRemoteInventory = (machine: string): Promise<Candidate[]> =>
	new Promise((resolve) => {
		execFile(
			"ssh",
			[
				"-o",
				"BatchMode=yes",
				"-o",
				`ConnectTimeout=${Math.ceil(SSH_TIMEOUT_MS / 1000)}`,
				machine,
				`bash -lc ${shellQuote(REMOTE_INVENTORY_SCRIPT)}`,
			],
			{ encoding: "utf8", timeout: SSH_TIMEOUT_MS },
			(err, stdout) => {
				if (err) return resolve([]);
				try {
					const rows = JSON.parse(stdout.trim()) as PiManifest[];
					resolve(
						rows.map((m: any) => {
							const c = buildCandidate(m.socket, m, null, Boolean(m.reachable));
							c.machine = machine;
							c.id = [
								machine,
								m.session || "?",
								m.window || "?",
								m.pane || m.pid || path.basename(m.socket),
							].join(":");
							c.state = m.state || "orphaned/unreachable";
							c.label = labelFor(c);
							c.searchText = [
								c.id,
								c.session,
								c.sessionId,
								c.sessionName,
								c.window,
								c.pane,
								c.cwd,
								c.paneTitle,
								c.displayTitle,
								c.socket,
							]
								.filter(Boolean)
								.join(" ")
								.toLowerCase();
							return c;
						}),
					);
				} catch {
					resolve([]);
				}
			},
		);
	});

const sendRemoteJsonLine = (
	machine: string,
	target: string,
	payload: unknown,
): Promise<RemoteSendResult> =>
	new Promise((resolve) => {
		const payloadB64 = Buffer.from(JSON.stringify(payload), "utf8").toString(
			"base64",
		);
		const command = `bash -lc ${shellQuote(remoteTellScript(target, payloadB64))}`;
		execFile(
			"ssh",
			[
				"-o",
				"BatchMode=yes",
				"-o",
				`ConnectTimeout=${Math.ceil(SSH_TIMEOUT_MS / 1000)}`,
				machine,
				command,
			],
			{ encoding: "utf-8", timeout: SSH_TIMEOUT_MS },
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

				let response: unknown = responseText || undefined;
				if (responseText) {
					try {
						response = JSON.parse(responseText);
					} catch {
						// Keep raw response.
					}
				}

				resolve({ ok: true, target, socket, response });
			},
		);
	});

const makeMessageId = (): string =>
	`tell-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;

const buildControlRequest = (
	operation: ControlOperation,
	params: Record<string, unknown> = {},
	id = `control-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`,
): ControlRequest => ({
	type: "control",
	protocol: CONTROL_PROTOCOL,
	id,
	operation,
	params,
});

const isOkResponse = (response: unknown): boolean =>
	response !== null &&
	typeof response === "object" &&
	"ok" in response &&
	(response as { ok?: unknown }).ok === true;

const isUnsupportedControlResponse = (response: unknown): boolean => {
	if (
		response === null ||
		typeof response !== "object" ||
		!("ok" in response) ||
		(response as { ok?: unknown }).ok !== false
	) {
		return false;
	}
	const error = String((response as { error?: unknown }).error || "");
	return /unsupported (?:payload type: control|control protocol)/i.test(error);
};

const parseControlResponse = (
	request: ControlRequest,
	response: unknown,
): { ok: true; response: ControlResponse } | { ok: false; error: string } => {
	if (response === null || typeof response !== "object") {
		return { ok: false, error: "Target returned no control response" };
	}
	const value = response as Partial<ControlResponse>;
	if (
		value.type !== "control_response" ||
		value.protocol !== CONTROL_PROTOCOL ||
		value.id !== request.id ||
		value.operation !== request.operation ||
		typeof value.ok !== "boolean"
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
	return { ok: true, response: value as ControlResponse };
};

const controlSendParams = (
	payload: Record<string, unknown>,
	mode: DeliveryMode | undefined,
): Record<string, unknown> => {
	const { type: _type, protocol, id, ...params } = payload;
	return {
		...params,
		messageId: id,
		tellProtocol: protocol,
		...(mode ? { mode } : {}),
	};
};

const tellResponseError = (
	request: ControlRequest,
	response: unknown,
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
		(candidate) => candidate.socket === currentSocket,
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
): Promise<Record<string, unknown>> => {
	const wrapped = await wrapGuidance(
		ctx,
		message,
		id,
		options.includeMachineReply,
	);
	const payload: Record<string, unknown> = {
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
): Promise<SendResult> => {
	const route = normalizeRoute(rawRoute);
	if (!route.target?.trim() && route.machine) {
		return {
			ok: false,
			error: `Remote tell target missing for ${route.machine}. Usage: /tell ${route.machine} <tmux-session[:window]> <message>`,
		};
	}

	const inventory = route.machine
		? await fetchRemoteInventory(route.machine)
		: undefined;
	const selection = await selectCandidate(route.target, ctx, inventory);
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
					response: remoteResponse,
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
	const inventory = route.machine
		? await fetchRemoteInventory(route.machine)
		: undefined;
	const selection = await selectCandidate(route.target, ctx, inventory);
	if (!selection.ok) {
		return {
			ok: false,
			candidates: selection.candidates,
			error: selection.error,
		};
	}
	const request = buildControlRequest(operation);
	const target = selection.candidate;
	try {
		let response: unknown;
		if (route.machine) {
			const remote = await sendRemoteJsonLine(
				route.machine,
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
	response: unknown,
): { content: string; timestamp?: number } | null => {
	if (response === null || typeof response !== "object") return null;
	const data = (response as { data?: unknown }).data;
	if (data === null || typeof data !== "object") return null;
	const message = (data as { message?: unknown }).message;
	if (message === null || typeof message !== "object") return null;
	const content = (message as { content?: unknown }).content;
	if (typeof content !== "string" || !content) return null;
	const timestamp = (message as { timestamp?: unknown }).timestamp;
	return {
		content,
		timestamp: typeof timestamp === "number" ? timestamp : undefined,
	};
};

const restoreRecentTellWidget = (ctx: ExtensionContext): void => {
	if (!ctx.hasUI) return;
	const entries = ctx.sessionManager.getEntries() as Array<{
		type?: string;
		customType?: string;
		data?: {
			direction?: string;
			from?: string;
			text?: string;
			timestamp?: number;
		};
	}>;
	for (let i = entries.length - 1; i >= 0; i--) {
		const entry = entries[i];
		if (entry.type !== "custom" || entry.customType !== "tell-message") {
			continue;
		}
		const data = entry.data;
		if (data?.direction !== "received" || !data.text) continue;
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
	buildCandidate,
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
					target =
						selected.candidate.session && selected.candidate.window
							? `${selected.candidate.session}:${selected.candidate.window}`
							: selected.candidate.id;
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
			});
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
			const candidates = await listSessions(machine);
			ctx.ui.notify(formatSessionList(candidates), "info");
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
