import { afterAll, describe, expect, spyOn, test } from "bun:test";
import * as childProcess from "node:child_process";
import { execFileSync } from "node:child_process";
import { mkdir, mkdtemp, readFile, writeFile } from "node:fs/promises";
import crypto from "node:crypto";
import net from "node:net";
import type { ExtensionAPI, ExtensionCommandContext, ExtensionContext } from "@earendil-works/pi-coding-agent";

const { visibleWidth } = await import("@earendil-works/pi-tui");

const stateDir = await mkdtemp("/tmp/pi-tell-");

const previousStateDir = process.env.PI_STATE_DIR;

const previousSocket = process.env.PI_SOCKET;

process.env.PI_STATE_DIR = stateDir;

process.env.PI_SOCKET = `${stateDir}/self.sock`;

const { default: extension, _test } = await import("../agent/extensions/tell.ts");

const servers: net.Server[] = [];

afterAll(async () => {
	await Promise.all(servers.map((server) => new Promise<void>((resolve) => server.close(() => resolve()))));

	if (previousStateDir === undefined) delete process.env.PI_STATE_DIR;
	else process.env.PI_STATE_DIR = previousStateDir;

	if (previousSocket === undefined) delete process.env.PI_SOCKET;
	else process.env.PI_SOCKET = previousSocket;

	execFileSync("trash", [stateDir]);
});

const now = Date.parse("2026-09-01T12:00:00Z");

const candidate = (pane: string, statusUpdatedAt?: string, reachable = true, current = false) => _test.buildCandidate(
	`${stateDir}/sockets/pi-work-agent-${pane}.sock`,
	{
		session: "work",
		window: "agent",
		windowIndex: "0",
		pane,
		paneIndex: pane.slice(1),
		sessionName: "Fix auth",
		cwd: "/project",
		state: "working",
		statusUpdatedAt,
		heartbeatAt: now + 100_000,
	},
	current ? `${stateDir}/sockets/pi-work-agent-${pane}.sock` : null,
	reachable,
);

const context = (select: (title: string, options: string[]) => Promise<string | undefined>, hasUI = true): ExtensionContext => {
	// SAFETY: selection tests only use hasUI, mode, and ui.select.
	return { mode: "rpc", hasUI, ui: { select } } as ExtensionContext;
};

const neverSelect = async () => {
	throw new Error("Unexpected picker");
};

describe("tell activity ordering", () => {
	test("keeps bridge state and activity time separate from reachability", () => {
		const item = candidate("%0", "2026-09-01T11:00:00Z");

		expect(item.state).toBe("working");
		expect(item.statusUpdatedAt).toBe("2026-09-01T11:00:00Z");
		expect(candidate("%1", item.statusUpdatedAt, false).state).toBe("orphaned/unreachable");
	});

	test("sorts activity newest first, unknown last, without using heartbeat", () => {
		const older = candidate("%0", "2026-09-01T10:00:00Z");
		const newer = candidate("%1", "2026-09-01T11:00:00Z");
		const unknown = candidate("%2");
		const invalid = candidate("%3", "invalid");
		const current = candidate("%4", "2026-09-01T12:00:00Z", true, true);
		const offline = candidate("%5", "2026-09-01T12:00:00Z", false);

		expect([offline, unknown, older, current, invalid, newer].sort(_test.compareCandidates)).toEqual([
			newer, older, unknown, invalid, current, offline,
		]);
	});

	test("no-target picker sorts supplied inventory and excludes self and unreachable peers", async () => {
		const older = candidate("%0", "2026-09-01T10:00:00Z");
		const newer = candidate("%1", "2026-09-01T11:00:00Z");

		const ctx = context(async (title, options) => {
			expect(title).toContain("latest activity first");
			expect(options).toEqual([newer.label, older.label]);

			return options[0];
		});

		const result = await _test.selectCandidate(undefined, ctx, [older, candidate("%2", undefined, false), candidate("%3", undefined, true, true), newer]);

		expect(result).toEqual({ ok: true, candidate: newer });
	});
});

describe("tell picker display and routing", () => {
	test("shows zero-based tmux addresses, state, name and honest activity age", () => {
		const item = candidate("%0", "2026-09-01T11:58:00Z");
		item.state = "input_needed";
		const row = _test.pickerItem(item, now);

		expect(row.value).toBe(item.socket);
		expect(row.label).toBe("work:0.0 %0");
		expect(row.description).toContain("needs input");
		expect(row.description).toContain("2m ago");
		expect(row.description).toContain("Fix auth");
		expect(_test.pickerItem(candidate("%2"), now).description).toContain("activity unknown");
	});

	test("replaces control characters in picker metadata", () => {
		const item = candidate("%0");
		item.sessionName = "name\n\x1b[2J";

		expect(_test.pickerItem(item, now).description).not.toMatch(/\p{Cc}/u);
	});

	test("an exact selected socket wins even over a peer with that logical name", async () => {
		const chosen = candidate("%0");
		const sibling = candidate("%1");
		sibling.sessionName = chosen.socket;
		const result = await _test.selectCandidate(chosen.socket, context(neverSelect), [sibling, chosen]);

		expect(result).toEqual({ ok: true, candidate: chosen });
	});

	test("ambiguous window targets still require selection", async () => {
		const first = candidate("%0");
		const second = candidate("%1");

		const result = await _test.selectCandidate("work:agent", context(async (_title, options) => {
			expect(options).toHaveLength(2);

			return second.label;
		}), [first, second]);

		expect(result).toEqual({ ok: true, candidate: second });
	});

	test("cancelled and headless selection stay fail-closed", async () => {
		const inventory = [candidate("%0")];

		expect((await _test.selectCandidate(undefined, context(async () => undefined), inventory)).ok).toBe(false);
		expect((await _test.selectCandidate(undefined, context(neverSelect, false), inventory)).ok).toBe(false);
	});

	test.each(["\x1b[B", "j", "k"])("custom TUI navigation %s renders bounded rows and returns the exact socket", async (key) => {
		const choices = [candidate("%0"), candidate("%1")];
		let selected: string | undefined;

		// SAFETY: this fixture implements the custom picker APIs used by pickCandidate.
		const ctx = {
			mode: "tui",
			hasUI: true,
			ui: {
				async custom(factory) {
					const component = factory(
						{ terminal: { rows: 24 }, requestRender() {} },
						{ fg: (_color: string, text: string) => text },
						{ matches: (data: string, key: string) => data === "\r" && key === "tui.select.confirm" },
						(value: string | undefined) => { selected = value; },
					);

					component.handleInput(key);

					for (const width of [20, 40, 80, 120]) {
						const lines = component.render(width);

						expect(lines.every((line: string) => visibleWidth(line) <= width)).toBe(true);
						expect(lines.join("\n")).toContain("/project");
						expect(lines.join("\n")).toContain("Fix auth");
					}

					component.handleInput("\r");

					return selected;
				},
			},
		} as ExtensionContext;

		expect(await _test.pickCandidate(choices, ctx, "Select Pi instance")).toBe(choices[1]);
	});
});

