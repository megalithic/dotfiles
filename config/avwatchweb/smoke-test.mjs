#!/usr/bin/env node
import assert from "node:assert/strict";
import { spawn, spawnSync } from "node:child_process";
import { mkdtempSync } from "node:fs";
import net from "node:net";
import os from "node:os";
import path from "node:path";

const daemonPath =
    process.env.AVWATCHD_BIN ?? path.join(os.homedir(), ".local/bin/avwatchd");
const temporaryDir = mkdtempSync(path.join(os.tmpdir(), "avwatchd-smoke-"));
const socketPath = path.join(temporaryDir, "sock");
const nonce = "7fc4ba9b-c52f-4e27-8828-69f70c65f53d";
const extensionId = "ogfaajbfamngmlmkppahdpkoliobdemk";
let daemon;
let host;

const delay = (milliseconds) =>
    new Promise((resolve) => setTimeout(resolve, milliseconds));
const waitForSocket = async () => {
    for (let attempt = 0; attempt < 100; attempt += 1) {
        try {
            await new Promise((resolve, reject) => {
                const socket = net.createConnection(socketPath, () => {
                    socket.destroy();
                    resolve();
                });
                socket.once("error", reject);
            });
            return;
        } catch {
            await delay(50);
        }
    }
    throw new Error("avwatchd socket did not appear");
};

const request = (object, predicate, timeoutMs = 3000) =>
    new Promise((resolve, reject) => {
        const socket = net.createConnection(socketPath);
        let buffer = "";
        const timeout = setTimeout(() => {
            socket.destroy();
            reject(new Error("socket response timeout"));
        }, timeoutMs);
        socket.on("connect", () => socket.write(`${JSON.stringify(object)}\n`));
        socket.on("data", (chunk) => {
            buffer += chunk;
            while (buffer.includes("\n")) {
                const index = buffer.indexOf("\n");
                const line = buffer.slice(0, index);
                buffer = buffer.slice(index + 1);
                if (!line) continue;
                let value;
                try {
                    value = JSON.parse(line);
                } catch {
                    continue;
                }
                if (!predicate(value)) continue;
                clearTimeout(timeout);
                socket.destroy();
                resolve(value);
                return;
            }
        });
        socket.once("error", reject);
    });

const frame = (object) => {
    const payload = Buffer.from(JSON.stringify(object));
    const header = Buffer.alloc(4);
    header.writeUInt32LE(payload.length);
    return Buffer.concat([header, payload]);
};

const frameWaiters = [];
let frameBuffer = Buffer.alloc(0);
const waitForFrame = (predicate) =>
    new Promise((resolve, reject) => {
        const timer = setTimeout(
            () => reject(new Error("native frame timeout")),
            3000,
        );
        frameWaiters.push({
            predicate,
            resolve: (value) => {
                clearTimeout(timer);
                resolve(value);
            },
        });
    });
const handleFrame = (value) => {
    const index = frameWaiters.findIndex(({ predicate }) => predicate(value));
    if (index < 0) return;
    frameWaiters.splice(index, 1)[0].resolve(value);
};

try {
    daemon = spawn(daemonPath, ["--socket", socketPath], {
        stdio: ["ignore", "ignore", "pipe"],
    });
    await waitForSocket();

    host = spawn(daemonPath, ["--native-host", "--socket", socketPath], {
        stdio: ["pipe", "pipe", "pipe"],
    });
    host.stdout.on("data", (chunk) => {
        frameBuffer = Buffer.concat([frameBuffer, chunk]);
        while (frameBuffer.length >= 4) {
            const length = frameBuffer.readUInt32LE(0);
            if (frameBuffer.length < 4 + length) break;
            const payload = frameBuffer.subarray(4, 4 + length);
            frameBuffer = frameBuffer.subarray(4 + length);
            try {
                handleFrame(JSON.parse(payload));
            } catch {
                // Native host must emit JSON frames. Timeout below reports malformed output.
            }
        }
    });

    const connected = waitForFrame(
        (value) => value.type === "status" && value.connected === true,
    );
    host.stdin.write(frame({ v: 1, type: "hello", nonce, extensionId }));
    await connected;
    host.stdin.write(frame({ v: 1, type: "reset", nonce }));
    host.stdin.write(
        frame({
            v: 1,
            type: "snapshot",
            nonce,
            tabs: [
                {
                    tabId: 42,
                    windowId: 7,
                    url: "https://meet.google.com/abc-defg-hij",
                    meetingState: "joined",
                    displaySharing: true,
                    userMedia: { audio: "muted", video: "on" },
                    playback: { active: true, kinds: ["video"] },
                },
            ],
        }),
    );
    await delay(200);

    const presence = await request(
        { cmd: "get" },
        (value) => value.event === "get",
    );
    assert.equal(presence.v, 2);
    assert.equal(presence.inMeeting, true);
    assert.equal(presence.sharingSource, "browser-tab");
    assert.equal(presence.meetingTabId, 42);
    assert.equal(presence.playbackActive, true);
    assert.equal(presence.inAppMic, "muted");

    const focusFrame = waitForFrame((value) => value.type === "focus");
    const focusReply = await request(
        { cmd: "focus" },
        (value) => typeof value.ok === "boolean",
    );
    assert.equal(focusReply.ok, true);
    const focus = await focusFrame;
    assert.equal(focus.tabId, 42);
    assert.equal(focus.windowId, 7);
    assert.equal(focus.target, "meeting");
    host.stdin.write(
        frame({
            v: 1,
            type: "focus-result",
            nonce,
            requestId: focus.requestId,
            ok: true,
        }),
    );

    host.stdin.write(
        frame({
            v: 1,
            type: "event",
            nonce,
            tab: {
                tabId: 99,
                windowId: 7,
                url: "file:///tmp/forged",
                meetingState: "joined",
                displaySharing: true,
                userMedia: { audio: "on", video: "on" },
                playback: { active: false, kinds: [] },
            },
        }),
    );
    await delay(100);
    const unchanged = await request(
        { cmd: "get" },
        (value) => value.event === "get",
    );
    assert.equal(unchanged.meetingTabId, 42);

    const heartbeat = request({}, (value) => value.event === "heartbeat", 7000);
    assert.equal((await heartbeat).v, 2);

    host.kill("SIGTERM");
    await new Promise((resolve) => host.once("exit", resolve));
    await delay(200);
    const cleared = await request(
        { cmd: "get" },
        (value) => value.event === "get",
    );
    assert.equal(cleared.inMeeting, false);
    assert.equal(cleared.browserTabSharing, false);

    console.log("avwatchweb/avwatchd smoke: ok");
} finally {
    if (host && host.exitCode === null) host.kill("SIGTERM");
    if (daemon && daemon.exitCode === null) {
        daemon.kill("SIGTERM");
        await new Promise((resolve) => daemon.once("exit", resolve));
    }
    spawnSync("trash", [temporaryDir]);
}
