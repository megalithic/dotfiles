import { describe, expect, test } from "bun:test";
import { readFileSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";
import { applyRules, findDenied } from "../scripts/sync.mjs";

const root = join(import.meta.dir, "..");

const table = JSON.parse(readFileSync(join(root, "scripts/substitutions.json"), "utf8"));

function walk(dir: string, out: string[] = []): string[] {
	for (const name of readdirSync(dir)) {
		const p = join(dir, name);

		if (statSync(p).isDirectory()) walk(p, out);
		else if (p.endsWith(".md")) out.push(p);
	}

	return out;
}

describe("substitution rules", () => {
	test("Cursor primitives become pi tool names", () => {
		const out = applyRules("Use the Task tool, then `AskQuestion`. The rule is `~/.cursor/rules/pstack-models.mdc`.", table.rules);
		expect(out).toBe("Use the `subagent` tool, then `ask_user_question`. The rule is `~/.pi/agent/pi-stack/models.json`.");
	});
	test("documented slash commands become /skill: commands; extension commands stay", () => {
		const out = applyRules("Type /interrogate review this, or /poteto-mode, or /setup-pstack, or /recall x, or /bro.", table.rules);
		expect(out).toBe("Type /skill:interrogate review this, or /poteto-mode, or /setup-pstack, or /skill:pstack-recall x, or /skill:bro.");
	});
	test("applyRules records which rules matched", () => {
		const used = new Set<string>();

		applyRules("Use the Task tool.", table.rules, used);

		expect(used.size).toBeGreaterThan(0);
		expect(used.size).toBeLessThan(table.rules.length);
	});

	test("a prose path through a word is not rewritten", () => {
		expect(applyRules("the /how-to guide", table.rules)).toBe("the /how-to guide");
	});
	test("denylist catches what the rules missed", () => {
		const hits = findDenied("see ~/.cursor/projects/x\nfine line\n`Task tool`", table.deny.patterns);
		expect([...new Set(hits.map((h) => h.line))].sort()).toEqual([1, 3]);
	});
});

describe("vendored skills", () => {
	const skills = join(root, "vendor/skills");
	test("exist, with no denied pattern left", () => {
		const files = walk(skills);
		expect(files.length).toBeGreaterThan(100);
		const hits = files.flatMap((f) => findDenied(readFileSync(f, "utf8"), table.deny.patterns).map((h) => `${f}:${h.line}`));
		expect(hits).toEqual([]);
	});
	test("excluded and renamed skills", () => {
		const names = readdirSync(skills);
		expect(names).not.toContain("make-bot-ui");
		expect(names).not.toContain("bro");
		expect(names).not.toContain("recall");
		expect(names).toContain("pstack-recall");
		expect(readFileSync(join(skills, "pstack-recall/SKILL.md"), "utf8")).toMatch(/^name: pstack-recall$/m);
	});
	test("poteto-mode keeps disable-model-invocation so the catalog stays small", () => {
		expect(readFileSync(join(skills, "poteto-mode/SKILL.md"), "utf8")).toMatch(/^disable-model-invocation: true$/m);
	});
	test("every agent file carries the primitive map verbatim", () => {
		const map = readFileSync(join(root, "references/pi-primitives.md"), "utf8").trim();

		for (const name of readdirSync(join(root, "vendor/agents"))) {
			expect(readFileSync(join(root, "vendor/agents", name), "utf8")).toContain(map);
		}
	});

	test("the pin file matches what was vendored", () => {
		const pin = JSON.parse(readFileSync(join(root, "scripts/upstream.json"), "utf8"));
		const vendored = JSON.parse(readFileSync(join(root, "vendor/UPSTREAM.json"), "utf8"));
		expect(vendored.commit).toBe(pin.commit);
		expect(vendored.version).toBe(pin.version);
	});
});
