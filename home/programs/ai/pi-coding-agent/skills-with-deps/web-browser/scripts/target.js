/**
 * Target resolution for web-browser scripts.
 * 
 * Priority:
 * 1. --target <id> flag (explicit targetId)
 * 2. --url-match <pattern> flag (find tab by URL substring)
 * 3. Cached targetId from ~/.cache/agent-web/current-target
 * 4. Fallback to pages.at(-1)
 */

import { existsSync, readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const CACHE_DIR = join(homedir(), ".cache", "agent-web");
const TARGET_FILE = join(CACHE_DIR, "current-target");

/**
 * Parse --target and --url-match flags from argv
 */
export function parseTargetFlags(argv = process.argv) {
  const result = { targetId: null, urlMatch: null };
  
  const targetIdx = argv.indexOf("--target");
  if (targetIdx !== -1 && argv[targetIdx + 1]) {
    result.targetId = argv[targetIdx + 1];
  }
  
  const urlIdx = argv.indexOf("--url-match");
  if (urlIdx !== -1 && argv[urlIdx + 1]) {
    result.urlMatch = argv[urlIdx + 1];
  }
  
  return result;
}

/**
 * Get the current cached targetId, if valid
 */
export function getCachedTarget() {
  try {
    if (existsSync(TARGET_FILE)) {
      return readFileSync(TARGET_FILE, "utf8").trim();
    }
  } catch {
    // Ignore read errors
  }
  return null;
}

/**
 * Save targetId to cache
 */
export function saveCurrentTarget(targetId) {
  try {
    mkdirSync(CACHE_DIR, { recursive: true });
    writeFileSync(TARGET_FILE, targetId);
  } catch {
    // Ignore write errors - non-critical
  }
}

/**
 * Resolve the target page to use.
 * 
 * @param {Array} pages - Array of page objects from cdp.getPages()
 * @param {Object} options - Optional overrides { targetId, urlMatch }
 * @returns {Object|null} - The page object or null
 */
export function resolveTarget(pages, options = {}) {
  const flags = parseTargetFlags();
  const targetId = options.targetId || flags.targetId;
  const urlMatch = options.urlMatch || flags.urlMatch;
  
  // 1. Explicit targetId
  if (targetId) {
    const page = pages.find(p => p.targetId === targetId);
    if (page) return page;
    // Target not found - fall through to other methods
  }
  
  // 2. URL pattern match
  if (urlMatch) {
    const page = pages.find(p => p.url && p.url.includes(urlMatch));
    if (page) return page;
  }
  
  // 3. Cached target
  const cached = getCachedTarget();
  if (cached) {
    const page = pages.find(p => p.targetId === cached);
    if (page) return page;
  }
  
  // 4. Fallback to last page
  return pages.at(-1) || null;
}

/**
 * Get target help text for usage messages
 */
export function targetHelpText() {
  return `
Target options:
  --target <id>       Use specific targetId
  --url-match <str>   Find tab with URL containing <str>
  
Without flags, uses cached target from last nav.js call, or last tab.`;
}
