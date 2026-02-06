/**
 * Checkpoint Extension
 *
 * Encourages lean, incremental commits by tracking work and prompting
 * for review after thresholds are hit.
 *
 * Tracks:
 * - Files modified since last checkpoint
 * - Time elapsed since last checkpoint
 * - Current bookmark status
 *
 * Triggers checkpoint prompt when:
 * - 5+ files modified
 * - 20+ minutes elapsed
 * - Manual /checkpoint command
 */

import type {
  ExtensionAPI,
  ToolCallEvent,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";

// Store reference to pi API for exec
let piApi: ExtensionAPI | null = null;

// =============================================================================
// Configuration
// =============================================================================

const CONFIG = {
  fileThreshold: 5, // Prompt after this many files changed
  timeThresholdMs: 20 * 60 * 1000, // 20 minutes in ms
  enabled: true,
};

// =============================================================================
// State
// =============================================================================

interface CheckpointState {
  filesModified: Set<string>;
  lastCheckpointTime: number;
  currentGoal: string | null;
  checkpointCount: number;
}

const state: CheckpointState = {
  filesModified: new Set(),
  lastCheckpointTime: Date.now(),
  currentGoal: null,
  checkpointCount: 0,
};

// =============================================================================
// Helpers
// =============================================================================

function resetCheckpoint() {
  state.filesModified.clear();
  state.lastCheckpointTime = Date.now();
  state.checkpointCount++;
}

function getTimeSinceCheckpoint(): number {
  return Date.now() - state.lastCheckpointTime;
}

function formatDuration(ms: number): string {
  const minutes = Math.floor(ms / 60000);
  if (minutes < 1) return "less than a minute";
  if (minutes === 1) return "1 minute";
  return `${minutes} minutes`;
}

function shouldPromptCheckpoint(): boolean {
  if (!CONFIG.enabled) return false;

  const fileThresholdHit = state.filesModified.size >= CONFIG.fileThreshold;
  const timeThresholdHit = getTimeSinceCheckpoint() >= CONFIG.timeThresholdMs;

  return fileThresholdHit || timeThresholdHit;
}

async function getCurrentBookmark(): Promise<string | null> {
  if (!piApi) return null;
  
  try {
    const result = await piApi.exec("jj", [
      "log", "-r", "@", "--no-graph", "-T", "bookmarks"
    ], { timeout: 5000 });
    
    const bookmark = result.stdout?.trim();
    return bookmark || null;
  } catch {
    return null;
  }
}

async function getJJDiffStat(): Promise<string> {
  if (!piApi) return "(unable to get diff)";
  
  try {
    const result = await piApi.exec("jj", ["diff", "--stat"], { timeout: 5000 });
    return result.stdout?.trim() || "(no changes)";
  } catch {
    return "(unable to get diff)";
  }
}

async function buildCheckpointPrompt(): Promise<string> {
  const fileCount = state.filesModified.size;
  const elapsed = formatDuration(getTimeSinceCheckpoint());
  const files = Array.from(state.filesModified).slice(0, 10);
  const bookmark = await getCurrentBookmark();
  const diffStat = await getJJDiffStat();

  let reason = "";
  if (fileCount >= CONFIG.fileThreshold) {
    reason = `**${fileCount} files modified** (threshold: ${CONFIG.fileThreshold})`;
  } else {
    reason = `**${elapsed} elapsed** (threshold: 20 min)`;
  }

  let prompt = `## 🛑 Checkpoint suggested\n\n${reason}\n\n`;

  // Bookmark status
  if (bookmark) {
    prompt += `**Bookmark:** \`${bookmark}\` ✓\n\n`;
  } else {
    prompt += `**⚠️ No bookmark!** Create one before committing:\n`;
    prompt += `\`jj bookmark create <name>\`\n\n`;
  }

  if (state.currentGoal) {
    prompt += `**Current goal:** ${state.currentGoal}\n\n`;
  }

  prompt += `**Files modified (${fileCount}):**\n`;
  for (const file of files) {
    prompt += `- ${file}\n`;
  }
  if (fileCount > 10) {
    prompt += `- ... and ${fileCount - 10} more\n`;
  }

  prompt += `\n**Diff summary:**\n\`\`\`\n${diffStat}\n\`\`\`\n`;

  prompt += `\n**Options:**\n`;
  prompt += `1. Commit: \`jj dm "message"\` (describe + move bookmark)\n`;
  prompt += `2. Push: \`jj push -b ${bookmark || "<name>"}\`\n`;
  prompt += `3. Create PR: \`jj pr\` (push + gh pr create)\n`;
  prompt += `4. Continue: say "continue" or "skip checkpoint"\n`;
  prompt += `5. Set goal: \`/goal "description"\`\n`;

  return prompt;
}

// =============================================================================
// Tool tracking
// =============================================================================

function trackFileChange(event: ToolCallEvent) {
  const toolName = event.toolName;
  const input = event.input as Record<string, unknown>;

  if (toolName === "write" || toolName === "edit") {
    const path = input.path as string;
    if (path) {
      state.filesModified.add(path);
    }
  }
}

// =============================================================================
// Extension entry point
// =============================================================================

export default function (pi: ExtensionAPI) {
  // Store API reference for exec calls
  piApi = pi;

  // Track file modifications
  pi.on("tool_call", async (event, ctx) => {
    trackFileChange(event);

    // Check if we should prompt for checkpoint
    // Only check on write/edit to avoid spamming
    if (event.toolName === "write" || event.toolName === "edit") {
      if (shouldPromptCheckpoint()) {
        const prompt = await buildCheckpointPrompt();
        return {
          block: true,
          reason: prompt,
        };
      }
    }
  });

  // Listen for user input to handle commands and reset signals
  pi.on("input", async (event, ctx) => {
    const text = (event.text || "").toLowerCase();

    // Handle /goal command
    const goalMatch = text.match(/\/goal\s+["']?([^"'\n]+)["']?/i);
    if (goalMatch) {
      state.currentGoal = goalMatch[1].trim();
      ctx.ui.notify(`Goal set: ${state.currentGoal}`, "info");
      return { action: "handled" as const };
    }

    // Handle /checkpoint command - show status
    if (text === "/checkpoint") {
      const fileCount = state.filesModified.size;
      const elapsed = formatDuration(getTimeSinceCheckpoint());
      const files = Array.from(state.filesModified).slice(0, 5);
      
      let msg = `📊 Checkpoint status:\n`;
      msg += `Files: ${fileCount} | Time: ${elapsed}`;
      if (state.currentGoal) msg += ` | Goal: ${state.currentGoal}`;
      if (fileCount > 0) msg += `\nRecent: ${files.join(", ")}`;
      
      ctx.ui.notify(msg, "info");
      return { action: "handled" as const };
    }

    // Reset on continue/skip
    if (
      text.includes("continue") ||
      text.includes("skip checkpoint") ||
      text.includes("keep going")
    ) {
      resetCheckpoint();
      // Don't handle - let the message pass through to agent
    }

    // Reset on commit confirmation
    if (text.includes("committed") || text.includes("jj describe")) {
      resetCheckpoint();
    }

    return { action: "continue" as const };
  });

  // Expose state for debugging
  (globalThis as Record<string, unknown>).__checkpointState = state;
  (globalThis as Record<string, unknown>).__checkpointReset = resetCheckpoint;
}
