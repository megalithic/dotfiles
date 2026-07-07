/**
 * Resurrect Tag Extension
 *
 * Tags the surrounding tmux pane with pi's session UUID (pane option
 * @pi_session_id) whenever a session starts, resumes, or switches. This lets
 * tmux-resurrect restore the exact session per pane instead of guessing with
 * `pi -c` (which collides when two pi panes share a cwd).
 *
 * Consumers:
 * - bin/tmux-resurrect-save-pi (custom resurrect save_command_strategy) reads
 *   the tag at save time and records `pi --session <uuid>`.
 * - config/tmux/plugins.tmux.conf inline strategy `"pi->pinvim *"` relaunches
 *   the pane via pinvim with the saved args on restore.
 *
 * The tag is the bare session UUID (hex only, never contains "pi") because
 * resurrect's inline-strategy arg extraction uses a greedy sed on the match
 * token; a full path like ~/.pi/agent/sessions/... would break it.
 */

import { execFile } from "node:child_process";
import path from "node:path";
import type {
	ExtensionAPI,
	ExtensionContext,
} from "@earendil-works/pi-coding-agent";

function tagPane(sessionFile: string | null): void {
	const pane = process.env.TMUX_PANE;
	if (!process.env.TMUX || !pane) return;

	let args: string[];
	if (sessionFile) {
		// Session filename: <timestamp>_<uuid>.jsonl
		const base = path.basename(sessionFile, ".jsonl");
		const uuid = base.includes("_") ? base.split("_").pop()! : base;
		args = ["set-option", "-p", "-t", pane, "@pi_session_id", uuid];
	} else {
		// Ephemeral session (--no-session): clear any stale tag
		args = ["set-option", "-p", "-t", pane, "-u", "@pi_session_id"];
	}
	execFile("tmux", args, () => {
		// Best-effort: ignore failures (tmux gone, pane closed, etc.)
	});
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx: ExtensionContext) => {
		tagPane(ctx.sessionManager.getSessionFile() ?? null);
	});
}
