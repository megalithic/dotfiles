/**
 * Worker-side cost tracking (Option A). The cost is retrieved by the EXTENSION code from pi's
 * built-in per-message `usage.cost.total` — the model's experience is unchanged (it never sees
 * or fills a cost field). We accumulate across the run and write the total to the cost handoff
 * file at `agent_end`, before the role's shutdown handler tears the process down.
 *
 * This works for ephemeral worker sessions too: cost rides the result-file IPC, never a saved
 * session log.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { writeWorkerCost } from "../src/spawn/runs.js";

type CostUsage = { cost?: { total?: unknown } };
type MaybeAssistantMessage = { role?: string; usage?: CostUsage };

/**
 * Register shared cost accumulation. Gated on OM_COST_PATH (always set by the orchestrator via
 * buildWorkerEnv). No-op when unset, so the worker still runs if launched standalone.
 */
export function trackWorkerCost(pi: ExtensionAPI): void {
	const costPath = process.env.OM_COST_PATH;
	if (!costPath) return;

	let costUsd = 0;

	pi.on("message_end", async (event: { message?: MaybeAssistantMessage }) => {
		const message = event?.message;
		if (message?.role !== "assistant") return;
		const total = message.usage?.cost?.total;
		if (typeof total === "number" && Number.isFinite(total) && total > 0) {
			costUsd += total;
		}
	});

	// Write before the role's agent_end shutdown handler runs (handlers fire in registration
	// order; trackWorkerCost is registered first). Best-effort: a write failure must not crash
	// the worker.
	pi.on("agent_end", async () => {
		try {
			writeWorkerCost(costPath, { costUsd });
		} catch {
			// ignore — cost is non-critical telemetry
		}
	});
}
