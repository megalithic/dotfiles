#!/usr/bin/env node

// asana - generic Asana API CLI with browser-session fallback.
//
// Auth resolution order:
//   1. $ASANA_ACCESS_TOKEN            -> direct REST API (Bearer)
//   2. ~/.config/asana/token          -> direct REST API (Bearer)
//   3. Browser CDP proxy              -> fetch() evaluated inside a logged-in
//      app.asana.com tab (Helium/Chrome with remote debugging enabled).
//
// Requires Node 22+ (built-in WebSocket, fetch).
//
// Usage:
//   asana.mjs me                                    auth sanity check
//   asana.mjs task <url|gid> [--fields a,b,c]       task details
//   asana.mjs subtasks <url|gid> [--fields ...]     all subtasks (paginated)
//   asana.mjs stories <url|gid>                     comments + activity
//   asana.mjs comment <url|gid> <text>              add a comment
//   asana.mjs update <url|gid> <json>               PUT {"data": <json>}
//   asana.mjs complete <url|gid> [true|false]       toggle completion
//   asana.mjs api <METHOD> <path> [json-body]       raw API passthrough
//
// Asana-first ticket workflow (Asana = source of truth, tk = local layer):
//   asana.mjs mine [--refresh]                      my open tasks (assignee or "Developer" field), cached 24h
//   asana.mjs link [--branch b] [--gid g ...]       link worktree to Asana task(s); interactive without --gid
//   asana.mjs sync [--push] [--yes]                 pull linked tasks -> mirror tickets; --push completes Asana
//   asana.mjs unlink <url|gid>                      remove a link (mirror ticket kept)
//   asana.mjs status                                link + mirror + cache state
//
// <path> is relative to https://app.asana.com/api/1.0, e.g. /tasks/123/subtasks

import { execFileSync, execSync } from "child_process";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "fs";
import { homedir } from "os";
import { dirname, join } from "path";
import readline from "readline/promises";

const API_BASE = "https://app.asana.com/api/1.0";

// ---------- helpers ----------

function die(msg, code = 1) {
	process.stderr.write(`error: ${msg}\n`);
	process.exit(code);
}

function extractGid(input) {
	// full URL: .../task/1214940291952619 (possibly with ?focus=... suffix)
	const m = String(input).match(/task\/(\d+)/);

	if (m) return m[1];
	// bare gid
	const g = String(input).match(/^(\d{6,})$/);

	if (g) return g[1];
	// any long number in the string (project URLs etc.)
	const any = String(input).match(/(\d{10,})/);

	if (any) return any[1];
	die(`cannot extract a task gid from: ${input}`);
}

function parseFlags(args) {
	const flags = { gids: [] };
	const rest = [];

	for (let i = 0; i < args.length; i++) {
		if (args[i] === "--fields") flags.fields = args[++i];
		else if (args[i] === "--all") flags.all = true;
		else if (args[i] === "--refresh") flags.refresh = true;
		else if (args[i] === "--push") flags.push = true;
		else if (args[i] === "--yes") flags.yes = true;
		else if (args[i] === "--branch") flags.branch = args[++i];
		else if (args[i] === "--gid") flags.gids.push(args[++i]);
		else rest.push(args[i]);
	}

	return { flags, rest };
}

function output(obj) {
	process.stdout.write(JSON.stringify(obj, null, 2) + "\n");
}

// ---------- auth: token ----------

function findToken() {
	if (process.env.ASANA_ACCESS_TOKEN) return process.env.ASANA_ACCESS_TOKEN;

	const tokenFile =
		process.env.ASANA_TOKEN_FILE || `${homedir()}/.config/asana/token`;

	if (existsSync(tokenFile)) {
		const t = readFileSync(tokenFile, "utf8").trim();

		if (t) return t;
	}

	return null;
}

async function tokenRequest(token, method, path, body) {
	const options = { method, headers: { Authorization: `Bearer ${token}` } };

	if (body) {
		options.headers["Content-Type"] = "application/json";
		options.body = JSON.stringify(body);
	}

	const res = await fetch(API_BASE + path, options);

	const text = await res.text();

	try {
		return { status: res.status, json: JSON.parse(text) };
	} catch {
		return { status: res.status, json: { raw: text.slice(0, 2000) } };
	}
}

// ---------- auth: browser CDP proxy ----------