type PreviewResponse = {
	ok: boolean;
	type?: string;
	protocol?: string;
	id?: string;
	operation?: string;
	error?: string;
	data?: { message: { content: string } | null };
};

type PreviewRequest = {
	payload: { id: string; operation: string; type: string; protocol: string };
	reply: (response: PreviewResponse) => Promise<void>;
};

const deferred = <T,>() => {
	let resolve!: (value: T) => void;
	const promise = new Promise<T>((done) => { resolve = done; });

	return { promise, resolve };
};

let previewPeerCount = 0;

const previewPeer = async (onRequest: (request: PreviewRequest) => void) => {
	const peer = candidate(`%preview${++previewPeerCount}`);
	peer.socket = `${stateDir}/preview-${previewPeerCount}.sock`;

	const server = net.createServer((socket) => {
		let buffer = "";

		socket.on("data", (chunk) => {
			buffer += chunk.toString();

			if (!buffer.includes("\n")) return;
			onRequest({
				payload: JSON.parse(buffer.trim()),
				reply: (response) => new Promise<void>((resolve) => {
					socket.once("close", resolve);
					socket.end(`${JSON.stringify(response)}\n`);
				}),
			});
		});
	});

	servers.push(server);
	await new Promise<void>((resolve, reject) => {
		server.once("error", reject);
		server.listen(peer.socket, resolve);
	});

	return peer;
};

const lastMessageResponse = (request: PreviewRequest, content: string | null) => ({
	ok: true,
	type: "control_response",
	protocol: "pi.control.v1",
	id: request.payload.id,
	operation: request.payload.operation,
	data: { message: content === null ? null : { content } },
});

type PickerFixture = {
	render: (width: number) => string[];
	handleInput: (data: string) => void;
	dispose: () => void;
	renderCount: () => number;
	resize: (rows: number) => void;
};

const withPicker = async (
	choices: ReturnType<typeof candidate>[],
	run: (picker: PickerFixture) => Promise<void>,
	rows = 24,
) => {
	let selected: string | undefined;

	// SAFETY: the fixture implements the APIs used by the custom picker.
	const ctx = {
		mode: "tui",
		hasUI: true,
		ui: {
			async custom(factory) {
				let renders = 0;
				const terminal = { rows };

				const component = factory(
					{ terminal, requestRender() { renders += 1; } },
					{ fg: (_color: string, text: string) => text },
					{ matches: (data: string, key: string) => (data === "\r" && key === "tui.select.confirm") || (data === "\x1b" && key === "tui.select.cancel") },
					(value: string | undefined) => { selected = value; },
				);

				try {
					await run({ ...component, renderCount: () => renders, resize: (height: number) => { terminal.rows = height; } });
				} finally {
					component.dispose();
				}

				return selected;
			},
		},
	} as ExtensionContext;

	return _test.pickCandidate(choices, ctx, "Select Pi instance");
};

