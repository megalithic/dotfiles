/**
 * Custom footer that removes cost/subscription info from the default footer
 * and uses starship prompt instead of plain cwd.
 */

import type { AssistantMessage } from "@mariozechner/pi-ai";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";
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

async function fetchJjInfo(cwd: string): Promise<string> {
  try {
    // Get bookmark + change id + dirty state in one call
    const { stdout: logOut } = await execFile(
      "jj",
      ["log", "--no-graph", "-r", "@", "-T", 'separate(" ", bookmarks, change_id.shortest(4))'],
      { cwd, timeout: 500 },
    );
    const jjLine = logOut.trim();
    if (!jjLine) return "";

    // Check for uncommitted changes
    const { stdout: statusOut } = await execFile(
      "jj",
      ["status", "--no-pager"],
      { cwd, timeout: 500 },
    );
    const dirty = statusOut.includes("Working copy changes:") ? "*" : "";

    return jjLine + dirty;
  } catch {
    return "";
  }
}

interface TokenCache {
  totalInput: number;
  totalOutput: number;
  totalCacheRead: number;
  totalCacheWrite: number;
  entryCount: number;
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    let cachedStarship = "";
    let cachedJjInfo = "";
    const tokenCache: TokenCache = {
      totalInput: 0,
      totalOutput: 0,
      totalCacheRead: 0,
      totalCacheWrite: 0,
      entryCount: 0,
    };

    ctx.ui.setFooter((tui, theme, footerData) => {
      // Pre-fetch starship + jj info asynchronously, re-render when ready
      fetchStarship(ctx.cwd).then((val) => {
        cachedStarship = val;
        tui.requestRender();
      });
      fetchJjInfo(ctx.cwd).then((val) => {
        cachedJjInfo = val;
        tui.requestRender();
      });

      const unsub = footerData.onBranchChange(async () => {
        cachedStarship = await fetchStarship(ctx.cwd);
        cachedJjInfo = await fetchJjInfo(ctx.cwd);
        tui.requestRender();
      });

      return {
        dispose: unsub,
        invalidate() {},
        render(width: number): string[] {
          // Line 1: starship prompt (cached) with jj info + session name right-aligned
          const starship =
            cachedStarship || theme.fg("dim", getCwdDisplay(ctx.cwd));
          const sessionName = ctx.sessionManager.getSessionName();
          const jjDisplay = cachedJjInfo
            ? theme.fg("muted", "jj:") + theme.fg("accent", cachedJjInfo)
            : "";
          const rightParts = [jjDisplay, sessionName ? theme.fg("dim", sessionName) : ""]
            .filter(Boolean)
            .join(theme.fg("dim", " │ "));
          const line1 = rightParts
            ? rightAlign(starship, rightParts, width)
            : starship;

          // Token totals (cached, only recompute when entry count changes)
          const entries = ctx.sessionManager.getEntries();
          if (entries.length !== tokenCache.entryCount) {
            let ti = 0,
              to = 0,
              tcr = 0,
              tcw = 0;
            for (const entry of entries) {
              if (
                entry.type === "message" &&
                entry.message.role === "assistant"
              ) {
                const m = entry.message as AssistantMessage;
                ti += m.usage.input;
                to += m.usage.output;
                tcr += m.usage.cacheRead;
                tcw += m.usage.cacheWrite;
              }
            }
            tokenCache.totalInput = ti;
            tokenCache.totalOutput = to;
            tokenCache.totalCacheRead = tcr;
            tokenCache.totalCacheWrite = tcw;
            tokenCache.entryCount = entries.length;
          }

          // Line 2 left: token stats + context usage
          const contextUsage = ctx.getContextUsage();
          const contextPct = contextUsage?.percent ?? 0;
          const contextWindow = contextUsage?.contextWindow ?? 0;

          const statsParts: string[] = [];
          if (tokenCache.totalInput)
            statsParts.push(
              theme.fg("muted", `↑${formatTokens(tokenCache.totalInput)}`),
            );
          if (tokenCache.totalOutput)
            statsParts.push(
              theme.fg("muted", `↓${formatTokens(tokenCache.totalOutput)}`),
            );
          if (tokenCache.totalCacheRead)
            statsParts.push(
              theme.fg("muted", `R${formatTokens(tokenCache.totalCacheRead)}`),
            );
          if (tokenCache.totalCacheWrite)
            statsParts.push(
              theme.fg("muted", `W${formatTokens(tokenCache.totalCacheWrite)}`),
            );

          const contextDisplay = `${contextPct.toFixed(1)}%/${formatTokens(contextWindow)}`;
          const contextColor =
            contextPct > 75 ? "error" : contextPct > 50 ? "warning" : "success";
          statsParts.push(theme.fg(contextColor, contextDisplay));

          let statsLeft = statsParts.join(" ");
          if (visibleWidth(statsLeft) > width) {
            statsLeft = truncateToWidth(statsLeft, width, "...");
          }

          // Line 2 right: model + thinking level
          const modelName = ctx.model?.id || "no-model";
          let rightSide = theme.fg("accent", modelName);
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

          const lines = [
            truncateToWidth(line1, width),
            rightAlign(statsLeft, rightSide, width),
          ];

          // Extension statuses
          const extensionStatuses = footerData.getExtensionStatuses();
          if (extensionStatuses.size > 0) {
            const statusLine = Array.from(extensionStatuses.entries())
              .sort(([a], [b]) => a.localeCompare(b))
              .map(([, text]) =>
                text
                  .replace(/[\r\n\t]/g, " ")
                  .replace(/ +/g, " ")
                  .trim(),
              )
              .join(" ");
            lines.push(
              truncateToWidth(statusLine, width, theme.fg("dim", "...")),
            );
          }

          return lines;
        },
      };
    });
  });
}