function discoverCdpPorts() {
	const ports = [];

	if (process.env.ASANA_CDP_PORT)
		ports.push(Number(process.env.ASANA_CDP_PORT));

	// scan running browser processes for --remote-debugging-port=N
	try {
		const ps = execSync("ps ax -o command", {
			encoding: "utf8",
			maxBuffer: 16e6,
		});

		for (const m of ps.matchAll(/--remote-debugging-port=(\d+)/g)) {
			const p = Number(m[1]);

			if (!ports.includes(p)) ports.push(p);
		}
	} catch {
		/* ignore */
	}

	for (const p of [9222, 9223]) if (!ports.includes(p)) ports.push(p);

	return ports;
}

async function findAsanaTab() {
	for (const port of discoverCdpPorts()) {
		let list;

		try {
			const res = await fetch(`http://localhost:${port}/json/list`, {
				signal: AbortSignal.timeout(1500),
			});

			list = await res.json();
		} catch {
			continue; // port not listening
		}

		const tab = list.find(
			(t) => t.type === "page" && /https:\/\/app\.asana\.com\//.test(t.url),
		);

		if (tab && tab.webSocketDebuggerUrl) return { port, tab };

		if (list.some((t) => t.type === "page")) {
			// browser is debuggable but no asana tab open
			return { port, tab: null };
		}
	}

	return null;
}

function cdpEval(wsUrl, expression) {
	return new Promise((resolvePromise, reject) => {
		const ws = new WebSocket(wsUrl);

		const timer = setTimeout(() => {
			ws.close();
			reject(new Error("CDP evaluate timed out after 30s"));
		}, 30_000);

		ws.onerror = () => {
			clearTimeout(timer);
			reject(new Error(`cannot connect to browser CDP websocket: ${wsUrl}`));
		};

		ws.onopen = () => {
			ws.send(
				JSON.stringify({
					id: 1,
					method: "Runtime.evaluate",
					params: { expression, awaitPromise: true, returnByValue: true },
				}),
			);
		};

		ws.onmessage = (ev) => {
			const msg = JSON.parse(ev.data);

			if (msg.id !== 1) return;
			clearTimeout(timer);
			ws.close();

			if (msg.error) return reject(new Error(msg.error.message));
			const r = msg.result;

			if (r.exceptionDetails) {
				return reject(
					new Error(
						r.exceptionDetails.exception?.description ||
							r.exceptionDetails.text,
					),
				);
			}

			resolvePromise(r.result.value);
		};
	});
}

async function browserRequest(tab, method, path, body) {
	// fetch() runs in the asana tab's origin, so session cookies apply.
	const expr = `
    (async () => {
      const res = await fetch(${JSON.stringify(API_BASE + path)}, {
        method: ${JSON.stringify(method)},
        credentials: "include",
        headers: ${
					// X-Allow-Asana-Client: 1 is required for cookie-session writes
					// (POST/PUT/DELETE return 401 without it).
					body
						? '{ "Content-Type": "application/json", "X-Allow-Asana-Client": "1" }'
						: '{ "X-Allow-Asana-Client": "1" }'
				},
        body: ${body ? JSON.stringify(JSON.stringify(body)) : "undefined"},
      });
      const text = await res.text();
      return JSON.stringify({ status: res.status, text });
    })()`;

	const raw = await cdpEval(tab.webSocketDebuggerUrl, expr);
	const { status, text } = JSON.parse(raw);

	try {
		return { status, json: JSON.parse(text) };
	} catch {
		return { status, json: { raw: text.slice(0, 2000) } };
	}
}

// ---------- unified request with pagination ----------

let transport = null; // lazily resolved: {kind:"token",token} | {kind:"browser",tab}

async function resolveTransport() {
	if (transport) return transport;
	const token = findToken();

	if (token) {
		transport = { kind: "token", token };

		return transport;
	}

	const found = await findAsanaTab();

	if (found?.tab) {
		transport = { kind: "browser", tab: found.tab };

		return transport;
	}

	if (found) {
		die(
			`no ASANA_ACCESS_TOKEN and no app.asana.com tab open in the debuggable browser (port ${found.port}).\n` +
				`Open Asana in that browser (logged in), or export ASANA_ACCESS_TOKEN.`,
		);
	}

	die(
		"no Asana auth available.\n" +
			"Either: export ASANA_ACCESS_TOKEN (or write it to ~/.config/asana/token),\n" +
			"or run a Chromium browser with --remote-debugging-port and an app.asana.com tab open\n" +
			"(Helium: enable via chrome://inspect/#remote-debugging).",
	);
}

