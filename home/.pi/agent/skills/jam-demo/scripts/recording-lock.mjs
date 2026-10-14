#!/usr/bin/env node
// One Tidewave recording at a time across every checkout that shares the Helium window and its localhost cookie.
import { execFileSync } from "node:child_process";
import { appendFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const stateDir =
  process.env.JAM_DEMO_STATE_DIR ??
  join(process.env.XDG_STATE_HOME ?? join(homedir(), ".local/state"), "jam-demo");

const lockDir = join(stateDir, "recording.lock");

const ownerFile = join(lockDir, "owner.json");

const waitersFile = join(lockDir, "waiters");

const cdp = join(homedir(), ".pi/agent/skills/chrome-cdp/scripts/cdp.mjs");

const STALE_MS = 15 * 60 * 1000;

const print = (value) => console.log(JSON.stringify(value, null, 2));

const cdpText = (args) => execFileSync(cdp, args, { encoding: "utf8", timeout: 30000 });

const cdpJson = (args) => {
  const out = cdpText(args);

  return JSON.parse(out.slice(out.indexOf("{")));
};

function tabRecorder(target, origin) {
  try {
    const proto = cdpJson(["evalraw", target, "Runtime.evaluate", JSON.stringify({ expression: "MediaRecorder.prototype" })]);
    const list = cdpJson(["evalraw", target, "Runtime.queryObjects", JSON.stringify({ prototypeObjectId: proto.result.objectId })]);

    const states = cdpJson([
      "evalraw",
      target,
      "Runtime.callFunctionOn",
      JSON.stringify({ objectId: list.objects.objectId, functionDeclaration: "function () { return this.map((r) => r.state); }", returnByValue: true }),
    ]).result.value;

    const url = cdpText(["eval", target, '[...document.querySelectorAll("input")].map((i) => i.value).find((v) => /^https?:/.test(v)) || ""'])
      .trim()
      .split("\n")
      .pop();

    return { target, origin, url, active: states.some((state) => state !== "inactive") };
  } catch (error) {
    return { target, origin, url: "", active: false, error: String(error.message).split("\n")[0] };
  }
}

function recorders() {
  if (process.env.JAM_DEMO_RECORDERS) return JSON.parse(process.env.JAM_DEMO_RECORDERS);

  return cdpText(["list"])
    .split("\n")
    .filter((line) => line.includes("/tidewave/connect"))
    .map((line) => tabRecorder(line.trim().split(/\s+/)[0], line.match(/https?:\/\/[^/\s]+/)?.[0] ?? ""));
}

const readOwner = () => (existsSync(ownerFile) ? JSON.parse(readFileSync(ownerFile, "utf8")) : null);

const readWaiters = () =>
  existsSync(waitersFile) ? [...new Set(readFileSync(waitersFile, "utf8").split("\n").filter(Boolean))] : [];

const writeOwner = (owner, url, title, requestedBy) =>
  writeFileSync(ownerFile, JSON.stringify({ owner, url, title, requestedBy, startedAt: new Date().toISOString() }, null, 2));

function acquire([owner, url, title, requestedBy = "user"]) {
  if (!owner || !url || !title) usage();
  mkdirSync(stateDir, { recursive: true });
  const live = recorders().filter((r) => r.active);

  if (!existsSync(lockDir) && live.length) return busy(null, live);

  try {
    mkdirSync(lockDir);
  } catch (error) {
    if (error.code !== "EEXIST") throw error;
    const holder = readOwner();

    if (holder?.owner === owner) return print({ acquired: true, reentered: true, lock: holder });
    const fresh = holder && Date.now() - Date.parse(holder.startedAt) < STALE_MS;

    if (live.length || fresh) return busy(holder, live);
    writeOwner(owner, url, title, requestedBy);

    return print({ acquired: true, tookOverStale: holder, lock: readOwner(), waiters: readWaiters() });
  }

  writeOwner(owner, url, title, requestedBy);
  print({ acquired: true, lock: readOwner() });
}

function busy(holder, live) {
  print({ busy: true, holder, recording: live, waiters: holder ? readWaiters() : [] });
  process.exit(3);
}

function wait([waiter]) {
  if (!waiter) usage();
  const holder = readOwner();

  if (!holder) {
    print({ waiting: false, free: true });
    process.exit(5);
  }

  if (!readWaiters().includes(waiter)) appendFileSync(waitersFile, `${waiter}\n`);
  print({ waiting: true, holder, waiters: readWaiters() });
}

function release([owner]) {
  if (!owner) usage();
  const holder = readOwner();

  if (!holder) return print({ released: false, reason: "no lock held", notify: [] });

  if (holder.owner !== owner) {
    print({ released: false, reason: "held by another owner", holder });
    process.exit(4);
  }

  const notify = readWaiters().filter((waiter) => waiter !== owner);
  execFileSync("trash", [lockDir]);
  print({ released: true, lock: holder, notify });
}

function usage() {
  console.error(`usage:
  recording-lock.mjs status
  recording-lock.mjs acquire <owner-tell-id> <url> <title> [requested-by]   exit 3 = busy
  recording-lock.mjs wait <waiter-tell-id>                                  exit 5 = already free
  recording-lock.mjs release <owner-tell-id>                                exit 4 = not the owner`);
  process.exit(2);
}

const [command, ...args] = process.argv.slice(2);

const commands = {
  status: () => print({ lock: readOwner(), waiters: readWaiters(), recorders: recorders() }),
  acquire,
  wait,
  release,
};

(commands[command] ?? usage)(args);
