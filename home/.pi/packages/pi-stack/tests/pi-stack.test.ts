import { describe, expect, test } from "bun:test";
import { mkdtempSync, mkdirSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { DEFAULT_CONFIG, matchesActivation, readConfig, readRoleTable, validate, validateRoleTable } from "../extensions/pi-stack/config.ts";
import { SECTION_ROLES, SECTION_ROUTE, applySections } from "../extensions/pi-stack/sections.ts";
import { STATE_ENTRY, parseCommand, resolveMode } from "../extensions/pi-stack/state.ts";

const HOME = "/Users/me";

const WORK = ["~/code/work/strive/*"];

describe("activation by cwd", () => {
	test("a work repo and anything below it turns the mode on", () => {
		expect(matchesActivation("/Users/me/code/work/strive/rx", WORK, HOME)).toBe(true);
		expect(matchesActivation("/Users/me/code/work/strive/rx/lib/rx_web", WORK, HOME)).toBe(true);
		expect(matchesActivation("/Users/me/code/work/strive/rx/.worktrees/fix-123", WORK, HOME)).toBe(true);
	});
	test("the parent directory and unrelated repos stay off", () => {
		expect(matchesActivation("/Users/me/code/work/strive", WORK, HOME)).toBe(false);
		expect(matchesActivation("/Users/me/code/oss/pi-extensions", WORK, HOME)).toBe(false);
		expect(matchesActivation("/Users/me/code/work/striveX/rx", WORK, HOME)).toBe(false);
	});
	test("a plain absolute path matches itself and its subtree only", () => {
		expect(matchesActivation("/srv/app", ["/srv/app"], HOME)).toBe(true);
		expect(matchesActivation("/srv/app/x", ["/srv/app"], HOME)).toBe(true);
		expect(matchesActivation("/srv/application", ["/srv/app"], HOME)).toBe(false);
	});
	test("** matches any depth", () => {
		expect(matchesActivation("/a/b/c/rx", ["/a/**/rx"], HOME)).toBe(true);
		expect(matchesActivation("/a/rx", ["/a/**/rx"], HOME)).toBe(true);
	});
	test("relative entries never match", () => {
		expect(matchesActivation("/Users/me/rx", ["rx"], HOME)).toBe(false);
	});
});

describe("config files", () => {
	test("missing files mean defaults, not errors", () => {
		const dir = mkdtempSync(join(tmpdir(), "pi-stack-"));
		expect(readConfig(dir)).toEqual(DEFAULT_CONFIG);
		expect(readRoleTable(dir)).toEqual({});
	});
	test("a malformed file names its path", () => {
		const dir = mkdtempSync(join(tmpdir(), "pi-stack-"));
		mkdirSync(join(dir, "pi-stack"));
		writeFileSync(join(dir, "pi-stack", "config.json"), "{not json");
		expect(() => readConfig(dir)).toThrow(/config\.json/);
	});
	test("unknown roles and wrong shapes are rejected", () => {
		expect(() => validateRoleTable({ "how critics": "x" })).toThrow(/how critics|additional|unexpected/i);
		expect(() => validateRoleTable({ "bug-fix": 3 })).toThrow(/\/bug-fix/);
		expect(() => validate({ activate: "not-a-list" })).toThrow(/array/);
		expect(() => validate({ activate: [3] })).toThrow(/\/activate\/0/);
	});
	test("$-prefixed keys in models.json are comments", () => {
		expect(validateRoleTable({ $available: ["a/b"], "bug-fix": "a/b:high" })).toEqual({ "bug-fix": "a/b:high" });
	});
});

describe("mode restore from the session branch", () => {
	const custom = (on: boolean | null) => ({ type: "custom", customType: STATE_ENTRY, data: { on } });
	test("no entries: the cwd rule decides", () => {
		expect(resolveMode([], true)).toEqual({ on: true, source: "auto" });
		expect(resolveMode([], false)).toEqual({ on: false, source: "auto" });
	});
	test("the newest override wins over the cwd rule", () => {
		expect(resolveMode([custom(true), custom(false)], true)).toEqual({ on: false, source: "override" });
		expect(resolveMode([custom(false), custom(true)], false)).toEqual({ on: true, source: "override" });
	});
	test("auto clears an earlier override", () => {
		expect(resolveMode([custom(false), custom(null)], true)).toEqual({ on: true, source: "auto" });
	});
	test("entries of other extensions are ignored", () => {
		expect(resolveMode([{ type: "custom", customType: "ponytail-mode", data: { mode: "off" } }], true)).toEqual({ on: true, source: "auto" });
	});
	test("malformed mode entries do not erase a valid override", () => {
		for (const data of [undefined, null, false, 3, "on", [], {}, { on: "true" }]) {
			expect(resolveMode([custom(true), { type: "custom", customType: STATE_ENTRY, data }], false)).toEqual({ on: true, source: "override" });
		}
	});
	test("/poteto-mode arguments", () => {
		expect(parseCommand("")).toEqual({ kind: "set", on: true });
		expect(parseCommand(" OFF ")).toEqual({ kind: "set", on: false });
		expect(parseCommand("auto")).toEqual({ kind: "auto" });
		expect(parseCommand("status")).toEqual({ kind: "status" });
		expect(parseCommand("lite")).toEqual({ kind: "invalid", text: "lite" });
	});
});

describe("prompt sections", () => {
	const base = () => ({
		packageRoot: "/pkg",
		config: { activate: [], supersedes: ["ponytail"] },
		roles: {},
		tools: ["read", "subagent", "todo", "ask_user_question", "typesafe_evaluate"],
		primitives: "# map\nMAP BODY",
	});

	test("on: adds the route section with the absolute skill path and the map, and deletes superseded sections", () => {
		const sections: Record<string, string> = {};

		sections.ponytail = "lazy dev rules";
		sections.other = "keep";
		applySections(sections, true, base());
		expect(sections.ponytail).toBeUndefined();
		expect(sections.other).toBe("keep");
		expect(sections[SECTION_ROUTE]).toContain("/pkg/vendor/skills/poteto-mode/SKILL.md");
		expect(sections[SECTION_ROUTE]).toContain("MAP BODY");
		expect(sections[SECTION_ROUTE]).not.toContain("Missing in this session");
		expect(sections[SECTION_ROLES]).toBeUndefined();
	});

	test("off: removes our sections and leaves everyone else's alone", () => {
		const sections: Record<string, string> = {};

		sections[SECTION_ROUTE] = "stale";
		sections[SECTION_ROLES] = "stale";
		sections.ponytail = "lazy dev rules";
		applySections(sections, false, base());
		expect(sections[SECTION_ROUTE]).toBeUndefined();
		expect(sections[SECTION_ROLES]).toBeUndefined();
		expect(sections.ponytail).toBe("lazy dev rules");
	});

	test("missing tools are named so the skills degrade with a label instead of failing", () => {
		const sections: Record<string, string> = {};
		applySections(sections, true, { ...base(), tools: ["read"] });
		const route = sections[SECTION_ROUTE];
		expect(route).toContain("Missing in this session");
		expect(route).toContain("`subagent` is not available");
		expect(route).toContain("single reviewer, no independent panel");
		expect(route).toContain("`typesafe_evaluate` is not available");
	});

	test("the role table renders only configured roles, lists stay lists", () => {
		const sections: Record<string, string> = {};
		applySections(sections, true, {
			...base(),
			roles: { "bug-fix": "anthropic/claude-opus-5-5:xhigh", "interrogate reviewers": ["anthropic/claude-opus-5-5:xhigh", "openai-codex/gpt-6-astra:high"] },
		});
		const roles = sections[SECTION_ROLES];
		expect(roles).toContain("bug-fix: anthropic/claude-opus-5-5:xhigh");
		expect(roles).toContain("interrogate reviewers: anthropic/claude-opus-5-5:xhigh, openai-codex/gpt-6-astra:high");
		expect(roles).not.toContain("hillclimb");
	});

	test("the route section stays under a token budget", () => {
		const sections: Record<string, string> = {};
		const primitives = Bun.file(join(import.meta.dir, "..", "references", "pi-primitives.md"));

		return primitives.text().then((text) => {
			applySections(sections, true, { ...base(), primitives: text });
			// About 4 chars per token; the whole section must stay near 2k tokens so it is cheap on every turn.
			expect(sections[SECTION_ROUTE].length).toBeLessThan(9000);
		});
	});
});