async function request(method, path, body) {
	const t = await resolveTransport();

	const res =
		t.kind === "token"
			? await tokenRequest(t.token, method, path, body)
			: await browserRequest(t.tab, method, path, body);

	if (res.status >= 400) {
		die(
			`Asana API ${method} ${path} -> HTTP ${res.status}\n` +
				JSON.stringify(res.json, null, 2),
		);
	}

	return res.json;
}

async function requestAll(path) {
	// follow next_page for collection endpoints; caps at 20 pages
	const sep = path.includes("?") ? "&" : "?";
	let url = `${path}${sep}limit=100`;
	const items = [];

	for (let i = 0; i < 20; i++) {
		const res = await request("GET", url);

		if (Array.isArray(res.data)) items.push(...res.data);
		else return res; // not a collection
		const next = res.next_page?.uri;

		if (!next) break;
		url = next.replace(API_BASE, "");
	}

	return { data: items };
}

// ---------- Asana-first ticket workflow: worktree link + cache ----------

const CACHE_DIR = join(homedir(), ".local", "share", "asana");

const MINE_MAX_AGE_HOURS = 24;

const MINE_TASK_FIELDS =
	"name,completed,permalink_url,assignee.name,due_on,modified_at," +
	"memberships.project.name";

function sh(cmd, args, opts = {}) {
	try {
		return execFileSync(cmd, args, {
			encoding: "utf8",
			stdio: ["ignore", "pipe", "pipe"],
			...opts,
		}).trim();
	} catch {
		return null;
	}
}

function currentBranch() {
	return sh("git", ["rev-parse", "--abbrev-ref", "HEAD"]);
}

function findTicketsDir() {
	let dir = process.cwd();

	while (dir !== "/") {
		const candidate = join(dir, ".tickets");

		if (existsSync(candidate)) return candidate;

		dir = dirname(dir);
	}

	return null;
}

function ticketsDirOrCreate() {
	const existing = findTicketsDir();

	if (existing) return existing;

	const root = sh("git", ["rev-parse", "--show-toplevel"]);

	if (!root) die("not inside a git repository and no .tickets/ found");

	const dir = join(root, ".tickets");

	mkdirSync(dir, { recursive: true });

	return dir;
}

function linkFilePath(ticketsDir) {
	return join(ticketsDir, ".asana.json");
}

function loadLinkFile() {
	const dir = findTicketsDir();

	if (!dir) return null;

	const path = linkFilePath(dir);

	if (!existsSync(path)) return null;

	try {
		return { dir, path, data: JSON.parse(readFileSync(path, "utf8")) };
	} catch {
		die(`malformed link file: ${path} (fix or remove it)`);
	}
}

function saveLinkFile(path, data) {
	writeFileSync(path, JSON.stringify(data, null, 2) + "\n");
}

function loadCache(name, maxAgeHours) {
	const path = join(CACHE_DIR, name);

	if (!existsSync(path)) return null;

	try {
		const data = JSON.parse(readFileSync(path, "utf8"));

		const ageHours =
			(Date.now() - Date.parse(data.fetched_at || 0)) / 3_600_000;

		if (maxAgeHours != null && ageHours > maxAgeHours) return null;

		return data;
	} catch {
		return null;
	}
}

function saveCache(name, data) {
	mkdirSync(join(CACHE_DIR, "tasks"), { recursive: true });
	writeFileSync(join(CACHE_DIR, name), JSON.stringify(data, null, 2) + "\n");
}

function cacheAgeHours(data) {
	return (Date.now() - Date.parse(data.fetched_at || 0)) / 3_600_000;
}

function oneLine(text) {
	return String(text || "")
		.replace(/\s+/g, " ")
		.trim();
}

function taskBrief(t) {
	return {
		gid: t.gid,
		name: oneLine(t.name),
		completed: Boolean(t.completed),
		url: t.permalink_url || null,
		due_on: t.due_on || null,
		projects: (t.memberships || []).flatMap((m) =>
			m.project?.name ? [m.project.name] : [],
		),
	};
}

async function findDeveloperField(wsGid) {
	try {
		const res = await requestAll(`/workspaces/${wsGid}/custom_fields?opt_fields=name,resource_subtype`);
		const field = (res.data || []).find((f) => f.name === "Developer");

		return field ? field.gid : null;
	} catch {
		return null;
	}
}

