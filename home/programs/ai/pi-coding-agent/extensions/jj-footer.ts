/**
 * JJ Footer Extension - replaces git branch with jj status when in a jj repo
 * Also shows auth method (subscription vs API key identifier)
 *
 * Detects .jj directory and shows jj change/bookmark info instead of git branch.
 * Falls back to git branch when not in a jj repo.
 *
 * Auth display:
 * - OAuth subscription: shows "(sub)"
 * - API key with PI_AUTH_LABEL env var: shows that label, e.g., "(work)" or "(personal)"
 * - API key without label: shows first 4 chars of key, e.g., "(sk-a...)"
 *
 * Replicates the default footer structure:
 * Line 1: cwd (vcs-info)
 * Line 2: ↑input ↓output [cache] $cost (auth) [context%] [extension statuses]
 */

import type { AssistantMessage } from "@mariozechner/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";
import { execSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";

// Check if we're in a jj repo by looking for .jj directory
function isJjRepo(cwd: string): boolean {
  let dir = cwd;
  while (dir !== "/") {
    if (fs.existsSync(path.join(dir, ".jj"))) {
      return true;
    }
    dir = path.dirname(dir);
  }
  return false;
}

// Get jj status (change id + bookmarks)
function getJjStatus(): string | null {
  try {
    const result = execSync(
      'jj log -r @ --no-graph --ignore-working-copy -T \'separate(" ", change_id.shortest(4), bookmarks)\'',
      {
        encoding: "utf-8",
        timeout: 1000,
        stdio: ["pipe", "pipe", "pipe"],
      }
    ).trim();
    return result || null;
  } catch {
    return null;
  }
}

// Get git branch (fallback)
function getGitBranch(): string | null {
  try {
    const result = execSync("git rev-parse --abbrev-ref HEAD", {
      encoding: "utf-8",
      timeout: 1000,
      stdio: ["pipe", "pipe", "pipe"],
    }).trim();
    return result || null;
  } catch {
    return null;
  }
}

// Get VCS info - jj if available, otherwise git
function getVcsInfo(cwd: string): string | null {
  if (isJjRepo(cwd)) {
    const jjStatus = getJjStatus();
    if (jjStatus) {
      return jjStatus;
    }
  }
  const gitBranch = getGitBranch();
  return gitBranch;
}

// Shorten path with ~ for home
function shortenPath(p: string): string {
  const home = os.homedir();
  if (p.startsWith(home)) {
    return "~" + p.slice(home.length);
  }
  return p;
}

// Get auth identifier for display
async function getAuthLabel(ctx: ExtensionContext): Promise<string | null> {
  if (!ctx.model) return null;

  // Check if using OAuth subscription
  const isOAuth = ctx.modelRegistry.isUsingOAuth(ctx.model);
  if (isOAuth) {
    return "sub";
  }

  // Check for custom label env var
  const customLabel = process.env.PI_AUTH_LABEL;
  if (customLabel) {
    return customLabel;
  }

  // Try to get a short identifier from the API key
  try {
    const apiKey = await ctx.modelRegistry.getApiKey(ctx.model);
    if (apiKey) {
      // Show first 4 chars as identifier (e.g., "sk-a" for Anthropic keys)
      const prefix = apiKey.slice(0, 4);
      return `${prefix}…`;
    }
  } catch {
    // Ignore errors getting API key
  }

  return null;
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    setupCustomFooter(ctx);
  });

  pi.on("session_switch", (_event, ctx) => {
    setupCustomFooter(ctx);
  });
}

function setupCustomFooter(ctx: ExtensionContext) {
  if (!ctx.hasUI) return;

  // Cache auth label (async, so we fetch it once)
  let cachedAuthLabel: string | null | undefined = undefined;

  ctx.ui.setFooter((tui, theme, footerData) => {
    const unsub = footerData.onBranchChange(() => tui.requestRender());

    // Cache VCS info, refresh on cwd change
    let cachedVcs: string | null = null;
    let lastCwd = process.cwd();

    // Fetch auth label asynchronously
    void getAuthLabel(ctx).then((label) => {
      cachedAuthLabel = label;
      tui.requestRender();
    });

    return {
      dispose: unsub,
      invalidate() {
        cachedVcs = null;
        cachedAuthLabel = undefined;
        void getAuthLabel(ctx).then((label) => {
          cachedAuthLabel = label;
          tui.requestRender();
        });
      },
      render(width: number): string[] {
        // Refresh VCS cache if cwd changed
        const cwd = process.cwd();
        if (cwd !== lastCwd || cachedVcs === null) {
          cachedVcs = getVcsInfo(cwd);
          lastCwd = cwd;
        }

        // Line 1: cwd + vcs info
        const shortCwd = shortenPath(cwd);
        const vcsStr = cachedVcs ? ` (${cachedVcs})` : "";
        const line1 = theme.fg("dim", shortCwd + vcsStr);

        // Compute tokens
        let input = 0,
          output = 0,
          cacheRead = 0,
          cacheWrite = 0,
          cost = 0;
        for (const e of ctx.sessionManager.getBranch()) {
          if (e.type === "message" && e.message.role === "assistant") {
            const m = e.message as AssistantMessage;
            input += m.usage.input;
            output += m.usage.output;
            cacheRead += m.usage.cacheRead ?? 0;
            cacheWrite += m.usage.cacheWrite ?? 0;
            cost += m.usage.cost.total;
          }
        }

        const fmt = (n: number) => {
          if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
          if (n >= 1000) return `${(n / 1000).toFixed(0)}k`;
          return `${n}`;
        };

        // Line 2: token stats + auth label + extension statuses
        let line2Parts: string[] = [];

        // Token stats
        line2Parts.push(`↑${fmt(input)}`);
        line2Parts.push(`↓${fmt(output)}`);
        if (cacheRead > 0) line2Parts.push(`R${fmt(cacheRead)}`);
        if (cacheWrite > 0) line2Parts.push(`W${fmt(cacheWrite)}`);
        
        // Cost with auth label
        const authStr = cachedAuthLabel ? ` (${cachedAuthLabel})` : "";
        line2Parts.push(`$${cost.toFixed(3)}${authStr}`);

        const statsStr = theme.fg("dim", line2Parts.join(" "));

        // Extension statuses (includes context% from default footer extensions)
        const statuses = footerData.getExtensionStatuses();
        const sortedStatuses = Array.from(statuses.entries())
          .sort(([a], [b]) => a.localeCompare(b))
          .map(([, value]) => value);
        const statusStr = sortedStatuses.length > 0 ? " " + sortedStatuses.join(" ") : "";

        const line2 = statsStr + statusStr;

        return [
          truncateToWidth(line1, width),
          truncateToWidth(line2, width),
        ];
      },
    };
  });
}
