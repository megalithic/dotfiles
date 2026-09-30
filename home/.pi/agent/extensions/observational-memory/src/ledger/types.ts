/**
 * Ledger custom-type vocabulary for observational memory (v1, minimal schema).
 *
 * Trimmed from OM V3: the reflections tier, the `relevance` field, `sourceEntryIds`,
 * content-hash ids, and the usage tier are all gone. An observation is the minimal
 * `{ timestamp, content, tokenCount }`; the precise event-`timestamp` doubles as the id
 * (the orchestrator guarantees uniqueness at commit — see ../ids.ts).
 */

/** Observer output committed by the orchestrator; the buffer tier. */
export const OM_OBSERVATIONS_RECORDED = "om.observations.recorded";
/** Promotion tombstones written by the orchestrator after a consolidator run (Phase B). */
export const OM_OBSERVATIONS_DROPPED = "om.observations.dropped";
/** Compaction details type stamped into the compaction entry's `details`. */
export const OM_FOLDED = "om.folded";
/** Per-session on/off gate state (default OFF). See src/index.ts. */
export const OM_ENABLED = "om.enabled";
/**
 * Per-worker cost record (one per finished worker run). The orchestrator appends these from
 * pi's built-in `usage.cost.total`, reported back by the worker extension via the cost file.
 * Summed across the WHOLE session (every branch), so spend never rolls back under /tree.
 */
export const OM_COST = "om.cost";
/**
 * Synthetic continuation message used to resume the agent loop after a mid-run compaction
 * (a `turn_end` that was NOT the run's terminal turn). Carried as a `role: "custom"` message
 * with `display: false` so it is hidden from the human TUI; pi still surfaces it to the model
 * as a user-role turn (convertToLlm rewrites custom → user). See hooks/compaction-trigger.ts.
 */
export const OM_RESUME = "om.resume";

export type Entry = {
	type: string;
	id: string;
	timestamp?: string;
	message?: unknown;
	content?: unknown;
	customType?: string;
	summary?: unknown;
	fromId?: string;
	data?: unknown;
	details?: unknown;
	firstKeptEntryId?: string;
};

/**
 * Minimal observation unit (decision 9 / L5).
 * - `timestamp`: the orchestrator-assigned precise, unique id-timestamp
 *   ("YYYY-MM-DDTHH:MM:SS" with an optional ".NN" disambiguator). Doubles as the id.
 * - `content`: single-line plain prose.
 * - `tokenCount`: computed in code (never by the model).
 */
export type Observation = {
	timestamp: string;
	content: string;
	tokenCount: number;
};

export type ObservationsRecordedEntryData = {
	observations: Observation[];
	coversUpToId: string;
};

export type ObservationsDroppedEntryData = {
	observationTimestamps: string[];
	coversUpToId: string;
};

export type CostEntryData = {
	costUsd: number;
	role: "observer" | "consolidator";
	runId: string;
};

/** Stamped into the compaction entry's `details` so a future visible projection can read it back. */
export type MemoryDetails = {
	type: typeof OM_FOLDED;
	version: 1;
	observations: Observation[];
};

export type MemoryCustomType = typeof OM_OBSERVATIONS_RECORDED | typeof OM_OBSERVATIONS_DROPPED;

export function isNonEmptyString(value: unknown): value is string {
	return typeof value === "string" && value.length > 0;
}

export function isNonEmptyStringArray(value: unknown): value is string[] {
	return Array.isArray(value) && value.length > 0 && value.every(isNonEmptyString);
}

function isTokenCount(value: unknown): value is number {
	return typeof value === "number" && Number.isFinite(value) && value >= 0;
}

function isPlainRecord(value: unknown): value is Record<string, unknown> {
	return !!value && typeof value === "object";
}

export function isObservation(value: unknown): value is Observation {
	if (!isPlainRecord(value)) return false;
	return (
		isNonEmptyString(value.timestamp) &&
		isNonEmptyString(value.content) &&
		!/\r|\n/.test(value.content) &&
		isTokenCount(value.tokenCount)
	);
}

export function isObservationsRecordedData(value: unknown): value is ObservationsRecordedEntryData {
	if (!isPlainRecord(value)) return false;
	return (
		Array.isArray(value.observations) &&
		value.observations.length > 0 &&
		value.observations.every(isObservation) &&
		isNonEmptyString(value.coversUpToId)
	);
}

export function isObservationsDroppedData(value: unknown): value is ObservationsDroppedEntryData {
	if (!isPlainRecord(value)) return false;
	return isNonEmptyStringArray(value.observationTimestamps) && isNonEmptyString(value.coversUpToId);
}

export function isMemoryDetails(value: unknown): value is MemoryDetails {
	if (!isPlainRecord(value)) return false;
	return (
		value.type === OM_FOLDED &&
		value.version === 1 &&
		Array.isArray(value.observations) &&
		value.observations.every(isObservation)
	);
}

export function isObservationsRecordedEntry(entry: Entry): entry is Entry & {
	type: "custom";
	customType: typeof OM_OBSERVATIONS_RECORDED;
	data: ObservationsRecordedEntryData;
} {
	return entry.type === "custom" && entry.customType === OM_OBSERVATIONS_RECORDED && isObservationsRecordedData(entry.data);
}

export function isCostEntry(entry: Entry): entry is Entry & {
	type: "custom";
	customType: typeof OM_COST;
	data: CostEntryData;
} {
	if (entry.type !== "custom" || entry.customType !== OM_COST) return false;
	const data = entry.data as Record<string, unknown> | undefined;
	return !!data && typeof data.costUsd === "number" && Number.isFinite(data.costUsd as number) && (data.costUsd as number) >= 0;
}

/**
 * Sum every `om.cost` entry across the WHOLE session. Callers MUST pass all entries
 * (`getEntries()`), NOT a single branch (`getBranch()`): counting every branch is what makes
 * real spend monotonic — it never decreases when /tree navigates onto another branch.
 */
export function sumSessionCost(allEntries: Entry[]): { costUsd: number; runs: number } {
	let costUsd = 0;
	let runs = 0;
	for (const entry of allEntries) {
		if (isCostEntry(entry)) {
			costUsd += (entry.data as CostEntryData).costUsd;
			runs += 1;
		}
	}
	return { costUsd, runs };
}

export function isObservationsDroppedEntry(entry: Entry): entry is Entry & {
	type: "custom";
	customType: typeof OM_OBSERVATIONS_DROPPED;
	data: ObservationsDroppedEntryData;
} {
	return entry.type === "custom" && entry.customType === OM_OBSERVATIONS_DROPPED && isObservationsDroppedData(entry.data);
}

export function buildObservationsRecordedData(
	observations: Observation[],
	coversUpToId: string,
): ObservationsRecordedEntryData | undefined {
	if (observations.length === 0 || !isNonEmptyString(coversUpToId)) return undefined;
	return { observations, coversUpToId };
}

export function buildObservationsDroppedData(
	observationTimestamps: string[],
	coversUpToId: string,
): ObservationsDroppedEntryData | undefined {
	if (observationTimestamps.length === 0 || !isNonEmptyString(coversUpToId)) return undefined;
	return { observationTimestamps, coversUpToId };
}