async function fetchMine() {
	const me = await request("GET", "/users/me?opt_fields=name,email,workspaces.name");
	const user = me.data;
	const tasks = new Map();
	const warnings = [];

	for (const ws of user.workspaces || []) {
		const assigned = await requestAll(
			`/tasks?assignee=me&workspace=${ws.gid}&completed_since=now&opt_fields=${MINE_TASK_FIELDS}`,
		);

		for (const t of assigned.data || []) tasks.set(t.gid, taskBrief(t));

		const devField = await findDeveloperField(ws.gid);

		if (!devField) {
			warnings.push(`workspace ${ws.name}: no "Developer" custom field visible; assignee-only`);
			continue;
		}

		try {
			const searched = await requestAll(
				`/workspaces/${ws.gid}/tasks/search?completed=false&custom_fields.${devField}.value=${user.gid}&opt_fields=${MINE_TASK_FIELDS}`,
			);

			for (const t of searched.data || []) tasks.set(t.gid, taskBrief(t));
		} catch (e) {
			warnings.push(`workspace ${ws.name}: Developer-field search failed (${e.message})`);
		}
	}

	return {
		fetched_at: new Date().toISOString(),
		user: { gid: user.gid, name: user.name },
		warnings,
		tasks: [...tasks.values()],
	};
}

async function loadMine(refresh) {
	if (!refresh) {
		const cached = loadCache("mine.json", MINE_MAX_AGE_HOURS);

		if (cached) return cached;
	}

	const fresh = await fetchMine();

	saveCache("mine.json", fresh);

	return fresh;
}

function branchMatchScore(branch, name) {
	const tokens = oneLine(branch)
		.toLowerCase()
		.split(/[^a-z0-9]+/)
		.filter((tok) => tok.length > 2);

	const haystack = name.toLowerCase();
	let score = 0;

	for (const tok of tokens) if (haystack.includes(tok)) score++;

	return score;
}

async function promptPick(candidates) {
	process.stderr.write("Select Asana task(s) to link (e.g. 1 or 1,3):\n");

	candidates.forEach((c, i) => {
		process.stderr.write(`  ${i + 1}. ${c.name}  [${c.projects.join(", ")}] ${c.url || c.gid}\n`);
	});

	const rl = readline.createInterface({ input: process.stdin, output: process.stderr });
	const answer = await rl.question("> ");

	rl.close();

	const picks = answer
		.split(/[,\s]+/)
		.flatMap((n) => {
			const idx = Number(n) - 1;

			return candidates[idx] ? [candidates[idx]] : [];
		});

	if (picks.length === 0) die("nothing selected");

	return picks;
}

function createMirrorTicket(dir, task) {
	const description = `${task.notes || ""}\n\nAsana: ${task.url}`.trim();

	const id = sh(
		"tk",
		[
			"create",
			task.name,
			"-d",
			description,
			"--external-ref",
			`asana-${task.gid}`,
			"--tags",
			"asana",
		],
		{ cwd: dirname(dir) },
	);

	if (!id) die("tk create failed for mirror ticket");

	return id;
}

function readTicketFrontmatter(dir, id) {
	const path = join(dir, `${id}.md`);

	if (!existsSync(path)) return null;

	const text = readFileSync(path, "utf8");
	const m = text.match(/^---\n([\s\S]*?)\n---/);

	if (!m) return null;

	const fm = {};

	for (const line of m[1].split("\n")) {
		const kv = line.match(/^([a-z-]+):\s*(.*)$/);

		if (kv) fm[kv[1]] = kv[2];
	}

	return fm;
}

function updateMirrorBody(dir, id, task) {
	const path = join(dir, `${id}.md`);

	if (!existsSync(path)) return;

	const text = readFileSync(path, "utf8");
	const m = text.match(/^(---\n[\s\S]*?\n---\n)/);

	if (!m) return;

	const body = `# ${oneLine(task.name)}\n\n${(task.notes || "").trim()}\n\nAsana: ${task.url}\n`;

	writeFileSync(path, m[1] + body);
}

async function fetchTaskDetail(gid) {
	const res = await request(
		"GET",
		`/tasks/${gid}?opt_fields=name,notes,completed,permalink_url,due_on,modified_at`,
	);

	const t = res.data;

	return {
		gid: t.gid,
		name: oneLine(t.name),
		notes: t.notes || "",
		completed: Boolean(t.completed),
		url: t.permalink_url || null,
		due_on: t.due_on || null,
		modified_at: t.modified_at || null,
	};
}

async function confirm(question, autoYes) {
	if (autoYes) return true;

	if (!process.stdin.isTTY) {
		process.stderr.write(`skipped (non-interactive; pass --yes to allow): ${question}\n`);

		return false;
	}

	const rl = readline.createInterface({ input: process.stdin, output: process.stderr });
	const answer = await rl.question(`${question} [y/N] `);

	rl.close();

	return /^y(es)?$/i.test(answer.trim());
}

