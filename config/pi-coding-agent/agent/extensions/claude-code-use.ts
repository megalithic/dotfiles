/**
 * pi-claude-code-use (local)
 *
 * Patches Pi's Anthropic OAuth payloads so Claude subscription requests look
 * like Claude Code use:
 * - rewrites "pi itself" prompt references to "the cli itself"
 * - renames unknown flat extension tools to `mcp__pi__<name>` on the wire so
 *   they pass Anthropic's tool-name classifier instead of being dropped,
 *   then unmaps `mcp__pi__*` tool calls back to their flat names before Pi
 *   resolves them (approach from @zgltyq/pi-provider-claude)
 * - passes Claude Code core tools, Anthropic typed tools, and real MCP tools
 *   through untouched
 *
 * Based on @benvargas/pi-claude-code-use 1.0.4. The previous toolAliases
 * config (pi-claude-code-use.json) is gone: renaming keeps every extension
 * tool visible, so user-maintained alias maps are no longer needed.
 */

import { appendFileSync } from "node:fs";
import type {
	ExtensionAPI,
	ExtensionContext,
} from "@earendil-works/pi-coding-agent";

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
	disableToolRenaming?: boolean;
};

type ActiveModel = NonNullable<ExtensionContext["model"]>;

const debugLogPath = process.env.PI_CLAUDE_CODE_USE_DEBUG_LOG;

// Prefix used to disguise flat tools as MCP tools. Kept short so
// `mcp__pi__<name>` stays well under Anthropic's 64-char tool-name limit.
const ALIAS_PREFIX = "mcp__pi__";

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

function isToolRenamingDisabled(options?: AnthropicTransformOptions): boolean {
	return (
		options?.disableToolRenaming ??
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

// True for tools that must NOT be renamed: Anthropic-native typed tools, core
// Claude Code tools, already-mcp__ tools, or nameless entries.
function shouldRenameTool(tool: Record<string, unknown>): boolean {
	if (typeof tool.type === "string" && tool.type.trim().length > 0) {
		return false;
	}
	const name = typeof tool.name === "string" ? tool.name : "";
	if (!name) {
		return false;
	}
	return !isCoreClaudeCodeToolName(name) && !isMcpToolName(name);
}

// Rename unknown flat tools to `mcp__pi__<name>`; returns surviving tools plus
// the flat→alias map of exactly what was renamed (so tool_choice and message
// history stay consistent). Schema and cache_control ride along unchanged.
function renameFlatTools(tools: AnthropicPayload["tools"]): {
	tools: AnthropicPayload["tools"];
	renamed: Map<string, string>;
} {
	const renamed = new Map<string, string>();
	if (!Array.isArray(tools)) {
		return { tools, renamed };
	}

	const emitted = new Set<string>();
	const result: NonNullable<AnthropicPayload["tools"]> = [];

	for (const tool of tools) {
		if (!isRecord(tool)) {
			continue;
		}

		if (!shouldRenameTool(tool)) {
			const key =
				typeof tool.name === "string"
					? normalizeToolName(tool.name)
					: `__native_${result.length}`;
			if (emitted.has(key)) {
				continue;
			}
			emitted.add(key);
			result.push(tool);
			continue;
		}

		const name = tool.name as string;
		const alias = ALIAS_PREFIX + name;
		renamed.set(normalizeToolName(name), alias);
		const aliasKey = normalizeToolName(alias);
		if (emitted.has(aliasKey)) {
			continue;
		}
		emitted.add(aliasKey);
		result.push({ ...tool, name: alias });
	}

	return { tools: result, renamed };
}

function rewriteAnthropicToolChoice(
	toolChoice: AnthropicPayload["tool_choice"],
	renamed: Map<string, string>,
): AnthropicPayload["tool_choice"] {
	if (toolChoice?.type !== "tool" || typeof toolChoice.name !== "string") {
		return toolChoice;
	}
	const alias = renamed.get(normalizeToolName(toolChoice.name));
	return alias ? { ...toolChoice, name: alias } : toolChoice;
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

// Rewrite historical tool_use block names to match the renamed tools.
function rewriteHistoricalToolUseBlocks(
	messages: AnthropicPayload["messages"],
	renamed: Map<string, string>,
): AnthropicPayload["messages"] {
	if (!Array.isArray(messages) || renamed.size === 0) {
		return messages;
	}

	let changed = false;
	const nextMessages = messages.map((message) => {
		if (!Array.isArray(message?.content)) {
			return message;
		}

		const content = remapBlockNames(message.content, "tool_use", (name) =>
			renamed.get(normalizeToolName(name)),
		);
		if (content === message.content) {
			return message;
		}

		changed = true;
		return { ...message, content };
	});

	return changed ? nextMessages : messages;
}

// Rewrite mcp__pi__<name> tool calls back to <name> in the finalized assistant
// message, BEFORE Pi resolves which tool to run. Only touches our own prefix,
// so foreign mcp__ tools (real MCP servers) are untouched.
function unaliasToolCalls(message: unknown): unknown {
	if (!isRecord(message) || message.role !== "assistant") {
		return undefined;
	}
	if (!Array.isArray(message.content)) {
		return undefined;
	}

	const content = remapBlockNames(message.content, "toolCall", (name) =>
		name.startsWith(ALIAS_PREFIX) ? name.slice(ALIAS_PREFIX.length) : undefined,
	);

	return content === message.content ? undefined : { ...message, content };
}

function clonePayload(payload: AnthropicPayload): AnthropicPayload {
	return JSON.parse(JSON.stringify(payload)) as AnthropicPayload;
}

function transformAnthropicOAuthPayload(
	payload: AnthropicPayload,
	options?: AnthropicTransformOptions,
): AnthropicPayload {
	const disableRenaming = isToolRenamingDisabled(options);
	const nextPayload = clonePayload(payload);

	if (nextPayload.system !== undefined) {
		nextPayload.system = rewriteSystemBlocks(nextPayload.system);
	}

	if (disableRenaming) {
		return nextPayload;
	}

	const { tools, renamed } = renameFlatTools(nextPayload.tools);
	nextPayload.tools = tools;

	if (nextPayload.tool_choice !== undefined) {
		nextPayload.tool_choice = rewriteAnthropicToolChoice(
			nextPayload.tool_choice,
			renamed,
		);
	}

	if (nextPayload.messages !== undefined) {
		nextPayload.messages = rewriteHistoricalToolUseBlocks(
			nextPayload.messages,
			renamed,
		);
	}

	return nextPayload;
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
	// mcp__pi__* → flat, before the agent loop resolves the tool. Runs
	// unconditionally: alias names only ever originate from our own transform.
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
	ALIAS_PREFIX,
	CORE_TOOL_NAMES,
	normalizeToolName,
	renameFlatTools,
	rewriteAnthropicToolChoice,
	rewriteHistoricalToolUseBlocks,
	rewritePiSelfReferences,
	rewriteSystemBlocks,
	shouldRenameTool,
	transformAnthropicOAuthPayload,
	unaliasToolCalls,
};
