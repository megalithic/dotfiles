import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { OM_RESUME, rawTokensSinceLastCompaction, type Entry } from "../ledger/index.js";
import type { Runtime } from "../runtime.js";

/**
 * Synthetic prompt that resumes the agent after a mid-run compaction. Delivered as a hidden
 * `role: "custom"` message (display:false) that pi surfaces to the model as a user turn. Kept
 * terse: the freshly-rendered compaction block already carries the recovered context.
 */
const RESUME_PROMPT =
	"[automatic] Your context was just compacted to free space; no user message was sent. " +
	"Continue exactly where you left off, as if the compaction had not happened.";

/** Pi's retryable-error detection: don't compact between an auto-retried turn's attempts. */
const RETRYABLE_ERROR_RE =
	/overloaded|provider.?returned.?error|rate.?limit|too many requests|429|500|502|503|504|service.?unavailable|server.?error|internal.?error|network.?error|connection.?error|connection.?refused|connection.?lost|websocket.?closed|websocket.?error|other side closed|fetch failed|upstream.?connect|reset before headers|socket hang up|ended without|http2 request did not get a response|timed? out|timeout|terminated|retry delay/i;

function contextPressureTokens(
	ctx: { getContextUsage?: () => { tokens: number | null } | undefined; sessionManager: { getBranch: () => Entry[] } },
	threshold: number,
): { tokens: number; due: boolean } {
	const live = ctx.getContextUsage?.()?.tokens;
	if (live != null) return { tokens: live, due: live >= threshold };
	const raw = rawTokensSinceLastCompaction(ctx.sessionManager.getBranch());
	return { tokens: raw, due: raw >= threshold };
}

/**
 * Did this `turn_end` leave pending work — i.e. will the agent loop run another turn?
 *
 * The agent loop continues after a turn iff that turn issued tool calls (whose results are fed
 * back). pi hands us those results on the event, so a non-empty `toolResults` means "mid-run";
 * an empty one means this `turn_end` IS the run's terminal turn (equivalent to `agent_end`).
 * We use that to decide whether to auto-resume after compaction.
 */
function turnWillContinue(event: any): boolean {
	const toolResults = event?.toolResults;
	if (Array.isArray(toolResults) && toolResults.length > 0) return true;
	// Fallback for shapes without toolResults: an assistant that stopped to call tools.
	const stop = event?.message?.stopReason;
	return stop === "tool_use" || stop === "tool_calls";
}

/**
 * Trigger compaction on `turn_end` once live context usage crosses `compactAtContextTokens`.
 *
 * We fire on turn_end (not agent_end) so compaction can kick in BETWEEN turns — pausing the
 * chat immediately — rather than only after the whole agent run settles. We call `ctx.compact()`
 * straight away (no idle gating): waiting for in-flight observers happens inside the
 * `session_before_compact` hook, so the chat is already paused while the observers finish and
 * the rendered block reflects settled memory state (design R5).
 *
 * Mid-run vs terminal turn (the resume decision):
 * `ctx.compact()` synchronously disconnects + aborts the agent loop, then compacts; when it
 * settles the session is idle and will NOT continue on its own (only pi's internal overflow
 * path auto-retries; a manual/threshold compaction always stops). So if this turn had pending
 * tool work we resume the agent ourselves — via a hidden custom message that triggers a new
 * turn (option A; no agent-invisible resume exists through the public API). A `turn_end` that
 * was the run's terminal turn is left to stop, exactly as if no compaction had happened.
 */
export function registerCompactionTrigger(pi: ExtensionAPI, runtime: Runtime): void {
	pi.on("turn_end", (event: any, ctx: any) => {
		if (!runtime.enabled || runtime.config.passive) return;
		if (runtime.compactInFlight) return;

		// Don't compact if pi will auto-retry this turn (transient provider/network error).
		const message = event?.message;
		if (
			message?.role === "assistant" &&
			message.stopReason === "error" &&
			message.errorMessage &&
			RETRYABLE_ERROR_RE.test(message.errorMessage)
		) {
			return;
		}

		if (!contextPressureTokens(ctx, runtime.config.compactAtContextTokens).due) return;

		// Capture the resume decision NOW, from this turn's event — ctx state at onComplete
		// (post-abort, post-reload) no longer reflects whether the turn had pending tool work.
		const shouldResume = runtime.config.resumeAfterMidRunCompaction && turnWillContinue(event);

		const hasUI = ctx.hasUI;
		const ui = ctx.ui;
		runtime.compactInFlight = true;
		if (hasUI) ui?.notify("om: context threshold reached — compacting (waiting for in-flight observers)…", "info");

		// Fire-and-forget. The before-compact hook waits for observers and renders the block.
		ctx.compact({
			onComplete: () => {
				runtime.compactInFlight = false;
				if (hasUI) ui?.notify("om: compaction complete", "info");
				// Resume only a mid-run compaction, and only if still enabled (the gate may have
				// flipped, or the session may be tearing down, while compaction ran).
				if (!shouldResume || !runtime.enabled || runtime.config.passive) return;
				try {
					// sendMessage lives on the ExtensionAPI (`pi`), not on the event-handler ctx
					// (ExtensionContext). Triggers a new turn from a hidden custom message.
					pi.sendMessage(
						{ customType: OM_RESUME, content: RESUME_PROMPT, display: false },
						{ triggerTurn: true },
					);
				} catch (error) {
					const msg = error instanceof Error ? error.message : String(error);
					runtime.lastWorkerError = `resume failed: ${msg}`;
					if (hasUI) ui?.notify(`om: resume failed — ${msg}`, "error");
				}
			},
			onError: (error: { message: string }) => {
				runtime.compactInFlight = false;
				if (error.message === "Compaction cancelled") return;
				if (hasUI) ui?.notify(`om: ${error.message}`, "error");
			},
		});
	});
}
