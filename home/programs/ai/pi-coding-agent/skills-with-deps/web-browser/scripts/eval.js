#!/usr/bin/env node

import { connect } from "./cdp.js";
import { resolveTarget, targetHelpText } from "./target.js";

const DEBUG = process.env.DEBUG === "1";
const log = DEBUG ? (...args) => console.error("[debug]", ...args) : () => {};

// Filter out target flags from code
const args = process.argv.slice(2);
const codeArgs = [];
for (let i = 0; i < args.length; i++) {
  if (args[i] === "--target" || args[i] === "--url-match") {
    i++; // Skip flag and its value
  } else if (!args[i].startsWith("--")) {
    codeArgs.push(args[i]);
  }
}
const code = codeArgs.join(" ");

if (!code) {
  console.log("Usage: eval.js 'code' [--target <id>] [--url-match <str>]");
  console.log("\nExamples:");
  console.log('  eval.js "document.title"');
  console.log("  eval.js \"document.querySelectorAll('a').length\"");
  console.log('  eval.js "document.title" --url-match github');
  console.log(targetHelpText());
  process.exit(1);
}

// Global timeout
const globalTimeout = setTimeout(() => {
  console.error("✗ Global timeout exceeded (45s)");
  process.exit(1);
}, 45000);

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

  log("evaluating...");
  const expression = `(async () => { return (${code}); })()`;
  const result = await cdp.evaluate(sessionId, expression);

  log("formatting result...");
  if (Array.isArray(result)) {
    for (let i = 0; i < result.length; i++) {
      if (i > 0) console.log("");
      for (const [key, value] of Object.entries(result[i])) {
        console.log(`${key}: ${value}`);
      }
    }
  } else if (typeof result === "object" && result !== null) {
    for (const [key, value] of Object.entries(result)) {
      console.log(`${key}: ${value}`);
    }
  } else {
    console.log(result);
  }

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
