/**
 * Checkpoint Extension
 *
 * Encourages lean, incremental commits by tracking work and prompting
 * for review after thresholds are hit.
 *
 * Tracks:
 * - Files modified since last checkpoint
 * - Time elapsed since last checkpoint
 * - Current goal/todo being worked on
 *
 * Triggers checkpoint prompt when:
 * - 5+ files modified
 * - 20+ minutes elapsed
 * - Todo marked as done/closed
 * - Delegated task received from another agent
 * - Manual /checkpoint command
 *
 * Goal setting (natural language):
 * - "/goal description" or "/goal 'description'"
 * - "set goal: description" or "set next goal description"
 * - "goal: description" or "next goal: description"
 * - "working on: description"
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
  todoJustCompleted: boolean; // Flag when a todo was just closed
  lastCompletedTodo: string | null;
  delegatedTaskReceived: boolean; // Flag when a task is delegated from another agent
  delegatedTaskInfo: { id: string; from: string; task: string } | null;
}

const state: CheckpointState = {
  filesModified: new Set(),
  lastCheckpointTime: Date.now(),
  currentGoal: null,
  checkpointCount: 0,
  todoJustCompleted: false,
  lastCompletedTodo: null,
  delegatedTaskReceived: false,
  delegatedTaskInfo: null,
};


// =============================================================================
// Helpers
// =============================================================================

function resetCheckpoint() {
  state.filesModified.clear();
  state.lastCheckpointTime = Date.now();
  state.checkpointCount++;
  state.todoJustCompleted = false;
  state.lastCompletedTodo = null;
  state.delegatedTaskReceived = false;
  state.delegatedTaskInfo = null;
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
  const todoCompleted = state.todoJustCompleted;
  const delegatedTask = state.delegatedTaskReceived;

  return fileThresholdHit || timeThresholdHit || todoCompleted || delegatedTask;
}

// Get the trigger reason for the checkpoint prompt
function getCheckpointTrigger(): string {
  if (state.todoJustCompleted && state.lastCompletedTodo) {
    return `todo-completed:${state.lastCompletedTodo}`;
  }
  if (state.delegatedTaskReceived && state.delegatedTaskInfo) {
    return `delegated:${state.delegatedTaskInfo.from}`;
  }
  if (state.filesModified.size >= CONFIG.fileThreshold) {
    return `files:${state.filesModified.size}`;
  }
  if (getTimeSinceCheckpoint() >= CONFIG.timeThresholdMs) {
    return `time:${formatDuration(getTimeSinceCheckpoint())}`;
  }
  return "manual";
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
  if (state.delegatedTaskReceived && state.delegatedTaskInfo) {
    reason = `**📋 Delegated task received from ${state.delegatedTaskInfo.from}**\n\nTask: ${state.delegatedTaskInfo.task}\n\nConsider creating a new bookmark for this work.`;
  } else if (state.todoJustCompleted && state.lastCompletedTodo) {
    reason = `**✅ Todo completed:** ${state.lastCompletedTodo}`;
  } else if (fileCount >= CONFIG.fileThreshold) {
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
  prompt += `5. Set goal: "set next goal ..." or "working on: ..."\n`;

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

  // Track file modifications and todo completions
  pi.on("tool_call", async (event, ctx) => {
    trackFileChange(event);

    // Track todo completions
    if (event.toolName === "todo") {
      const input = event.input as Record<string, unknown>;
      const action = input.action as string;
      const status = input.status as string;
      
      // Detect closing/completing a todo
      if (action === "update" && (status === "done" || status === "closed")) {
        state.todoJustCompleted = true;
        state.lastCompletedTodo = (input.title as string) || (input.id as string) || "unknown";
      }
    }

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

  // Also check for checkpoint after todo operations
  pi.on("tool_result", async (event, ctx) => {
    if (event.toolName === "todo" && state.todoJustCompleted) {
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
    const text = event.text || "";
    const textLower = text.toLowerCase();

    // Detect delegated task from another agent: [TASK:xxx from session] description
    const delegatedTaskMatch = text.match(/\[TASK:([a-f0-9]+)\s+from\s+(\w+)\]\s*(.+)/i);
    if (delegatedTaskMatch && state.filesModified.size > 0) {
      // Only checkpoint if we have uncommitted work
      state.delegatedTaskReceived = true;
      state.delegatedTaskInfo = {
        id: delegatedTaskMatch[1],
        from: delegatedTaskMatch[2],
        task: delegatedTaskMatch[3].trim().slice(0, 100), // First 100 chars
      };
      // Trigger checkpoint immediately
      if (shouldPromptCheckpoint()) {
        const prompt = await buildCheckpointPrompt();
        // Show as notification since we can't block input
        ctx.ui.notify(prompt.slice(0, 500), "warning");
      }
    }


    // Handle goal setting - multiple patterns:

    // /goal description
    // set goal: description
    // set next goal description
    // goal: description
    // next goal: description
    // working on: description
    const goalPatterns = [
      /\/goal\s+["']?([^"'\n]+)["']?/i,
      /set\s+(?:next\s+)?goal[:\s]+["']?([^"'\n]+)["']?/i,
      /(?:next\s+)?goal[:\s]+["']?([^"'\n]+)["']?/i,
      /working\s+on[:\s]+["']?([^"'\n]+)["']?/i,
    ];

    for (const pattern of goalPatterns) {
      const match = text.match(pattern);
      if (match) {
        state.currentGoal = match[1].trim();
        ctx.ui.notify(`🎯 Goal set: ${state.currentGoal}`, "info");
        // Don't return handled for natural language - let it pass to agent
        // Only block for explicit /goal command
        if (text.trim().startsWith("/goal")) {
          return { action: "handled" as const };
        }
        break;
      }
    }

    // Handle /checkpoint command - show status
    if (textLower.trim() === "/checkpoint") {
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
      textLower.includes("continue") ||
      textLower.includes("skip checkpoint") ||
      textLower.includes("keep going")
    ) {
      resetCheckpoint();
      // Don't handle - let the message pass through to agent
    }

    // Reset on commit confirmation
    if (textLower.includes("committed") || textLower.includes("jj describe")) {
      resetCheckpoint();
    }

    return { action: "continue" as const };
  });

  // Expose state for debugging
  (globalThis as Record<string, unknown>).__checkpointState = state;
  (globalThis as Record<string, unknown>).__checkpointReset = resetCheckpoint;
}
