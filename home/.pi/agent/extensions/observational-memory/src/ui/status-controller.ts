/**
 * TUI observability for observational memory, driven entirely by the in-process orchestrator
 * (subprocess workers are headless). Three surfaces:
 *
 *   - Footer status ("om"): set once at attach, never cleared mid-session.
 *   - Single "om-workers" widget: all active/settling workers rendered side-by-side on
 *     one line so parallel observers appear next to each other, not stacked vertically.
 *       ◐ [observer]   ◐ [observer]   ✓ [observer] +4
 *   - Toasts via notify (start/finish/error), gated on hasUI by the caller.
 */

export type WorkerType = "observer" | "consolidator";

/** Live token gauges shown in the footer, right of "○ om". */
export interface FooterGauges {
	/** Raw tokens accrued toward the next observer chunk. */
	nextValue: number;
	nextMax: number;
	/** Active pool tokens accrued toward the consolidation threshold. */
	poolValue: number;
	poolMax: number;
	/** Live context-window tokens toward the compaction threshold. */
	ctxValue: number;
	ctxMax: number;
}

interface Theme {
	fg(color: string, text: string): string;
}

export interface StatusUI {
	setStatus(key: string, text: string | undefined): void;
	setWidget(key: string, content: string[] | undefined): void;
	theme: Theme;
}

type WorkerState =
	| { kind: "running" }
	| { kind: "done"; delta?: number }
	| { kind: "error" };

const FOOTER_KEY = "om";
const WORKERS_WIDGET_KEY = "om-workers";
const SPINNER_FRAMES = ["◐", "◓", "◑", "◒"] as const;
/** Separator between worker indicators on the single combined line. */
const WORKER_SEP = "   ";

export interface StatusControllerOptions {
	spinnerIntervalMs?: number;
	settleMs?: number;
}

interface WorkerEntry {
	type: WorkerType;
	state: WorkerState;
	settleTimer?: ReturnType<typeof setTimeout>;
}

export class StatusController {
	private ui: StatusUI | undefined;
	private frame = 0;
	private readonly workers = new Map<string, WorkerEntry>();
	private spinnerTimer: ReturnType<typeof setInterval> | undefined;
	private gauges: FooterGauges | undefined;
	private cost: { costUsd: number; runs: number } | undefined;
	private readonly spinnerIntervalMs: number;
	private readonly settleMs: number;

	constructor(options: StatusControllerOptions = {}) {
		this.spinnerIntervalMs = options.spinnerIntervalMs ?? 120;
		this.settleMs = options.settleMs ?? 5000;
	}

	attach(ui: StatusUI): void {
		this.ui = ui;
		this.ui.setStatus(FOOTER_KEY, this.renderFooter());
	}

	detach(): void {
		this.stopSpinner();
		for (const entry of this.workers.values()) {
			if (entry.settleTimer) clearTimeout(entry.settleTimer);
		}
		this.workers.clear();
		this.gauges = undefined;
		this.cost = undefined;
		this.ui?.setWidget(WORKERS_WIDGET_KEY, undefined);
		if (this.ui) this.ui.setStatus(FOOTER_KEY, undefined);
		this.ui = undefined;
	}

	/** Update (or clear) the live footer gauges and re-render the footer in place. */
	setGauges(gauges: FooterGauges | undefined): void {
		this.gauges = gauges;
		if (this.ui) this.ui.setStatus(FOOTER_KEY, this.renderFooter());
	}

	/** Update the accumulated session cost shown in the footer and re-render in place. */
	setCost(costUsd: number, runs: number): void {
		this.cost = { costUsd, runs };
		if (this.ui) this.ui.setStatus(FOOTER_KEY, this.renderFooter());
	}

	workerStart(type: WorkerType, runId: string): void {
		if (!this.ui) return;
		const existing = this.workers.get(runId);
		if (existing?.settleTimer) clearTimeout(existing.settleTimer);
		this.workers.set(runId, { type, state: { kind: "running" } });
		this.startSpinner();
		this.renderWorkersWidget();
	}

	workerDone(runId: string, delta?: number): void {
		this.settle(runId, { kind: "done", delta });
	}

	workerError(runId: string): void {
		this.settle(runId, { kind: "error" });
	}

