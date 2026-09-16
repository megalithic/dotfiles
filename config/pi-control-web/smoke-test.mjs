#!/usr/bin/env node

import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdirSync, mkdtempSync, writeFileSync } from "node:fs";
import { createServer as createSocketServer } from "node:net";
import { tmpdir } from "node:os";
import path from "node:path";
import { createGateway } from "./server.mjs";

const root = mkdtempSync(path.join(tmpdir(), "pi-control-web-"));
const stateDir = path.join(root, "state");
const manifestDir = path.join(stateDir, "manifests");
const socketPath = path.join(root, "pi-test.sock");
const token = "a".repeat(64);
const sentMessages = [];
mkdirSync(manifestDir, { recursive: true });

const bridge = createSocketServer((socket) => {
	let buffer = "";
	socket.on("data", (chunk) => {
		buffer += chunk.toString("utf8");
		let newline = buffer.indexOf("\n");
		while (newline !== -1) {
			const line = buffer.slice(0, newline);
			buffer = buffer.slice(newline + 1);
			const request = JSON.parse(line);
			let data;
			if (request.operation === "sessions.list") {
				data = {
					sessions: [
						{
							sessionId: "session-123",
							sessionName: "Gateway work",
							socket: socketPath,
							cwd: "/Users/seth/example-project",
							pid: process.pid,
							session: "mega",
							windowIndex: "2",
							paneIndex: "1",
							heartbeatAt: "2026-09-16T10:00:00.000Z",
							state: "done",
							statusUpdatedAt: "2026-09-16T10:00:01.000Z",
							reachable: true,
						},
					],
				};
			} else if (request.operation === "message.last") {
				data = {
					message: {
						role: "assistant",
						content: "The private gateway is ready.",
						timestamp: 1_800_000_000_000,
					},
				};
			} else if (request.operation === "message.send") {
				sentMessages.push(request.params);
				data = {
					accepted: true,
					deliveredAs: request.params.mode,
					messageId: request.id,
				};
			} else {
				socket.write(
					`${JSON.stringify({
						ok: false,
						type: "control_response",
						protocol: "pi.control.v1",
						id: request.id,
						operation: request.operation,
						error: "unsupported",
					})}\n`,
				);
				newline = buffer.indexOf("\n");
				continue;
			}
			socket.write(
				`${JSON.stringify({
					ok: true,
					type: "control_response",
					protocol: "pi.control.v1",
					id: request.id,
					operation: request.operation,
					data,
				})}\n`,
			);
			newline = buffer.indexOf("\n");
		}
	});
});

const listenUnix = () =>
	new Promise((resolve, reject) => {
		bridge.once("error", reject);
		bridge.listen(socketPath, () => {
			bridge.off("error", reject);
			resolve();
		});
	});

const closeServer = (server) =>
	new Promise((resolve, reject) =>
		server.close((error) => (error ? reject(error) : resolve())),
	);

let gateway;
try {
	await listenUnix();
	writeFileSync(
		path.join(manifestDir, "pi-test.info"),
		`${JSON.stringify({
			socket: socketPath,
			cwd: "/Users/seth/example-project",
			pid: process.pid,
			ephemeral: false,
		})}\n`,
		{ mode: 0o600 },
	);

	gateway = createGateway({ token, stateDir, port: 0 });
	const address = await gateway.listen();
	assert.equal(address.address, "127.0.0.1");
	const base = `http://127.0.0.1:${address.port}`;

	const health = await fetch(`${base}/healthz`);
	assert.equal(health.status, 200);

	const unauthorized = await fetch(`${base}/api/sessions`);
	assert.equal(unauthorized.status, 401);

	const badLogin = await fetch(`${base}/api/login`, {
		method: "POST",
		headers: { "Content-Type": "application/json", Origin: base },
		body: JSON.stringify({ token: "wrong" }),
	});
	assert.equal(badLogin.status, 401);

	const login = await fetch(`${base}/api/login`, {
		method: "POST",
		headers: { "Content-Type": "application/json", Origin: base },
		body: JSON.stringify({ token }),
	});
	assert.equal(login.status, 200);
	const cookie = login.headers.get("set-cookie")?.split(";", 1)[0];
	assert.ok(cookie);
	assert.ok(!cookie.includes(token));

	const authenticated = { Cookie: cookie };
	const sessionResponse = await fetch(`${base}/api/sessions`, {
		headers: authenticated,
	});
	assert.equal(sessionResponse.status, 200);
	const { sessions } = await sessionResponse.json();
	assert.equal(sessions.length, 1);
	assert.equal(sessions[0].project, "example-project");
	assert.equal(sessions[0].state, "done");
	assert.equal("socket" in sessions[0], false);
	assert.equal("cwd" in sessions[0], false);
	assert.equal("pid" in sessions[0], false);

	const id = sessions[0].id;
	const latestResponse = await fetch(`${base}/api/sessions/${id}/last`, {
		headers: authenticated,
	});
	assert.equal(latestResponse.status, 200);
	const latest = await latestResponse.json();
	assert.equal(latest.message.content, "The private gateway is ready.");

	for (const mode of ["follow_up", "steer"]) {
		const send = await fetch(`${base}/api/sessions/${id}/messages`, {
			method: "POST",
			headers: {
				...authenticated,
				"Content-Type": "application/json",
				Origin: base,
			},
			body: JSON.stringify({ text: `Send as ${mode}`, mode }),
		});
		assert.equal(send.status, 202);
	}
	assert.deepEqual(
		sentMessages.map((message) => message.mode),
		["follow_up", "steer"],
	);
	assert.ok(sentMessages.every((message) => message.from === "pi-control-web"));

	const invalidMode = await fetch(`${base}/api/sessions/${id}/messages`, {
		method: "POST",
		headers: {
			...authenticated,
			"Content-Type": "application/json",
			Origin: base,
		},
		body: JSON.stringify({ text: "No", mode: "direct" }),
	});
	assert.equal(invalidMode.status, 400);

	const controller = new AbortController();
	const stream = await fetch(`${base}/api/events`, {
		headers: authenticated,
		signal: controller.signal,
	});
	assert.equal(stream.status, 200);
	const reader = stream.body.getReader();
	let eventText = "";
	while (!eventText.includes("event: snapshot")) {
		const { value, done } = await reader.read();
		if (done) break;
		eventText += new TextDecoder().decode(value);
	}
	assert.match(eventText, /event: snapshot/);
	assert.match(eventText, /Gateway work/);

	await Promise.race([
		gateway.close(),
		new Promise((_, reject) =>
			setTimeout(() => reject(new Error("gateway shutdown timed out")), 1_000),
		),
	]);
	gateway = null;
	controller.abort();

	console.log("pi-control-web smoke test passed");
} finally {
	if (gateway) await gateway.close().catch(() => {});
	await closeServer(bridge).catch(() => {});
	execFileSync("trash", [root]);
}
