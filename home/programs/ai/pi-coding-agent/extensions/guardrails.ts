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
];

// ============================================================================
// Extension entry point
// ============================================================================

export default function (pi: ExtensionAPI) {
  // Handle override commands from user
  pi.on("user_message", async (event) => {
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
    
    // override or yes/y = grant permission (agent handles confirmation flow)
    if (text === "override" || text === "yes" || text === "y") {
      if (state.lastBlockedCommand || state.overrideGranted) {
        grantOverride(state.noConfirm);
        log(`override/yes: Permission granted`);
      } else {
        log(`override/yes: No blocked command to override`);
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
                return undefined; // Allow the command
              }
            }
            
            // Store blocked command for override tracking
            if (event.toolName === "bash") {
              const cmd = (event as ToolCallEvent).input.command;
              state.lastBlockedCommand = cmd;
              state.lastBlockedAt = Date.now();
              log(`Blocked: ${cmd.slice(0, 80)}...`);
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