describe("tell highlighted session preview", () => {
	test("fetches the initial highlight and wraps the full logical UUID at narrow widths", async () => {
		const received = deferred<PreviewRequest>();
		const peer = await previewPeer(received.resolve);
		peer.sessionId = "01a0c3f4-f229-7745-82ff-232f32b6859c";

		const selected = await withPicker([peer], async (picker) => {
			expect(picker.render(80).join("\n")).toContain("Loading...");
			const request = await received.promise;
			expect(request.payload).toMatchObject({ type: "control", protocol: "pi.control.v1", operation: "message.last" });
			await request.reply(lastMessageResponse(request, "Initial highlighted reply"));

			for (const width of [12, 20, 40, 80, 120]) {
				const lines = picker.render(width);
				expect(lines.every((line) => visibleWidth(line) <= width)).toBe(true);
				expect(lines.join("").replace(/\s/g, "")).toContain(peer.sessionId);
			}

			expect(picker.render(80).join("\n")).toContain("Initial highlighted reply");
			picker.handleInput("\r");
		});

		expect(selected).toBe(peer);
	});

	test.each(["\x1b[B", "j", "k"])("navigation %s clears the preview and ignores late responses", async (key) => {
		const firstRequest = deferred<PreviewRequest>();
		const secondRequest = deferred<PreviewRequest>();
		const first = await previewPeer(firstRequest.resolve);
		const second = await previewPeer(secondRequest.resolve);

		await withPicker([first, second], async (picker) => {
			const oldRequest = await firstRequest.promise;
			picker.handleInput(key);
			expect(picker.render(80).join("\n")).toContain("Loading...");
			const newRequest = await secondRequest.promise;
			await newRequest.reply(lastMessageResponse(newRequest, "Second session reply"));
			expect(picker.render(80).join("\n")).toContain("Second session reply");
			const renders = picker.renderCount();
			await oldRequest.reply(lastMessageResponse(oldRequest, "Wrong first session reply"));
			expect(picker.renderCount()).toBe(renders);
			expect(picker.render(80).join("\n")).not.toContain("Wrong first");
			picker.handleInput("\x1b");
		});
	});

	test("returning to the first row ignores its older in-flight request", async () => {
		const oldFirst = deferred<PreviewRequest>();
		const newFirst = deferred<PreviewRequest>();
		const secondRequest = deferred<PreviewRequest>();
		const firstRequests = [oldFirst, newFirst];
		const first = await previewPeer((request) => firstRequests.shift()!.resolve(request));
		const second = await previewPeer(secondRequest.resolve);

		await withPicker([first, second], async (picker) => {
			const oldRequest = await oldFirst.promise;
			picker.handleInput("j");
			const middleRequest = await secondRequest.promise;
			picker.handleInput("k");
			const newRequest = await newFirst.promise;
			await newRequest.reply(lastMessageResponse(newRequest, "Fresh first reply"));
			await oldRequest.reply(lastMessageResponse(oldRequest, "Stale first reply"));
			await middleRequest.reply(lastMessageResponse(middleRequest, "Second reply"));
			expect(picker.render(80).join("\n")).toContain("Fresh first reply");
			expect(picker.render(80).join("\n")).not.toContain("Stale first");
		});
	});

	test.each(["cancel", "select", "dispose"])("late completions do not render after %s", async (action) => {
		const received = deferred<PreviewRequest>();
		const peer = await previewPeer(received.resolve);

		await withPicker([peer], async (picker) => {
			const request = await received.promise;

			if (action === "dispose") picker.dispose();
			else picker.handleInput(action === "cancel" ? "\x1b" : "\r");
			const renders = picker.renderCount();
			await request.reply(lastMessageResponse(request, "Late reply"));
			picker.handleInput("j");
			expect(picker.renderCount()).toBe(renders);
		});
	});

	test.each([
		["empty", "No assistant message yet."],
		["legacy", "target needs pi.control.v1 reload"],
		["invalid", "Preview unavailable."],
		["error", "Preview unavailable."],
	] as const)("shows explicit %s state and unknown session IDs", async (kind, expected) => {
		const received = deferred<PreviewRequest>();
		const peer = await previewPeer(received.resolve);

		await withPicker([peer], async (picker) => {
			const request = await received.promise;
			const response = lastMessageResponse(request, kind === "empty" ? null : "Rejected private text");
			await request.reply(kind === "legacy" ? { ok: false, error: "unsupported payload type: control" }
				: kind === "invalid" ? { ...response, id: "wrong-id" }
					: kind === "error" ? { ...response, ok: false, error: "Peer refused request" } : response);
			const rendered = picker.render(120).join("\n");
			expect(rendered).toContain(expected);
			expect(rendered).toContain("Session ID: unknown");
			expect(rendered).not.toContain("Rejected private text");
			expect(rendered).not.toContain("Peer refused request");
		});
	});

	test("sanitizes controls, bounds long responses and fits typical terminal sizes", async () => {
		const received = deferred<PreviewRequest>();
		const peer = await previewPeer(received.resolve);

		await withPicker([peer], async (picker) => {
			const request = await received.promise;
			await request.reply(lastMessageResponse(request, `Safe\x1b[2J\x1b]52;c;YWJj\x07\x00\b\u202e text\n${"界😀 ".repeat(2000)}`));

			for (const width of [20, 40, 80]) {
				const lines = picker.render(width);
				expect(lines.every((line) => visibleWidth(line) <= width)).toBe(true);
				expect(lines.length).toBeLessThanOrEqual(24);

				for (const control of ["\x00", "\x07", "\x08", "\u202e", "\x1b[2J", "\x1b]52"]) {
					expect(lines.join("\n")).not.toContain(control);
				}

				expect(lines.join("\n")).toContain("[Preview truncated]");
			}
		});
	});

	test("keeps the full UUID and some reply text visible in short panes and after resize", async () => {
		const received = deferred<PreviewRequest>();
		const peer = await previewPeer(received.resolve);
		peer.sessionId = "01a0c3f4-f229-7745-82ff-232f32b6859c";
		const choices = [peer, ...Array.from({ length: 9 }, (_, index) => candidate(`%resize${index}`))];

		await withPicker(choices, async (picker) => {
			const request = await received.promise;
			await request.reply(lastMessageResponse(request, "Visible reply text ".repeat(100)));

			for (const [width, height] of [[80, 24], [40, 16], [20, 16], [20, 13]]) {
				picker.resize(height);
				const lines = picker.render(width);
				expect(lines.length).toBeLessThanOrEqual(height);
				expect(lines.every((line) => visibleWidth(line) <= width)).toBe(true);
				expect(lines.join("").replace(/\s/g, "")).toContain(peer.sessionId);
				expect(lines.join("\n")).toContain("Visible reply");
			}
		});
	});

	test("reports unreachable sockets without opening another selector", async () => {
		const peer = candidate("%missing");
		const result = await _test.requestCandidateControl(peer, "message.last");

		expect(result.ok).toBe(false);
		expect(result.target).toBe(peer);
		expect(result.error).toContain("ENOENT");
	});

	test("routes a remote highlight over SSH to its exact socket", async () => {
		const peer = candidate("%remote");
		peer.machine = "remote-preview.example";
		peer.socket = "/tmp/exact remote.sock";

		const exec = spyOn(childProcess, "execFile").mockImplementation((_file, args, _options, callback) => {
			expect(_file).toBe("ssh");
			expect(args).toContain(peer.machine);
			const command = args.at(-1);
			expect(command).toContain(peer.socket);
			const encoded = command.match(/payload_b64=[^\n]*?(ey[A-Za-z0-9+/]+=*)/)?.[1];
			expect(encoded).toBeDefined();
			const request = JSON.parse(Buffer.from(encoded!, "base64").toString());
			expect(request.operation).toBe("message.last");
			callback(null, JSON.stringify({ ...request, type: "control_response", ok: true, data: { message: { content: "Remote reply" } } }), "");

			return new childProcess.ChildProcess();
		});

		try {
			const result = await _test.requestCandidateControl(peer, "message.last");
			expect(result).toMatchObject({ ok: true });
			expect(_test.controlLastMessage(result.response)?.content).toBe("Remote reply");
			expect(exec).toHaveBeenCalledTimes(1);
		} finally {
			exec.mockRestore();
		}
	});
});

