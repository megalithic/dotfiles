import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { foldLedger, poolTokens, selectPromotionOverflow, type Entry } from "../ledger/index.js";
import type { Runtime } from "../runtime.js";
import { evaluateConsolidatorTrigger } from "../hooks/consolidator-trigger.js";

/**
 * Force a consolidation now, ignoring the pool threshold. Promotes the oldest observations
 * above `poolTargetTokens`; no-op when there is nothing above target or one is already running.
 */
export function registerConsolidateCommand(pi: ExtensionAPI, runtime: Runtime): void {
	pi.registerCommand("om:consolidate", {
		description: "Force an observational-memory consolidation now (ignores the pool threshold)",
		handler: async (_args: string, ctx: any) => {
			if (!runtime.enabled) {
				if (ctx.hasUI) ctx.ui.notify("om is off (use /om on to enable)", "info");
				return;
			}
			if (runtime.consolidatorInFlight) {
				if (ctx.hasUI) ctx.ui.notify("om: consolidation already in progress", "warning");
				return;
			}
			runtime.ensureConfig(ctx.cwd);
			const branch = ctx.sessionManager.getBranch() as Entry[];
			const active = foldLedger(branch).activeObservations;
			const { promote } = selectPromotionOverflow(active, runtime.config.poolTargetTokens);
			if (promote.length === 0) {
				if (ctx.hasUI) {
					ctx.ui.notify(
						`om: nothing to consolidate (pool ${poolTokens(active).toLocaleString()} tok <= target ${runtime.config.poolTargetTokens.toLocaleString()} tok)`,
						"info",
					);
				}
				return;
			}
			// Temporarily lower the threshold to 0 for this evaluation so the trigger fires
			// regardless of the configured pool threshold.
			const saved = runtime.config.consolidateAtPoolTokens;
			runtime.config.consolidateAtPoolTokens = 0;
			try {
				evaluateConsolidatorTrigger(pi, runtime, ctx);
			} finally {
				runtime.config.consolidateAtPoolTokens = saved;
			}
		},
	});
}