async function cmdMine(flags) {
	const mine = await loadMine(flags.refresh);

	output({
		fetched_at: mine.fetched_at,
		age_hours: Math.round(cacheAgeHours(mine) * 10) / 10,
		user: mine.user,
		warnings: mine.warnings,
		tasks: mine.tasks.filter((t) => !t.completed),
	});
}

async function cmdLink(flags) {
	const dir = ticketsDirOrCreate();
	const path = linkFilePath(dir);
	const existing = loadLinkFile();
	const data = existing?.data || { linked: [] };
	const branch = flags.branch || currentBranch() || "unknown";
	let picks;

	if (flags.gids.length > 0) {
		picks = [];

		for (const raw of flags.gids) {
			const gid = extractGid(raw);

			picks.push(await fetchTaskDetail(gid));
		}
	} else {
		const mine = await loadMine(flags.refresh);
		const open = mine.tasks.filter((t) => !t.completed);

		const scored = open
			.map((t) => ({ ...t, score: branchMatchScore(branch, t.name) }))
			.sort((a, b) => b.score - a.score);

		const candidates = scored.slice(0, 15);

		if (candidates.length === 0) die("no open Asana tasks found; run: asana.mjs mine --refresh");

		if (!process.stdin.isTTY) {
			output({ branch, candidates });
			die(
				"non-interactive: ask the user which task(s) to link, then re-run with --gid <gid> [--gid <gid>...]",
				2,
			);
		}

		picks = await promptPick(candidates);
	}

	for (const pick of picks) {
		const already = data.linked.find((l) => l.gid === pick.gid);

		if (already) {
			process.stderr.write(`already linked: ${pick.name} (${pick.gid})\n`);
			continue;
		}

		const detail = pick.notes === undefined ? await fetchTaskDetail(pick.gid) : pick;
		const ticketId = createMirrorTicket(dir, detail);

		data.linked.push({
			gid: detail.gid,
			url: detail.url,
			name: detail.name,
			branch,
			ticket_id: ticketId,
			linked_at: new Date().toISOString(),
			synced_at: new Date().toISOString(),
			completed: detail.completed,
		});
		updateMirrorBody(dir, ticketId, detail);
		saveCache(join("tasks", `${detail.gid}.json`), { fetched_at: new Date().toISOString(), task: detail });
		process.stderr.write(`linked: ${detail.name} -> ${ticketId}\n`);
	}

	saveLinkFile(path, data);
	output(data);
}

async function cmdSync(flags) {
	const link = loadLinkFile();

	if (!link) die("no .tickets/.asana.json here; run: asana.mjs link");

	const { dir, path, data } = link;

	for (const entry of data.linked) {
		const task = await fetchTaskDetail(entry.gid);

		entry.name = task.name;
		entry.url = task.url;
		entry.completed = task.completed;
		entry.synced_at = new Date().toISOString();
		updateMirrorBody(dir, entry.ticket_id, task);
		saveCache(join("tasks", `${entry.gid}.json`), { fetched_at: entry.synced_at, task });

		const fm = readTicketFrontmatter(dir, entry.ticket_id);

		if (!fm) {
			process.stderr.write(`warning: mirror ticket ${entry.ticket_id} missing\n`);
			continue;
		}

		if (task.completed && fm.status !== "closed") {
			sh("tk", ["close", entry.ticket_id], { cwd: dirname(dir) });
			process.stderr.write(`closed locally (completed in Asana): ${entry.ticket_id}\n`);
		}

		if (flags.push && !task.completed && fm.status === "closed") {
			const ok = await confirm(
				`complete in Asana: "${task.name}" (${entry.gid})?`,
				flags.yes,
			);

			if (ok) {
				await request("PUT", `/tasks/${entry.gid}`, { data: { completed: true } });
				entry.completed = true;
				process.stderr.write(`completed in Asana: ${entry.gid}\n`);
			}
		}
	}

	saveLinkFile(path, data);
	output(data);
}

function cmdUnlink(rest) {
	const link = loadLinkFile();

	if (!link) die("no .tickets/.asana.json here");

	const gid = extractGid(rest[0] || die("usage: asana unlink <url|gid>"));
	const entry = link.data.linked.find((l) => l.gid === gid);

	if (!entry) die(`not linked: ${gid}`);

	link.data.linked = link.data.linked.filter((l) => l.gid !== gid);
	saveLinkFile(link.path, link.data);
	process.stderr.write(`unlinked ${gid}; mirror ticket ${entry.ticket_id} kept\n`);
	output(link.data);
}