test("bare /tell selects once and sends only to the chosen same-window pane", async () => {
	await mkdir(`${stateDir}/sockets`, { recursive: true });
	await mkdir(`${stateDir}/manifests`, { recursive: true });

	const received: string[] = [];

	for (const pane of ["%800001", "%800002"]) {
		const peer = candidate(pane, "2026-09-01T11:00:00Z");

		const server = net.createServer((socket) => {
			let buffer = "";

			socket.on("data", (chunk) => {
				buffer += chunk.toString();

				if (!buffer.includes("\n")) return;

				const request = JSON.parse(buffer.trim());

				if (request.type === "ping") {
					socket.end('{"ok":true}\n');

					return;
				}

				received.push(pane);
				socket.end(`${JSON.stringify({ ok: true, type: "control_response", protocol: "pi.control.v1", id: request.id, operation: request.operation, data: {} })}\n`);
			});
		});

		servers.push(server);
		await new Promise<void>((resolve, reject) => {
			server.once("error", reject);
			server.listen(peer.socket, resolve);
		});
		await writeFile(`${stateDir}/manifests/${pane}.info`, JSON.stringify({ ...peer.manifest, socket: peer.socket, pid: 900000 + Number(pane.slice(1)) }));
	}

	let handler: ((args: string, ctx: ExtensionCommandContext) => Promise<void>) | undefined;
	// SAFETY: registration only uses these APIs; the test invokes only the tell command.
	extension({
		on() {},
		registerCommand(name, command) { if (name === "tell") handler = command.handler; },
		registerTool() {},
		appendEntry() {},
	} as ExtensionAPI);

	let selections = 0;
	const notifications: string[] = [];

	// SAFETY: the bare tell command only reads these UI and session methods.
	const ctx = {
		mode: "rpc",
		hasUI: true,
		cwd: "/project",
		sessionManager: { getSessionId: () => "sender", getSessionName: () => "Sender" },
		ui: {
			async select(_title: string, options: string[]) {
				selections += 1;

				return options.find((option) => option.includes("%800002"));
			},
			async editor() { return "Review this change"; },
			notify(text: string) { notifications.push(text); },
		},
	} as ExtensionCommandContext;

	expect(handler).toBeDefined();
	await handler!("", ctx);

	expect(selections).toBe(1);
	expect(received).toEqual(["%800002"]);
	expect(notifications.at(-1)).toStartWith("Told ");

	// A peer disappearing during composition must not reroute to a namesake.
	ctx.ui.editor = async () => {
		await new Promise<void>((resolve) => servers.at(-1)!.close(() => resolve()));
		execFileSync("trash", [`${stateDir}/manifests/%800002.info`]);

		const namesake = candidate("%800001");
		await writeFile(`${stateDir}/manifests/%800001.info`, JSON.stringify({
			...namesake.manifest,
			socket: namesake.socket,
			sessionName: candidate("%800002").socket,
			pid: 900000 + 800001,
		}));

		return "Do not reroute this";
	};

	await handler!("", ctx);

	expect(selections).toBe(2);
	expect(received).toEqual(["%800002"]);
	expect(notifications.at(-1)).toStartWith("Tell failed:");
}, 15_000);

const discoveryPeer = async (name: string, pid: number) => {
	await mkdir(`${stateDir}/sockets`, { recursive: true });
	await mkdir(`${stateDir}/manifests`, { recursive: true });
	const socketPath = `${stateDir}/sockets/pi-${name}.sock`;
	const manifest = { socket: socketPath, pid, session: "owner", window: "old" };

	const server = net.createServer((socket) => {
		socket.once("data", () => socket.end('{"ok":true}\n'));
	});

	servers.push(server);
	await new Promise<void>((resolve, reject) => {
		server.once("error", reject);
		server.listen(socketPath, resolve);
	});
	await writeFile(`${stateDir}/manifests/${name}.info`, JSON.stringify(manifest));

	return manifest;
};

const paneRow = (session: string, pane: string, pid: number) => ({
	session, pane, pid, window: "renamed", windowName: "renamed", windowIndex: "2", paneIndex: "0", title: "Working", cwd: "/project",
});

