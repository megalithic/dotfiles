// @ts-nocheck
/**
 * /tell extension - async Pi-to-Pi guidance messages.
 *
 * This replaces the shell-script tell skill for Pi instance targeting. It sends
 * line-delimited JSON to the existing Pi/pinvim socket for a selected running Pi
 * instance. The receiver injects the message as a user prompt, and can reply by
 * using /tell or the tell_pi tool back to the origin instance.
 */

import { execFile } from "node:child_process";
import fsp from "node:fs/promises";
import net from "node:net";
import path from "node:path";
import type {
	ExtensionAPI,
	ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const xdgStateHome =
	process.env.XDG_STATE_HOME ||
	(process.env.HOME ? path.join(process.env.HOME, ".local", "state") : "/tmp");
const PI_STATE_DIR = process.env.PI_STATE_DIR || path.join(xdgStateHome, "pi");
const SOCKET_DIR = path.join(PI_STATE_DIR, "sockets");
const MANIFEST_DIR = path.join(PI_STATE_DIR, "manifests");
const SOCKET_PREFIX = "pi";
const CONNECT_TIMEOUT_MS = 800;
const PING_TIMEOUT_MS = 1000;
const PING_ATTEMPTS = 2;
const SSH_TIMEOUT_MS = 5000;
const KNOWN_MACHINE_ALIASES = new Set(["megabookpro", "workbookpro"]);

type TmuxInfo = {
	session: string;
	window: string;
	pane?: string;
};

type PiManifest = {
	socket?: string;
	cwd?: string;
	root?: string;
	pid?: number;
	session?: string;
	window?: string;
	pane?: string;
	owner?: string;
	role?: string;
	linkMode?: string;
	ephemeral?: boolean;
	startedAt?: string;
	heartbeatAt?: number;
};

type Candidate = {
	socket: string;
	id: string;
	label: string;
	searchText: string;
	session?: string;
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
};

type OriginInfo = {
	display: string;
	replyTarget: string;
};

type TellPayloadOptions = {
	includeMachineReply: boolean;
	includeFromSocket: boolean;
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

		execFile(
			"tmux",
			[
				"display-message",
				"-p",
				"#{session_name}\t#{window_name}\t#{window_index}\t#{pane_id}",
			],
			{ encoding: "utf-8", timeout: 2000 },
			(err, stdout) => {
				if (err) {
					resolve(null);
					return;
				}
				const [session, windowName, windowIndex, pane] = stdout
					.trim()
					.split("\t");
				const window =
					windowName && /^[a-zA-Z0-9_-]+$/.test(windowName)
						? windowName
						: windowIndex;
				resolve(session && window ? { session, window, pane } : null);
			},
		);
	});

