/**
 * pi-claude-code-use (local)
 *
 * Patches Pi's Anthropic OAuth payloads so Claude subscription requests look
 * like Claude Code use:
 * - rewrites "pi itself" prompt references to "the cli itself"
 * - filters tools to Claude Code core tools, Anthropic typed tools, and MCP tools
 * - optionally maps user-configured flat extension tool names to MCP-style aliases
 *
 * Based on @benvargas/pi-claude-code-use 1.0.4, minus companion-package loading
 * for packages not used here.
 */

import { appendFileSync, existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { getAgentDir } from "@earendil-works/pi-coding-agent";

type ToolAliasPair = readonly [flatName: string, mcpName: string];

type CacheControl = {
  type: "ephemeral";
  ttl?: "1h";
};

type TextBlock = {
  type: "text";
  text: string;
  cache_control?: CacheControl;
  [key: string]: unknown;
};

type AnthropicPayload = {
  messages?: Array<{
    role?: string;
    content?: string | unknown[];
    [key: string]: unknown;
  }>;
  tool_choice?: {
    type?: string;
    name?: string;
    [key: string]: unknown;
  };
  tools?: Array<{
    type?: string;
    name?: string;
    [key: string]: unknown;
  }>;
  system?: string | unknown[];
  [key: string]: unknown;
};

type AnthropicTransformOptions = {
  disableToolFiltering?: boolean;
};

type ActiveModel = NonNullable<ExtensionContext["model"]>;
type ToolInfo = ReturnType<ExtensionAPI["getAllTools"]>[number];

const CONFIG_FILENAME = "pi-claude-code-use.json";
const debugLogPath = process.env.PI_CLAUDE_CODE_USE_DEBUG_LOG;

// Mirror Pi core's Anthropic Claude Code tool set from:
// packages/ai/src/providers/anthropic.ts -> claudeCodeTools
const CORE_TOOL_NAMES = new Set(
  [
    "read",
    "write",
    "edit",
    "bash",
    "grep",
    "glob",
    "askuserquestion",
    "enterplanmode",
    "exitplanmode",
    "killshell",
    "notebookedit",
    "skill",
    "task",
    "taskoutput",
    "todowrite",
    "webfetch",
    "websearch",
  ].map((name) => name.toLowerCase()),
);

// Local fork intentionally has no built-in aliases for other users' companion
// packages. Users can opt into generic aliases with pi-claude-code-use.json.
const FLAT_TO_MCP = new Map<string, string>();
const MCP_TO_FLAT = new Map<string, string>();
const configuredMcpAliases = new Set<string>();
const autoActivatedAliases = new Set<string>();
let lastManagedToolList: string[] | undefined;

function isToolFilteringDisabled(options?: AnthropicTransformOptions): boolean {
  return (
    options?.disableToolFiltering ??
    process.env.PI_CLAUDE_CODE_USE_DISABLE_TOOL_FILTER === "1"
  );
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isTextBlock(value: unknown): value is TextBlock {
  return (
    isRecord(value) && value.type === "text" && typeof value.text === "string"
  );
}

function normalizeToolName(name: string | undefined): string {
  return (name ?? "").trim().toLowerCase();
}

function isCoreClaudeCodeToolName(name: string | undefined): boolean {
  return CORE_TOOL_NAMES.has(normalizeToolName(name));
}

function isMcpToolName(name: string | undefined): boolean {
  return normalizeToolName(name).startsWith("mcp__");
}

function readConfigFile(filePath: string): Record<string, unknown> {
  if (!existsSync(filePath)) {
    return {};
  }
  try {
    const parsed = JSON.parse(readFileSync(filePath, "utf8")) as unknown;
    return isRecord(parsed) ? parsed : {};
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.warn(`[pi-claude-code-use] Failed to read ${filePath}: ${message}`);
    return {};
  }
}

function extractToolAliasPairs(value: unknown): ToolAliasPair[] | undefined {
  if (!isRecord(value)) {
    return undefined;
  }
  const raw = value.toolAliases;
  if (raw === undefined) {
    return undefined;
  }
  if (!Array.isArray(raw)) {
    console.warn(
      `[pi-claude-code-use] Ignoring "toolAliases": expected array, got ${typeof raw}`,
    );
    return undefined;
  }
  return raw.filter(
    (entry): entry is ToolAliasPair =>
      Array.isArray(entry) &&
      typeof entry[0] === "string" &&
      typeof entry[1] === "string",
  );
}

function loadToolAliases(
  cwd: string,
  agentDir: string = getAgentDir(),
): ToolAliasPair[] {
  const globalPath = join(agentDir, "extensions", CONFIG_FILENAME);
  const projectPath = join(cwd, ".pi", "extensions", CONFIG_FILENAME);
  const merged = {
    ...readConfigFile(globalPath),
    ...readConfigFile(projectPath),
  };
  return extractToolAliasPairs(merged) ?? [];
}

function refreshAliasMap(userToolAliases: ToolAliasPair[]): void {
  FLAT_TO_MCP.clear();
  MCP_TO_FLAT.clear();
  configuredMcpAliases.clear();
  for (const [flat, mcp] of userToolAliases) {
    FLAT_TO_MCP.set(normalizeToolName(flat), mcp);
    MCP_TO_FLAT.set(normalizeToolName(mcp), flat);
    configuredMcpAliases.add(normalizeToolName(mcp));
  }
}

function collectToolNames(tools: unknown[]): Set<string> {
  const names = new Set<string>();
  for (const tool of tools) {
    if (isRecord(tool) && typeof tool.name === "string") {
      names.add(normalizeToolName(tool.name));
    }
  }
  return names;
}

function collectToolsByName(
  tools: unknown[],
): Map<string, Record<string, unknown>> {
  const byName = new Map<string, Record<string, unknown>>();
  for (const tool of tools) {
    if (isRecord(tool) && typeof tool.name === "string") {
      byName.set(normalizeToolName(tool.name), tool);
    }
  }
  return byName;
}

function getAdvertisedToolNames(tools: AnthropicPayload["tools"]): Set<string> {
  if (!Array.isArray(tools)) {
    return new Set<string>();
  }
  return collectToolNames(tools);
}

function rewritePiSelfReferences(text: string): string {
  return text
    .replaceAll("pi itself", "the cli itself")
    .replaceAll("pi .md files", "cli .md files")
    .replaceAll("pi packages", "cli packages");
}

function rewriteSystemBlocks(
  system: AnthropicPayload["system"],
): AnthropicPayload["system"] {
  if (typeof system === "string") {
    return rewritePiSelfReferences(system);
  }
  if (!Array.isArray(system)) {
    return system;
  }
  return system.map((block) => {
    if (!isTextBlock(block)) {
      return block;
    }
    const rewritten = rewritePiSelfReferences(block.text);
    return rewritten === block.text ? block : { ...block, text: rewritten };
  });
}

function filterAndRemapTools(
  tools: AnthropicPayload["tools"],
  disableFiltering: boolean,
): AnthropicPayload["tools"] {
  if (!Array.isArray(tools)) {
    return tools;
  }

  const advertised = collectToolNames(tools);
  const toolsByName = collectToolsByName(tools);
  const emitted = new Set<string>();
  const result: NonNullable<AnthropicPayload["tools"]> = [];

  for (const tool of tools) {
    if (!isRecord(tool)) {
      continue;
    }

    // Anthropic-native typed tools always pass through.
    if (typeof tool.type === "string" && tool.type.trim().length > 0) {
      result.push(tool);
      continue;
    }

    const originalName = typeof tool.name === "string" ? tool.name : "";
    if (!originalName) {
      continue;
    }
    const name = normalizeToolName(originalName);

    if (isCoreClaudeCodeToolName(originalName) || isMcpToolName(originalName)) {
      if (!emitted.has(name)) {
        emitted.add(name);
        result.push(tool);
      }
      continue;
    }

    const mcpAlias = FLAT_TO_MCP.get(name);
    if (mcpAlias) {
      const aliasName = normalizeToolName(mcpAlias);
      if (advertised.has(aliasName) && !emitted.has(aliasName)) {
        // Preserve alias metadata, including cache_control, when alias exists.
        emitted.add(aliasName);
        result.push(toolsByName.get(aliasName) ?? { ...tool, name: mcpAlias });
      } else if (disableFiltering && !emitted.has(name)) {
        emitted.add(name);
        result.push(tool);
      }
      continue;
    }

    if (disableFiltering && !emitted.has(name)) {
      emitted.add(name);
      result.push(tool);
    }
  }

  return result;
}

function rewriteAnthropicToolChoice(
  toolChoice: AnthropicPayload["tool_choice"],
  survivingNames: Map<string, string>,
): AnthropicPayload["tool_choice"] {
  if (toolChoice?.type !== "tool" || typeof toolChoice.name !== "string") {
    return toolChoice;
  }

  const name = normalizeToolName(toolChoice.name);
  const actualName = survivingNames.get(name);
  if (actualName) {
    return actualName === toolChoice.name
      ? toolChoice
      : { ...toolChoice, name: actualName };
  }

  const mcpAlias = FLAT_TO_MCP.get(name);
  if (mcpAlias && survivingNames.has(normalizeToolName(mcpAlias))) {
    return { ...toolChoice, name: mcpAlias };
  }

  return undefined;
}

function remapBlockNames(
  content: unknown[],
  blockType: "tool_use" | "toolCall",
  mapName: (name: string) => string | undefined,
): unknown[] {
  let changed = false;
  const next = content.map((block) => {
    if (
      !isRecord(block) ||
      block.type !== blockType ||
      typeof block.name !== "string"
    ) {
      return block;
    }
    const newName = mapName(block.name);
    if (!newName || newName === block.name) {
      return block;
    }
    changed = true;
    return { ...block, name: newName };
  });
  return changed ? next : content;
}

function rewriteHistoricalToolUseBlocks(
  messages: AnthropicPayload["messages"],
  survivingNames: Map<string, string>,
): AnthropicPayload["messages"] {
  if (!Array.isArray(messages)) {
    return messages;
  }

  let changed = false;
  const nextMessages = messages.map((message) => {
    if (!Array.isArray(message?.content)) {
      return message;
    }

    const content = remapBlockNames(message.content, "tool_use", (name) => {
      const mcpAlias = FLAT_TO_MCP.get(normalizeToolName(name));
      return mcpAlias && survivingNames.has(normalizeToolName(mcpAlias))
        ? mcpAlias
        : undefined;
    });
    if (content === message.content) {
      return message;
    }

    changed = true;
    return { ...message, content };
  });

  return changed ? nextMessages : messages;
}

function unaliasToolCalls(message: unknown): unknown {
  if (!isRecord(message) || message.role !== "assistant") {
    return undefined;
  }
  if (!Array.isArray(message.content)) {
    return undefined;
  }

  const content = remapBlockNames(message.content, "toolCall", (name) => {
    const flat = MCP_TO_FLAT.get(normalizeToolName(name));
    if (!flat || !configuredMcpAliases.has(normalizeToolName(name))) {
      return undefined;
    }
    return flat;
  });

  return content === message.content ? undefined : { ...message, content };
}

function clonePayload(payload: AnthropicPayload): AnthropicPayload {
  return JSON.parse(JSON.stringify(payload)) as AnthropicPayload;
}

function transformAnthropicOAuthPayload(
  payload: AnthropicPayload,
  options?: AnthropicTransformOptions,
): AnthropicPayload {
  const disableFiltering = isToolFilteringDisabled(options);
  const nextPayload = clonePayload(payload);

  if (nextPayload.system !== undefined) {
    nextPayload.system = rewriteSystemBlocks(nextPayload.system);
  }

  if (disableFiltering) {
    return nextPayload;
  }

  nextPayload.tools = filterAndRemapTools(nextPayload.tools, false);

  const survivingNames = new Map<string, string>();
  if (Array.isArray(nextPayload.tools)) {
    for (const tool of nextPayload.tools) {
      if (typeof tool?.name === "string") {
        survivingNames.set(normalizeToolName(tool.name), tool.name);
      }
    }
  }

  if (nextPayload.tool_choice !== undefined) {
    const rewrittenToolChoice = rewriteAnthropicToolChoice(
      nextPayload.tool_choice,
      survivingNames,
    );
    if (rewrittenToolChoice === undefined) {
      delete nextPayload.tool_choice;
    } else {
      nextPayload.tool_choice = rewrittenToolChoice;
    }
  }

  if (nextPayload.messages !== undefined) {
    nextPayload.messages = rewriteHistoricalToolUseBlocks(
      nextPayload.messages,
      survivingNames,
    );
  }

  return nextPayload;
}

function syncAliasActivation(pi: ExtensionAPI, enableAliases: boolean): void {
  const activeNames = pi.getActiveTools();
  const allNames = new Set(pi.getAllTools().map((tool: ToolInfo) => tool.name));

  if (enableAliases) {
    const activeLc = new Set(activeNames.map(normalizeToolName));
    const desiredAliases: string[] = [];
    for (const [flat, mcp] of FLAT_TO_MCP) {
      if (
        activeLc.has(flat) &&
        allNames.has(mcp) &&
        configuredMcpAliases.has(normalizeToolName(mcp))
      ) {
        desiredAliases.push(mcp);
      }
    }
    const desiredSet = new Set(desiredAliases);

    if (lastManagedToolList !== undefined) {
      const activeSet = new Set(activeNames);
      const lastManaged = new Set(lastManagedToolList);
      for (const alias of autoActivatedAliases) {
        if (!activeSet.has(alias) || desiredSet.has(alias)) {
          continue;
        }
        const flatName = [...FLAT_TO_MCP.entries()].find(
          ([, mcp]) => mcp === alias,
        )?.[0];
        if (flatName && lastManaged.has(flatName) && !activeSet.has(flatName)) {
          autoActivatedAliases.delete(alias);
        }
      }
    }

    const activeConfiguredAliases = activeNames.filter(
      (name) =>
        configuredMcpAliases.has(normalizeToolName(name)) && allNames.has(name),
    );
    const preserved = activeConfiguredAliases.filter(
      (name) => !autoActivatedAliases.has(name),
    );
    const nonAlias = activeNames.filter(
      (name) => !configuredMcpAliases.has(normalizeToolName(name)),
    );
    const next = Array.from(
      new Set([...nonAlias, ...preserved, ...desiredAliases]),
    );

    const preservedSet = new Set(preserved);
    autoActivatedAliases.clear();
    for (const name of desiredAliases) {
      if (!preservedSet.has(name)) {
        autoActivatedAliases.add(name);
      }
    }

    if (
      next.length !== activeNames.length ||
      next.some((name, i) => name !== activeNames[i])
    ) {
      pi.setActiveTools(next);
      lastManagedToolList = [...next];
    }
    return;
  }

  const next = activeNames.filter((name) => !autoActivatedAliases.has(name));
  autoActivatedAliases.clear();
  if (
    next.length !== activeNames.length ||
    next.some((name, i) => name !== activeNames[i])
  ) {
    pi.setActiveTools(next);
    lastManagedToolList = [...next];
  } else {
    lastManagedToolList = undefined;
  }
}

function debugLogPayload(payload: unknown): void {
  if (!debugLogPath) {
    return;
  }

  try {
    appendFileSync(
      debugLogPath,
      `${new Date().toISOString()}\n${JSON.stringify(payload, null, 2)}\n---\n`,
      "utf8",
    );
  } catch {}
}

function isAnthropicOAuthModel(
  model: ActiveModel | undefined,
  modelRegistry: ExtensionContext["modelRegistry"],
): model is ActiveModel {
  if (!model || !modelRegistry.isUsingOAuth(model)) {
    return false;
  }

  return (
    model.provider === "anthropic" ||
    /(^|-)anthropic($|-)/.test(model.provider) ||
    model.api === "anthropic-messages"
  );
}

export default async function piClaudeCodeUse(pi: ExtensionAPI): Promise<void> {
  pi.on("session_start", (_event, ctx) => {
    refreshAliasMap(loadToolAliases(ctx.cwd));
  });

  pi.on("before_agent_start", (_event, ctx) => {
    refreshAliasMap(loadToolAliases(ctx.cwd));
    syncAliasActivation(
      pi,
      isAnthropicOAuthModel(ctx.model, ctx.modelRegistry),
    );
  });

  pi.on("message_end", (event) => {
    const rewritten = unaliasToolCalls(event.message);
    if (!rewritten) {
      return undefined;
    }
    return { message: rewritten as typeof event.message };
  });

  pi.on("before_provider_request", (event, ctx) => {
    const model = ctx.model;
    if (!isAnthropicOAuthModel(model, ctx.modelRegistry)) {
      return undefined;
    }
    if (!isRecord(event.payload)) {
      return undefined;
    }

    debugLogPayload({
      stage: "before",
      provider: model.provider,
      payload: event.payload,
    });
    const transformedPayload = transformAnthropicOAuthPayload(
      event.payload as AnthropicPayload,
    );
    debugLogPayload({
      stage: "after",
      provider: model.provider,
      payload: transformedPayload,
    });
    return transformedPayload;
  });
}

export const _test = {
  CORE_TOOL_NAMES,
  MCP_TO_FLAT,
  FLAT_TO_MCP,
  autoActivatedAliases,
  collectToolNames,
  extractToolAliasPairs,
  filterAndRemapTools,
  getAdvertisedToolNames,
  loadToolAliases,
  normalizeToolName,
  refreshAliasMap,
  rewriteAnthropicToolChoice,
  rewriteHistoricalToolUseBlocks,
  rewritePiSelfReferences,
  rewriteSystemBlocks,
  setLastManagedToolList: (value: string[] | undefined) => {
    lastManagedToolList = value;
  },
  syncAliasActivation,
  transformAnthropicOAuthPayload,
  unaliasToolCalls,
};
