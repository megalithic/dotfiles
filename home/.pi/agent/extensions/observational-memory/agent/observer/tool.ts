import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import type { Static } from "typebox";
import { writeObserverResult, type RawObservation } from "../../src/spawn/runs.js";

export const OBSERVATION_TIMESTAMP_PATTERN = "^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}$";

const RecordObservationsSchema = Type.Object({
	observations: Type.Array(
		Type.Object({
			timestamp: Type.String({
				pattern: OBSERVATION_TIMESTAMP_PATTERN,
				description: "Observation time in local 'YYYY-MM-DD HH:MM' format.",
			}),
			content: Type.String({
				minLength: 1,
				description: "Single-line plain prose. No markdown, no tags, no embedded timestamp.",
			}),
		}),
		{ description: "Batch of new observations. Call multiple times until the chunk is fully covered." },
	),
});

export type RecordObservationsInput = Static<typeof RecordObservationsSchema>;

/**
 * Register the observer's only tool. It accumulates observations across calls and rewrites the
 * result file (atomic) on every call, so the file always reflects the full set even though
 * there is no clean "terminal call" signal — headless `pi -p` exits when the agent loop ends.
 */
export function registerObserverTool(pi: ExtensionAPI, resultPath: string): void {
	const accumulated: RawObservation[] = [];
	const seen = new Set<string>();

	function flush(): void {
		writeObserverResult(resultPath, { observations: accumulated });
	}

	// Ensure a valid (possibly empty) result file exists even for zero-observation chunks.
	flush();

	pi.registerTool({
		name: "record_observations",
		label: "Record observations",
		description:
			"Record a batch of observations distilled from the conversation chunk. " +
			"Call multiple times as you work through the chunk; stop calling when coverage is complete, " +
			"then emit a short plain-text confirmation to end the run.",
		parameters: RecordObservationsSchema,
		async execute(_id: string, params: RecordObservationsInput, _signal: AbortSignal | undefined, _onUpdate: unknown, _ctx: ExtensionContext) {
			let added = 0;
			let duplicates = 0;
			for (const obs of params.observations) {
				const content = obs.content.replace(/[\r\n]+/g, " ").trim();
				if (!content) continue;
				const key = `${obs.timestamp}␞${content}`;
				if (seen.has(key)) {
					duplicates++;
					continue;
				}
				seen.add(key);
				accumulated.push({ timestamp: obs.timestamp, content });
				added++;
			}
			flush();
			const dupPart = duplicates > 0 ? ` (${duplicates} duplicate${duplicates === 1 ? "" : "s"} skipped)` : "";
			return {
				content: [
					{
						type: "text" as const,
						text: `Recorded ${added} observation${added === 1 ? "" : "s"}${dupPart}. Total so far: ${accumulated.length}. Continue if the chunk has uncovered content; otherwise stop and emit a short plain-text confirmation.`,
					},
				],
				details: { added, duplicates, total: accumulated.length },
			};
		},
	});
}
