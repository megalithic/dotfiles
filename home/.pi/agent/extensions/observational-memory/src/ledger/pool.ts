/**
 * Observation-pool accounting for the Phase B consolidator clock.
 *
 * The "pool" is the folded set of ACTIVE observations (recorded minus tombstoned). The
 * consolidator fires when the pool's total token count crosses `consolidateAtPoolTokens`,
 * and promotes the OLDEST observations above `poolTargetTokens` — keeping the newest
 * `poolTargetTokens` worth in the buffer and draining the rest into topic files.
 */
import { sortObservations } from "./render.js";
import type { Observation } from "./types.js";

export function poolTokens(observations: Observation[]): number {
	let total = 0;
	for (const observation of observations) total += observation.tokenCount;
	return total;
}

export type PromotionOverflow = {
	/** Oldest observations to hand to the consolidator (chronological order). */
	promote: Observation[];
	/** Token total of the observations kept in the buffer. */
	keptTokens: number;
	/** Token total of the whole active pool. */
	totalTokens: number;
};

/**
 * Select the promotion overflow: keep the newest observations whose cumulative tokens stay
 * within `poolTargetTokens`, promote everything older. Always keeps at least the single
 * newest observation, even if it alone exceeds the target, so the buffer never fully empties
 * on one oversized entry. Returns `promote` in chronological (oldest-first) order.
 */
export function selectPromotionOverflow(active: Observation[], poolTargetTokens: number): PromotionOverflow {
	const sorted = sortObservations(active);
	const totalTokens = poolTokens(sorted);

	let keptTokens = 0;
	let firstKeptIdx = sorted.length;
	for (let i = sorted.length - 1; i >= 0; i--) {
		const t = sorted[i].tokenCount;
		// Once at least one obs is kept, stop as soon as adding the next would exceed target.
		if (firstKeptIdx !== sorted.length && keptTokens + t > poolTargetTokens) break;
		keptTokens += t;
		firstKeptIdx = i;
	}

	return { promote: sorted.slice(0, firstKeptIdx), keptTokens, totalTokens };
}