function cmdStatus() {
	const link = loadLinkFile();
	const mine = loadCache("mine.json", null);

	const summary = {
		linked: [],
		mine_cache_age_hours: mine ? Math.round(cacheAgeHours(mine) * 10) / 10 : null,
	};

	if (link) {
		for (const entry of link.data.linked) {
			const fm = readTicketFrontmatter(link.dir, entry.ticket_id);

			summary.linked.push({
				gid: entry.gid,
				name: entry.name,
				branch: entry.branch,
				ticket_id: entry.ticket_id,
				local_status: fm ? fm.status : "missing",
				asana_completed: entry.completed,
				synced_at: entry.synced_at,
			});
		}
	}

	output(summary);
}

// ---------- commands ----------

const TASK_FIELDS =
	"name,notes,completed,assignee.name,due_on,permalink_url,parent.name," +
	"num_subtasks,memberships.project.name,created_at,modified_at";

const SUBTASK_FIELDS = "name,completed,assignee.name,due_on,permalink_url";

async function main() {
	const [cmd, ...argv] = process.argv.slice(2);
	const { flags, rest } = parseFlags(argv);

	switch (cmd) {
		case "me": {
			output(
				await request("GET", "/users/me?opt_fields=name,email,workspaces.name"),
			);
			break;
		}

		case "task": {
			const gid = extractGid(rest[0] || die("usage: asana task <url|gid>"));
			const fields = flags.fields || TASK_FIELDS;
			output(await request("GET", `/tasks/${gid}?opt_fields=${fields}`));
			break;
		}

		case "subtasks": {
			const gid = extractGid(rest[0] || die("usage: asana subtasks <url|gid>"));
			const fields = flags.fields || SUBTASK_FIELDS;
			output(await requestAll(`/tasks/${gid}/subtasks?opt_fields=${fields}`));
			break;
		}

		case "stories": {
			const gid = extractGid(rest[0] || die("usage: asana stories <url|gid>"));

			const fields =
				flags.fields || "type,text,created_by.name,created_at,resource_subtype";

			output(await requestAll(`/tasks/${gid}/stories?opt_fields=${fields}`));
			break;
		}

		case "comment": {
			const gid = extractGid(
				rest[0] || die("usage: asana comment <url|gid> <text>"),
			);

			const text = rest.slice(1).join(" ");

			if (!text) die("usage: asana comment <url|gid> <text>");
			output(
				await request("POST", `/tasks/${gid}/stories`, { data: { text } }),
			);
			break;
		}

		case "update": {
			const gid = extractGid(
				rest[0] || die("usage: asana update <url|gid> <json>"),
			);

			let data;

			try {
				data = JSON.parse(rest[1]);
			} catch {
				die("usage: asana update <url|gid> '{\"completed\":true,...}'");
			}

			output(await request("PUT", `/tasks/${gid}`, { data }));
			break;
		}

		case "complete": {
			const gid = extractGid(
				rest[0] || die("usage: asana complete <url|gid> [true|false]"),
			);

			const val = rest[1] !== "false";
			output(
				await request("PUT", `/tasks/${gid}`, { data: { completed: val } }),
			);
			break;
		}

		case "api": {
			const method = (rest[0] || "").toUpperCase();
			const path = rest[1];

			if (!/^(GET|POST|PUT|DELETE)$/.test(method) || !path?.startsWith("/"))
				die("usage: asana api <GET|POST|PUT|DELETE> </path> [json-body]");
			let body;

			if (rest[2]) {
				try {
					body = JSON.parse(rest[2]);
				} catch {
					die("body must be valid JSON");
				}
			}

			if (method === "GET" && flags.all) output(await requestAll(path));
			else output(await request(method, path, body));
			break;
		}

		case "mine": {
			await cmdMine(flags);
			break;
		}

		case "link": {
			await cmdLink(flags);
			break;
		}

		case "sync": {
			await cmdSync(flags);
			break;
		}

		case "unlink": {
			cmdUnlink(rest);
			break;
		}

		case "status": {
			cmdStatus();
			break;
		}

		default:
			die(
				`unknown command: ${cmd || "(none)"}\n` +
					"commands: me | task | subtasks | stories | comment | update | complete | api\n" +
					"workflow: mine | link | sync | unlink | status",
			);
	}
}

main().catch((e) => die(e.message));
