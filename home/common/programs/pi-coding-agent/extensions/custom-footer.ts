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

          // Detect multi-pass preset from extension status
          const extensionStatuses = footerData.getExtensionStatuses();
          const multiPassStatus = extensionStatuses.get("multi-pass") || "";
          const presetMatch = multiPassStatus.match(/^preset:([^\s|]+)/);
          const activePreset = presetMatch?.[1];

          // Extract model-quota status for right-side display
          const quotaStatus = extensionStatuses.get("model-quota") || "";

          // Line 2 right: model + thinking level + quota
          const modelName = ctx.model?.id || "no-model";
          let rightSide: string;

          if (activePreset && ctx.model) {
            // Preset active: show ({preset}) provider/model • thinkingLevel
            const providerName = ctx.model.provider;
            rightSide =
              theme.fg("muted", `(${activePreset}) `) +
              theme.fg("muted", `${providerName}/`) +
              theme.fg("accent", modelName);
            if (ctx.model.reasoning) {
              const level = pi.getThinkingLevel() || "off";
              rightSide +=
                theme.fg("dim", " • ") +
                theme.fg("mdQuote", level === "off" ? "thinking off" : level);
            }
          } else {
            // No preset: standard provider/model display
            rightSide = theme.fg("accent", modelName);
            if (ctx.model?.reasoning) {
              const level = pi.getThinkingLevel() || "off";
              rightSide +=
                theme.fg("dim", " • ") +
                theme.fg("mdQuote", level === "off" ? "thinking off" : level);
            }

            // Prepend provider if multiple available
            if (footerData.getAvailableProviderCount() > 1 && ctx.model) {
              const withProvider =
                theme.fg("muted", `(${ctx.model.provider}) `) + rightSide;
              if (
                visibleWidth(statsLeft) + 2 + visibleWidth(withProvider) <=
                width
              ) {
                rightSide = withProvider;
              }
            }
          }

          // Append quota status after thinking level (right side)
          if (quotaStatus) {
            const quotaClean = quotaStatus
              .replace(/[\r\n\t]/g, " ")
              .replace(/ +/g, " ")
              .trim();
            if (quotaClean) {
              const quotaPart = theme.fg("dim", quotaClean);
              const candidate = rightSide + theme.fg("dim", " • ") + quotaPart;
              if (
                visibleWidth(statsLeft) + 2 + visibleWidth(candidate) <=
                width
              ) {
                rightSide = candidate;
              }
            }
          }

          // Merge remaining extension statuses into stats line (between left stats and right model info)
          // Exclude "multi-pass" preset status (shown on right) and "model-quota" (shown on right)
          if (extensionStatuses.size > 0) {
            const excludedKeys = new Set<string>();
            if (activePreset) excludedKeys.add("multi-pass");
            if (quotaStatus) excludedKeys.add("model-quota");

            const statusParts = Array.from(extensionStatuses.entries())
              .sort(([a], [b]) => a.localeCompare(b))
              .filter(([key]) => !excludedKeys.has(key))
              .map(([, text]) =>
                text
                  .replace(/[\r\n\t]/g, " ")
                  .replace(/ +/g, " ")
                  .trim(),
              )
              .filter((t) => t.length > 0);
            if (statusParts.length > 0) {
              const extStatus = statusParts
                .map((s) => theme.fg("dim", s))
                .join(" ");
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
