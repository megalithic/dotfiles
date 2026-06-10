/**
 * Custom footer that removes cost/subscription info from the default footer
 * and uses starship prompt instead of plain cwd.
 */

import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { execFile as execFileCb } from "node:child_process";
import { promisify } from "node:util";

const execFile = promisify(execFileCb);

function formatTokens(count: number): string {
  if (count < 1000) return count.toString();
  if (count < 10000) return `${(count / 1000).toFixed(1)}k`;
  if (count < 1000000) return `${Math.round(count / 1000)}k`;
  if (count < 10000000) return `${(count / 1000000).toFixed(1)}M`;
  return `${Math.round(count / 1000000)}M`;
}

function formatCost(cost: number): string {
  if (cost < 0.01) return "<$0.01";
  return `$${cost.toFixed(2)}`;
}

function rightAlign(
  left: string,
  right: string,
  width: number,
  minPad = 2,
): string {
  const leftW = visibleWidth(left);
  const rightW = visibleWidth(right);
  if (leftW + minPad + rightW <= width) {
    return left + " ".repeat(width - leftW - rightW) + right;
  }
  const available = width - leftW - minPad;
  if (available > 3) {
    const truncRight = truncateToWidth(right, available);
    const truncRightW = visibleWidth(truncRight);
    return left + " ".repeat(width - leftW - truncRightW) + truncRight;
  }
  return left;
}

function getCwdDisplay(cwd: string): string {
  const home = process.env.HOME || process.env.USERPROFILE;
  if (home && cwd.startsWith(home)) {
    return `~${cwd.slice(home.length)}`;
  }
  return cwd;
}

function sanitizeStatusText(text: string): string {
  return text
    .replace(/[\r\n\t]/g, " ")
    .replace(/ +/g, " ")
    .trim();
}

interface MultiPassFooterStatus {
  preset?: string;
  activeProvider?: string;
  currentPool?: string;
  startingPool?: string;
  model?: string;
}

function parseMultiPassStatus(status: string): MultiPassFooterStatus {
  const parsed: MultiPassFooterStatus = {};
  const clean = sanitizeStatusText(status);
  if (!clean) return parsed;

  const presetMatch = clean.match(/(?:^|\|)\s*preset:([^|\s]+)/);
  if (presetMatch?.[1]) parsed.preset = presetMatch[1];

  const poolMatch = clean.match(/(?:^|\|)\s*pool:([^|\s]+)/);
  if (poolMatch?.[1]) parsed.currentPool = poolMatch[1];

  const startMatch = clean.match(/(?:^|\|)\s*start:([^|\s]+)/);
  if (startMatch?.[1]) parsed.startingPool = startMatch[1];

  const activeMatch = clean.match(/active\s+([^|()\s]+)\s*\(([^)]+)\)/);
  if (activeMatch?.[1]) parsed.activeProvider = activeMatch[1];
  if (activeMatch?.[2]) parsed.model = activeMatch[2];

  return parsed;
}

interface McpFooterStatus {
  text: string;
  activeCount: number;
}

function formatMcpStatus(
  key: string,
  text: string,
): McpFooterStatus | undefined {
  const clean = sanitizeStatusText(text);
  if (!/mcp/i.test(key) && !/mcp/i.test(clean)) return undefined;

  const slashMatch = clean.match(/(\d+)\s*\/\s*(\d+)/);
  if (slashMatch?.[1] && slashMatch?.[2]) {
    const activeCount = Number.parseInt(slashMatch[1], 10);
    return { text: ` ${slashMatch[1]}/${slashMatch[2]}`, activeCount };
  }

  const wordsMatch = clean.match(
    /(\d+)\s+(?:active|connected|ready|enabled)\D+(\d+)\s+(?:total|servers|configured)/i,
  );
  if (wordsMatch?.[1] && wordsMatch?.[2]) {
    const activeCount = Number.parseInt(wordsMatch[1], 10);
    return { text: ` ${wordsMatch[1]}/${wordsMatch[2]}`, activeCount };
  }

  return undefined;
}