describe("tell discovery recovery", () => {
	test("correlates legacy manifests by exact PID and chooses their linked tmux owner", async () => {
		const manifest = await discoveryPeer("legacy-pid", 990001);
		const panes = ["alias-a", "alias-b", "owner", "alias-c", "alias-d"].map((session) => paneRow(session, "%legacy", manifest.pid));
		const inventory = await _test.discoverCandidates(async () => panes);
		const matches = inventory.filter((item) => item.pid === manifest.pid);

		expect(matches).toHaveLength(1);
		expect(matches[0]).toMatchObject({ socket: manifest.socket, session: "owner", pane: "%legacy", window: "renamed", reachable: true });
	});

	test("recovers a moved pane when the manifest's owning session no longer exists", async () => {
		const manifest = await discoveryPeer("moved", 990002);
		await writeFile(`${stateDir}/manifests/moved.info`, JSON.stringify({ ...manifest, pane: "%moved" }));
		const inventory = await _test.discoverCandidates(async () => [paneRow("new-owner", "%moved", manifest.pid)]);
		const matches = inventory.filter((item) => item.pid === manifest.pid);

		expect(matches).toHaveLength(1);
		expect(matches[0]).toMatchObject({ socket: manifest.socket, session: "new-owner", pane: "%moved", reachable: true });
		expect(matches[0].searchText).toContain("new-owner");
	});

	test("replaces stale pane metadata with a recovered live socket without duplicate orphan rows", async () => {
		const manifest = await discoveryPeer("alias-renamed-%restart", 990005);
		execFileSync("trash", [`${stateDir}/manifests/alias-renamed-%restart.info`]);
		const staleSocket = `${stateDir}/sockets/pi-retired.sock`;
		await writeFile(`${stateDir}/manifests/retired.info`, JSON.stringify({ socket: staleSocket, session: "owner", window: "old", pid: manifest.pid, pane: "%restart" }));
		const inventory = await _test.discoverCandidates(async () => [paneRow("owner", "%restart", manifest.pid), paneRow("alias", "%restart", manifest.pid)]);

		expect(inventory.some((item) => item.socket === staleSocket)).toBe(false);
		expect(inventory.filter((item) => item.pane === "%restart")).toHaveLength(1);
		expect(inventory.find((item) => item.socket === manifest.socket)).toMatchObject({ reachable: true, pid: manifest.pid, pane: "%restart" });
	});

	test("excludes a manifestless self socket after linked-pane PID enrichment", async () => {
		const manifest = await discoveryPeer("alias-renamed-%selfenriched", process.pid);
		execFileSync("trash", [`${stateDir}/manifests/alias-renamed-%selfenriched.info`]);
		const inventory = await _test.discoverCandidates(async () => [paneRow("primary", "%selfenriched", process.pid), paneRow("alias", "%selfenriched", process.pid)]);
		const self = inventory.find((item) => item.socket === manifest.socket)!;

		expect(self.current).toBe(true);
		expect(self.pid).toBe(process.pid);
		expect((await _test.selectCandidate(undefined, context(neverSelect, false), [self])).ok).toBe(false);
	});

	test("uses PID for self identity when reconstructed socket paths differ", () => {
		const self = _test.buildCandidate("/tmp/legacy-self.sock", { pid: process.pid }, "/tmp/new-name.sock", true);

		expect(self.current).toBe(true);
	});

	test("prefers an exact process owner over conflicting stale pane metadata", async () => {
		const wrong = await discoveryPeer("wrong-owner", 990006);
		const right = await discoveryPeer("right-owner", 990007);
		await writeFile(`${stateDir}/manifests/wrong-owner.info`, JSON.stringify({ ...wrong, pane: "%conflict", statusUpdatedAt: "2099-01-01T00:00:00Z" }));
		const inventory = await _test.discoverCandidates(async () => [paneRow("owner", "%conflict", right.pid)]);

		expect(inventory.find((item) => item.socket === right.socket)).toMatchObject({ pane: "%conflict", window: "renamed", pid: right.pid });
		expect(inventory.find((item) => item.socket === wrong.socket)?.window).toBe("old");
	});

	test("does not assign an inferred socket to a conflicting manifest PID", async () => {
		const wrong = await discoveryPeer("owner-renamed-%inferred", 990010);
		const inventory = await _test.discoverCandidates(async () => [paneRow("owner", "%inferred", 990011)]);

		expect(inventory.find((item) => item.socket === wrong.socket)).toMatchObject({ pid: wrong.pid, window: "old" });
		expect(inventory.some((item) => item.pid === 990011 && item.reachable)).toBe(false);
	});

	test("a stale ephemeral pane does not hide a replacement process", async () => {
		await writeFile(`${stateDir}/manifests/dead-ephemeral.info`, JSON.stringify({ socket: `${stateDir}/missing-eph.sock`, ephemeral: true, pane: "%reused", pid: 990008 }));
		const inventory = await _test.discoverCandidates(async () => [paneRow("owner", "%reused", 990009)]);

		expect(inventory.find((item) => item.pane === "%reused")).toMatchObject({ pid: 990009, reachable: false });
	});

	test("does not reintroduce ephemeral manifests through process discovery", async () => {
		const manifest = await discoveryPeer("hidden", 990003);
		await writeFile(`${stateDir}/manifests/hidden.info`, JSON.stringify({ ...manifest, ephemeral: true }));
		const inventory = await _test.discoverCandidates(async () => [paneRow("owner", "%hidden", manifest.pid)]);

		expect(inventory.some((item) => item.pid === manifest.pid)).toBe(false);
	});

	test("rejects malformed manifest field types at the file boundary", async () => {
		const file = `${stateDir}/bad-manifest.info`;

		for (const value of [null, [], { socket: 12 }, { socket: "/tmp/a", sessionName: {} }, { socket: "/tmp/a", pid: "12" }]) {
			await writeFile(file, JSON.stringify(value));
			expect(await _test.readManifest(file)).toBeNull();
		}
	});

	test("accepts bridge runtime metadata before tell has loaded", async () => {
		const file = `${stateDir}/runtime.info`;
		const manifest = { socket: "/tmp/runtime.sock", startedAt: 123, bridge: { version: "bridge.v2", loadedAt: "2026-09-01T00:00:00Z", sourceHash: null }, tell: null };
		await writeFile(file, JSON.stringify(manifest));

		expect(await _test.readManifest(file)).toEqual(manifest);
	});

	test("process inventory uses comm and never matches a tool argument mentioning pi", async () => {
		const run = (file, args, _options, callback) => {
			if (file === "tmux") callback(null, "owner\t0\twork\t%one\t0\tWork\t100\t/project\nowner\t1\twork\t%two\t0\tWork\t200\t/project", "");
			else {
				expect(args).toEqual(["-axo", "pid=,ppid=,comm="]);
				callback(null, "100 1 /bin/sh\n101 100 /opt/pi\n200 1 /bin/sh\n201 200 /usr/bin/printf pi", "");
			}

			return new childProcess.ChildProcess();
		};

		const rows = await _test.listTmuxPanes(run);

		expect(rows).toHaveLength(1);
		expect(rows[0]).toMatchObject({ pane: "%one", pid: 101 });
	});

	test("ignores an inherited marked socket and uses a process-specific headless path", async () => {
		const previous = { socket: process.env.PI_SOCKET, owner: process.env.PI_SOCKET_OWNER_PID, tmux: process.env.TMUX };
		process.env.PI_SOCKET = "/tmp/parent.sock";
		process.env.PI_SOCKET_OWNER_PID = String(process.pid + 1);
		delete process.env.TMUX;

		try {
			expect(await _test.currentSocketPath()).toBe(`${stateDir}/sockets/pi-process-${process.pid}.sock`);
			process.env.PI_SOCKET_OWNER_PID = String(process.pid);
			expect(await _test.currentSocketPath()).toBe("/tmp/parent.sock");
		} finally {
			if (previous.socket === undefined) delete process.env.PI_SOCKET;
			else process.env.PI_SOCKET = previous.socket;

			if (previous.owner === undefined) delete process.env.PI_SOCKET_OWNER_PID;
			else process.env.PI_SOCKET_OWNER_PID = previous.owner;

			if (previous.tmux === undefined) delete process.env.TMUX;
			else process.env.TMUX = previous.tmux;
		}
	});

	test("bounds Unicode socket names by UTF-8 bytes without splitting codepoints", () => {
		const socket = _test.buildSocketPath("界😀".repeat(70), "window", "%1");

		expect(Buffer.byteLength(socket)).toBeLessThanOrEqual(103);
		expect(socket).not.toContain("�");
		expect(socket).toMatch(/-[a-f0-9]{8}\.sock$/);
		expect(_test.buildSocketPath("界😀".repeat(70), "window", "%2")).not.toBe(socket);
	});
});

let boundedPeerCount = 0;

