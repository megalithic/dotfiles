#!/usr/bin/env node

import { connect } from "./cdp.js";
import { resolveTargetStrict, saveCurrentTarget, targetHelpText } from "./target.js";

const DEBUG = process.env.DEBUG === "1";
const log = DEBUG ? (...args) => console.error("[debug]", ...args) : () => {};

const args = process.argv.slice(2).filter(a => !a.startsWith("--"));
const url = args[0];
const newTab = process.argv.includes("--new");

if (!url) {
  console.log("Usage: nav.js <url> [--new] [--target <id>] [--url-match <str>]");
  console.log("\nExamples:");
  console.log("  nav.js https://example.com            # Opens new tab (safe default)");
  console.log("  nav.js https://example.com --new      # Explicitly open new tab");
  console.log("  nav.js https://example.com --url-match github  # Navigate existing tab");
  console.log("\nNote: Only reuses tabs with explicit --target/--url-match or cached target.");
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
  let openedNew = newTab;
  
  if (newTab) {
    log("creating new tab (--new flag)...");
    const { targetId: newTargetId } = await cdp.send("Target.createTarget", {
      url: "about:blank",
    });
    targetId = newTargetId;
  } else {
    // Only reuse a tab if we have explicit target context
    const page = resolveTargetStrict(pages);
    if (page) {
      log("reusing existing tab:", page.targetId);
      targetId = page.targetId;
    } else {
      // No target context - open new tab to avoid hijacking existing content
      log("no target context, creating new tab...");
      const { targetId: newTargetId } = await cdp.send("Target.createTarget", {
        url: "about:blank",
      });
      targetId = newTargetId;
      openedNew = true;
    }
  }

  log("attaching to page...");
  const sessionId = await cdp.attachToPage(targetId);

  log("navigating...");
  await cdp.navigate(sessionId, url);

  // Save targetId for other scripts to use
  saveCurrentTarget(targetId);
  log("saved target:", targetId);

  console.log(openedNew ? "✓ Opened in new tab:" : "✓ Navigated to:", url);

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