async function fetchStarship(cwd: string): Promise<string> {
  try {
    const { stdout: raw } = await execFile(
      "starship",
      ["prompt", "--status=0", "--cmd-duration=0", "--jobs=0"],
      {
        cwd,
        timeout: 500,
        env: { ...process.env, TERM_PROGRAM: "ghostty" },
      },
    );
    const cleaned = raw.replace(/\x1b\[[0-9]*[JKHG]/g, "");
    const line = cleaned.split("\n").find((l) => visibleWidth(l) > 2) ?? "";
    return line.replace(/^\s+/, "").replace(/\s+$/, "");
  } catch {
    return "";
  }
}

interface TokenCache {
  totalCost: number;
  entryCount: number;
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    let cachedStarship = "";
    const tokenCache: TokenCache = {
      totalCost: 0,
      entryCount: 0,
    };

    ctx.ui.setFooter((tui, theme, footerData) => {
      // Pre-fetch starship asynchronously, re-render when ready
      fetchStarship(ctx.cwd).then((val) => {
        cachedStarship = val;
        tui.requestRender();
      });

      const unsub = footerData.onBranchChange(async () => {
        cachedStarship = await fetchStarship(ctx.cwd);
        tui.requestRender();
      });

      const vcsTools = new Set(["bash", "edit", "write"]);
      pi.on("tool_execution_end", async (event) => {
        if (vcsTools.has(event.toolName.toLowerCase())) {
          cachedStarship = await fetchStarship(ctx.cwd);
          tui.requestRender();
        }
      });

      return {
        dispose: unsub,
        invalidate() {},
        render(width: number): string[] {
          // Line 1: starship prompt (cached) with jj info + session name right-aligned
          const starship =
            cachedStarship || theme.fg("dim", getCwdDisplay(ctx.cwd));
          const sessionName = ctx.sessionManager.getSessionName();
          const rightParts = sessionName ? theme.fg("dim", sessionName) : "";
          const line1 = rightParts
            ? rightAlign(starship, rightParts, width)
            : truncateToWidth(starship, width);

          // Token totals (cached, only recompute when entry count changes)
          const entries = ctx.sessionManager.getEntries();
          if (entries.length !== tokenCache.entryCount) {
            let cost = 0;
            for (const entry of entries) {
              if (
                entry.type === "message" &&
                entry.message.role === "assistant"
              ) {
                const m = entry.message as AssistantMessage;
                cost += m.usage.cost?.total ?? 0;
              }
            }
            tokenCache.totalCost = cost;
            tokenCache.entryCount = entries.length;
          }

          // Line 2 left: token stats + context usage
          const contextUsage = ctx.getContextUsage();
          const contextPct = contextUsage?.percent ?? 0;
          const contextWindow = contextUsage?.contextWindow ?? 0;

          const statsParts: string[] = [];

          // Display session cost (pre-calculated by pi-ai)
          if (tokenCache.totalCost > 0) {
            statsParts.push(
              theme.fg("muted", formatCost(tokenCache.totalCost)),
            );
          }

          // Context: used/total (pct%)
          const usedTokens =
            contextUsage?.tokens != null
              ? formatTokens(contextUsage.tokens)
              : "?";
          const contextDisplay = `${usedTokens}/${formatTokens(contextWindow)} (${contextPct.toFixed(1)}%)`;
          const contextColor =
            contextPct > 75 ? "error" : contextPct > 50 ? "warning" : "success";
          statsParts.push(theme.fg(contextColor, contextDisplay));

          let statsLeft = statsParts.join(" ");
          if (visibleWidth(statsLeft) > width) {
            statsLeft = truncateToWidth(statsLeft, width, "...");
          }

          const extensionStatuses = footerData.getExtensionStatuses();
          const multiPass = parseMultiPassStatus(
            extensionStatuses.get("multi-pass") || "",
          );

          // Line 2 right: compact multi-pass routing status.
          // @lat: [[pi-coding-agent#Runtime settings]]
          // Shape: ({preset}){provider-or-failover-pool}/{model}/thinking_level
          const sep = theme.fg("dim", "/");
          const activeProvider =
            multiPass.activeProvider || ctx.model?.provider || "";
          const currentPool = multiPass.currentPool || activeProvider;
          const startingPool = multiPass.startingPool || currentPool;
          const activeModel = multiPass.model || ctx.model?.id || "no-model";
          const poolChanged =
            currentPool.length > 0 &&
            startingPool.length > 0 &&
            currentPool !== startingPool;
          const displayProvider = poolChanged ? currentPool : activeProvider;
          const providerPart = displayProvider
            ? poolChanged
              ? theme.fg("success", theme.bold(displayProvider))
              : displayProvider
            : "";
          const modelPart = theme.fg("accent", activeModel);
          const thinkingLevel = pi.getThinkingLevel() || "off";
          const thinkingPart = ctx.model?.reasoning
            ? sep + theme.fg("dim", thinkingLevel)
            : "";
          const presetPart = multiPass.preset
            ? theme.fg("dim", `(${multiPass.preset}) `)
            : "";

          const poolModelPart = providerPart
            ? providerPart + sep + modelPart
            : modelPart;
          const availableForRight = width - visibleWidth(statsLeft) - 2;
          const candidates = [
            presetPart + poolModelPart + thinkingPart,
            poolModelPart + thinkingPart,
            modelPart + thinkingPart,
            modelPart,
          ].filter((candidate) => visibleWidth(candidate) > 0);

          let rightSide = modelPart;
          for (const candidate of candidates) {
            if (visibleWidth(candidate) <= availableForRight) {
              rightSide = candidate;
              break;
            }
          }

          // Merge remaining extension statuses into stats line.
          // Multi-pass owns the right side. Caveman never belongs in the footer.
          if (extensionStatuses.size > 0) {
            const excludedKeys = new Set<string>(["multi-pass", "caveman"]);
            const statusParts = Array.from(extensionStatuses.entries())
              .sort(([a], [b]) => a.localeCompare(b))
              .filter(([key]) => !excludedKeys.has(key))
              .map(([key, text]) => {
                const mcpStatus = formatMcpStatus(key, text);
                if (mcpStatus) {
                  const color = mcpStatus.activeCount > 0 ? "accent" : "dim";
                  return theme.fg(color, mcpStatus.text);
                }
                if (/mcp/i.test(key) || /mcp/i.test(text)) return "";
                const clean = sanitizeStatusText(text);
                if (!clean || /caveman/i.test(clean)) return "";
                return theme.fg("dim", clean);
              })
              .filter((text) => text.length > 0);
            if (statusParts.length > 0) {
              const extStatus = statusParts.join(" ");
              statsLeft += theme.fg("dim", " │ ") + extStatus;
              if (visibleWidth(statsLeft) > width) {
                statsLeft = truncateToWidth(statsLeft, width, "...");
              }
            }
          }

          return [
            truncateToWidth(line1, width),
            rightAlign(statsLeft, rightSide, width),
          ];
        },
      };
    });
  });
}