const withBoundedPeer = async (mode: string, connections: number, run: (socketPath: string) => Promise<void>) => {
	const socketPath = `${stateDir}/bounds-${++boundedPeerCount}.sock`;
	const sockets = new Set<net.Socket>();
	const closed = deferred<void>();
	let closedCount = 0;

	const server = net.createServer((socket) => {
		sockets.add(socket);
		let drip: ReturnType<typeof setInterval> | undefined;
		socket.on("error", () => {});
		socket.once("data", () => {
			if (mode === "oversize") socket.write("x".repeat(_test.MAX_RESPONSE_BYTES + 1));
			else drip = setInterval(() => socket.write("x"), 20);
		});
		socket.once("close", () => {
			clearInterval(drip);
			sockets.delete(socket);
			closedCount += 1;

			if (closedCount === connections) closed.resolve();
		});
	});

	servers.push(server);
	await new Promise<void>((resolve) => server.listen(socketPath, resolve));
	let watchdog: ReturnType<typeof setTimeout> | undefined;

	try {
		await Promise.race([
			(async () => {
				const start = Date.now();
				await run(socketPath);
				await closed.promise;
				expect(sockets.size).toBe(0);
				expect(Date.now() - start).toBeLessThan(mode === "oversize" ? 700 : 3300);
			})(),
			new Promise<never>((_resolve, reject) => { watchdog = setTimeout(() => reject(new Error("response reader exceeded its deadline")), 3500); }),
		]);
	} finally {
		clearTimeout(watchdog);

		for (const socket of sockets) socket.destroy();
	}
};

describe("tell wire boundaries", () => {
	test.each(["drip", "oversize"])("bounds %s responses and closes every local and remote socket", async (mode) => {
		const request = _test.buildControlRequest("message.last");
		await withBoundedPeer(mode, 1, async (socket) => {
			expect(await _test.pingSocketOnce(socket)).toBe(false);
		});
		await withBoundedPeer(mode, 1, async (socket) => {
			await expect(_test.sendJsonLine(socket, request)).rejects.toThrow(mode === "drip" ? "timed out" : "exceeds");
		});
		await withBoundedPeer(mode, 1, async (socket) => {
			const result = await new Promise<{ failed: boolean; stdout: string }>((resolve) => {
				childProcess.execFile("node", ["-e", _test.REMOTE_TELL_NODE], { env: { ...process.env, PI_TELL_SOCKET: socket, PI_TELL_PAYLOAD_B64: Buffer.from(JSON.stringify(request)).toString("base64") }, timeout: 3000 }, (error, stdout) => resolve({ failed: Boolean(error), stdout }));
			});

			expect(result.failed).toBe(true);
			expect(result.stdout).toContain(mode === "drip" ? "timed out" : "exceeds");
		});
		await withBoundedPeer(mode, 2, async (socket) => {
			const remoteDir = `${stateDir}/bounded-inventory-${mode}`;
			await mkdir(`${remoteDir}/manifests`, { recursive: true });
			await mkdir(`${remoteDir}/bin`);
			await writeFile(`${remoteDir}/bin/ps`, "#!/bin/sh\nexit 0\n", { mode: 0o755 });
			await writeFile(`${remoteDir}/bin/tmux`, "#!/bin/sh\nexit 0\n", { mode: 0o755 });
			await writeFile(`${remoteDir}/manifests/peer.info`, JSON.stringify({ socket }));

			const stdout = await new Promise<string>((resolve, reject) => {
				childProcess.execFile("bash", ["-c", _test.REMOTE_INVENTORY_SCRIPT], { env: { ...process.env, PI_STATE_DIR: remoteDir, PATH: `${remoteDir}/bin:${process.env.PATH}` }, timeout: 3000 }, (error, stdout) => {
					if (error) reject(error);
					else resolve(stdout);
				});
			});

			expect(JSON.parse(stdout)[0].reachable).toBe(false);
		});
	}, 12_000);

	test("rejects SSH option destinations and separates allowed destinations from options", async () => {
		let calls = 0;
		const request = _test.buildControlRequest("message.last");

		const run = (stdout: string) => (file, args, options, callback) => {
			calls += 1;
			expect(file).toBe("ssh");
			expect(args.slice(-3, -1)).toEqual(["--", "user@remote.example"]);
			expect(options.maxBuffer).toBe(_test.MAX_RESPONSE_BYTES);
			callback(null, stdout, "");

			return new childProcess.ChildProcess();
		};

		for (const machine of ["-oProxyCommand=touch /tmp/never", " -V", ""]) {
			await expect(_test.fetchRemoteInventory(machine, run("[]"))).rejects.toThrow("Invalid SSH machine");
			expect(await _test.sendRemoteJsonLine(machine, "/tmp/peer.sock", request, run('{"ok":true}'))).toMatchObject({ ok: false, error: expect.stringContaining("Invalid SSH machine") });
		}

		expect(calls).toBe(0);
		expect(await _test.fetchRemoteInventory("user@remote.example", run("[]"))).toEqual([]);
		expect((await _test.sendRemoteJsonLine("user@remote.example", "/tmp/peer.sock", request, run('{"ok":true}'))).ok).toBe(true);
		expect(calls).toBe(2);
	});
	test("waits for fragmented ping lines", async () => {
		const socketPath = `${stateDir}/fragmented.sock`;

		const server = net.createServer((socket) => {
			socket.once("data", () => {
				socket.write('{"o');
				setTimeout(() => socket.end('k":true}\n'), 10);
			});
		});

		servers.push(server);
		await new Promise<void>((resolve) => server.listen(socketPath, resolve));
		expect(await _test.pingSocketOnce(socketPath)).toBe(true);
	});

	test("rejects malformed control data rather than leaking it into the picker", () => {
		for (const value of [null, [], { ok: "true" }, { ok: true, data: { message: { content: [] } } }, { ok: true, error: {} }]) {
			expect(() => _test.parseWireResponse(JSON.stringify(value))).toThrow();
		}

		expect(_test.parseWireResponse('{"ok":false,"error":"unsupported payload type: control"}')).toMatchObject({ ok: false });
	});

	test("reports SSH failure and malformed inventory separately from successful emptiness", async () => {
		const run = (stdout: string, error: Error | null = null) => (_file, _args, _options, callback) => {
			callback(error, stdout, error ? "Permission denied" : "");

			return new childProcess.ChildProcess();
		};

		await expect(_test.fetchRemoteInventory("remote", run("", new Error("ssh failed")))).rejects.toThrow("Permission denied");
		await expect(_test.fetchRemoteInventory("remote", run("not JSON"))).rejects.toThrow("Invalid Pi inventory from remote");
		await expect(_test.fetchRemoteInventory("remote", run('{"sessions":[]}'))).rejects.toThrow("Invalid Pi inventory");
		await expect(_test.fetchRemoteInventory("remote", run('[{"socket":null,"reachable":true}]'))).rejects.toThrow("Invalid Pi inventory");
		expect(await _test.fetchRemoteInventory("remote", run("[]"))).toEqual([]);
	});

	test("remote inventory never mistakes the remote PID for the local sender", async () => {
		const run = (_file, _args, _options, callback) => {
			callback(null, JSON.stringify([{ socket: "/tmp/remote.sock", reachable: true, pid: process.pid, windowIndex: "0", paneIndex: "1", windowName: "Remote title", statusUpdatedAt: "2026-09-01T11:00:00Z" }]), "");

			return new childProcess.ChildProcess();
		};

		const [peer] = await _test.fetchRemoteInventory("remote", run);

		expect(peer.current).toBe(false);
		expect(peer.windowName).toBe("Remote title");
		expect(peer.searchText).toContain("remote title");
	});
});

