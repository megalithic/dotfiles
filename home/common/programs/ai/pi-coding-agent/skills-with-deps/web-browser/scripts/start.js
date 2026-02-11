#!/usr/bin/env node

import { spawn, execSync } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

// Check if browser is already listening on port 9222
function isPortListening(port) {
  try {
    const result = execSync(`lsof -i :${port} -sTCP:LISTEN`, { stdio: "pipe" });
    return result.toString().trim().length > 0;
  } catch {
    return false;
  }
}

// Get browser name from lsof output
function getBrowserOnPort(port) {
  try {
    const result = execSync(`lsof -i :${port} -sTCP:LISTEN`, { stdio: "pipe" });
    const lines = result.toString().trim().split("\n");
    if (lines.length > 1) {
      return lines[1].split(/\s+/)[0].replace(/\\x20/g, " ");
    }
  } catch {}
  return null;
}

// Get BROWSER bundle ID from Hammerspoon config
function getBrowserFromHammerspoon() {
  try {
    const result = execSync('hs -c "print(BROWSER)"', { stdio: "pipe" });
    const bundleId = result.toString().trim();
    if (bundleId && bundleId !== "nil") {
      return bundleId;
    }
  } catch {}
  return null;
}

// Get app path from bundle ID
function getAppPathFromBundleId(bundleId) {
  try {
    const result = execSync(`mdfind "kMDItemCFBundleIdentifier == '${bundleId}'" | head -1`, { stdio: "pipe" });
    const appPath = result.toString().trim();
    if (appPath) {
      // Get executable name from Info.plist
      const execName = execSync(`defaults read "${appPath}/Contents/Info.plist" CFBundleExecutable`, { stdio: "pipe" }).toString().trim();
      return `${appPath}/Contents/MacOS/${execName}`;
    }
  } catch {}
  return null;
}

// Known browser paths (fallbacks)
const BROWSER_PATHS = {
  "com.nix.brave-browser-nightly": `${process.env["HOME"]}/Applications/Home Manager Apps/Brave Browser Nightly.app/Contents/MacOS/Brave Browser Nightly`,
  "com.brave.Browser.nightly": "/Applications/Brave Browser Nightly.app/Contents/MacOS/Brave Browser Nightly",
  "com.google.Chrome": "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
};

// Profile source paths for --profile flag
const PROFILE_SOURCES = {
  "com.nix.brave-browser-nightly": `${process.env["HOME"]}/Library/Application Support/BraveSoftware/Brave-Browser-Nightly`,
  "com.brave.Browser.nightly": `${process.env["HOME"]}/Library/Application Support/BraveSoftware/Brave-Browser-Nightly`,
  "com.google.Chrome": `${process.env["HOME"]}/Library/Application Support/Google/Chrome`,
};

// If browser already listening on 9222, just use it
if (isPortListening(9222)) {
  const browser = getBrowserOnPort(9222);
  console.log(`✓ Browser already listening on :9222${browser ? ` (${browser})` : ""}`);
  console.log("  Use nav.js, eval.js, etc. to interact");
  
  const scriptDir = dirname(fileURLToPath(import.meta.url));
  const watcherPath = join(scriptDir, "watch.js");
  spawn(process.execPath, [watcherPath], { detached: true, stdio: "ignore" }).unref();
  
  process.exit(0);
}

const useProfile = process.argv[2] === "--profile";

if (process.argv[2] && process.argv[2] !== "--profile") {
  console.log("Usage: start.js [--profile]");
  console.log("\nOptions:");
  console.log("  --profile  Copy your browser profile (cookies, logins)");
  console.log("\nBrowser detection order:");
  console.log("  1. Already listening on :9222 (use existing)");
  console.log("  2. BROWSER from Hammerspoon config");
  console.log("  3. Google Chrome (fallback)");
  process.exit(1);
}

// Determine which browser to use
let browserPath = null;
let browserBundleId = null;
let browserName = "browser";

// Try Hammerspoon BROWSER first
const hsBrowser = getBrowserFromHammerspoon();
if (hsBrowser) {
  browserBundleId = hsBrowser;
  browserPath = BROWSER_PATHS[hsBrowser] || getAppPathFromBundleId(hsBrowser);
  browserName = hsBrowser.split(".").pop();
}

// Fallback to Chrome
if (!browserPath) {
  browserBundleId = "com.google.Chrome";
  browserPath = BROWSER_PATHS["com.google.Chrome"];
  browserName = "Chrome";
}

// Verify browser exists
try {
  execSync(`test -x "${browserPath}"`, { stdio: "ignore" });
} catch {
  console.error(`✗ Browser not found: ${browserPath}`);
  process.exit(1);
}

const SCRAPING_DIR = `${process.env["HOME"]}/.cache/scraping`;
execSync(`mkdir -p "${SCRAPING_DIR}"`, { stdio: "ignore" });

if (useProfile) {
  const profileSrc = PROFILE_SOURCES[browserBundleId];
  if (profileSrc) {
    console.log(`Syncing ${browserName} profile...`);
    try {
      execSync(`rsync -a --delete "${profileSrc}/" "${SCRAPING_DIR}/"`, { stdio: "pipe" });
    } catch (e) {
      console.warn(`Warning: Could not sync profile from ${profileSrc}`);
    }
  }
}

spawn(browserPath, [
  "--remote-debugging-port=9222",
  `--user-data-dir=${SCRAPING_DIR}`,
  "--profile-directory=Default",
  "--disable-search-engine-choice-screen",
  "--no-first-run",
  "--disable-features=ProfilePicker",
], { detached: true, stdio: "ignore" }).unref();

let connected = false;
for (let i = 0; i < 30; i++) {
  try {
    const response = await fetch("http://localhost:9222/json/version");
    if (response.ok) { connected = true; break; }
  } catch {
    await new Promise((r) => setTimeout(r, 500));
  }
}

if (!connected) {
  console.error("✗ Failed to connect to browser");
  process.exit(1);
}

const scriptDir = dirname(fileURLToPath(import.meta.url));
const watcherPath = join(scriptDir, "watch.js");
spawn(process.execPath, [watcherPath], { detached: true, stdio: "ignore" }).unref();

console.log(`✓ ${browserName} started on :9222${useProfile ? " with your profile" : ""}`);
