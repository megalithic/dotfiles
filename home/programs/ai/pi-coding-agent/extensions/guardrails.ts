/**
 * Coding Guardrails Extension - Override protocol support
 */
import type { ExtensionAPI, ToolCallEvent, AgentResponseEvent, ExtensionContext } from "@mariozechner/pi-coding-agent";
interface GuardResult { block: true; reason: string; immutable?: boolean; }
type GuardFn = (event: ToolCallEvent | AgentResponseEvent, ctx: ExtensionContext) => GuardResult | undefined;
const state = { lastBlockedCommand: null as string | null, overrideGranted: false };
function getResponseText(event: AgentResponseEvent): string {
  return event.response.content.filter((c) => c.type === "text").map((c) => c.text).join("\n");
}

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
  if (/(^|[\s;&|])(git\s+push|jj\s+git\s+push)/.test(cmd)) {
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

const blockNpxBunx: GuardFn = (event) => {
  if (event.toolName !== "bash") return;
  if (/\b(npx|bunx)\s+/.test((event as ToolCallEvent).input.command)) {
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
  if (event.toolName !== "bash" && event.toolName !== "write" && event.toolName !== "edit") return;
  let path = event.toolName === "bash" ? (event as ToolCallEvent).input.command : ((event as ToolCallEvent).input.path || "");
  if (!path) return;
  path = path.replace(/^~\//, process.env.HOME + "/").replace(/^\$HOME\//, process.env.HOME + "/");
  const managed = [process.env.HOME + "/bin/", process.env.HOME + "/.config/", process.env.HOME + "/.hammerspoon/", process.env.HOME + "/.pi/agent/", "/nix/store/"];
  for (const m of managed) {
    if (path.includes(m)) {
      return { block: true, immutable: true, reason: "**Write to " + m + " blocked** ⛔ IMMUTABLE - Edit ~/.dotfiles/ source instead." };
    }
  }
};

const blockTitleCaseHeaders: GuardFn = (event) => {
  if (event.toolName !== "agent_response") return;
  if (/^#+\s+(?:[A-Z][a-z]*\\s+)+[A-Z][a-z]+/m.test(getResponseText(event as AgentResponseEvent))) {
    return { block: true, reason: "**Title case** - Use sentence case." };
  }
};

const guards: GuardFn[] = [blockCorporateBuzzwords, blockGitCommands, blockPush, blockFindCommand, blockGrepCommand, blockBrewInstall, blockRmCommand, blockNpxBunx, blockSecretTools, blockNixManagedWrites, blockTitleCaseHeaders];

export default function (pi: ExtensionAPI) {
  pi.on("user_message", async (event) => {
    const text = event.message?.trim().toLowerCase() || "";
    if (text === "!override" || text === "override" || text === "y" || text === "yes") {
      if (state.lastBlockedCommand) { state.overrideGranted = true; console.log("[guardrails] Override granted"); }
    }
  });
  for (const eventType of ["tool_call", "agent_response"] as const) {
    pi.on(eventType, async (event, ctx) => {
      for (const guard of guards) {
        try {
          const result = guard(event, ctx);
          if (result?.block) {
            if (result.immutable) return result;
            if (state.overrideGranted && event.toolName === "bash") {
              state.overrideGranted = false; state.lastBlockedCommand = null;
              console.log("[guardrails] Override consumed"); return undefined;
            }
            if (event.toolName === "bash") state.lastBlockedCommand = (event as ToolCallEvent).input.command;
            return result;
          }
        } catch (e) { console.error("Guard error:", e); }
      }
    });
  }
}