test("remote inventory script recovers legacy and linked panes without trusting stale PID liveness", async () => {
	const remoteDir = `${stateDir}/remote`;
	const bin = `${remoteDir}/bin`;

	await mkdir(`${remoteDir}/manifests`, { recursive: true });
	await mkdir(`${remoteDir}/sockets`);
	await mkdir(bin);
	await writeFile(`${bin}/ps`, '#!/bin/sh\nprintf "%s" "$TEST_PS"\n', { mode: 0o755 });
	await writeFile(`${bin}/tmux`, '#!/bin/sh\nprintf "%s" "$TEST_PANES"\n', { mode: 0o755 });
	const socketPath = `${remoteDir}/sockets/pi-legacy.sock`;

	const server = net.createServer((socket) => {
		socket.once("data", () => {
			socket.write('{"o');
			setTimeout(() => socket.end('k":true}\n'), 10);
		});
	});

	servers.push(server);
	await new Promise<void>((resolve) => server.listen(socketPath, resolve));
	await writeFile(`${remoteDir}/manifests/legacy.info`, JSON.stringify({ socket: socketPath, pid: 990099, session: "owner", window: "old", tell: null, startedAt: 123, bridge: { version: "bridge.v2", loadedAt: "2026-09-01T00:00:00Z", sourceHash: null } }));
	await writeFile(`${remoteDir}/manifests/malformed.info`, JSON.stringify({ socket: "/tmp/invalid-remote.sock", pid: "12" }));

	const env = {
		...process.env,
		PI_STATE_DIR: remoteDir,
		PATH: `${bin}:${process.env.PATH}`,
		TEST_PS: "100 1 /bin/sh\n990099 100 /opt/pi",
		TEST_PANES: ["alias", "owner", "another"].map((session) => `${session}\t2\trenamed\t%linked\t0\tWork\t100\t/project`).join("\n"),
	};

	const runScript = () => new Promise<string>((resolve, reject) => {
		childProcess.execFile("bash", ["-c", _test.REMOTE_INVENTORY_SCRIPT], { env, timeout: 5000 }, (error, stdout, stderr) => {
			if (error) reject(new Error(stderr || error.message));
			else resolve(stdout);
		});
	});

	const registered = _test.buildCandidate(socketPath, { pid: 990099, session: "owner", window: "old" }, null, true);

	const decode = (text: string) => _test.fetchRemoteInventory(registered.machine || "local", (_file, _args, _options, callback) => {
		callback(null, text, "");

		return new childProcess.ChildProcess();
	});

	const linkedPanes = env.TEST_PANES;
	env.TEST_PANES = "owner\t0\told\t%linked\t0\tWork\t100\t/project";
	const [before] = await decode(await runScript());
	env.TEST_PANES = linkedPanes;
	const inventoryText = await runScript();
	const inventory = JSON.parse(inventoryText);
	const [renamed] = await decode(inventoryText);

	expect(before.id).toBe(registered.id);
	expect(renamed.id).toBe(before.id);
	expect(renamed.socket).toBe(before.socket);
	expect(renamed.window).toBe("renamed");
	expect(inventory).toHaveLength(1);
	expect(inventory[0]).toMatchObject({ socket: socketPath, pid: 990099, reachable: true, session: "owner", pane: "%linked", window: "renamed" });

	// The owner session disappeared; keep the live socket and use its remaining tmux address.
	env.TEST_PANES = "moved\t2\trenamed\t%linked\t0\tWork\t100\t/project";
	const movedText = await runScript();
	const moved = JSON.parse(movedText);
	const [movedCandidate] = await decode(movedText);

	expect(movedCandidate.id).toBe(before.id);
	expect(movedCandidate.socket).toBe(before.socket);
	expect(movedCandidate.session).toBe("moved");
	expect(moved).toHaveLength(1);
	expect(moved[0]).toMatchObject({ socket: socketPath, reachable: true, session: "moved" });

	// No manifest or socket can be safely inferred for a headless parent-1 process.
	env.TEST_PS += "\n990100 1 /opt/pi";
	expect(JSON.parse(await runScript())).toHaveLength(1);

	await new Promise<void>((resolve) => server.close(() => resolve()));
	const recoveredSocket = `${remoteDir}/sockets/pi-moved-renamed-%linked.sock`;
	const recoveredServer = net.createServer((socket) => socket.once("data", () => socket.end('{"ok":true}\n')));
	servers.push(recoveredServer);
	await new Promise<void>((resolve) => recoveredServer.listen(recoveredSocket, resolve));
	await writeFile(`${remoteDir}/manifests/legacy.info`, JSON.stringify({ socket: socketPath, pid: 990099, pane: "%linked", session: "owner", window: "old" }));
	env.TEST_PANES = "owner\t2\trenamed\t%linked\t0\tWork\t100\t/project\nmoved\t2\trenamed\t%linked\t0\tWork\t100\t/project";
	const recovered = JSON.parse(await runScript());

	expect(recovered).toHaveLength(1);
	expect(recovered[0]).toMatchObject({ socket: recoveredSocket, pid: 990099, reachable: true, pane: "%linked" });

	env.PI_STATE_DIR = `${stateDir}/unicode`;
	env.TEST_PANES = `${"界😀".repeat(70)}\t2\twindow\t%unicode\t0\tWork\t100\t/project`;
	const unicode = JSON.parse(await runScript());

	expect(unicode).toHaveLength(1);
	expect(Buffer.byteLength(unicode[0].socket)).toBeLessThanOrEqual(103);
	expect(unicode[0].socket).not.toContain("�");

	env.PI_STATE_DIR = `${stateDir}/${"x".repeat(78 - Buffer.byteLength(stateDir) - 1)}`;
	env.TEST_PANES = "a\t0\tb\t%1\t0\tWork\t100\t/project";
	const shortName = JSON.parse(await runScript());

	expect(Buffer.byteLength(shortName[0].socket)).toBe(101);
	expect(shortName[0].socket).toEndWith("/pi-a-b-%1.sock");

	env.PI_STATE_DIR = `${stateDir}/${"long".repeat(40)}`;
	await expect(runScript()).rejects.toThrow("socket directory exceeds");

	await mkdir(`${env.PI_STATE_DIR}/manifests`, { recursive: true });
	await writeFile(`${env.PI_STATE_DIR}/manifests/override.info`, JSON.stringify({ socket: recoveredSocket, pid: 990099, session: "a" }));
	const override = JSON.parse(await runScript());

	expect(override).toHaveLength(1);
	expect(override[0]).toMatchObject({ socket: recoveredSocket, reachable: true, pid: 990099 });

	const moduleUrl = new URL("../agent/extensions/tell.ts", import.meta.url).href;
	const script = `const {_test}=await import(${JSON.stringify(moduleUrl)}); console.log(JSON.stringify(await _test.discoverCandidates(async()=>[${JSON.stringify(paneRow("a", "%1", 990099))}])));`;

	const childTsconfig = `${stateDir}/child-tsconfig.json`;
	await writeFile(childTsconfig, JSON.stringify({ compilerOptions: { paths: Object.fromEntries(
		["@earendil-works/pi-ai", "@earendil-works/pi-tui", "typebox", "typebox/value"].map((specifier) => [specifier, [Bun.resolveSync(specifier, import.meta.dir)]]),
	) } }));

	const localOutput = await new Promise<string>((resolve, reject) => {
		childProcess.execFile("bun", ["--tsconfig-override", childTsconfig, "-e", script], { env: { ...env, PI_SOCKET: recoveredSocket, PI_SOCKET_OWNER_PID: "" }, timeout: 5000 }, (error, stdout, stderr) => {
			if (error) reject(new Error(stderr || error.message));
			else resolve(stdout);
		});
	});

	expect(JSON.parse(localOutput)[0]).toMatchObject({ socket: recoveredSocket, reachable: true, pid: 990099 });
}, 15_000);

