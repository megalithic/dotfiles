/**
 * Statusline Extension - Customizable 2-line footer with segment API
 *
 * Layout:
 *   Line 1 LEFT:  π {session} {cwd} {jj_status} │ n/total
 *   Line 1 RIGHT: 󱎫 reset │ ctx% │ ↑in ↓out │ model
 *
 *   Line 2 LEFT:  [status │ tool] │ {segments}
 *   Line 2 RIGHT: {segments}
 *
 * Segment API:
 *   Extensions can register segments via setStatus with structured data:
 *   ctx.ui.setStatus("myext", JSON.stringify({ text: "...", line: 2, align: "left" }))
 *
 * Color conditions:
 *   - π icon: dim if no socket, green if connected
 *   - jj_status: colored by jj (uses --color always)
 *   - Rate reset: yellow at 30m, red at 10m remaining
 *   - Context %: yellow at 70%, red at 90%
 */

import type { AssistantMessage } from "@mariozechner/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";
import { execSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";

// =============================================================================
// Types
// =============================================================================

interface Segment {
  text: string;
  line: 1 | 2;
  align: "left" | "right";
  priority?: number; // Higher = closer to edge
}

interface Theme {
  fg: (color: string, text: string) => string;
}

// =============================================================================
// Configuration
// =============================================================================

const CONFIG = {
  separator: "│",
  contextWarning: 70,  // Yellow at this %
  contextDanger: 90,   // Red at this %
  resetWarning: 30,    // Yellow at this many minutes
  resetDanger: 10,     // Red at this many minutes
};

// =============================================================================
// Socket Detection
// =============================================================================

const PI_SOCKET = process.env.PI_SOCKET;
const PI_SESSION = process.env.PI_SESSION;
const IS_SOCKET_ENABLED = !!PI_SOCKET;

function isSocketActive(): boolean {
  if (!PI_SOCKET) return false;
  try {
    return fs.existsSync(PI_SOCKET);
  } catch {
    return false;
  }
}

// =============================================================================
// JJ/Git Status
// =============================================================================

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

function getJjStatus(): string | null {
  try {
    // Match starship format: change_id bookmarks ⋮ status description
    const result = execSync(
      `jj log -r @ --no-graph --ignore-working-copy --color always -T '
        separate(" ",
          change_id.shortest(4),
          bookmarks,
          "⋮",
          concat(
            if(conflict, "󰔷"),
            if(divergent, "󰧈"),
            if(hidden, "󰘓"),
            if(immutable, ""),
          ),
          if(empty, "(empty)"),
          truncate_end(25, description.first_line(), "…"),
        )
      '`,
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

function getVcsInfo(cwd: string): string | null {
  if (isJjRepo(cwd)) {
    return getJjStatus();
  }
  return getGitBranch();
}

// =============================================================================
// Path Utilities
// =============================================================================

function shortenPath(p: string): string {
  const home = os.homedir();
  if (p.startsWith(home)) {
    return "~" + p.slice(home.length);
  }
  return p;
}

function getBasename(p: string): string {
  return path.basename(p) || p;
}

// =============================================================================
// Token/Cost Formatting
// =============================================================================

function formatNumber(n: number): string {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
  if (n >= 1000) return `${(n / 1000).toFixed(0)}k`;
  return `${n}`;
}

function getModelShortName(modelId: string | undefined): string {
  if (!modelId) return "?";
  const name = modelId.split("/").pop() || modelId;
  
  // Extract model name with version (e.g., "claude-opus-4-5-20250131" -> "opus-4-5")
  // Or "gpt-4o-2024-08-06" -> "gpt-4o"
  
  // Anthropic models: claude-{type}-{version}-{date}
  const claudeMatch = name.match(/claude-(\w+)-(\d+-\d+)/);
  if (claudeMatch) {
    return `${claudeMatch[1]}-${claudeMatch[2]}`;  // e.g., "opus-4-5"
  }
  
  // OpenAI models
  if (name.includes("gpt-4o")) return "gpt-4o";
  if (name.includes("gpt-4")) return "gpt-4";
  if (name.startsWith("o1")) return name.split("-")[0];  // o1, o1-mini, etc.
  if (name.startsWith("o3")) return name.split("-")[0];
  
  // Fallback: first two parts
  const parts = name.split("-");
  return parts.slice(0, 2).join("-");
}


function getProviderName(modelId: string | undefined): string {
  if (!modelId) return "?";
  const provider = modelId.split("/")[0];
  
  // Handle explicit provider prefix
  if (provider === "anthropic") return "anth";
  if (provider === "openai") return "oai";
  if (provider === "google") return "goog";
  
  // Handle model names without provider prefix
  if (provider.startsWith("claude")) return "anth";
  if (provider.startsWith("gpt-") || provider.startsWith("o1") || provider.startsWith("o3")) return "oai";
  if (provider.startsWith("gemini")) return "goog";
  
  return provider.slice(0, 4);
}


// =============================================================================
// Context Percentage
// =============================================================================

function renderContextPercent(percent: number, theme: Theme): string {
  let color = "dim";
  if (percent >= CONFIG.contextDanger) {
    color = "error";
  } else if (percent >= CONFIG.contextWarning) {
    color = "warning";
  }
  
  return theme.fg(color, `${percent}%`);
}

// =============================================================================
// Rate Limit Reset
// =============================================================================

// This would need to be populated from API responses - placeholder for now
let rateLimitResetTime: Date | null = null;

function getRateLimitReset(theme: Theme): string | null {
  if (!rateLimitResetTime) return null;
  
  const now = new Date();
  const diffMs = rateLimitResetTime.getTime() - now.getTime();
  if (diffMs <= 0) {
    rateLimitResetTime = null;
    return null;
  }
  
  const minutes = Math.floor(diffMs / 60000);
  const hours = Math.floor(minutes / 60);
  const mins = minutes % 60;
  
  let color = "dim";
  if (minutes <= CONFIG.resetDanger) {
    color = "error";
  } else if (minutes <= CONFIG.resetWarning) {
    color = "warning";
  }
  
  const timeStr = hours > 0 ? `${hours}h${mins}m` : `${mins}m`;
  return theme.fg(color, `󱎫 ${timeStr}`);
}

// =============================================================================
// Session Count (placeholder - would need pi API)
// =============================================================================

function getSessionCount(): string {
  // Placeholder - would need access to session manager
  return "";
}

// =============================================================================
// Build Lines
// =============================================================================

function buildLine1(
  ctx: ExtensionContext,
  theme: Theme,
  width: number,
  vcsInfo: string | null,
  tokenStats: { input: number; output: number; cost: number }
): string {
  const sep = theme.fg("dim", ` ${CONFIG.separator} `);
  
  // LEFT side
  const leftParts: string[] = [];
  
  // π icon with session
  const socketActive = isSocketActive();
  const piIcon = socketActive
    ? theme.fg("success", "π")
    : theme.fg("dim", "π");
  
  if (PI_SESSION && socketActive) {
    leftParts.push(`${piIcon} ${theme.fg("success", PI_SESSION)}`);
  } else {
    leftParts.push(piIcon);
  }
  
  // CWD (shortened with ~/)
  const cwd = process.cwd();
  leftParts.push(theme.fg("dim", shortenPath(cwd)));
  
  // VCS info (with separator)
  if (vcsInfo) {
    leftParts.push(theme.fg("dim", CONFIG.separator));
    leftParts.push(vcsInfo);
  }
  
  const leftStr = leftParts.join(" ");
  
  // RIGHT side
  const rightParts: string[] = [];
  
  // Rate limit reset (if available)
  const resetStr = getRateLimitReset(theme);
  if (resetStr) {
    rightParts.push(resetStr);
  }
  
  // Context percentage (get from footerData if available)
  // For now, calculate roughly based on tokens
  const maxContext = 200000; // Assume 200k context
  const usedContext = tokenStats.input + tokenStats.output;
  const contextPercent = Math.min(100, Math.round((usedContext / maxContext) * 100));
  rightParts.push(renderContextPercent(contextPercent, theme));
  
  // Token stats
  rightParts.push(theme.fg("dim", `↑${formatNumber(tokenStats.input)} ↓${formatNumber(tokenStats.output)}`));
  
  // Model (provider)
  const model = getModelShortName(ctx.model?.id);
  const provider = getProviderName(ctx.model?.id);
  rightParts.push(theme.fg("dim", model));
  
  const rightStr = rightParts.join(sep);
  
  // Combine with padding
  const leftWidth = visibleWidth(leftStr);
  const rightWidth = visibleWidth(rightStr);
  const padding = Math.max(1, width - leftWidth - rightWidth);
  
  return truncateToWidth(leftStr + " ".repeat(padding) + rightStr, width);
}

function buildLine2(
  ctx: ExtensionContext,
  theme: Theme,
  width: number,
  extensionStatuses: Map<string, string>,
  agentStatus: string
): string {
  const sep = theme.fg("dim", ` ${CONFIG.separator} `);
  
  // LEFT side
  const leftParts: string[] = [];
  
  // Agent status [status │ tool]
  if (agentStatus) {
    leftParts.push(theme.fg("dim", `[${agentStatus}]`));
  }
  
  // Extension segments (left-aligned)
  const leftSegments: string[] = [];
  const rightSegments: string[] = [];
  
  for (const [name, value] of extensionStatuses) {
    // Try to parse as structured segment
    try {
      const segment = JSON.parse(value) as Segment;
      if (segment.line === 2) {
        if (segment.align === "right") {
          rightSegments.push(segment.text);
        } else {
          leftSegments.push(segment.text);
        }
      }
    } catch {
      // Plain text status - add to left
      if (value && !value.startsWith("{")) {
        leftSegments.push(value);
      }
    }
  }
  
  if (leftSegments.length > 0) {
    leftParts.push(...leftSegments);
  }
  
  const leftStr = leftParts.join(sep);
  const rightStr = rightSegments.join(sep);
  
  // Combine with padding
  const leftWidth = visibleWidth(leftStr);
  const rightWidth = visibleWidth(rightStr);
  const padding = Math.max(1, width - leftWidth - rightWidth);
  
  if (rightStr) {
    return truncateToWidth(leftStr + " ".repeat(padding) + rightStr, width);
  }
  
  return truncateToWidth(leftStr, width);
}

// =============================================================================
// Main Extension
// =============================================================================

let refreshFooter: (() => void) | null = null;
let currentAgentStatus = "";
let currentToolName = "";

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    setupStatusline(ctx);
  });

  pi.on("session_switch", (_event, ctx) => {
    setupStatusline(ctx);
  });

  // Track agent status
  pi.on("turn_start", () => {
    currentAgentStatus = "working";
    refreshFooter?.();
  });

  pi.on("turn_end", () => {
    currentAgentStatus = "idle";
    currentToolName = "";
    refreshFooter?.();
  });

  pi.on("tool_call", (event) => {
    const input = event.input as Record<string, unknown>;
    currentToolName = event.toolName;
    // Include file path for file operations
    let toolDetail = event.toolName;
    if ((event.toolName === "edit" || event.toolName === "write" || event.toolName === "read") && input.path) {
      const filePath = String(input.path);
      const fileName = filePath.split("/").pop() || filePath;
      toolDetail = `${event.toolName} ${fileName}`;
    } else if (event.toolName === "bash" && input.command) {
      const cmd = String(input.command).split(" ")[0];
      toolDetail = `bash ${cmd}`;
    }
    currentAgentStatus = `working ${CONFIG.separator} ${toolDetail}`;
    refreshFooter?.();
  });

  // Refresh after agent turn (jj state may have changed)
  pi.on("agent_end", () => {
    refreshFooter?.();
  });

  // Update on model change
  pi.on("model_select", () => {
    refreshFooter?.();
  });
}

function setupStatusline(ctx: ExtensionContext) {
  if (!ctx.hasUI) return;

  ctx.ui.setFooter((tui, theme, footerData) => {
    const unsub = footerData.onBranchChange(() => tui.requestRender());

    // Cache VCS info
    let cachedVcs: string | null = null;
    let lastCwd = process.cwd();

    // Set up refresh callback
    refreshFooter = () => {
      cachedVcs = null;
      tui.requestRender();
    };

    return {
      dispose: () => {
        unsub();
        refreshFooter = null;
      },
      invalidate() {
        cachedVcs = null;
        tui.requestRender();
      },
      render(width: number): string[] {
        // Refresh VCS cache if cwd changed
        const cwd = process.cwd();
        if (cwd !== lastCwd || cachedVcs === null) {
          cachedVcs = getVcsInfo(cwd);
          lastCwd = cwd;
        }

        // Compute token stats
        let input = 0, output = 0, cost = 0;
        for (const e of ctx.sessionManager.getBranch()) {
          if (e.type === "message" && e.message.role === "assistant") {
            const m = e.message as AssistantMessage;
            input += m.usage.input;
            output += m.usage.output;
            cost += m.usage.cost.total;
          }
        }

        const tokenStats = { input, output, cost };

        // Get extension statuses
        const statuses = footerData.getExtensionStatuses();

        // Build lines
        const line1 = buildLine1(ctx, theme, width, cachedVcs, tokenStats);
        const line2 = buildLine2(ctx, theme, width, statuses, currentAgentStatus);

        return [line1, line2];
      },
    };
  });
}
