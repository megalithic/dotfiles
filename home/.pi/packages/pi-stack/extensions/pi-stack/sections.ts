import type { Config, ModelRef, RoleTable } from "./config.ts";
import { ROLES } from "./config.ts";

export const SECTION_ROUTE = "pi-stack";

export const SECTION_ROLES = "pi-stack-roles";

export interface SectionInput {
	/** Absolute path of the package root; skills live at `<root>/vendor/skills`. */
	packageRoot: string;
	config: Config;
	roles: RoleTable;
	/** Names of tools declared to the model this run. */
	tools: readonly string[];
	/** The primitive map text (references/pi-primitives.md). */
	primitives: string;
}

/** Tools the primitive map depends on, and the line added when one is missing. */
const CAPABILITIES: ReadonlyArray<{ tool: string; missing: string }> = [
	{ tool: "subagent", missing: "`subagent` is not available: do each delegated step yourself, in sequence, and label the result \"single reviewer, no independent panel\"." },
	{ tool: "todo", missing: "`todo` is not available: keep the playbook steps as a numbered list at the top of your reply and tick them there." },
	{ tool: "ask_user_question", missing: "`ask_user_question` is not available: ask the one question in plain prose, with the options as a numbered list." },
	{ tool: "typesafe_evaluate", missing: "`typesafe_evaluate` is not available: make calibrated judgments yourself and say they are uncalibrated." },
];

/** The routing mandate plus the primitive map. Injected on every run while the mode is on. */
export function routeSection(input: SectionInput): string {
	const skillPath = `${input.packageRoot}/vendor/skills/poteto-mode/SKILL.md`;
	const missing = CAPABILITIES.flatMap((c) => (input.tools.includes(c.tool) ? [] : [`- ${c.missing}`]));

	const lines = [
		"Poteto mode is on for this session (pi-stack). For any task that needs rigor (a bug, a feature, a refactor, a perf question, an investigation with a cited answer, shipping, or anything the user wants to trust later), read the poteto-mode skill in full before acting and follow it:",
		"",
		`    ${skillPath}`,
		"",
		"Match the task to one of its playbooks, open the playbook's steps as todo items verbatim, and route to the other skills as the steps fire. For a trivial exchange (a one-line answer, a lookup, a yes or no) stay out of the way and answer plainly. Put that absolute path in every poteto-agent brief. Principle leaves are at `../principle-<title>/SKILL.md` from that file.",
		"",
		"Delegates (subagent children) never run the playbook; the chat that owns this session does.",
		"",
		input.primitives.trim(),
	];

	if (missing.length) lines.push("", "## Missing in this session", "", ...missing);

	return lines.join("\n");
}

/** The per-role model table, rendered only for roles the config sets. Absent roles inherit the parent model. */
export function rolesSection(roles: RoleTable): string | undefined {
	const rows = ROLES.flatMap((role) => {
		const ref = roles[role];

		return ref === undefined || ref === "inherit-parent" || ref === "auto" ? [] : [`${role}: ${renderRef(ref)}`];
	});

	if (rows.length === 0) return undefined;

	return [
		"pi-stack role table (from ~/.pi/agent/pi-stack/models.json). Pass the value as `model` to `subagent`. A list is one seat per entry. `inherit-parent` or `auto` means omit `model`. A role not listed here runs on the parent model.",
		"",
		...rows,
	].join("\n");
}

function renderRef(ref: ModelRef | ModelRef[]): string {
	return Array.isArray(ref) ? ref.join(", ") : ref;
}

/**
 * Applies the mode to a mutable sections map: adds ours and deletes superseded ones when on,
 * removes ours when off (so a stale section from an earlier turn does not linger).
 */
export function applySections(sections: Record<string, string>, on: boolean, input: SectionInput): void {
	if (!on) {
		delete sections[SECTION_ROUTE];
		delete sections[SECTION_ROLES];

		return;
	}

	sections[SECTION_ROUTE] = routeSection(input);
	const roles = rolesSection(input.roles);

	if (roles) sections[SECTION_ROLES] = roles;
	else delete sections[SECTION_ROLES];

	dropSections(sections, input.config.supersedes);
}

/** Delegates pi-stack ships; a full-tool one loads every extension, so it drops superseded sections too. */
export const PI_STACK_AGENTS: ReadonlySet<string> = new Set(["general-purpose", "poteto-agent", "comment-sicko", "pstack-reviewer"]);

export function dropSections(sections: Record<string, string>, names: readonly string[]): void {
	for (const name of names) delete sections[name];
}
