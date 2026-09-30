import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

// Shared harness for offline Pi RPC checks: temp agent dir with fake OAuth,
// scrubbed env, and a get_state + get_commands round trip. No prompts are sent.

export const piBin = Bun.spawnSync(["mise", "which", "pi"]).stdout.toString().trim();

export type State = { model: { provider: string; id: string }; thinkingLevel: string };

type RpcRecord = { id?: string; type?: string; success?: boolean; data?: unknown };

export function tempAgentDir(prefix: string, settingsJson: string): string {
	const agentDir = mkdtempSync(join(tmpdir(), prefix));

	writeFileSync(join(agentDir, "settings.json"), settingsJson);

	// Fake, unexpired OAuth entries so both providers count as configured; runs are --offline.
	const fake = { type: "oauth", access: "fake", refresh: "fake", expires: Date.now() + 3_600_000, accountId: "fake" };

	writeFileSync(join(agentDir, "auth.json"), JSON.stringify({ "my-codex": fake, "openai-codex": fake }), { mode: 0o600 });

	return agentDir;
}

// Drop inherited profile/tmux hints so only the test settings pick the preset.
const inheritedProfileKey = /^(TMUX$|PI_(PROFILE|MODEL_SCOPE|MULTI_PASS_PRESET|SUB_PRESET|PRESET))/;

export function testEnv(agentDir: string): Record<string, string> {
	const env = Object.fromEntries(
		Object.entries(process.env).filter(([key, value]) => value !== undefined && !inheritedProfileKey.test(key)),
	);

	env.PI_CODING_AGENT_DIR = agentDir;

	env.PI_OFFLINE = "1";

	return env;
}

export async function rpc(args: string[], env: Record<string, string>): Promise<{ state: State; commands: string[] }> {
	const proc = Bun.spawn([piBin, "--mode", "rpc", "--offline", "--no-session", ...args], {
		env,
		stdin: "pipe",
		stdout: "pipe",
		stderr: "pipe",
	});

	proc.stdin.write('{"id":"state","type":"get_state"}\n{"id":"commands","type":"get_commands"}\n');
	proc.stdin.flush();

	const responses = new Map<string, RpcRecord>();
	const decoder = new TextDecoder();
	let buffer = "";

	try {
		for await (const chunk of proc.stdout) {
			buffer += decoder.decode(chunk, { stream: true });

			const lines = buffer.split("\n");

			buffer = lines.pop() ?? "";

			for (const line of lines.filter((l) => l.startsWith("{"))) {
				// SAFETY: Pi RPC stdout lines starting with "{" are JSON protocol records.
				const msg = JSON.parse(line) as RpcRecord;

				if (msg.type === "response" && msg.id) responses.set(msg.id, msg);
			}

			if (responses.has("state") && responses.has("commands")) break;
		}
	} finally {
		proc.kill();
	}

	const state = responses.get("state");
	const commands = responses.get("commands");

	if (!state?.success || !commands?.success) {
		throw new Error(`rpc failed: ${await new Response(proc.stderr).text()}`);
	}

	return {
		// SAFETY: successful get_state responses carry the RpcSessionState shape.
		state: state.data as State,
		// SAFETY: successful get_commands responses carry { commands: RpcSlashCommand[] }.
		commands: (commands.data as { commands: { name: string }[] }).commands.map((c) => c.name),
	};
}
