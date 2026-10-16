import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { isAbsolute, join, resolve, sep } from "node:path";
import { type Static, Type } from "typebox";
import { Value } from "typebox/value";

/** Upstream pstack roles, one line each in setup-pstack. Panel roles hold a list. */
export const ROLES = [
	"feature, refactoring",
	"bug-fix",
	"perf-issue",
	"hillclimb",
	"judgment and prose",
	"hardest tasks",
	"how explorer",
	"how explainer",
	"why investigators",
	"why synthesizer",
	"reflect tooling",
	"reflect judgment, divergent, synthesizer",
	"arena runners",
	"arena cross-judge pool",
	"swarm workers",
	"architect runners",
	"interrogate reviewers",
] as const;

export type Role = (typeof ROLES)[number];

export const PANEL_ROLES: readonly Role[] = ["arena runners", "arena cross-judge pool", "architect runners", "interrogate reviewers"];

/** "provider/id:thinking", or an alias meaning "run on the parent model". */
const ModelRefSchema = Type.String({ minLength: 1 });

export type ModelRef = Static<typeof ModelRefSchema>;

const ConfigSchema = Type.Object({
	/** Absolute paths or globs; a session cwd at or below one of these turns the mode on. */
	activate: Type.Array(Type.String(), { default: [] }),
	/** Prompt section names from other extensions to delete while the mode is on. */
	supersedes: Type.Array(Type.String(), { default: [] }),
});

export type Config = Static<typeof ConfigSchema>;

const RoleTableSchema = Type.Object(
	Object.fromEntries(ROLES.map((role) => [role, Type.Optional(Type.Union([ModelRefSchema, Type.Array(ModelRefSchema)]))])),
	{ additionalProperties: false },
);

/** Per-role model refs. A panel role may hold a list, one seat per entry. */
export type RoleTable = Partial<Record<Role, ModelRef | ModelRef[]>>;

export const DEFAULT_CONFIG: Config = { activate: [], supersedes: [] };

export function configPath(agentDir: string): string {
	return join(agentDir, "pi-stack", "config.json");
}

export function modelsPath(agentDir: string): string {
	return join(agentDir, "pi-stack", "models.json");
}

/** Reads the config; a missing file is the default, a malformed one throws with its path. */
export function readConfig(agentDir: string): Config {
	const path = configPath(agentDir);

	if (!existsSync(path)) return DEFAULT_CONFIG;

	return validate(parseJsonFile(path), path);
}

/** Reads the role table the vendored skills name as `~/.pi/agent/pi-stack/models.json`. Missing means every role inherits the parent model. */
export function readRoleTable(agentDir: string): RoleTable {
	const path = modelsPath(agentDir);

	if (!existsSync(path)) return {};

	return validateRoleTable(parseJsonFile(path), path);
}

function parseJsonFile(path: string): JsonValue {
	try {
		return JSON.parse(readFileSync(path, "utf8"));
	} catch (error) {
		throw new Error(`pi-stack: ${path} is not valid JSON: ${error instanceof Error ? error.message : String(error)}`);
	}
}

export type JsonValue = string | number | boolean | null | JsonValue[] | { [key: string]: JsonValue };

export function validate(raw: JsonValue, path = "config"): Config {
	const withDefaults = Value.Default(ConfigSchema, raw);

	if (!Value.Check(ConfigSchema, withDefaults)) throw new Error(`pi-stack: ${path}: ${firstError(Value.Errors(ConfigSchema, withDefaults))}`);

	return withDefaults;
}

const JsonObjectSchema = Type.Record(Type.String(), Type.Unknown());

export function validateRoleTable(raw: JsonValue, path = "models.json"): RoleTable {
	if (!Value.Check(JsonObjectSchema, raw)) throw new Error(`pi-stack: ${path} must be an object`);

	// Keys that start with `$` are comments the setup command writes ($comment, $available).
	const table = Object.fromEntries(Object.entries(raw).filter(([key]) => !key.startsWith("$")));
	const unknown = Object.keys(table).find((key) => !ROLES.some((role) => role === key));

	if (unknown !== undefined) throw new Error(`pi-stack: ${path}: unknown role "${unknown}"`);

	if (!Value.Check(RoleTableSchema, table)) throw new Error(`pi-stack: ${path}: ${firstError(Value.Errors(RoleTableSchema, table))}`);

	return table;
}

function firstError(errors: ReturnType<typeof Value.Errors>): string {
	for (const error of errors) return `${error.instancePath || "/"} ${error.message}`;

	return "invalid";
}

export function expandHome(path: string, home = homedir()): string {
	return path === "~" ? home : path.startsWith("~/") ? join(home, path.slice(2)) : path;
}

/**
 * True when cwd is at or below one of the activation entries. An entry is an absolute
 * path (prefix match on path segments) or a glob with `*` and `**` segments. Relative
 * entries never match. Realpaths are the caller's job; a worktree under the repo matches
 * because it is below it.
 */
export function matchesActivation(cwd: string, entries: string[], home = homedir()): boolean {
	const target = resolve(cwd).split(sep).filter(Boolean);

	return entries.some((entry) => {
		const expanded = expandHome(entry, home);

		if (!isAbsolute(expanded)) return false;

		return segmentsMatch(expanded.split(sep).filter(Boolean), target);
	});
}

/** Glob segments against path segments; the pattern matches when it consumes a prefix of the path. */
function segmentsMatch(pattern: string[], path: string[]): boolean {
	if (pattern.length === 0) return true;

	if (pattern[0] === "**") {
		for (let i = 0; i <= path.length; i++) if (segmentsMatch(pattern.slice(1), path.slice(i))) return true;

		return false;
	}

	if (path.length === 0) return false;

	if (!segmentMatch(pattern[0], path[0])) return false;

	return segmentsMatch(pattern.slice(1), path.slice(1));
}

function segmentMatch(pattern: string, segment: string): boolean {
	if (!pattern.includes("*")) return pattern === segment;

	return new RegExp(`^${pattern.split("*").map(escapeRegExp).join(".*")}$`).test(segment);
}

function escapeRegExp(s: string): string {
	return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}
