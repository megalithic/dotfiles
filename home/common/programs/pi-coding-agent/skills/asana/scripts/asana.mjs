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
// <path> is relative to https://app.asana.com/api/1.0, e.g. /tasks/123/subtasks

import { execSync } from "child_process";
import { existsSync, readFileSync } from "fs";
import { homedir } from "os";

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
	const flags = {};
	const rest = [];
	for (let i = 0; i < args.length; i++) {
		if (args[i] === "--fields") flags.fields = args[++i];
		else if (args[i] === "--all") flags.all = true;
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
	const res = await fetch(API_BASE + path, {
		method,
		headers: {
			Authorization: `Bearer ${token}`,
			...(body ? { "Content-Type": "application/json" } : {}),
		},
		body: body ? JSON.stringify(body) : undefined,
	});
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
					body
						? '{ "Content-Type": "application/json", "X-Requested-With": "XMLHttpRequest" }'
						: "{}"
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
		default:
			die(
				`unknown command: ${cmd || "(none)"}\n` +
					"commands: me | task | subtasks | stories | comment | update | complete | api",
			);
	}
}

main().catch((e) => die(e.message));
