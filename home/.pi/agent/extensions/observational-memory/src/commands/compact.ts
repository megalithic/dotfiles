import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import type { Runtime } from "../runtime.js";

export function registerCompactCommand(pi: ExtensionAPI, runtime: Runtime): void {
	pi.registerCommand("om:compact", {
		description: "Force an observational-memory compaction now (ignores threshold)",
		handler: async (_args: string, ctx: any) => {
			if (!runtime.enabled) {
				if (ctx.hasUI) ctx.ui.notify("om is off (use /om on to enable)", "info");
				return;
			}
			if (runtime.compactInFlight) {
				if (ctx.hasUI) ctx.ui.notify("om: compaction already in progress", "warning");
				return;
			}
			runtime.compactInFlight = true;
			// The before-compact hook waits for in-flight observers before folding (design R5),
			// so we trigger compaction straight away here too.
			if (ctx.hasUI) ctx.ui.notify("om: compacting (waiting for in-flight observers)…", "info");
			ctx.compact({
				onComplete: () => {
					runtime.compactInFlight = false;
					if (ctx.hasUI) ctx.ui.notify("om: compaction complete", "info");
				},
				onError: (error: { message: string }) => {
					runtime.compactInFlight = false;
					if (error.message === "Compaction cancelled") return;
					if (ctx.hasUI) ctx.ui.notify(`om: ${error.message}`, "error");
				},
			});
		},
	});
}
