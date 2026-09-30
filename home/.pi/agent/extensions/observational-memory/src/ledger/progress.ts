import { estimateEntryTokens } from "../tokens.js";
import {
	OM_OBSERVATIONS_DROPPED,
	OM_OBSERVATIONS_RECORDED,
	type Entry,
	type MemoryCustomType,
} from "./types.js";

const SOURCE_ENTRY_TYPES = new Set(["message", "custom_message", "branch_summary"]);

export function isSourceEntry(entry: Entry): boolean {
	return SOURCE_ENTRY_TYPES.has(entry.type);
}

/**
 * A source entry is a valid chunk/compaction boundary only if it can legitimately START a
 * chunk — i.e. it is not a tool-result message. In pi a tool call (an assistant message) and
 * its result(s) are SEPARATE source entries; a boundary placed between them would split a
 * tool call from its result across two chunks. Anchoring boundaries to non-tool-result entries
 * keeps every tool call together with its result in the same chunk (and the same verbatim tail
 * at compaction). Shared by `selectSourceSlice` (chunk cutting) and the compaction snapper.
 */
export function isValidCutPoint(entry: Entry): boolean {
	if (entry.type === "custom_message" || entry.type === "branch_summary") return true;
	if (entry.type === "message") {
		const role = (entry.message as { role?: string } | undefined)?.role;
		return role === "user" || role === "assistant";
	}
	return false;
}

/** Id of the last source entry on the branch (the tip). Tombstone `coversUpToId` anchor. */
export function lastSourceEntryId(entries: Entry[]): string | undefined {
	for (let i = entries.length - 1; i >= 0; i--) {
		if (isSourceEntry(entries[i])) return entries[i].id;
	}
	return undefined;
}

export function entryIndexById(entries: Entry[]): Map<string, number> {
	const idToIndex = new Map<string, number>();
	for (let i = 0; i < entries.length; i++) idToIndex.set(entries[i].id, i);
	return idToIndex;
}

export function entryIndexForId(entries: Entry[], entryId: string | undefined): number {
	if (!entryId) return -1;
	const idx = entryIndexById(entries).get(entryId);
	return idx ?? -1;
}

function isObject(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null;
}

function isNonEmptyArray(value: unknown): value is unknown[] {
	return Array.isArray(value) && value.length > 0;
}

function isValidCoverageEntry(entry: Entry, customType: MemoryCustomType): entry is Entry & { data: { coversUpToId: string } } {
	if (entry.type !== "custom" || entry.customType !== customType) return false;
	if (!isObject(entry.data) || typeof entry.data.coversUpToId !== "string") return false;

	if (customType === OM_OBSERVATIONS_RECORDED) return isNonEmptyArray(entry.data.observations);
	return isNonEmptyArray(entry.data.observationTimestamps);
}

export function latestCoverageIndex(entries: Entry[], customType: MemoryCustomType): number {
	const idToIndex = entryIndexById(entries);
	let latest = -1;

	for (const entry of entries) {
		if (!isValidCoverageEntry(entry, customType)) continue;
		const coveredIndex = idToIndex.get(entry.data.coversUpToId);
		if (coveredIndex === undefined) continue;
		if (coveredIndex > latest) latest = coveredIndex;
	}

	return latest;
}

export function latestCoverageMarkerId(entries: Entry[], customType: MemoryCustomType): string | undefined {
	const idToIndex = entryIndexById(entries);
	let latestIndex = -1;
	let latestMarkerId: string | undefined;

	for (const entry of entries) {
		if (!isValidCoverageEntry(entry, customType)) continue;
		const coveredIndex = idToIndex.get(entry.data.coversUpToId);
		if (coveredIndex === undefined) continue;
		if (coveredIndex > latestIndex) {
			latestIndex = coveredIndex;
			latestMarkerId = entry.data.coversUpToId;
		}
	}

	return latestMarkerId;
}

