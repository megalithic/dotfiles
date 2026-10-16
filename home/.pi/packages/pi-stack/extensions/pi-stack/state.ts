export const STATE_ENTRY = "pi-stack-mode";

export interface ModeEntry {
	/** `null` clears an earlier override and returns to the cwd rule. */
	on: boolean | null;
}

/** The shape of a session entry pi-stack cares about; everything else is ignored. */
export interface SessionEntryLike {
	type: string;
	customType?: string;
	data?: unknown;
}

/**
 * The mode for this branch: the newest pi-stack entry wins; with none, the cwd rule decides.
 * Reads only the active branch so an abandoned branch cannot flip the mode.
 */
export function resolveMode(branch: readonly SessionEntryLike[], autoOn: boolean): { on: boolean; source: "override" | "auto" } {
	for (let i = branch.length - 1; i >= 0; i--) {
		const entry = branch[i];
		if (entry.type !== "custom" || entry.customType !== STATE_ENTRY) continue;
		const data = entry.data as Partial<ModeEntry> | undefined;
		if (typeof data?.on === "boolean") return { on: data.on, source: "override" };
		if (data?.on === null) return { on: autoOn, source: "auto" };
	}
	return { on: autoOn, source: "auto" };
}

export type Command = { kind: "set"; on: boolean } | { kind: "auto" } | { kind: "status" } | { kind: "invalid"; text: string };

/** Parses the `/poteto-mode` argument. Bare means on. */
export function parseCommand(args: string): Command {
	const text = args.trim().toLowerCase();
	if (text === "" || text === "on") return { kind: "set", on: true };
	if (text === "off") return { kind: "set", on: false };
	if (text === "auto") return { kind: "auto" };
	if (text === "status") return { kind: "status" };
	return { kind: "invalid", text };
}
