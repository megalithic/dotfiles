/**
 * Coding Guardrails Extension - Override protocol support
 * 
 * Blocks dangerous commands with option to override via user confirmation.
 * Override protocol:
 *   - User says "override" → immediate confirmation prompt
 *   - User says "!override" → immediate execution (no confirm)
 *   - Override valid for 60 seconds or until consumed
 */
import type { ExtensionAPI, ToolCallEvent, AgentResponseEvent, ExtensionContext } from "@mariozechner/pi-coding-agent";

interface GuardResult { block: true; reason: string; immutable?: boolean; }
type GuardFn = (event: ToolCallEvent | AgentResponseEvent, ctx: ExtensionContext) => GuardResult | undefined;

// Override state with TTL
interface OverrideState {
  lastBlockedCommand: string | null;
  lastBlockedAt: number | null;
  overrideGranted: boolean;
  overrideGrantedAt: number | null;
  noConfirm: boolean; // !override skips confirmation
}

const OVERRIDE_TTL_MS = 60_000; // 60 seconds

const state: OverrideState = {
  lastBlockedCommand: null,
  lastBlockedAt: null,
  overrideGranted: false,
  overrideGrantedAt: null,
  noConfirm: false,
};

function log(msg: string) {
  console.log(`[guardrails] ${msg}`);
}

function isOverrideValid(): boolean {
  if (!state.overrideGranted) return false;
  if (!state.overrideGrantedAt) return false;
  const elapsed = Date.now() - state.overrideGrantedAt;
  if (elapsed > OVERRIDE_TTL_MS) {
    log(`Override expired (${Math.round(elapsed / 1000)}s > ${OVERRIDE_TTL_MS / 1000}s)`);
    resetOverride();
    return false;
  }
  return true;
}

function resetOverride() {
  state.overrideGranted = false;
  state.overrideGrantedAt = null;
  state.noConfirm = false;
}

function resetBlocked() {
  state.lastBlockedCommand = null;
  state.lastBlockedAt = null;
}

function grantOverride(noConfirm: boolean = false) {
  state.overrideGranted = true;
  state.overrideGrantedAt = Date.now();
  state.noConfirm = noConfirm;
  log(`Override granted (noConfirm=${noConfirm})`);
}

function consumeOverride(): boolean {
  if (isOverrideValid()) {
    log(`Override consumed for: ${state.lastBlockedCommand?.slice(0, 50)}...`);
    resetOverride();
    resetBlocked();
    return true;
  }
  return false;
}

function getResponseText(event: AgentResponseEvent): string {
  return event.response.content.filter((c) => c.type === "text").map((c) => c.text).join("\n");
}

// ============================================================================
// Guards
// ============================================================================

const blockCorporateBuzzwords: GuardFn = (event) => {
  if (event.toolName !== "agent_response") return;
  const text = getResponseText(event as AgentResponseEvent);
  if (/\b(comprehensive|robust|utilize|optimize|streamline|enhance|leverage)\b/i.test(text)) {
    return { block: true, reason: "Corporate buzzword detected." };
  }
};

const blockGitCommands: GuardFn = (event) => {
  if (event.toolName !== "bash") return;
  const cmd = (event as ToolCallEvent).input.command;
  const gitPattern = /(^|[\s;&|])git\s+/;
  const jjGitPattern = /(^|[\s;&|])jj\s+git\s+/;
  if (gitPattern.test(cmd) && !jjGitPattern.test(cmd)) {
    return { block: true, reason: "**git command blocked** - Use jj." };
  }
};

const blockPush: GuardFn = (event) => {
  if (event.toolName !== "bash") return;
  const cmd = (event as ToolCallEvent).input.command;
  if (/(^|[\s;&|])(git\s+push|jj\s+git\s+push|jj\s+push)/.test(cmd)) {
    return { block: true, reason: "**push blocked** - Say `override` or `!override` to grant permission." };
  }
};

const blockFindCommand: GuardFn = (event) => {
  if (event.toolName !== "bash") return;
  if (/(^|[\s;&|])find\s+/.test((event as ToolCallEvent).input.command)) {
    return { block: true, reason: "**find blocked** - Use fd." };
  }
};

const blockGrepCommand: GuardFn = (event) => {
  if (event.toolName !== "bash") return;
  if (/(^|[\s;&|])grep\s+/.test((event as ToolCallEvent).input.command)) {
    return { block: true, reason: "**grep blocked** - Use rg." };
  }
};

const blockBrewInstall: GuardFn = (event) => {
  if (event.toolName !== "bash") return;
  if (/(^|[\s;&|])brew\s+(install|cask|tap)/.test((event as ToolCallEvent).input.command)) {
    return { block: true, reason: "**brew blocked** - Use Nix." };
  }
};

const blockRmCommand: GuardFn = (event) => {
  if (event.toolName !== "bash") return;
  if (/(^|[\s;&|])(sudo\s+)?(rm|rmdir)(\s|$)/.test((event as ToolCallEvent).input.command)) {
    return { block: true, reason: "**rm blocked** - Use trash." };
  }
};

