#!/usr/bin/env node

import { tmpdir } from "node:os";
import { join } from "node:path";
import { writeFileSync } from "node:fs";
import { connect } from "./cdp.js";
import { resolveTarget, targetHelpText } from "./target.js";

const DEBUG = process.env.DEBUG === "1";
const log = DEBUG ? (...args) => console.error("[debug]", ...args) : () => {};

if (process.argv.includes("--help")) {
  console.log("Usage: screenshot.js [--target <id>] [--url-match <str>]");
  console.log("\nCaptures a screenshot of the current tab.");
  console.log(targetHelpText());
  process.exit(0);
}

// Global timeout
const globalTimeout = setTimeout(() => {
  console.error("✗ Global timeout exceeded (15s)");
  process.exit(1);
}, 15000);

try {
  log("connecting...");
  const cdp = await connect(5000);

  log("getting pages...");
  const pages = await cdp.getPages();
  const page = resolveTarget(pages);

  if (!page) {
    console.error("✗ No active tab found");
    process.exit(1);
  }

  log("attaching to page:", page.targetId);
  const sessionId = await cdp.attachToPage(page.targetId);

  log("taking screenshot...");
  const data = await cdp.screenshot(sessionId);

  const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
  const filename = `screenshot-${timestamp}.png`;
  const filepath = join(tmpdir(), filename);

  writeFileSync(filepath, data);
  console.log(filepath);

  log("closing...");
  cdp.close();
  log("done");
} catch (e) {
  console.error("✗", e.message);
  process.exit(1);
} finally {
  clearTimeout(globalTimeout);
  setTimeout(() => process.exit(0), 100);
}