export function earlierCoverageMarkerId(
	entries: Entry[],
	firstId: string | undefined,
	secondId: string | undefined,
): string | undefined {
	if (!firstId) return secondId;
	if (!secondId) return firstId;

	const idToIndex = entryIndexById(entries);
	const firstIndex = idToIndex.get(firstId);
	const secondIndex = idToIndex.get(secondId);
	if (firstIndex === undefined) return secondIndex === undefined ? undefined : secondId;
	if (secondIndex === undefined) return firstId;
	return firstIndex <= secondIndex ? firstId : secondId;
}

export function rawTokensAfterIndex(entries: Entry[], index: number): number {
	let total = 0;
	for (let i = Math.max(0, index + 1); i < entries.length; i++) {
		if (isSourceEntry(entries[i])) total += estimateEntryTokens(entries[i]);
	}
	return total;
}

export function rawTokensSinceCoverage(entries: Entry[], customType: MemoryCustomType): number {
	return rawTokensAfterIndex(entries, latestCoverageIndex(entries, customType));
}

export function rawTokensSinceObservationCoverage(entries: Entry[]): number {
	return rawTokensSinceCoverage(entries, OM_OBSERVATIONS_RECORDED);
}

export function rawTokensSinceDropCoverage(entries: Entry[]): number {
	return rawTokensSinceCoverage(entries, OM_OBSERVATIONS_DROPPED);
}

export function findLastCompactionIndex(entries: Entry[]): number {
	for (let i = entries.length - 1; i >= 0; i--) {
		if (entries[i].type === "compaction") return i;
	}
	return -1;
}

export function rawTokensSinceLastCompaction(entries: Entry[]): number {
	const compactionIndex = findLastCompactionIndex(entries);
	if (compactionIndex === -1) return rawTokensAfterIndex(entries, -1);

	const firstKeptEntryId = entries[compactionIndex].firstKeptEntryId;
	const firstKeptIndex = entryIndexForId(entries, firstKeptEntryId);

	if (firstKeptIndex === -1) return rawTokensAfterIndex(entries, compactionIndex);
	return rawTokensAfterIndex(entries, firstKeptIndex - 1);
}

export type SourceSlice = {
	entries: Entry[];
	/** Id of the last source entry in the slice → the chunk's `coversUpToId` watermark. */
	coversUpToId: string | undefined;
	tokens: number;
};

/**
 * Select the next observation chunk: the source entries strictly after `afterEntryId`
 * (the latest covered watermark), accumulated until adding the next entry would exceed
 * `chunkTokens`. Always includes at least one source entry so progress never stalls on a
 * single oversized entry. Non-source entries (ledger records, compaction) are skipped.
 *
 * The cut only lands on a valid boundary (`isValidCutPoint`): a chunk never ends with a tool
 * call whose result is a separate, later entry. When the token budget is reached but the next
 * entry is a tool result, the slice keeps extending past the budget until it reaches an entry
 * that may legitimately start the next chunk — so tool calls and their results always stay in
 * the same chunk.
 */
export function selectSourceSlice(entries: Entry[], afterEntryId: string | undefined, chunkTokens: number): SourceSlice {
	const startIndex = afterEntryId ? entryIndexForId(entries, afterEntryId) : -1;
	const slice: Entry[] = [];
	let tokens = 0;
	let coversUpToId: string | undefined;

	for (let i = Math.max(0, startIndex + 1); i < entries.length; i++) {
		const entry = entries[i];
		if (!isSourceEntry(entry)) continue;
		const entryTokens = estimateEntryTokens(entry);
		// Break only when over budget AND `entry` could legitimately start the next chunk.
		// If `entry` is a tool result, breaking here would orphan it from its tool call in the
		// previous chunk, so keep extending instead.
		if (slice.length > 0 && tokens + entryTokens > chunkTokens && isValidCutPoint(entry)) break;
		slice.push(entry);
		tokens += entryTokens;
		coversUpToId = entry.id;
	}

	return { entries: slice, coversUpToId, tokens };
}
