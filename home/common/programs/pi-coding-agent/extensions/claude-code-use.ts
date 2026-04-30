/**
 * pi-claude-code-use (simplified)
 *
 * Patches Pi's Anthropic provider so that OAuth subscription requests are
 * classified as "subscription use" rather than "third-party/extra usage".
 *
 * Core trick: rewrite "pi itself" → "the cli itself" in system prompts,
 * and filter tools to only include known Claude Code tools + MCP tools.
 *
 * Based on: https://github.com/ben-vargas/pi-packages/pull/8
 * Simplified to remove jiti-dependent companion extension aliasing.
 */

import { appendFileSync } from "node:fs";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

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

const debugLogPath = process.env.PI_CLAUDE_CODE_USE_DEBUG_LOG;

// Mirror Pi core's Anthropic Claude Code tool set from:
// packages/ai/src/providers/anthropic.ts -> claudeCodeTools
const ALLOWED_TOOL_NAMES = new Set(
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

function isToolFilteringDisabled(options?: AnthropicTransformOptions): boolean {
	return options?.disableToolFiltering ?? process.env.PI_CLAUDE_CODE_USE_DISABLE_TOOL_FILTER === "1";
}

function isRecord(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isTextBlock(value: unknown): value is TextBlock {
	return isRecord(value) && value.type === "text" && typeof value.text === "string";
}

function normalizeToolName(name: string | undefined): string {
	return (name ?? "").trim().toLowerCase();
}

function isCoreClaudeCodeToolName(name: string | undefined): boolean {
	return ALLOWED_TOOL_NAMES.has(normalizeToolName(name));
}

function isMcpToolName(name: string | undefined): boolean {
	return normalizeToolName(name).startsWith("mcp__");
}

function getAdvertisedToolNames(tools: AnthropicPayload["tools"]): Set<string> {
	if (!Array.isArray(tools)) {
		return new Set<string>();
	}
	return new Set(
		tools
			.map((tool) => (typeof tool?.name === "string" ? normalizeToolName(tool.name) : ""))
			.filter((name) => name.length > 0),
	);
}

function getClaudeCodeVisibleToolName(toolName: string | undefined): string | undefined {
	if (!toolName) {
		return undefined;
	}
	if (isCoreClaudeCodeToolName(toolName) || isMcpToolName(toolName)) {
		return toolName;
	}
	return undefined;
}

function rewriteAnthropicToolChoice(
	toolChoice: AnthropicPayload["tool_choice"],
	advertisedToolNames: Set<string>,
	disableFiltering: boolean,
): AnthropicPayload["tool_choice"] {
	if (toolChoice?.type !== "tool" || typeof toolChoice.name !== "string") {
		return toolChoice;
	}

	const visibleToolName = getClaudeCodeVisibleToolName(toolChoice.name);
	if (visibleToolName) {
		return visibleToolName === toolChoice.name ? toolChoice : { ...toolChoice, name: visibleToolName };
	}
	if (disableFiltering) {
		return toolChoice;
	}
	return undefined;
}

function rewriteHistoricalToolUseBlocks(
	messages: AnthropicPayload["messages"],
	advertisedToolNames: Set<string>,
): AnthropicPayload["messages"] {
	if (!Array.isArray(messages)) {
		return messages;
	}

	return messages.map((message) => {
		if (!Array.isArray(message?.content)) {
			return message;
		}

		let changed = false;
		const content = message.content.map((block) => {
			if (!isRecord(block) || block.type !== "tool_use" || typeof block.name !== "string") {
				return block;
			}

			const visibleToolName = getClaudeCodeVisibleToolName(block.name);
			if (!visibleToolName || visibleToolName === block.name) {
				return block;
			}

			changed = true;
			return { ...block, name: visibleToolName };
		});

		return changed ? { ...message, content } : message;
	});
}

function clonePayload(payload: AnthropicPayload): AnthropicPayload {
	return JSON.parse(JSON.stringify(payload)) as AnthropicPayload;
}

function rewritePiSelfReferences(text: string): string {
	return text
		.replaceAll("pi itself", "the cli itself")
		.replaceAll("pi .md files", "cli .md files")
		.replaceAll("pi packages", "cli packages");
}

function rewriteSystemBlocks(system: AnthropicPayload["system"]): AnthropicPayload["system"] {
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

function filterToolsForClaudeCode(payload: AnthropicPayload, options?: AnthropicTransformOptions): AnthropicPayload {
	const disableFiltering = isToolFilteringDisabled(options);
	const advertisedToolNames = getAdvertisedToolNames(payload.tools);
	let tools = payload.tools;

	if (Array.isArray(payload.tools)) {
		const seenToolNames = new Set<string>();
		tools = payload.tools.flatMap((tool) => {
			if (typeof tool?.type === "string" && tool.type.trim().length > 0) {
				return [tool];
			}

			const originalName = typeof tool?.name === "string" ? tool.name : undefined;
			const visibleName = getClaudeCodeVisibleToolName(originalName);
			const nextName = visibleName ?? (disableFiltering ? originalName : undefined);
			const normalizedNextName = normalizeToolName(nextName);
			if (!nextName || seenToolNames.has(normalizedNextName)) {
				return [];
			}

			seenToolNames.add(normalizedNextName);
			return [nextName === originalName ? tool : { ...tool, name: nextName }];
		});
	}

	const rewrittenToolChoice = rewriteAnthropicToolChoice(
		payload.tool_choice,
		getAdvertisedToolNames(tools),
		disableFiltering,
	);

	return {
		...payload,
		...(tools ? { tools } : {}),
		...(rewrittenToolChoice ? { tool_choice: rewrittenToolChoice } : {}),
		...(rewrittenToolChoice ? {} : { tool_choice: undefined }),
	};
}

function transformAnthropicOAuthPayload(
	payload: AnthropicPayload,
	options?: AnthropicTransformOptions,
): AnthropicPayload {
	const nextPayload = filterToolsForClaudeCode(clonePayload(payload), options);
	if (nextPayload.system !== undefined) {
		nextPayload.system = rewriteSystemBlocks(nextPayload.system);
	}
	if (nextPayload.messages !== undefined) {
		nextPayload.messages = rewriteHistoricalToolUseBlocks(
			nextPayload.messages,
			getAdvertisedToolNames(nextPayload.tools),
		);
	}
	return nextPayload;
}

function debugLogPayload(payload: unknown): void {
	if (!debugLogPath) {
		return;
	}

	try {
		appendFileSync(debugLogPath, `${new Date().toISOString()}\n${JSON.stringify(payload, null, 2)}\n---\n`, "utf8");
	} catch {}
}

export default async function piClaudeCodeUse(pi: ExtensionAPI): Promise<void> {
	pi.on("before_provider_request", (event, ctx) => {
		const model = ctx.model;
		if (!model || model.provider !== "anthropic" || !ctx.modelRegistry.isUsingOAuth(model)) {
			return undefined;
		}
		if (!isRecord(event.payload)) {
			return undefined;
		}

		debugLogPayload({ stage: "before", payload: event.payload });
		const transformedPayload = transformAnthropicOAuthPayload(event.payload as AnthropicPayload);
		debugLogPayload({ stage: "after", payload: transformedPayload });
		return transformedPayload;
	});
}
