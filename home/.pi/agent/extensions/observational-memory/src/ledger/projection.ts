import {
	OM_FOLDED,
	isMemoryDetails,
	isObservationsDroppedEntry,
	isObservationsRecordedEntry,
	type Entry,
	type MemoryDetails,
	type Observation,
} from "./types.js";

export type Projection = {
	observations: Observation[];
};

export type CompactionProjection = Projection & {
	details: MemoryDetails;
};

type ProjectionBoundary =
	| { kind: "entry"; entryId: string }
	| { kind: "beforeEntry"; entryId: string }
	| { kind: "tip" }
	| { kind: "none" };

function entryIndexById(entries: Entry[]): Map<string, number> {
	const indexes = new Map<string, number>();
	for (let i = 0; i < entries.length; i++) indexes.set(entries[i].id, i);
	return indexes;
}

function boundaryIndex(entries: Entry[], indexes: Map<string, number>, boundary: ProjectionBoundary): number {
	if (boundary.kind === "tip") return entries.length - 1;
	if (boundary.kind === "none") return -1;
	const idx = indexes.get(boundary.entryId);
	if (idx === undefined) return -1;
	// "beforeEntry": the entry itself is kept verbatim, so only cover sources strictly before it.
	return boundary.kind === "beforeEntry" ? idx - 1 : idx;
}

function coverageIndex(entry: Entry & { data: { coversUpToId: string } }, indexes: Map<string, number>): number {
	return indexes.get(entry.data.coversUpToId) ?? -1;
}

function isCoveredAtOrBefore(
	entry: Entry & { data: { coversUpToId: string } },
	indexes: Map<string, number>,
	boundary: number,
): boolean {
	const index = coverageIndex(entry, indexes);
	return index >= 0 && boundary >= 0 && index <= boundary;
}

/**
 * Fold active observations whose source coverage lies at-or-before `boundary`, in
 * first-valid-record-wins order, with folded drops applied. Observations whose source lies
 * after the boundary (e.g. inside the verbatim compaction tail) are excluded automatically.
 */
function foldProjection(entries: Entry[], boundary: ProjectionBoundary): Projection {
	const indexes = entryIndexById(entries);
	const boundaryIdx = boundaryIndex(entries, indexes, boundary);
	const observations: Observation[] = [];
	const seen = new Set<string>();
	const dropped = new Set<string>();

	for (const entry of entries) {
		if (isObservationsRecordedEntry(entry) && isCoveredAtOrBefore(entry, indexes, boundaryIdx)) {
			for (const observation of entry.data.observations) {
				if (seen.has(observation.timestamp)) continue;
				seen.add(observation.timestamp);
				observations.push(observation);
			}
			continue;
		}
		if (isObservationsDroppedEntry(entry) && isCoveredAtOrBefore(entry, indexes, boundaryIdx)) {
			for (const timestamp of entry.data.observationTimestamps) dropped.add(timestamp);
		}
	}

	return { observations: observations.filter((observation) => !dropped.has(observation.timestamp)) };
}

export function fullProjection(entries: Entry[], upToEntryId?: string): Projection {
	return foldProjection(entries, upToEntryId ? { kind: "entry", entryId: upToEntryId } : { kind: "tip" });
}

function latestCompactionDetails(entries: Entry[]): MemoryDetails | undefined {
	for (let i = entries.length - 1; i >= 0; i--) {
		const entry = entries[i];
		if (entry.type !== "compaction") continue;
		if (isMemoryDetails(entry.details)) return entry.details;
	}
	return undefined;
}

/** What a fresh session (no `upToEntryId`) sees: the observations folded into the last compaction. */
export function visibleProjection(entries: Entry[], upToEntryId?: string): Projection {
	if (!upToEntryId) {
		const details = latestCompactionDetails(entries);
		return details ? { observations: [...details.observations] } : { observations: [] };
	}
	// At an explicit tree position, show every observation active through that position (inclusive).
	return fullProjection(entries, upToEntryId);
}

/**
 * Build the deterministic compaction projection: active observations covered up to
 * `firstKeptEntryId`, plus the `details` blob stamped into the compaction entry so a
 * future visible projection can replay it. Phase A renders the full active buffer up to the
 * cutoff (no dropper yet); Phase B's tombstones thin it via the same drop fold.
 */
export function buildCompactionProjection(entries: Entry[], firstKeptEntryId: string): CompactionProjection {
	const projection = foldProjection(entries, { kind: "beforeEntry", entryId: firstKeptEntryId });
	const details: MemoryDetails = {
		type: OM_FOLDED,
		version: 1,
		observations: projection.observations,
	};
	return { observations: projection.observations, details };
}
