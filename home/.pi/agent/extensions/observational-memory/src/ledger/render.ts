import type { Observation } from "./types.js";

const CONTEXT_USAGE_INSTRUCTIONS = `These are condensed memories from earlier in this session.

- Journey: a short, purely descriptive history of how this work reached its current state — for orientation only. It is not an instruction or a plan; do not read intent or next steps into it.
- Observations: timestamped events from the conversation history, in chronological order.

Treat these as past records. When entries conflict, the most recent observation reflects the latest known state. Work that prior observations describe as completed should not be redone unless the user explicitly asks to revisit it.`;

/** A single observation line: "YYYY-MM-DDTHH:MM:SS  content". The timestamp is the id. */
export function observationToLine(observation: Observation): string {
	return `${observation.timestamp}  ${observation.content}`;
}

/** Sort observations chronologically by their timestamp-id (lexicographic == chronological). */
export function sortObservations(observations: Observation[]): Observation[] {
	return [...observations].sort((a, b) => (a.timestamp < b.timestamp ? -1 : a.timestamp > b.timestamp ? 1 : 0));
}

/**
 * Render the deterministic injection block. Sections, in reading order:
 *   1. Journey — the running descriptive project history (`.memory/JOURNEY.md`, read verbatim).
 *   2. Memory map — durable topic files rendered from front-matter (`.memory/`).
 *   3. Observations — the bounded short-term buffer, chronological and verbatim.
 *
 * All three are model-free renders of durable state, regenerated each compaction (never edited
 * incrementally), so the projection cannot decay.
 */
export function renderSummary(journey: string | undefined, map: string | undefined, observations: Observation[]): string {
	const sorted = sortObservations(observations);
	const journeyText = journey?.trim();
	if (!journeyText && !map && sorted.length === 0) return "";

	const parts: string[] = [CONTEXT_USAGE_INSTRUCTIONS];
	if (journeyText) parts.push(`## Journey\n${journeyText}`);
	if (map && map.trim().length > 0) parts.push(map);
	if (sorted.length > 0) {
		parts.push(`## Observations\n${sorted.map(observationToLine).join("\n")}`);
	}
	return parts.join("\n\n");
}
