import { estimateStringTokens } from "./tokens.js";
import type { Observation } from "./ledger/types.js";

/** What the observer model emits: minute-resolution event time + single-line content. */
export type ModelObservation = {
	timestamp: string; // "YYYY-MM-DD HH:MM"
	content: string;
};

const MODEL_TIMESTAMP_RE = /^(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2})$/;

function pad(n: number): string {
	return n.toString().padStart(2, "0");
}

/** Format an absolute time (epoch ms or parseable string) to a local "YYYY-MM-DDTHH:MM:SS" id base. */
function formatAnchorBase(anchor: number | string | undefined): string | undefined {
	if (anchor === undefined) return undefined;
	const d = new Date(anchor);
	if (Number.isNaN(d.getTime())) return undefined;
	return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
}

/**
 * Convert a model-emitted minute-resolution timestamp ("YYYY-MM-DD HH:MM") into a
 * second-resolution id base ("YYYY-MM-DDTHH:MM:00"). Returns undefined if it doesn't match
 * the expected shape, so the caller can fall back to a source-entry anchor.
 */
function modelTimestampToBase(modelTimestamp: string): string | undefined {
	const m = MODEL_TIMESTAMP_RE.exec(modelTimestamp.trim());
	if (!m) return undefined;
	return `${m[1]}T${m[2]}:00`;
}

export type AssignTimestampsOptions = {
	/** Already-used timestamp ids (the folded buffer) so new ids never collide across batches. */
	used?: Iterable<string>;
	/**
	 * Fallback anchor for observations whose model timestamp is missing/malformed — typically
	 * the chunk's last bounding source-entry time (epoch ms or parseable string).
	 */
	fallbackAnchor?: number | string;
};

/**
 * L5: the orchestrator re-derives a precise, unique id-timestamp for each model observation
 * at commit. The model only emits minute resolution (OM-proven, low copy-fidelity risk); the
 * orchestrator turns that into a "YYYY-MM-DDTHH:MM:SS[.NN]" id, appending a deterministic
 * ".01", ".02", … disambiguator when two observations resolve to the same second (within the
 * batch or against the existing buffer). `tokenCount` is computed here, never by the model.
 */
export function assignObservationTimestamps(
	modelObservations: ModelObservation[],
	options: AssignTimestampsOptions = {},
): Observation[] {
	const used = new Set<string>(options.used ?? []);
	const fallbackBase = formatAnchorBase(options.fallbackAnchor) ?? formatAnchorBase(Date.now())!;
	const result: Observation[] = [];

	for (const model of modelObservations) {
		const content = model.content;
		const base = modelTimestampToBase(model.timestamp) ?? fallbackBase;

		let timestamp = base;
		if (used.has(timestamp)) {
			let suffix = 1;
			do {
				timestamp = `${base}.${pad(suffix)}`;
				suffix++;
			} while (used.has(timestamp));
		}
		used.add(timestamp);

		result.push({ timestamp, content, tokenCount: estimateStringTokens(content) });
	}

	return result;
}