const blockPackageRunners: GuardFn = (event) => {
  if (event.toolName !== "bash") return;
  if (/\\b(npx|bunx)\\s+/.test((event as ToolCallEvent).input.command)) {
    return { block: true, reason: "**npx/bunx blocked** - Use package.json scripts." };
  }
};

const blockSecretTools: GuardFn = (event) => {
  if (event.toolName !== "bash") return;
  if (/(^|[|&;]|\$\()\s*(pass|gpg)(\s|$)/.test((event as ToolCallEvent).input.command)) {
    return { block: true, immutable: true, reason: "**Secret tools blocked** ⛔ IMMUTABLE - Cannot be overridden." };
  }
};

const blockNixManagedWrites: GuardFn = (event) => {
  // Only check write/edit tools - bash commands are handled by other guards
  // This prevents false positives when running scripts FROM managed paths
  if (event.toolName !== "write" && event.toolName !== "edit") return;
  
  let path = ((event as ToolCallEvent).input.path || "") as string;
  if (!path) return;
  path = path.replace(/^~\//, process.env.HOME + "/").replace(/^\$HOME\//, process.env.HOME + "/");
  
  const managed = [
    process.env.HOME + "/bin/",
    process.env.HOME + "/.config/",
    process.env.HOME + "/.hammerspoon/",
    process.env.HOME + "/.pi/agent/",
  ];
  
  for (const m of managed) {
    if (path.startsWith(m)) {
      return { block: true, immutable: true, reason: `**Write to ${m} blocked** ⛔ IMMUTABLE - Edit ~/.dotfiles/ source instead.` };
    }
  }
};

const blockTitleCaseHeaders: GuardFn = (event) => {
  if (event.toolName !== "agent_response") return;
  if (/^#+\s+(?:[A-Z][a-z]*\s+)+[A-Z][a-z]+/m.test(getResponseText(event as AgentResponseEvent))) {
    return { block: true, reason: "**Title case** - Use sentence case." };
  }
};

/**
 * CRITICAL: Block destructive jj commands that can discard uncommitted changes.
 * These are IMMUTABLE - user safety override is NOT allowed.
 * 
 * The agent MUST check `jj status` and `jj diff` BEFORE any VCS operations.
 * This guard exists because agents repeatedly assume "(no description set)"
 * commits are empty/disposable when they may contain user's uncommitted work.
 */
const blockDestructiveJjCommands: GuardFn = (event) => {
  if (event.toolName !== "bash") return;
  const cmd = (event as ToolCallEvent).input.command;
  
  // These commands can discard uncommitted changes
  // jj rebase - can orphan working copy changes
  if (/(^|[\s;&|])jj\s+rebase\b/.test(cmd)) {
    return { 
      block: true, 
      immutable: true, 
      reason: "**jj rebase blocked** ⛔ IMMUTABLE - Can discard uncommitted changes. First run `jj status` and `jj diff` to check for uncommitted work. If changes exist, commit them first with `jj describe -m \"wip: ...\"` or ask user what to do." 
    };
  }
  
  // jj abandon - directly discards changes
  if (/(^|[\s;&|])jj\s+abandon\b/.test(cmd)) {
    return { 
      block: true, 
      immutable: true, 
      reason: "**jj abandon blocked** ⛔ IMMUTABLE - Discards changes permanently. First run `jj status` and `jj diff -r <rev>` to see what would be lost. Ask user for explicit confirmation." 
    };
  }
  
  // jj restore - can overwrite working copy
  if (/(^|[\s;&|])jj\s+restore\b/.test(cmd)) {
    return { 
      block: true, 
      immutable: true, 
      reason: "**jj restore blocked** ⛔ IMMUTABLE - Can overwrite uncommitted changes. First run `jj status` and `jj diff` to check current state. Ask user for explicit confirmation." 
    };
  }
  
  // jj undo - can restore discarded changes but also undo wanted changes
  if (/(^|[\s;&|])jj\s+undo\b/.test(cmd)) {
    return { 
      block: true, 
      immutable: true, 
      reason: "**jj undo blocked** ⛔ IMMUTABLE - Can affect uncommitted work. First run `jj status` and explain what undo will do. Ask user for explicit confirmation." 
    };
  }
};

const blockInteractiveCommands: GuardFn = (event) => {
  if (event.toolName !== "bash") return;
  const cmd = (event as ToolCallEvent).input.command;
  
  // jj describe without -m flag
  if (/(^|[\s;&|])jj\s+describe\b/.test(cmd) && !/-m\s/.test(cmd)) {
    return { block: true, immutable: true, reason: "**jj describe blocked** ⛔ IMMUTABLE - Opens editor. Use `jj describe -m \"message\"`" };
  }
  
  // jj commit without -m flag
  if (/(^|[\s;&|])jj\s+commit\b/.test(cmd) && !/-m\s/.test(cmd)) {
    return { block: true, immutable: true, reason: "**jj commit blocked** ⛔ IMMUTABLE - Opens editor. Use `jj commit -m \"message\"`" };
  }
  
  // jj squash without -m or -u flag (opens editor when merging descriptions)
  if (/(^|[\s;&|])jj\s+squash\b/.test(cmd) && !/-m\s/.test(cmd) && !/-u\b/.test(cmd) && !/--use-destination-message/.test(cmd)) {
    return { block: true, immutable: true, reason: "**jj squash blocked** ⛔ IMMUTABLE - May open editor. Use `-m \"message\"` or `-u` (use destination message)" };
  }
  
  // jj split (always interactive)
  if (/(^|[\s;&|])jj\s+split\b/.test(cmd)) {
    return { block: true, immutable: true, reason: "**jj split blocked** ⛔ IMMUTABLE - Inherently interactive. Use separate commits instead." };
  }
  
  // jj commands with -i/--interactive flag (squash -i, split -i, etc.)
  if (/(^|[\s;&|])jj\s+(squash|split|restore|diff)\s+.*(-i|--interactive)\b/.test(cmd)) {
    return { block: true, immutable: true, reason: "**jj interactive flag blocked** ⛔ IMMUTABLE - Use file paths instead of -i/--interactive" };
  }
  
  // Direct editor invocations
  if (/(^|[\s;&|])(vim|nvim|nano|emacs|vi)\s/.test(cmd)) {
    return { block: true, immutable: true, reason: "**Editor blocked** ⛔ IMMUTABLE - Use Write tool or heredoc instead" };
  }
};

const guards: GuardFn[] = [
  blockCorporateBuzzwords,
  blockGitCommands,
  blockPush,
  blockFindCommand,
  blockGrepCommand,
  blockBrewInstall,
  blockRmCommand,
  blockPackageRunners,
  blockSecretTools,
  blockNixManagedWrites,
  blockTitleCaseHeaders,
  blockInteractiveCommands,
  blockDestructiveJjCommands, // CRITICAL: Protects uncommitted changes
];

// ============================================================================
// Extension entry point
// ============================================================================

export default function (pi: ExtensionAPI) {
  // Handle override commands from user
  pi.on("user_message", async (event, ctx) => {
    const text = event.message?.trim().toLowerCase() || "";
    
    // !override = immediate execution, no confirmation
    if (text === "!override") {
      if (state.lastBlockedCommand) {
        grantOverride(true);
        log(`!override: Will execute immediately`);
      } else {
        log(`!override: No blocked command to override`);
      }
      return;
    }
    
    // override = show UI confirmation prompt
    if (text === "override") {
      if (!state.lastBlockedCommand) {
        log(`override: No blocked command to override`);
        return;
      }
      
      // Show UI prompt if available
      if (ctx.hasUI) {
        const cmd = state.lastBlockedCommand;
        const choice = await ctx.ui.select(
          `⚠️  Override requested for:\n\n  ${cmd.slice(0, 100)}${cmd.length > 100 ? '...' : ''}\n\nAllow this command?`,
          ["Yes", "No"]
        );
        if (choice === "Yes") {
          grantOverride(false);
          log(`override: UI confirmed, permission granted`);
        } else {
          log(`override: UI rejected`);
          resetBlocked();
        }
      } else {
        // No UI, grant directly (fallback)
        grantOverride(false);
        log(`override: No UI, permission granted`);
      }
      return;
    }
    
    // yes/y = confirm after override prompt (legacy flow)
    if (text === "yes" || text === "y") {
      if (state.overrideGranted) {
        log(`yes: Override already granted`);
      } else if (state.lastBlockedCommand) {
        grantOverride(false);
        log(`yes: Permission granted`);
      }
      return;
    }
  });

  // Check guards on tool calls and agent responses
  for (const eventType of ["tool_call", "agent_response"] as const) {
    pi.on(eventType, async (event, ctx) => {
      for (const guard of guards) {
        try {
          const result = guard(event, ctx);
          if (result?.block) {
            // Immutable guards can never be overridden
            if (result.immutable) {
              log(`IMMUTABLE block: ${result.reason}`);
              return result;
            }
            
            // Check if override is valid and consume it
            if (event.toolName === "bash" && isOverrideValid()) {
              const allowed = consumeOverride();
              if (allowed) {
                log(`Override consumed, allowing: ${(event as ToolCallEvent).input.command.slice(0, 50)}...`);
                return undefined; // Allow the command
              }
            }
            
            // Store blocked command for override tracking (user can say `override` or `!override`)
            if (event.toolName === "bash") {
              const cmd = (event as ToolCallEvent).input.command;
              state.lastBlockedCommand = cmd;
              state.lastBlockedAt = Date.now();
              log(`Blocked (overridable): ${cmd.slice(0, 80)}...`);
            }
            
            return result;
          }
        } catch (e) {
          console.error("Guard error:", e);
        }
      }
    });
  }

  // Expose state for debugging (accessible via globalThis.__guardrailsState)
  (globalThis as Record<string, unknown>).__guardrailsState = state;
  (globalThis as Record<string, unknown>).__guardrailsGrantOverride = grantOverride;
  (globalThis as Record<string, unknown>).__guardrailsReset = () => { resetOverride(); resetBlocked(); };
}