const currentMachineName = (): string | undefined => {
	const raw = process.env.HOSTNAME || process.env.HOST || "";
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

const currentSocketPath = async (): Promise<string | null> => {
	if (process.env.PI_SOCKET) return process.env.PI_SOCKET;
	const tmux = await detectTmux();
	if (tmux) {
		return path.join(
			SOCKET_DIR,
			`${SOCKET_PREFIX}-${tmux.session}-${tmux.window}.sock`,
		);
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
	return home && value.startsWith(home)
		? `~${value.slice(home.length)}`
		: value;
};

const labelFor = (
	candidate: Omit<Candidate, "label" | "searchText">,
): string => {
	const session = candidate.session || "?";
	const window = candidate.window || "?";
	const cwd = compactPath(candidate.cwd || candidate.root);
	const pane = candidate.pane ? ` ${candidate.pane}` : "";
	const current = candidate.current ? " current" : "";
	const status = candidate.reachable ? "" : " busy/unreachable";
	return `${session}:${window}${pane} — ${cwd}${current}${status}`;
};

const buildCandidate = (
	socket: string,
	manifest: PiManifest | undefined,
	currentSocket: string | null,
	reachable: boolean,
): Candidate => {
	const parsed = parseSocketName(socket);
	const base = path.basename(socket).replace(/\.sock$/, "");
	const partial = {
		socket,
		id: parsed.id || base,
		session: manifest?.session || parsed.session,
		window: manifest?.window || parsed.window,
		pane: manifest?.pane,
		cwd: manifest?.cwd,
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
		partial.window,
		partial.pane,
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

const discoverCandidates = async (): Promise<Candidate[]> => {
	const currentSocket = await currentSocketPath();
	const bySocket = new Map<string, PiManifest | undefined>();

	if (await fileExists(MANIFEST_DIR)) {
		const entries = await fsp.readdir(MANIFEST_DIR);
		for (const entry of entries) {
			if (!entry.endsWith(".info")) continue;
			const manifest = await readManifest(path.join(MANIFEST_DIR, entry));
			if (!manifest?.socket) continue;
			if (manifest.ephemeral) continue;
			if (!pidAlive(manifest.pid)) continue;
			if (!(await isSocket(manifest.socket))) continue;
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
			if (!(await isSocket(socket))) continue;
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
				await socketRespondsToPing(socket),
			),
		),
	);

	return candidates.sort((a, b) => {
		if (a.reachable !== b.reachable) return a.reachable ? -1 : 1;
		if (a.current !== b.current) return a.current ? 1 : -1;
		return a.label.localeCompare(b.label);
	});
};

const normalizeTarget = (target: string): string =>
	target.trim().replace(/\s+/g, " ").toLowerCase();

const isExactSelfTarget = (candidate: Candidate, target: string): boolean => {
	const t = normalizeTarget(target);
	const exacts = [
		candidate.id,
		candidate.socket,
		path.basename(candidate.socket),
		candidate.session && candidate.window
			? `${candidate.session}:${candidate.window}`
			: undefined,
		candidate.session && candidate.window && candidate.pane
			? `${candidate.session}:${candidate.window} ${candidate.pane}`
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

	if (exactSessionWindowPane && exactSessionWindowPane === t) return 140;
	if (exactSessionWindow && exactSessionWindow === t) return 120;

	const exacts = [
		candidate.id,
		candidate.session,
		candidate.window,
		candidate.pane,
		candidate.socket,
		path.basename(candidate.socket),
	].flatMap((value) => (value ? [normalizeTarget(String(value))] : []));

	if (exacts.includes(t)) return 100;
	if (candidate.searchText.includes(t)) return 50;

	const words = t.split(/\s+/).filter(Boolean);
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
): Promise<SelectionResult> => {
	const candidates = await discoverCandidates();
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
			.sort((a, b) => b.score - a.score);
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
		const unreachableTop = topMatches.find(
			(entry) => !entry.candidate.reachable,
		);
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
				(!entry.candidate.current ||
					isExactSelfTarget(entry.candidate, target)),
		);
		const best = reachableScored[0];
		const next = reachableScored[1];
		if (best && (!next || best.score - next.score >= 25)) {
			return { ok: true, candidate: best.candidate };
		}

		return {
			ok: false,
			error: `Target "${target.trim()}" ambiguous.\nReachable candidates:\n${formatCandidateList(candidates)}`,
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

	const labels = nonCurrentReachable.map((candidate) => candidate.label);
	const selected = await ctx.ui.select("Select Pi instance", labels);
	const candidate = nonCurrentReachable.find(
		(entry) => entry.label === selected,
	);
	if (!candidate) {
		return { ok: false, error: "No Pi instance selected", candidates };
	}
	return { ok: true, candidate };
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

const remoteTellScript = (target: string, payloadB64: string): string => `
set -euo pipefail
target=${shellQuote(target)}
payload_b64=${shellQuote(payloadB64)}
state_dir="\${PI_STATE_DIR:-\${XDG_STATE_HOME:-$HOME/.local/state}/pi}"
sockets_dir="$state_dir/sockets"
prefix="${SOCKET_PREFIX}"
socket_path=""
socket_for() {
  printf '%s/%s-%s-%s.sock' "$sockets_dir" "$prefix" "$1" "$2"
}
first_session_socket() {
  local session="$1"
  local candidate
  candidate="$(socket_for "$session" agent)"
  if [[ -S "$candidate" ]]; then printf '%s' "$candidate"; return 0; fi
  candidate="$(socket_for "$session" 0)"
  if [[ -S "$candidate" ]]; then printf '%s' "$candidate"; return 0; fi
  shopt -s nullglob
  local sockets=("$sockets_dir/$prefix-$session-"*.sock)
  shopt -u nullglob
  for candidate in "\${sockets[@]}"; do
    [[ "$candidate" == *-eph-* ]] && continue
    [[ -S "$candidate" ]] || continue
    printf '%s' "$candidate"
    return 0
  done
  return 1
}
resolve_window_socket() {
  local session="$1"
  local window="$2"
  local candidate win_name win_index
  candidate="$(socket_for "$session" "$window")"
  if [[ -S "$candidate" ]]; then printf '%s' "$candidate"; return 0; fi
  if [[ "$window" =~ ^[0-9]+$ ]]; then
    win_name="$(tmux list-windows -t "$session" -F '#{window_index}:#{window_name}' 2>/dev/null | awk -F: -v w="$window" '$1 == w {print $2; exit}')"
    if [[ -n "$win_name" ]]; then
      candidate="$(socket_for "$session" "$win_name")"
      if [[ -S "$candidate" ]]; then printf '%s' "$candidate"; return 0; fi
    fi
  else
    win_index="$(tmux list-windows -t "$session" -F '#{window_index}:#{window_name}' 2>/dev/null | awk -F: -v w="$window" '$2 == w {print $1; exit}')"
    if [[ -n "$win_index" ]]; then
      candidate="$(socket_for "$session" "$win_index")"
      if [[ -S "$candidate" ]]; then printf '%s' "$candidate"; return 0; fi
    fi
  fi
  return 1
}
if [[ -z "$target" ]]; then
  echo 'remote tell target missing' >&2
  exit 2
fi
if [[ "$target" == *:* ]]; then
  session="\${target%%:*}"
  window="\${target#*:}"
  socket_path="$(resolve_window_socket "$session" "$window")" || true
else
  session="$target"
  socket_path="$(first_session_socket "$session")" || true
fi
if [[ -z "$socket_path" || ! -S "$socket_path" ]]; then
  echo "No Pi socket found for $target on $(hostname -s 2>/dev/null || hostname)" >&2
  echo "Available sockets:" >&2
  if [[ -d "$sockets_dir" ]]; then
    ls "$sockets_dir"/"$prefix"-*.sock 2>/dev/null | sed 's/^/  /' >&2 || true
  else
    echo "  (socket dir missing: $sockets_dir)" >&2
  fi
  exit 3
fi
printf '__TELL_SOCKET__ %s\n' "$socket_path"
PI_TELL_SOCKET="$socket_path" PI_TELL_PAYLOAD_B64="$payload_b64" node -e ${shellQuote(REMOTE_TELL_NODE)}
`;

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
	const localTarget = `${session}:${window}`;
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
		timestamp: Math.floor(Date.now() / 1000),
	};
	if (options.includeFromSocket) payload.fromSocket = await currentSocketPath();
	return payload;
};

const normalizeRoute = (route: TellRoute): TellRoute => {
	if (route.machine && isLocalMachine(route.machine)) {
		return { target: route.target, message: route.message };
	}
	return route;
};

const routeFromTargetHint = (
	targetText: string | undefined,
	message: string,
	machine?: string,
): TellRoute => {
	const trimmedTarget = targetText?.trim();
	if (!trimmedTarget) return normalizeRoute({ machine, message });

	const words = trimmedTarget.split(/\s+/).filter(Boolean);
	if (!machine && words.length >= 2 && looksLikeMachineTarget(words[0])) {
		return normalizeRoute({
			machine: words[0],
			target: words.slice(1).join(" "),
			message,
		});
	}

	return normalizeRoute({ machine, target: trimmedTarget, message });
};

const sendTell = async (
	ctx: ExtensionContext,
	rawRoute: TellRoute,
): Promise<SendResult> => {
	const route = normalizeRoute(rawRoute);
	if (route.machine) {
		if (!route.target?.trim()) {
			return {
				ok: false,
				error: `Remote tell target missing for ${route.machine}. Usage: /tell ${route.machine} <tmux-session[:window]> <message>`,
			};
		}

		const id = makeMessageId();
		const payload = await buildTellPayload(ctx, route.message, id, {
			includeMachineReply: true,
			includeFromSocket: false,
		});
		const response = await sendRemoteJsonLine(
			route.machine,
			route.target,
			payload,
		);
		const target: Candidate = {
			socket: response.socket || `${route.machine}:${route.target}`,
			id: `${route.machine} ${route.target}`,
			label: `${route.machine} ${route.target}${response.socket ? ` — ${response.socket}` : ""}`,
			searchText: `${route.machine} ${route.target}`.toLowerCase(),
			current: false,
			reachable: response.ok,
		};
		const ok =
			response.ok &&
			response.response !== null &&
			typeof response.response === "object" &&
			"ok" in response.response &&
			(response.response as { ok?: unknown }).ok === true;
		if (!ok) {
			return {
				ok: false,
				target,
				id,
				response,
				error:
					response.error ||
					`Remote target rejected tell payload: ${JSON.stringify(response.response)}`,
			};
		}
		return { ok: true, target, id, response: response.response };
	}

	const selection = await selectCandidate(route.target, ctx);
	if (selection.ok === false) {
		return { ok: false, error: selection.error };
	}
	const target = selection.candidate;

	const id = makeMessageId();
	const payload = await buildTellPayload(ctx, route.message, id, {
		includeMachineReply: false,
		includeFromSocket: true,
	});

	try {
		const response = await sendJsonLine(target.socket, payload);
		const ok =
			response !== null &&
			typeof response === "object" &&
			"ok" in response &&
			(response as { ok?: unknown }).ok === true;
		if (!ok) {
			return {
				ok: false,
				target,
				id,
				response,
				error: `Target rejected tell payload: ${JSON.stringify(response)}`,
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

const splitCommandArgs = (args: string): Partial<TellRoute> => {
	const trimmed = args.trim();
	if (!trimmed) return {};
	const normalized = trimmed.replace(/^to\s+/i, "");
	const tokens = normalized.match(/^(\S+)(?:\s+(\S+))?(?:\s+([\s\S]+))?$/);
	if (!tokens) return {};
	const [, first, second, rest] = tokens;
	if (looksLikeMachineTarget(first) && second) {
		return { machine: first, target: second, message: rest };
	}
	if (second)
		return { target: first, message: [second, rest].filter(Boolean).join(" ") };
	return { target: first };
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
			let target = parsed.target;
			let message = parsed.message;

			if (!message?.trim()) {
				if (!ctx.hasUI) {
					ctx.ui.notify("Usage: /tell [machine] <target> <message>", "error");
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

			const result = await sendTell(ctx, { machine, target, message });
			if (!result.ok) {
				ctx.ui.notify(
					`Tell failed: ${result.error || "unknown error"}`,
					"error",
				);
				return;
			}

			pi.appendEntry("tell-message", {
				id: result.id,
				direction: "sent",
				target: result.target?.label,
				socket: result.target?.socket,
				message,
				timestamp: Date.now(),
			});
			ctx.ui.notify(`Told ${result.target?.label}`, "info");
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
					description:
						"Optional machine/SSH host, e.g. megabookpro or workbookpro.",
				}),
			),
			target: Type.Optional(
				Type.String({
					description:
						"Pi target hint such as machine + session, session, session:window, cwd basename, pane, or loose description.",
				}),
			),
			message: Type.String({ description: "Guidance/prompt to send." }),
		}),
		async execute(...args) {
			const [, params, , , ctx] = args;
			const result = await sendTell(
				ctx,
				routeFromTargetHint(params.target, params.message, params.machine),
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
}
