#!/usr/bin/env node

import { connect } from "./cdp.js";
import { resolveTarget, saveCurrentTarget, targetHelpText } from "./target.js";

const DEBUG = process.env.DEBUG === "1";
const log = DEBUG ? (...args) => console.error("[debug]", ...args) : () => {};

const args = process.argv.slice(2).filter(a => !a.startsWith("--"));
const url = args[0];
const newTab = process.argv.includes("--new");

if (!url) {
  console.log("Usage: nav.js <url> [--new] [--target <id>] [--url-match <str>]");
  console.log("\nExamples:");
  console.log("  nav.js https://example.com            # Navigate current tab");
  console.log("  nav.js https://example.com --new      # Open in new tab");
  console.log("  nav.js https://example.com --url-match github  # Navigate tab with 'github' in URL");
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
  let targetId;

  const pages = await cdp.getPages();
  
  if (newTab) {
    log("creating new tab...");
    const { targetId: newTargetId } = await cdp.send("Target.createTarget", {
      url: "about:blank",
    });
    targetId = newTargetId;
  } else {
    const page = resolveTarget(pages);
    if (!page) {
      console.error("✗ No active tab found");
      process.exit(1);
    }
    targetId = page.targetId;
  }

  log("attaching to page...");
  const sessionId = await cdp.attachToPage(targetId);

  log("navigating...");
  await cdp.navigate(sessionId, url);

  // Save targetId for other scripts to use
  saveCurrentTarget(targetId);
  log("saved target:", targetId);

  console.log(newTab ? "✓ Opened:" : "✓ Navigated to:", url);

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