test("duplicate manifest sockets use the same registration identity locally and remotely", async () => {
	const manifest = await discoveryPeer("duplicates", 991000);
	await writeFile(`${stateDir}/manifests/duplicates.info`, JSON.stringify({ ...manifest, pane: "%older", cwd: "/older" }));
	await writeFile(`${stateDir}/manifests/zz-duplicates.info`, JSON.stringify({ socket: manifest.socket, session: "replacement", window: "replacement" }));
	const local = (await _test.discoverCandidates(async () => [])).find((item) => item.socket === manifest.socket)!;
	const bin = `${stateDir}/no-tmux`;
	await mkdir(bin);
	await writeFile(`${bin}/ps`, "#!/bin/sh\nexit 0\n", { mode: 0o755 });
	await writeFile(`${bin}/tmux`, "#!/bin/sh\nexit 0\n", { mode: 0o755 });

	const text = await new Promise<string>((resolve, reject) => {
		childProcess.execFile("bash", ["-c", _test.REMOTE_INVENTORY_SCRIPT], { env: { ...process.env, PI_STATE_DIR: stateDir, PATH: `${bin}:${process.env.PATH}` }, timeout: 5000 }, (error, stdout) => {
			if (error) reject(error);
			else resolve(stdout);
		});
	});

	const inventory = await _test.fetchRemoteInventory(local.machine || "local", (_file, _args, _options, callback) => {
		callback(null, text, "");

		return new childProcess.ChildProcess();
	});

	expect(inventory.find((item) => item.socket === local.socket)).toMatchObject({ id: local.id, session: local.session, window: local.window, pid: local.pid, pane: local.pane, cwd: local.cwd });
});

test("remote transport preserves fragmented UTF-8 and drains large replies before exiting", async () => {
	const socketPath = `${stateDir}/remote-wire.sock`;
	const content = `界😀${"large reply ".repeat(30000)}`;
	const request = _test.buildControlRequest("message.last");
	const response = { ...request, type: "control_response", ok: true, data: { message: { content } } };
	const bytes = Buffer.from(`${JSON.stringify(response)}\n`);
	const split = bytes.indexOf(Buffer.from("界")) + 1;

	const server = net.createServer((socket) => {
		socket.once("data", () => {
			socket.write(bytes.subarray(0, split));
			setTimeout(() => socket.end(bytes.subarray(split)), 10);
		});
	});

	servers.push(server);
	await new Promise<void>((resolve) => server.listen(socketPath, resolve));

	const stdout = await new Promise<string>((resolve, reject) => {
		childProcess.execFile("node", ["-e", _test.REMOTE_TELL_NODE], {
			env: { ...process.env, PI_TELL_SOCKET: socketPath, PI_TELL_PAYLOAD_B64: Buffer.from(JSON.stringify(request)).toString("base64") },
			timeout: 5000,
		}, (error, stdout) => {
			if (error) reject(error);
			else resolve(stdout);
		});
	});

	expect(_test.controlLastMessage(_test.parseWireResponse(stdout))?.content).toBe(content);
}, 10_000);

test("tell runtime identity is captured once and published on session start", async () => {
	let start: (() => void) | undefined;
	const emitted: Array<{ version: string; loadedAt: string; sourceHash: string }> = [];
	const source = await readFile(new URL("../agent/extensions/tell.ts", import.meta.url));

	// SAFETY: this fixture provides only the registration and event APIs used by the extension.
	extension({
		events: { emit(name, value) { expect(name).toBe("tell:runtime"); emitted.push(value); } },
		on(name, handler) { if (name === "session_start") start = () => handler({ type: "session_start" }, context(neverSelect, false)); },
		registerCommand() {},
		registerTool() {},
	} as ExtensionAPI);
	start!();
	start!();

	expect(emitted).toHaveLength(2);
	expect(emitted[0]).toEqual(emitted[1]);
	expect(emitted[0]).toMatchObject({ version: "tell.v2", sourceHash: crypto.createHash("sha256").update(source).digest("hex") });
	expect(Number.isFinite(Date.parse(emitted[0].loadedAt))).toBe(true);
});