	private settle(runId: string, state: WorkerState): void {
		if (!this.ui) return;
		const entry = this.workers.get(runId);
		if (!entry) return;
		if (entry.settleTimer) clearTimeout(entry.settleTimer);
		entry.state = state;
		this.renderWorkersWidget();
		entry.settleTimer = setTimeout(() => {
			this.workers.delete(runId);
			// Re-render the combined widget with this worker removed, or clear
			// the widget entirely if the last worker just left.
			this.renderWorkersWidget();
			if (!this.hasRunningWorker()) this.stopSpinner();
		}, this.settleMs);
		entry.settleTimer.unref?.();
		if (!this.hasRunningWorker()) this.stopSpinner();
	}

	private hasRunningWorker(): boolean {
		for (const entry of this.workers.values()) {
			if (entry.state.kind === "running") return true;
		}
		return false;
	}

	private startSpinner(): void {
		if (this.spinnerTimer) return;
		this.spinnerTimer = setInterval(() => {
			this.frame = (this.frame + 1) % SPINNER_FRAMES.length;
			// One re-render of the combined widget per tick covers all running workers.
			if (this.hasRunningWorker()) this.renderWorkersWidget();
		}, this.spinnerIntervalMs);
		this.spinnerTimer.unref?.();
	}

	private stopSpinner(): void {
		if (!this.spinnerTimer) return;
		clearInterval(this.spinnerTimer);
		this.spinnerTimer = undefined;
	}

	/** A compact colored fill bar, e.g. `▕████░░░░▏`. Filled cells use `over` (an alert color) past max. */
	private gaugeBar(value: number, max: number, cells = 8): string {
		const theme = this.ui!.theme;
		const frac = max <= 0 ? 0 : Math.max(0, value / max);
		const filled = Math.min(cells, Math.round(Math.min(1, frac) * cells));
		const fillColor = frac >= 1 ? "warning" : "dim";
		return (
			theme.fg(fillColor, "▕") +
			theme.fg(fillColor, "█".repeat(filled)) +
			theme.fg(fillColor, "░".repeat(cells - filled)) +
			theme.fg(fillColor, "▏")
		);
	}

	private renderFooter(): string {
		const theme = this.ui?.theme;
		if (!theme) return "om";
		const base = `${theme.fg("success", "om")}`;
		const g = this.gauges;
		if (!g) return base;
		const next = `${theme.fg("muted", "O")}${this.gaugeBar(g.nextValue, g.nextMax)}`;
		const pool = `${theme.fg("muted", "C")}${this.gaugeBar(g.poolValue, g.poolMax)}`;
		const ctx = `${theme.fg("muted", "X")}${this.gaugeBar(g.ctxValue, g.ctxMax)}`;
		const cost = this.cost ? ` ${theme.fg("dim", `$${this.cost.costUsd.toFixed(3)}`)}` : "";
		return `${next}  ${pool}  ${ctx}${cost}`;
	}

	/**
	 * Render all active/settling workers onto a single "om-workers" widget line so they
	 * appear side-by-side rather than stacking vertically. Clears the widget when empty.
	 */
	private renderWorkersWidget(): void {
		const ui = this.ui;
		if (!ui) return;
		if (this.workers.size === 0) {
			ui.setWidget(WORKERS_WIDGET_KEY, undefined);
			return;
		}
		const theme = ui.theme;
		const parts: string[] = [];
		for (const entry of this.workers.values()) {
			if (entry.state.kind === "running") {
				parts.push(`${theme.fg("accent", SPINNER_FRAMES[this.frame])} ${theme.fg("accent", `[${entry.type}]`)}`);
			} else if (entry.state.kind === "error") {
				parts.push(`${theme.fg("error", "✗")} ${theme.fg("muted", `[${entry.type}]`)}`);
			} else {
				const delta =
					entry.state.delta && entry.state.delta > 0
						? ` ${theme.fg("success", `+${entry.state.delta}`)}`
						: "";
				parts.push(`${theme.fg("success", "✓")} ${theme.fg("muted", `[${entry.type}]`)}${delta}`);
			}
		}
		ui.setWidget(WORKERS_WIDGET_KEY, [parts.join(WORKER_SEP)]);
	}
}
