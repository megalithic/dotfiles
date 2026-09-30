import { afterAll, describe, expect, test } from "bun:test";
import { existsSync, readFileSync, rmSync, symlinkSync } from "node:fs";
import { join, resolve } from "node:path";
import { loadConfig } from "../agent/extensions/observational-memory/src/config.ts";
import { AGENT_EXTENSION_PATH, buildWorkerArgv } from "../agent/extensions/observational-memory/src/spawn/launch.ts";
import { rpc, tempAgentDir, testEnv } from "./pi-rpc.fixture.ts";

// OM workers spawn `pi --no-extensions ... -e <worker>` directly, bypassing the
// bin/pi wrapper. buildWorkerArgv must add the multi-sub providers-only entry
// so the configured my-codex alias resolves, without loading full multi-sub.

const extensions = resolve(import.meta.dir, "../agent/extensions");

// SAFETY: the managed settings.json is a JSON object with an observational-memory block.
const managed = JSON.parse(readFileSync(resolve(import.meta.dir, "../agent/settings.json"), "utf8")) as { "observational-memory": object };

const agentDir = tempAgentDir(
	"om-worker-",
	JSON.stringify({
		multiSub: { subscriptions: [{ provider: "openai-codex", alias: "my-codex" }] },
		"observational-memory": managed["observational-memory"],
	}),
);

symlinkSync(extensions, join(agentDir, "extensions"));

const env = testEnv(agentDir);

// getAgentDir() reads PI_CODING_AGENT_DIR per call; restore it for other suites.
const previousAgentDir = process.env.PI_CODING_AGENT_DIR;

process.env.PI_CODING_AGENT_DIR = agentDir;

afterAll(() => {
	if (previousAgentDir === undefined) delete process.env.PI_CODING_AGENT_DIR;
	else process.env.PI_CODING_AGENT_DIR = previousAgentDir;

	rmSync(agentDir, { recursive: true, force: true });
});

function extensionArgs(argv: string[]): string[] {
	return argv.flatMap((arg, i) => (argv[i - 1] === "-e" ? [arg] : []));
}

describe("observational-memory worker launch", () => {
	const model = loadConfig(agentDir, {}).models.observer;

	const argv = buildWorkerArgv({ model, sessionName: "om-observer-test", kickoffPrompt: "unused" });

	test("uses the managed my-codex observer model", () => {
		expect(model).toMatchObject({ provider: "my-codex", id: "gpt-5.6-luna", thinking: "low" });
	});

	test("passes the providers-only entry and the worker, never full multi-sub", () => {
		expect(extensionArgs(argv)).toEqual([join(agentDir, "extensions/multi-sub-providers/providers.ts"), AGENT_EXTENSION_PATH]);
		expect(AGENT_EXTENSION_PATH.endsWith("/agent/worker.ts")).toBe(true);
		expect(existsSync(AGENT_EXTENSION_PATH)).toBe(true);
	});

	test(
		"resolves my-codex/gpt-5.6-luna offline with the worker flag set",
		async () => {
			// Keep the worker flags; drop the binary prefix and the -n/-p pairs (no prompt is sent).
			const flags = argv.slice(argv.indexOf("--no-extensions"));

			const workerFlags = flags.filter((_, i) => !["-n", "-p"].includes(flags[i]) && !["-n", "-p"].includes(flags[i - 1]));

			const { state, commands } = await rpc(workerFlags, env);

			expect(state.model).toMatchObject({ provider: "my-codex", id: "gpt-5.6-luna" });
			expect(state.thinkingLevel).toBe("low");
			expect(commands).not.toContain("subs");
		},
		60_000,
	);
});
