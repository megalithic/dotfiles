/**
 * Subprocess worker launch — the yt-edit `pi -e <ext> -p` pattern (L2).
 *
 * NOT the subagents extension: that uses `--no-session --mode json`, which would defeat
 * decision 11's requirement that every worker be an ordinary recorded GLOBAL session. We
 * spawn a plain headless `pi` with no `--session-dir`, so the run is recorded under the
 * project path in `~/.pi/agent/sessions` and is openable in the session browser.
 */
import { spawn } from "node:child_process";
import { existsSync, mkdirSync, realpathSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join, resolve } from "node:path";
import { getAgentDir } from "@earendil-works/pi-coding-agent";
import type { ConfiguredModel } from "../config.js";
import { runCostPath, runResultPath } from "./runs.js";

/** Repo root = two levels up from src/spawn/. The shared agent extension lives at agent/worker.ts. */
const REPO_ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");
export const AGENT_EXTENSION_PATH = join(REPO_ROOT, "agent", "worker.ts");

/**
 * Local: workers run with --no-extensions, so multi-sub alias providers (my-codex/...) would not
 * resolve. Load the providers-only entry (never full multi-sub, whose preset would override --model).
 */
export function providersExtensionPath(): string | undefined {
	const path = join(getAgentDir(), "extensions", "multi-sub-providers", "providers.ts");
	return existsSync(path) ? path : undefined;
}

export function modelArg(model: ConfiguredModel): string {
	return `${model.provider}/${model.id}`;
}

/** Resolve the `pi` entry point (subagents' trick), falling back to `pi` on PATH. */
export function resolvePiBinary(): { command: string; baseArgs: string[] } {
	const entry = process.argv[1];
	if (entry) {
		try {
			const realEntry = realpathSync(entry);
			if (/\.(?:mjs|cjs|js)$/i.test(realEntry)) {
				return { command: process.execPath, baseArgs: [realEntry] };
			}
		} catch {
			// fall through
		}
	}
	return { command: "pi", baseArgs: [] };
}

export function buildWorkerArgv(opts: {
	model: ConfiguredModel;
	sessionName: string;
	kickoffPrompt: string;
	agentExtensionPath?: string;
}): string[] {
	const pi = resolvePiBinary();
	const args = [
		...pi.baseArgs,
		"--no-extensions",
		"--no-skills",
		"--no-prompt-templates",
		"--no-context-files",
		"--no-builtin-tools",
		"--model",
		modelArg(opts.model),
	];
	if (opts.model.thinking) args.push("--thinking", opts.model.thinking);
	const providers = providersExtensionPath();
	if (providers) args.push("-e", providers);
	args.push("-e", opts.agentExtensionPath ?? AGENT_EXTENSION_PATH);
	args.push("-n", opts.sessionName);
	args.push("-p", opts.kickoffPrompt);
	return [pi.command, ...args];
}

export type WorkerExit = { code: number | null; signal: NodeJS.Signals | null; stderr: string };

/**
 * Spawn a headless worker; resolve when it exits. Workers run in their master session's
 * `.memory/<sessionId>/` root (not the project cwd) so pi keys the run into a distinct global
 * session bucket and it never clutters the project's `/resume` picker. The root is ensured to
 * exist before spawn — `spawn()` would ENOENT otherwise (the memory root is created lazily on
 * first durable write when there is no parent to seed).
 */
export function spawnWorker(opts: {
	argv: string[];
	cwd: string;
	env: NodeJS.ProcessEnv;
	signal?: AbortSignal;
}): Promise<WorkerExit> {
	const [command, ...rest] = opts.argv;
	mkdirSync(opts.cwd, { recursive: true });
	return new Promise<WorkerExit>((resolvePromise) => {
		const proc = spawn(command, rest, {
			cwd: opts.cwd,
			env: opts.env,
			stdio: ["ignore", "ignore", "pipe"],
		});
		let stderr = "";
		proc.stderr?.on("data", (d: Buffer) => {
			stderr += d.toString();
		});
		proc.on("error", () => resolvePromise({ code: 1, signal: null, stderr: stderr || "spawn error" }));
		proc.on("close", (code, signal) => resolvePromise({ code, signal, stderr }));

		if (opts.signal) {
			const kill = () => {
				proc.kill("SIGTERM");
				setTimeout(() => {
					if (!proc.killed) proc.kill("SIGKILL");
				}, 3000).unref?.();
			};
			if (opts.signal.aborted) kill();
			else opts.signal.addEventListener("abort", kill, { once: true });
		}
	});
}

export type ObserverLaunchEnv = {
	/** Absolute `.memory/<sessionId>/` root — IPC files and the consolidator sandbox live here. */
	memoryRoot: string;
	runId: string;
};

/**
 * Build the env a worker subprocess needs to write its result file. The chunk itself is NOT
 * passed via env/file — it is the `pi -p` prompt (recorded user message) so the run stays
 * faithfully inspectable on resume.
 */
export function buildWorkerEnv(role: "observer" | "consolidator", opts: ObserverLaunchEnv): NodeJS.ProcessEnv {
	return {
		...process.env,
		OM_WORKER: role,
		OM_RUN_ID: opts.runId,
		OM_RESULT_PATH: runResultPath(opts.memoryRoot, opts.runId),
		// Per-run cost handoff: the worker extension writes pi's built-in usage.cost.total here.
		OM_COST_PATH: runCostPath(opts.memoryRoot, opts.runId),
		// Sandbox root for the consolidator's scoped file tools (design risk 6).
		OM_MEMORY_DIR: opts.memoryRoot,
	};
}
