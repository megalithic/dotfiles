import { type Config, DEFAULTS, loadConfig } from "./config.js";
import { foldLedger, poolTokens, rawTokensSinceObservationCoverage, sumSessionCost, type Entry } from "./ledger/index.js";
import { StatusController } from "./ui/status-controller.js";

/**
 * In-process orchestrator state. Event-driven only — no daemon/timer beyond the status
 * spinner. Ephemeral: rebuilt on session_start, cleared on session_shutdown.
 */
export class Runtime {
	config: Config = { ...DEFAULTS };
	configLoaded = false;

	/** The per-session on/off gate (default OFF). Outermost guard in every handler. */
	enabled = false;

	/**
	 * Absolute `.memory/<sessionId>/` root for this session's durable + transient memory. Set
	 * whenever the gate is enabled (session_start / `/om on`) via `ensureSessionMemory`; empty
	 * while disabled. All path helpers (listTopics/indexPath/readJourney/run*Path) take this root.
	 */
	memoryRoot = "";

	/**
	 * In-flight observer subprocesses, keyed by runId. `coversUpToId` is the source-entry id at
	 * the END of the observer's chunk — it lets compaction decide whether the observer can affect
	 * the rendered block (an observer whose chunk lands entirely in the verbatim tail is excluded
	 * from the projection regardless, so compaction need not wait for it).
	 */
	readonly observersInFlight = new Map<string, { controller: AbortController; coversUpToId: string }>();

	/** In-flight observer async tasks, so compaction can wait for settled memory state (design R5). */
	readonly observerTasks = new Set<Promise<void>>();

	/**
	 * Strictly one consolidator at a time (design risk 4). The flag is held from dispatch through
	 * tombstone-commit so the pool clock cannot fire a second overlapping run. Runs in the
	 * background — compaction does NOT wait for it (R5).
	 */
	consolidatorInFlight = false;
	consolidatorController: AbortController | undefined;

	/**
	 * coversUpToId of the most-recent chunk DISPATCHED (committed or still in flight). Combined
	 * with the committed ledger watermark, this is the effective observation watermark: it keeps
	 * parallel observers from re-selecting the same slice and lets zero-observation chunks (which
	 * commit no ledger entry) still advance the clock. In-memory only — lost on resume (harmless;
	 * worst case a chunk is re-observed).
	 */
	dispatchedCoversUpToId: string | undefined;

	/** Guards so compaction trigger + hook never re-enter. */
	compactInFlight = false;
	compactHookInFlight = false;

	/** Last worker error message, surfaced by /om:status. */
	lastWorkerError: string | undefined;

	/**
	 * Whether the last compaction waited for in-flight observers or skipped the wait (fast path:
	 * no in-flight observer could affect the rendered block). Surfaced by /om:status.
	 */
	lastCompactionObserverWait: "skipped" | "waited" | undefined;

	readonly status = new StatusController();

	// ── Toast coalescer ──────────────────────────────────────────────────────────
	// Parallel observers fire finish toasts from independent async tasks. If two
	// land in the same event-loop tick, pi's showStatus() would replace the first
	// with the second. queueToast() accumulates info lines and flushes them as a
	// single multi-line notify on the next tick so both lines remain visible.

	private pendingInfoToastLines: string[] = [];
	private infoToastFlushTimer: ReturnType<typeof setTimeout> | undefined;

	/**
	 * Queue an info-level toast line for batched delivery on the next event-loop tick.
	 * Non-info levels (warning/error) bypass the queue and fire immediately so they
	 * always use their own styling and are never merged with info lines.
	 */
	queueToast(
		line: string,
		level: "info" | "warning" | "error",
		notify: (message: string, level: "info" | "warning" | "error") => void,
	): void {
		if (level !== "info") {
			notify(line, level);
			return;
		}
		this.pendingInfoToastLines.push(line);
		if (this.infoToastFlushTimer !== undefined) return;
		this.infoToastFlushTimer = setTimeout(() => {
			this.infoToastFlushTimer = undefined;
			const lines = this.pendingInfoToastLines.splice(0);
			if (lines.length > 0) notify(lines.join("\n"), "info");
		}, 0);
		this.infoToastFlushTimer.unref?.();
	}

	/** Discard any pending toast lines (called on session shutdown). */
	cancelPendingToasts(): void {
		if (this.infoToastFlushTimer !== undefined) {
			clearTimeout(this.infoToastFlushTimer);
			this.infoToastFlushTimer = undefined;
		}
		this.pendingInfoToastLines = [];
	}

	ensureConfig(cwd: string): void {
		if (this.configLoaded) return;
		this.config = loadConfig(cwd);
		this.configLoaded = true;
	}

	/** Recompute the live footer gauges (next-observer + pool + context) from the current branch. */
	refreshFooterGauges(branch: Entry[], contextTokens?: number | null): void {
		if (!this.enabled) return;
		const folded = foldLedger(branch);
		this.status.setGauges({
			nextValue: rawTokensSinceObservationCoverage(branch),
			nextMax: this.config.chunkTokens,
			poolValue: poolTokens(folded.activeObservations),
			poolMax: this.config.consolidateAtPoolTokens,
			ctxValue: contextTokens ?? 0,
			ctxMax: this.config.compactAtContextTokens,
		});
	}

	/**
	 * Recompute accumulated session cost for the footer from ALL entries (every branch), so the
	 * displayed spend never rolls back under /tree. Pass `getEntries()`, not `getBranch()`.
	 */
	refreshCost(allEntries: Entry[]): void {
		if (!this.enabled) return;
		const { costUsd, runs } = sumSessionCost(allEntries);
		this.status.setCost(costUsd, runs);
	}

	/** Abort and forget all in-flight workers (session shutdown / disable). */
	abortAllWorkers(): void {
		this.cancelPendingToasts();
		for (const { controller } of this.observersInFlight.values()) {
			controller.abort();
		}
		this.observersInFlight.clear();
		this.consolidatorController?.abort();
		this.consolidatorController = undefined;
		this.consolidatorInFlight = false;
	}

	/** Track an observer task for the lifetime of its async run. */
	trackObserverTask(task: Promise<void>): void {
		this.observerTasks.add(task);
		void task.finally(() => this.observerTasks.delete(task));
	}

	/** Resolve once no observer tasks are in flight (compaction blocks on this). */
	async whenObserversIdle(): Promise<void> {
		while (this.observerTasks.size > 0) {
			await Promise.allSettled([...this.observerTasks]);
		}
	}

	get observerSlotsAvailable(): number {
		return Math.max(0, this.config.observerConcurrency - this.observersInFlight.size);
	}
}
