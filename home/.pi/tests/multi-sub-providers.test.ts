import { afterAll, describe, expect, test } from "bun:test";
import { rmSync } from "node:fs";
import { join, resolve } from "node:path";
import { rpc, tempAgentDir, testEnv } from "./pi-rpc.fixture.ts";

// Restricted children run `pi --no-extensions -e <ext> --model my-codex/...`.
// The providers-only entry must resolve that alias model and leave it alone;
// the full multi-sub extension is the control, since its session_start
// activatePreset switches to the preset's first entry.

const extensions = resolve(import.meta.dir, "../agent/extensions");

const providersEntry = join(extensions, "multi-sub-providers/providers.ts");

const fullEntry = join(extensions, "multi-sub.ts");

const agentDir = tempAgentDir(
	"multi-sub-providers-",
	JSON.stringify({
		multiSub: {
			subscriptions: [
				{ provider: "openai-codex", alias: "openai-codex" },
				{ provider: "openai-codex", alias: "my-codex" },
			],
			presets: [
				{
					name: "mega",
					enabled: true,
					entries: [{ provider: "openai-codex", model: "gpt-6-astra", enabled: true }],
				},
			],
		},
	}),
);

afterAll(() => rmSync(agentDir, { recursive: true, force: true }));

const env = testEnv(agentDir);

const run = (extension: string) =>
	rpc(["--no-extensions", "-e", extension, "--model", "my-codex/gpt-5.6-luna:medium"], env);

describe("multi-sub providers-only entry", () => {
	test(
		"resolves the alias model without preset switching or multi-sub commands",
		async () => {
			const { state, commands } = await run(providersEntry);

			expect(state.model).toMatchObject({ provider: "my-codex", id: "gpt-5.6-luna" });
			expect(state.thinkingLevel).toBe("medium");
			expect(commands).not.toContain("subs");
		},
		60_000,
	);

	test(
		"control: the full extension's activatePreset overrides the explicit model",
		async () => {
			const { state, commands } = await run(fullEntry);

			expect(state.model).toMatchObject({ provider: "openai-codex", id: "gpt-6-astra" });
			expect(commands).toContain("subs");
		},
		60_000,
	);
});
