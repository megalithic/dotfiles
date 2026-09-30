import { estimateTokens as estimateMessageTokens } from "@earendil-works/pi-coding-agent";

/** Rough char-based token estimate. Matches OM's heuristic (≈4 chars/token). */
export function estimateStringTokens(text: string): number {
	return Math.ceil(text.length / 4);
}

/**
 * Estimate the token cost of a single ledger entry. Only "source" entries
 * (message / custom_message / branch_summary) carry conversational text; every
 * other entry type (memory ledger records, compaction, etc.) contributes 0 so
 * the raw-token clocks measure only new conversation.
 */
export function estimateEntryTokens(entry: { type: string; message?: unknown; content?: unknown; summary?: unknown }): number {
	if (entry.type === "message" && entry.message) {
		return estimateMessageTokens(entry.message as Parameters<typeof estimateMessageTokens>[0]);
	}
	if (entry.type === "custom_message" && entry.content) {
		const content = entry.content;
		if (typeof content === "string") return estimateStringTokens(content);
		if (Array.isArray(content)) {
			let total = 0;
			for (const block of content) {
				if (block.type === "text" && block.text) total += estimateStringTokens(block.text);
			}
			return total;
		}
	}
	if (entry.type === "branch_summary" && typeof entry.summary === "string") {
		return estimateStringTokens(entry.summary);
	}
	return 0;
}
